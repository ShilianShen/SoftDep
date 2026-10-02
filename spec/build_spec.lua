package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local build = require("softdep.build")

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
			lt = { { "read", "write" } },
		},
		default = { nodeAtag = "read", taskAtag = "write", apiAtag = "write" },
		nodes = nodes or {},
	}
end

local function assertBuildFails(declaration)
	local ok = build(declaration)
	assert.is_false(ok)
end

describe("build", function()
	it("builds an empty graph", function()
		local ok, graph = build(config())

		assert.is_true(ok)
		assert.are.same({}, graph.nodes)
		assert.are.same({}, graph.parents_n)
		assert.are.same({}, graph.children_n)
		assert.are.same({}, graph.parents_d)
		assert.are.same({}, graph.children_d)
		assert.are.same({}, graph.order_n)
		assert.are.equal("read", graph.access.bot)
		assert.are.equal("write", graph.access.top)
	end)

	it("builds nodes, tasks and APIs with defaults", function()
		local ok, graph = build(config({
			main = {
				tasks = {
					first = {},
					second = { parents_c = { "first" } },
				},
				apis = {
					run = { ttag = "second" },
					inspect = {},
				},
			},
		}))

		assert.is_true(ok)
		local node = graph.nodes.main
		assert.are.equal("read", node.atag)
		assert.is_true(node.dirty)
		assert.are.equal(0, node.count)
		assert.are.same({}, node.data)
		assert.are.equal(node.data, node.data_a.read)
		assert.are.equal(node.data, node.data_a.write)
		assert.are.same({ first = {}, second = { first = true } }, node.parents_c)
		assert.are.same({ first = { second = true }, second = {} }, node.children_c)
		assert.are.same({ "first", "second" }, node.order_c)

		for _, task in pairs(node.tasks) do
			assert.is_function(task.func)
			assert.is_function(task.auto)
			assert.are.equal("write", task.atag)
			assert.is_true(task.dirty)
			assert.are.equal(0, task.count)
			assert.is_false(task.back)
		end

		assert.are.equal("second", node.apis.run.ttag)
		assert.are.equal("write", node.apis.run.atag)
		assert.is_true(node.apis.run.dirty)
		assert.is_nil(node.apis.inspect.ttag)
		assert.are.equal("write", node.apis.inspect.atag)
		assert.is_true(node.apis.inspect.dirty)
	end)

	it("preserves explicit functions and access tags", function()
		local taskFunc = function() end
		local autoFunc = function() end
		local apiFunc = function() end
		local ok, graph = build(config({
			main = {
				atag = "read",
				tasks = {
					run = { func = taskFunc, auto = autoFunc, atag = "read", back = true },
				},
				apis = {
					call = { func = apiFunc, ttag = "run", atag = "read", dirty = false },
				},
			},
		}))

		assert.is_true(ok)
		assert.are.equal(taskFunc, graph.nodes.main.tasks.run.func)
		assert.are.equal(autoFunc, graph.nodes.main.tasks.run.auto)
		assert.are.equal("read", graph.nodes.main.tasks.run.atag)
		assert.is_true(graph.nodes.main.tasks.run.back)
		assert.are.equal(apiFunc, graph.nodes.main.apis.call.func)
		assert.are.equal("read", graph.nodes.main.apis.call.atag)
		assert.is_false(graph.nodes.main.apis.call.dirty)
	end)

	it("allows control dependencies to enter and remain in back tasks", function()
		local ok, graph = build(config({
			main = {
				tasks = {
					front = {},
					firstBack = { parents_c = { "front" }, back = true },
					secondBack = { parents_c = { "firstBack" }, back = true },
				},
			},
		}))

		assert.is_true(ok)
		assert.are.same({ "front", "firstBack", "secondBack" }, graph.nodes.main.order_c)
	end)

	it("creates independent access views for every node", function()
		local declaration = config({ first = {}, second = {} })
		declaration.access.levels.read.func = function(data)
			return { data = data, level = "read" }
		end
		declaration.access.levels.write.func = function(data)
			return { data = data, level = "write" }
		end

		local ok, graph = build(declaration)

		assert.is_true(ok)
		for _, node in pairs(graph.nodes) do
			assert.are.equal(node.data, node.data_a.read.data)
			assert.are.equal(node.data, node.data_a.write.data)
			assert.are.equal("read", node.data_a.read.level)
			assert.are.equal("write", node.data_a.write.level)
			assert.are_not.equal(node.data_a.read, node.data_a.write)
		end
		assert.are_not.equal(graph.nodes.first.data, graph.nodes.second.data)
	end)

	it("builds node and task data dependencies", function()
		local ok, graph = build(config({
			source = { tasks = { produce = {} } },
			middle = {
				tasks = {
					consume = { parents_d = { input = "source", alias = "source" } },
				},
			},
			sink = {
				tasks = {
					consume = { parents_d = { input = "middle" } },
				},
			},
		}))

		assert.is_true(ok)
		assert.are.same({ source = {}, middle = { source = true }, sink = { middle = true } }, graph.parents_n)
		assert.are.same({ source = { middle = true }, middle = { sink = true }, sink = {} }, graph.children_n)
		assert.are.same({ source = { produce = {} }, middle = { consume = { input = "source", alias = "source" } }, sink = {
			consume = { input = "middle" },
		} }, graph.parents_d)
		assert.are.same({
			source = { middle = { consume = true } },
			middle = { sink = { consume = true } },
			sink = {},
		}, graph.children_d)

		local position = {}
		for i, tag in ipairs(graph.order_n) do
			position[tag] = i
		end
		assert.is_true(position.source < position.middle)
		assert.is_true(position.middle < position.sink)
	end)

	describe("validation", function()
		it("rejects invalid access relations", function()
			local declaration = config()
			declaration.access.lt = { { "missing", "write" } }
			assertBuildFails(declaration)
		end)

		for _, field in ipairs({ "nodeAtag", "taskAtag", "apiAtag" }) do
			it("rejects an unknown default " .. field, function()
				local declaration = config()
				declaration.default[field] = "missing"
				assertBuildFails(declaration)
			end)
		end

		for _, subject in ipairs({ "node", "task", "api" }) do
			it("rejects an unknown " .. subject .. " access tag", function()
				local declaration = config({
					main = {
						tasks = { run = {} },
						apis = { call = {} },
					},
				})
				if subject == "node" then
					declaration.nodes.main.atag = "missing"
				elseif subject == "task" then
					declaration.nodes.main.tasks.run.atag = "missing"
				else
					declaration.nodes.main.apis.call.atag = "missing"
				end
				assertBuildFails(declaration)
			end)
		end

		it("rejects an order-sensitive node access level", function()
			local declaration = config({ main = { atag = "write" } })
			assertBuildFails(declaration)
		end)

		it("rejects a non-table access view", function()
			local declaration = config({ main = {} })
			declaration.access.levels.read.func = function()
				return "not a table"
			end
			assertBuildFails(declaration)
		end)

		it("rejects an unknown control dependency", function()
			assertBuildFails(config({
				main = { tasks = { run = { parents_c = { "missing" } } } },
			}))
		end)

		it("rejects non-unique control dependency order", function()
			assertBuildFails(config({
				main = { tasks = { first = {}, second = {} } },
			}))
		end)

		it("rejects cyclic control dependencies", function()
			assertBuildFails(config({
				main = {
					tasks = {
						first = { parents_c = { "second" } },
						second = { parents_c = { "first" } },
					},
				},
			}))
		end)

		it("rejects a non-back task depending on a back task", function()
			assertBuildFails(config({
				main = {
					tasks = {
						back = { back = true },
						front = { parents_c = { "back" } },
					},
				},
			}))
		end)

		it("rejects an API referring to an unknown task", function()
			assertBuildFails(config({
				main = { apis = { call = { ttag = "missing" } } },
			}))
		end)

		it("rejects an unknown data dependency", function()
			assertBuildFails(config({
				main = { tasks = { run = { parents_d = { input = "missing" } } } },
			}))
		end)

		it("rejects cyclic data dependencies", function()
			assertBuildFails(config({
				first = { tasks = { run = { parents_d = { input = "second" } } } },
				second = { tasks = { run = { parents_d = { input = "first" } } } },
			}))
		end)
	end)
end)
