package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path
local assert = require("luassert")
local softdep = require("softdep")

local function identity(data)
	return data
end

local function config(nodes)
	return {
		access = {
			levels = {
				read = { func = identity, os = false },
				write = { func = identity, os = true },
			},
			leq = { { "read", "write" } },
		},
		default = { nodeAtag = "read", taskAtag = "write" },
		nodes = nodes or {},
	}
end

local function assertClean(graph)
	for _, node in pairs(graph.nodes) do
		assert.is_false(node.dirty)
		for _, task in pairs(node.tasks) do
			assert.is_false(task.dirty)
		end
	end
end

describe("softdep", function()
	describe("update counts", function()
		it("counts completed dirty updates, not spread calls or clean runs", function()
			local graph = softdep.newGraph(config({ main = { tasks = { first = {}, second = {} } } }))
			local node = graph.nodes.main
			assert.equal(0, node.count)
			assert.equal(0, node.tasks.first.count)
			assert.equal(0, node.tasks.second.count)
			graph:spread()
			graph:spread()
			assert.equal(0, node.count)
			assert.equal(0, node.tasks.first.count)
			graph:update()
			assert.equal(1, node.count)
			assert.equal(1, node.tasks.first.count)
			assert.equal(1, node.tasks.second.count)
			graph:run()
			graph:update()
			assert.equal(1, node.count)
			assert.equal(1, node.tasks.first.count)
			assert.equal(1, node.tasks.second.count)
			node.tasks.first.dirty = true
			graph:run()
			assert.equal(2, node.count)
			assert.equal(2, node.tasks.first.count)
			assert.equal(1, node.tasks.second.count)
		end)

		it("counts read task execution without counting a clean node again", function()
			local graph = softdep.newGraph(config({ main = { tasks = { read = { atag = "read" } } } }))
			local node = graph.nodes.main
			graph:run()
			node.tasks.read.dirty = true
			graph:run()
			assert.equal(2, node.tasks.read.count)
			assert.equal(1, node.count)
			assertClean(graph)
		end)

		it("counts an empty node only when dirty", function()
			local graph = softdep.newGraph(config({ main = {} }))
			local node = graph.nodes.main
			graph:run()
			assert.equal(1, node.count)
			graph:run()
			assert.equal(1, node.count)
			node.dirty = true
			graph:spread()
			assert.equal(1, node.count)
			graph:update()
			assert.equal(2, node.count)
		end)

		it("counts API-triggered work when executed, not when requested", function()
			local graph = softdep.newGraph(config({
				main = {
					tasks = { run = {} },
					apis = { trigger = { ttag = "run" } },
				},
			}))
			local node = graph.nodes.main
			graph:run()
			node.apis.trigger()
			node.apis.trigger()
			assert.equal(1, node.count)
			assert.equal(1, node.tasks.run.count)
			graph:run()
			assert.equal(2, node.count)
			assert.equal(2, node.tasks.run.count)
		end)
	end)

	it("runs an empty graph and an empty node", function()
		local empty = softdep.newGraph(config())
		empty:spread()
		empty:update()
		empty:run()
		local graph = softdep.newGraph(config({ main = {} }))
		graph:run()
		assertClean(graph)
	end)

	it("executes tasks in dependency order and skips clean tasks on the next run", function()
		local calls = {}
		local graph = softdep.newGraph(config({
			main = {
				tasks = {
					first = {
						func = function()
							calls[#calls + 1] = "first"
						end,
					},
					second = {
						parents_c = { "first" },
						func = function()
							calls[#calls + 1] = "second"
						end,
					},
				},
			},
		}))
		graph:run()
		assert.same({ "first", "second" }, calls)
		assertClean(graph)
		graph:run()
		assert.same({ "first", "second" }, calls)
	end)

	it("passes task access views and current parent data under every configured alias", function()
		local seen
		local c = config({
			source = { tasks = { produce = {
				func = function(view)
					view.raw.value = 42
				end,
			} } },
			sink = {
				tasks = {
					consume = {
						parents_d = { input = "source", alias = "source" },
						func = function(view, parents)
							seen = { view = view, parents = parents, value = parents.input.raw.value }
						end,
					},
				},
			},
		})
		c.access.levels.read.func = function(data)
			return { raw = data, kind = "read" }
		end
		c.access.levels.write.func = function(data)
			return { raw = data, kind = "write" }
		end
		local graph = softdep.newGraph(c)
		graph:run()
		assert.equal(42, seen.value)
		assert.equal(graph.nodes.sink.data_a.write, seen.view)
		assert.equal(graph.nodes.source.data_a.read, seen.parents.input)
		assert.equal(seen.parents.input, seen.parents.alias)
	end)

	it("spreads dirty state through control and data dependencies without executing tasks", function()
		local calls = 0
		local function count()
			calls = calls + 1
		end
		local graph = softdep.newGraph(config({
			source = {
				tasks = {
					read = { atag = "read", func = count },
					write = { parents_c = { "read" }, func = count },
					isolated = { func = count },
				},
			},
			middle = { tasks = { run = { parents_d = { input = "source" }, func = count } } },
			sink = { tasks = { run = { parents_d = { input = "middle" }, func = count } } },
		}))
		graph:run()
		calls = 0
		graph.nodes.source.tasks.read.dirty = true
		graph:spread()
		assert.equal(0, calls)
		assert.is_true(graph.nodes.source.tasks.write.dirty)
		assert.is_false(graph.nodes.source.tasks.isolated.dirty)
		assert.is_true(graph.nodes.middle.tasks.run.dirty)
		assert.is_true(graph.nodes.sink.tasks.run.dirty)
		graph:update()
		assert.equal(4, calls)
		assertClean(graph)
	end)

	for _, level in ipairs({ "read", "write" }) do
		it("propagates a " .. level .. " task according to its access level", function()
			local calls = { source = 0, sink = 0 }
			local graph = softdep.newGraph(config({
				source = {
					tasks = {
						run = {
							atag = level,
							func = function()
								calls.source = calls.source + 1
							end,
						},
					},
				},
				sink = {
					tasks = {
						run = {
							parents_d = { input = "source" },
							func = function()
								calls.sink = calls.sink + 1
							end,
						},
					},
				},
			}))
			graph:run()
			graph.nodes.source.tasks.run.dirty = true
			graph:run()
			assert.equal(2, calls.source)
			assert.equal(level == "write" and 2 or 1, calls.sink)
			assertClean(graph)
		end)
	end

	it("propagates explicitly dirty nodes even when they have no tasks", function()
		local calls = 0
		local graph = softdep.newGraph(config({
			source = {},
			sink = {
				tasks = {
					run = {
						parents_d = { input = "source" },
						func = function()
							calls = calls + 1
						end,
					},
				},
			},
		}))
		graph:run()
		graph.nodes.source.dirty = true
		graph:run()
		assert.equal(2, calls)
		assertClean(graph)
	end)

	it("checks auto only for clean tasks and passes the node data", function()
		local autoCalls, taskCalls = 0, 0
		local seen
		local graph = softdep.newGraph(config({
			main = {
				tasks = {
					run = {
						auto = function(data)
							autoCalls = autoCalls + 1
							seen = data
							return data.trigger
						end,
						func = function()
							taskCalls = taskCalls + 1
						end,
					},
				},
			},
		}))
		graph:run()
		assert.equal(0, autoCalls)
		graph:run()
		assert.equal(1, autoCalls)
		assert.equal(1, taskCalls)
		assert.equal(graph.nodes.main.data, seen)
		graph.nodes.main.data.trigger = true
		graph:run()
		assert.equal(2, autoCalls)
		assert.equal(2, taskCalls)
		assertClean(graph)
	end)

	it("binds APIs to independent graph nodes and forwards arguments before marking tasks dirty", function()
		local observed
		local c = config({
			main = {
				tasks = { run = {} },
				apis = {
					change = {
						ttag = "run",
						func = function(data, ...)
							observed =
								{ data = data, count = select("#", ...), first = select(1, ...), last = select(3, ...) }
							data.changed = true
						end,
					},
				},
			},
		})
		local first, second = softdep.newGraph(c), softdep.newGraph(c)
		first:run()
		second:run()
		first.nodes.main.apis.change("a", nil, "c")
		assert.equal(first.nodes.main.data, observed.data)
		assert.equal(3, observed.count)
		assert.equal("a", observed.first)
		assert.equal("c", observed.last)
		assert.is_true(first.nodes.main.tasks.run.dirty)
		assert.is_false(second.nodes.main.tasks.run.dirty)
		assert.is_nil(second.nodes.main.data.changed)
		assert.is_nil(c.nodes.main.apis.change._node)
		assert.is_nil(getmetatable(c.nodes.main.apis.change))
	end)

	it("supports function-only, task-only and empty APIs", function()
		local calls = 0
		local graph = softdep.newGraph(config({
			main = {
				tasks = { run = {} },
				apis = {
					funcOnly = {
						func = function()
							calls = calls + 1
						end,
					},
					taskOnly = { ttag = "run" },
					empty = {},
				},
			},
		}))
		graph:run()
		graph.nodes.main.apis.funcOnly()
		assert.equal(1, calls)
		assertClean(graph)
		graph.nodes.main.apis.empty()
		assertClean(graph)
		graph.nodes.main.apis.taskOnly()
		assert.is_true(graph.nodes.main.tasks.run.dirty)
	end)

	it("keeps a failed task dirty and retries it without rerunning completed predecessors", function()
		local fail, firstCalls, secondCalls = true, 0, 0
		local graph = softdep.newGraph(config({
			main = {
				tasks = {
					first = {
						func = function()
							firstCalls = firstCalls + 1
						end,
					},
					second = {
						parents_c = { "first" },
						func = function()
							secondCalls = secondCalls + 1
							if fail then
								error("task failed", 0)
							end
						end,
					},
				},
			},
		}))
		assert.has_error(function()
			graph:run()
		end, "task failed")
		assert.is_false(graph.nodes.main.tasks.first.dirty)
		assert.is_true(graph.nodes.main.tasks.second.dirty)
		assert.equal(1, graph.nodes.main.tasks.first.count)
		assert.equal(0, graph.nodes.main.tasks.second.count)
		assert.equal(0, graph.nodes.main.count)
		fail = false
		graph:run()
		assert.equal(1, firstCalls)
		assert.equal(2, secondCalls)
		assert.equal(1, graph.nodes.main.tasks.first.count)
		assert.equal(1, graph.nodes.main.tasks.second.count)
		assert.equal(1, graph.nodes.main.count)
		assertClean(graph)
	end)

	it("propagates auto errors before executing updates", function()
		local calls = 0
		local graph = softdep.newGraph(config({
			main = {
				tasks = {
					run = {
						func = function()
							calls = calls + 1
						end,
						auto = function()
							error("auto failed", 0)
						end,
					},
				},
			},
		}))
		graph:run()
		assert.has_error(function()
			graph:run()
		end, "auto failed")
		assert.equal(1, calls)
	end)

	it("propagates API callback errors", function()
		local graph = softdep.newGraph(config({
			main = { apis = {
				fail = {
					func = function()
						error("API failed", 0)
					end,
				},
			} },
		}))
		assert.has_error(function()
			graph.nodes.main.apis.fail()
		end, "API failed")
	end)
end)
