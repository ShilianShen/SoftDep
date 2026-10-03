package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path
local assert = require("luassert")
local softdep = require("softdep")

local function identity(data)
	return data
end

local function config(nodes)
	nodes = nodes or {}
	for _, node in pairs(nodes) do
		node.atag = node.atag or "read"
		for _, task in pairs(node.tasks or {}) do
			task.atag = task.atag or "write"
			if task.back == nil then
				task.back = false
			end
		end
		for _, api in pairs(node.apis or {}) do
			api.atag = api.atag or "write"
			if api.dirty == nil then
				api.dirty = true
			end
		end
	end

	return {
		access = {
			levels = {
				read = { func = identity, os = false },
				write = { func = identity, os = true },
			},
			edges = { { "read", "write" } },
		},
		nodes = nodes,
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
	describe("newGraph", function()
		it("reports declaration validation errors", function()
			assert.has_error(function()
				softdep.newGraph(nil)
			end)
		end)

		it("rejects declarations that cannot be built", function()
			assert.has_error(function()
				softdep.newGraph(config({
					main = { tasks = { run = { parents_c = { "missing" } } } },
				}))
			end)
		end)
	end)

	describe("update counts", function()
		it("counts completed dirty updates, not spread calls or clean updates", function()
			local graph = softdep.newGraph(config({ main = { tasks = { first = {}, second = { parents_c = { "first" } } } } }))
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
			graph:update()
			graph:update()
			assert.equal(1, node.count)
			assert.equal(1, node.tasks.first.count)
			assert.equal(1, node.tasks.second.count)
			node.tasks.second.dirty = true
			graph:update()
			assert.equal(2, node.count)
			assert.equal(1, node.tasks.first.count)
			assert.equal(2, node.tasks.second.count)
		end)

		it("counts read task execution as a node update", function()
			local graph = softdep.newGraph(config({ main = { tasks = { read = { atag = "read" } } } }))
			local node = graph.nodes.main
			graph:update()
			node.tasks.read.dirty = true
			graph:update()
			assert.equal(2, node.tasks.read.count)
			assert.equal(2, node.count)
			assertClean(graph)
		end)

		it("counts an empty node only when dirty", function()
			local graph = softdep.newGraph(config({ main = {} }))
			local node = graph.nodes.main
			graph:update()
			assert.equal(1, node.count)
			graph:update()
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
			graph:update()
			node.apis.trigger()
			node.apis.trigger()
			assert.equal(1, node.count)
			assert.equal(1, node.tasks.run.count)
			graph:update()
			assert.equal(2, node.count)
			assert.equal(2, node.tasks.run.count)
		end)
	end)

	it("updates an empty graph and an empty node", function()
		local empty = softdep.newGraph(config())
		empty:spread()
		empty:update()
		local graph = softdep.newGraph(config({ main = {} }))
		graph:update()
		assertClean(graph)
	end)

	it("executes tasks in dependency order and skips clean tasks on the next update", function()
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
		graph:update()
		assert.same({ "first", "second" }, calls)
		assertClean(graph)
		graph:update()
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
		graph:update()
		assert.equal(42, seen.value)
		assert.equal(graph.nodes.sink.data_a.write, seen.view)
		assert.equal(graph._data.sink.consume, seen.parents)
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
					read = { atag = "read", parents_c = { "prepare" }, func = count },
					write = { parents_c = { "read" }, func = count },
					prepare = { func = count },
				},
			},
			middle = { tasks = { run = { parents_d = { input = "source" }, func = count } } },
			sink = { tasks = { run = { parents_d = { input = "middle" }, func = count } } },
		}))
		graph:update()
		calls = 0
		graph.nodes.source.tasks.read.dirty = true
		graph:spread()
		assert.equal(0, calls)
		assert.is_true(graph.nodes.source.tasks.write.dirty)
		assert.is_false(graph.nodes.source.tasks.prepare.dirty)
		assert.is_true(graph.nodes.middle.tasks.run.dirty)
		assert.is_true(graph.nodes.sink.tasks.run.dirty)
		graph:update()
		assert.equal(4, calls)
		assertClean(graph)
	end)

	for _, level in ipairs({ "read", "write" }) do
		it("propagates a non-back " .. level .. " task", function()
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
			graph:update()
			graph.nodes.source.tasks.run.dirty = true
			graph:update()
			assert.equal(2, calls.source)
			assert.equal(2, calls.sink)
			assertClean(graph)
		end)
	end

	it("executes front tasks forward and back tasks backward across nodes", function()
		local calls = {}
		local function record(name)
			return function()
				calls[#calls + 1] = name
			end
		end
		local graph = softdep.newGraph(config({
			first = {
				tasks = {
					front = { func = record("first.front") },
					back = { back = true, parents_c = { "front" }, func = record("first.back") },
				},
			},
			second = {
				tasks = {
					front = { parents_d = { input = "first" }, func = record("second.front") },
					back = { back = true, parents_c = { "front" }, func = record("second.back") },
				},
			},
			third = {
				tasks = {
					front = { parents_d = { input = "second" }, func = record("third.front") },
					back = { back = true, parents_c = { "front" }, func = record("third.back") },
				},
			},
		}))

		graph:update()

		assert.same({
			"first.front",
			"second.front",
			"third.front",
			"third.back",
			"second.back",
			"first.back",
		}, calls)
		assertClean(graph)
	end)

	it("runs a dirty back task without dirtying its node or data dependents", function()
		local calls = { back = 0, sink = 0 }
		local graph = softdep.newGraph(config({
			source = {
				tasks = {
					front = {},
					back = {
						back = true,
						parents_c = { "front" },
						func = function()
							calls.back = calls.back + 1
						end,
					},
				},
			},
			sink = {
				tasks = { run = {
					parents_d = { input = "source" },
					func = function()
						calls.sink = calls.sink + 1
					end,
				} },
			},
		}))
		graph:update()
		graph.nodes.source.tasks.back.dirty = true

		graph:update()

		assert.equal(2, calls.back)
		assert.equal(1, calls.sink)
		assert.equal(1, graph.nodes.source.count)
		assertClean(graph)
	end)

	it("activates clean back tasks when their node is dirty", function()
		local calls = 0
		local graph = softdep.newGraph(config({
			main = {
				tasks = { cleanup = {
					back = true,
					func = function()
						calls = calls + 1
					end,
				} },
			},
		}))
		graph:update()
		graph:update()
		assert.equal(1, calls)

		graph.nodes.main.dirty = true
		graph:spread()

		assert.is_true(graph.nodes.main.tasks.cleanup.dirty)
		assert.equal(1, calls)
		graph:update()
		assert.equal(2, calls)
		assertClean(graph)
	end)

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
		graph:update()
		graph.nodes.source.dirty = true
		graph:update()
		assert.equal(2, calls)
		assertClean(graph)
	end)

	it("checks auto only for clean tasks and passes the const node data", function()
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
		graph:update()
		assert.equal(0, autoCalls)
		graph:update()
		assert.equal(1, autoCalls)
		assert.equal(1, taskCalls)
		assert.equal(graph.nodes.main.data_const, seen)
		assert.are_not.equal(graph.nodes.main.data, seen)
		graph.nodes.main.data.trigger = true
		graph:update()
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
		first:update()
		second:update()
		first.nodes.main.apis.change("a", nil, "c")
		assert.equal(first.nodes.main.data, observed.data)
		assert.equal(3, observed.count)
		assert.equal("a", observed.first)
		assert.equal("c", observed.last)
		assert.is_true(first.nodes.main.dirty)
		assert.is_true(first.nodes.main.tasks.run.dirty)
		assert.is_false(second.nodes.main.dirty)
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
		graph:update()
		graph.nodes.main.apis.funcOnly()
		assert.equal(1, calls)
		assert.is_true(graph.nodes.main.dirty)
		assert.is_false(graph.nodes.main.tasks.run.dirty)
		graph:update()
		assert.equal(2, graph.nodes.main.count)
		assert.equal(1, graph.nodes.main.tasks.run.count)
		assertClean(graph)
		graph.nodes.main.apis.empty()
		assert.is_true(graph.nodes.main.dirty)
		assert.is_false(graph.nodes.main.tasks.run.dirty)
		graph:update()
		graph.nodes.main.apis.taskOnly()
		assert.is_true(graph.nodes.main.dirty)
		assert.is_true(graph.nodes.main.tasks.run.dirty)
	end)

	it("uses the API dirty flag independently of its function and task", function()
		local calls = 0
		local graph = softdep.newGraph(config({
			main = {
				tasks = { run = {} },
				apis = {
					clean = {
						func = function()
							calls = calls + 1
						end,
						ttag = "run",
						dirty = false,
					},
				},
			},
		}))
		graph:update()

		graph.nodes.main.apis.clean()

		assert.equal(1, calls)
		assert.is_false(graph.nodes.main.dirty)
		assert.is_true(graph.nodes.main.tasks.run.dirty)
	end)

	it("propagates function-only API changes to data dependents", function()
		local seen
		local graph = softdep.newGraph(config({
			source = {
				apis = { change = { func = function(data, value)
					data.value = value
				end } },
			},
			sink = { tasks = { consume = {
				parents_d = { input = "source" },
				func = function(_, parents)
					seen = parents.input.value
				end,
			} } },
		}))
		graph:update()
		graph.nodes.source.apis.change(42)
		assert.is_true(graph.nodes.source.dirty)
		assert.equal(1, graph.nodes.source.count)
		assert.is_false(graph.nodes.sink.tasks.consume.dirty)
		graph:spread()
		assert.is_true(graph.nodes.sink.tasks.consume.dirty)
		assert.is_nil(seen)
		graph:update()
		assert.equal(42, seen)
		assert.equal(2, graph.nodes.source.count)
		assert.equal(2, graph.nodes.sink.tasks.consume.count)
		assertClean(graph)
		graph:update()
		assert.equal(2, graph.nodes.source.count)
		assert.equal(2, graph.nodes.sink.tasks.consume.count)
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
			graph:update()
		end)
		assert.is_false(graph.nodes.main.tasks.first.dirty)
		assert.is_true(graph.nodes.main.tasks.second.dirty)
		assert.equal(1, graph.nodes.main.tasks.first.count)
		assert.equal(0, graph.nodes.main.tasks.second.count)
		assert.equal(0, graph.nodes.main.count)
		fail = false
		graph:update()
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
		graph:update()
		assert.has_error(function()
			graph:update()
		end)
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
		end)
	end)
end)
