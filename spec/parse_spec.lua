package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local parse = require("softdep.parse")

local function identity(data)
	return data
end

local function makeConfig()
	return {
		access = {
			levels = {
				read = { func = identity, os = false },
				write = { func = identity, os = true },
			},
			leq = { { "read", "write" } },
		},
		default = { nodeAtag = "read", taskAtag = "write" },
		nodes = { main = { tasks = { run = {} } } },
	}
end

-- Independent vertices may appear in any order.
local function assertOrder(order, vertices, edges)
	local positions = {}
	for i, tag in ipairs(order) do
		assert.is_nil(positions[tag])
		positions[tag] = i
	end
	assert.are.equal(#vertices, #order)
	for _, tag in ipairs(vertices) do
		assert.is_not_nil(positions[tag])
	end
	for _, edge in ipairs(edges) do
		assert.is_true(positions[edge[1]] < positions[edge[2]])
	end
end

describe("softdep.parse", function()
	describe("defaults and initialization", function()
		it("accepts omitted nodes and creates an empty graph", function()
			local config = makeConfig()
			config.nodes = nil
			local graph = parse(config)
			for _, field in ipairs({ "nodes", "parents_d", "parents_n", "children_n", "children_d", "order" }) do
				assert.are.same({}, graph[field])
			end
			assert.is_nil(graph.default)
		end)

		it("initializes an empty node", function()
			local config = makeConfig()
			config.nodes.main = {}
			local node = parse(config).nodes.main
			for _, field in ipairs({ "tasks", "apis", "data", "parents_c", "children_c", "order" }) do
				assert.are.same({}, node[field])
			end
			assert.are.equal("read", node.atag)
			assert.is_true(node.dirty)
			assert.are.equal(0, node.count)
		end)

		it("completes tasks with defaults and callable no-ops", function()
			local graph = parse(makeConfig())
			local task = graph.nodes.main.tasks.run
			assert.are.equal("write", task.atag)
			assert.is_true(task.dirty)
			assert.are.equal(0, task.count)
			assert.is_function(task.func)
			assert.is_function(task.auto)
			assert.is_nil(task.func())
			assert.is_nil(task.auto())
			assert.are.same({ run = {} }, graph.nodes.main.parents_c)
			assert.are.same({ main = { run = {} } }, graph.parents_d)
		end)

		it("preserves explicit tags, callbacks and API definitions without executing them", function()
			local config = makeConfig()
			local function callback()
				error("must not execute while parsing")
			end
			config.nodes.main.atag = "write"
			config.nodes.main.tasks.run = { atag = "read", func = callback, auto = callback }
			config.nodes.main.apis = {
				full = { func = callback, ttag = "run" },
				funcOnly = { func = callback },
				taskOnly = { ttag = "run" },
			}
			local node = parse(config).nodes.main
			assert.are.equal("write", node.atag)
			assert.are.equal("read", node.tasks.run.atag)
			assert.are.equal(callback, node.tasks.run.func)
			assert.are.equal(callback, node.tasks.run.auto)
			assert.are.same(config.nodes.main.apis, node.apis)
		end)

		it("constructs a usable access lattice", function()
			local access = parse(makeConfig()).access
			assert.are.equal("read", access.bot)
			assert.are.equal("write", access.top)
			assert.are.equal(access.poset.write, access:join("read", "write"))
			assert.are.equal(access.poset.read, access:meet("read", "write"))
		end)
	end)

	describe("data views and input isolation", function()
		it("calls each access function once per node with that node's data", function()
			local config = makeConfig()
			config.nodes.other = {}
			local calls = { read = {}, write = {} }
			for tag, level in pairs(config.access.levels) do
				level.func = function(data)
					calls[tag][#calls[tag] + 1] = data
					return { source = data }
				end
			end
			local graph = parse(config)
			for tag, inputs in pairs(calls) do
				assert.are.equal(2, #inputs)
				assert.is_false(inputs[1] == inputs[2])
				for _, node in pairs(graph.nodes) do
					assert.are.equal(node.data, node.data_a[tag].source)
					assert.is_true(inputs[1] == node.data or inputs[2] == node.data)
				end
			end
		end)

		it("does not mutate the input and creates independent parse results", function()
			local config = makeConfig()
			config.nodes.main.tasks.next = { parents_c = { "run" }, parents_d = { input = "source" } }
			config.nodes.source = {}
			local first = parse(config)
			local second = parse(config)
			first.nodes.main.data.value = 1
			first.parents_d.main.next.input = "changed"
			first.nodes.main.parents_c.next.run = nil
			first.access.levels.read.os = true
			assert.are.same({ parents_c = { "run" }, parents_d = { input = "source" } }, config.nodes.main.tasks.next)
			assert.are.same({}, config.nodes.main.tasks.run)
			assert.is_nil(config.nodes.main.data)
			assert.are.same({ nodeAtag = "read", taskAtag = "write" }, config.default)
			assert.is_false(config.access.levels.read.os)
			assert.are.same({}, second.nodes.main.data)
			assert.are.equal("source", second.parents_d.main.next.input)
			assert.is_true(second.nodes.main.parents_c.next.run)
			assert.is_false(second.access.levels.read.os)
		end)

		for _, value in ipairs({ false, 1, "invalid" }) do
			it("rejects a data view of type " .. type(value), function()
				local config = makeConfig()
				config.access.levels.read.func = function()
					return value
				end
				assert.has_error(function()
					parse(config)
				end)
			end)
		end

		it("rejects a nil data view", function()
			local config = makeConfig()
			config.access.levels.read.func = function() end
			assert.has_error(function()
				parse(config)
			end)
		end)

		it("checks each actual return value from a stateful access function", function()
			local config = makeConfig()
			config.nodes.other = {}
			local calls = 0
			config.access.levels.read.func = function(data)
				calls = calls + 1
				if calls == 1 then
					return data
				end
			end
			assert.has_error(function()
				parse(config)
			end)
			assert.are.equal(2, calls)
		end)

		it("propagates access callback errors", function()
			local config = makeConfig()
			config.access.levels.read.func = function()
				error("view failed", 0)
			end
			assert.has_error(function()
				parse(config)
			end, "view failed")
		end)
	end)

	describe("dependency construction", function()
		it("builds both task edge directions and sorts a branching DAG", function()
			local config = makeConfig()
			config.nodes.main.tasks = {
				start = {},
				left = { parents_c = { "start", "start" } },
				right = { parents_c = { "start" } },
				finish = { parents_c = { "left", "right" } },
				isolated = {},
			}
			local node = parse(config).nodes.main
			assert.are.same(
				{
					start = {},
					left = { start = true },
					right = { start = true },
					finish = { left = true, right = true },
					isolated = {},
				},
				node.parents_c
			)
			assert.are.same(
				{
					start = { left = true, right = true },
					left = { finish = true },
					right = { finish = true },
					finish = {},
					isolated = {},
				},
				node.children_c
			)
			assertOrder(node.order, { "start", "left", "right", "finish", "isolated" }, {
				{ "start", "left" },
				{ "start", "right" },
				{ "left", "finish" },
				{ "right", "finish" },
			})
			for _, task in pairs(node.tasks) do
				assert.is_nil(task.parents_c)
				assert.is_nil(task.parents_d)
			end
		end)

		it("preserves data aliases and indexes every dependent task and node", function()
			local config = makeConfig()
			config.nodes = {
				source = {},
				isolated = {},
				left = {
					tasks = {
						a = { parents_d = { x = "source", y = "source" } },
						b = { parents_d = { z = "source" } },
					},
				},
				right = { tasks = { a = { parents_d = { input = "source" } } } },
				finish = { tasks = { merge = { parents_d = { x = "left", y = "right" } } } },
			}
			local graph = parse(config)
			assert.are.same(
				{
					source = {},
					isolated = {},
					left = { a = { x = "source", y = "source" }, b = { z = "source" } },
					right = { a = { input = "source" } },
					finish = { merge = { x = "left", y = "right" } },
				},
				graph.parents_d
			)
			assert.are.same(
				{
					source = {},
					isolated = {},
					left = { source = true },
					right = { source = true },
					finish = { left = true, right = true },
				},
				graph.parents_n
			)
			assert.are.same(
				{
					source = { left = true, right = true },
					isolated = {},
					left = { finish = true },
					right = { finish = true },
					finish = {},
				},
				graph.children_n
			)
			assert.are.same(
				{
					source = { left = { a = true, b = true }, right = { a = true } },
					isolated = {},
					left = { finish = { merge = true } },
					right = { finish = { merge = true } },
					finish = {},
				},
				graph.children_d
			)
			assertOrder(graph.order, { "source", "isolated", "left", "right", "finish" }, {
				{ "source", "left" },
				{ "source", "right" },
				{ "left", "finish" },
				{ "right", "finish" },
			})
		end)
	end)

	describe("validation", function()
		local cases = {
			{
				"missing access",
				function(c)
					c.access = nil
				end,
			},
			{
				"missing defaults",
				function(c)
					c.default = nil
				end,
			},
			{
				"invalid nodes type",
				function(c)
					c.nodes = false
				end,
			},
			{
				"invalid task callback",
				function(c)
					c.nodes.main.tasks.run.func = true
				end,
			},
			{
				"invalid auto callback",
				function(c)
					c.nodes.main.tasks.run.auto = true
				end,
			},
			{
				"invalid access callback",
				function(c)
					c.access.levels.read.func = true
				end,
			},
			{
				"invalid order sensitivity",
				function(c)
					c.access.levels.read.os = "false"
				end,
			},
			{
				"invalid control parent type",
				function(c)
					c.nodes.main.tasks.run.parents_c = { 1 }
				end,
			},
			{
				"invalid data parent type",
				function(c)
					c.nodes.main.tasks.run.parents_d = { input = 1 }
				end,
			},
			{
				"short access edge",
				function(c)
					c.access.leq = { { "read" } }
				end,
			},
			{
				"long access edge",
				function(c)
					c.access.leq = { { "read", "write", "read" } }
				end,
			},
			{
				"unknown left access level",
				function(c)
					c.access.leq = { { "missing", "write" } }
				end,
			},
			{
				"unknown right access level",
				function(c)
					c.access.leq = { { "read", "missing" } }
				end,
			},
			{
				"reflexive access edge",
				function(c)
					c.access.leq = { { "read", "read" } }
				end,
			},
			{
				"access cycle",
				function(c)
					c.access.levels.write.os = false
					c.access.leq = { { "read", "write" }, { "write", "read" } }
				end,
			},
			{
				"order-sensitive below order-insensitive",
				function(c)
					c.access.levels.read.os = true
					c.access.levels.write.os = false
				end,
			},
			{
				"unknown node tag",
				function(c)
					c.nodes.main.atag = "missing"
				end,
			},
			{
				"unknown task tag",
				function(c)
					c.nodes.main.tasks.run.atag = "missing"
				end,
			},
			{
				"unknown default node tag",
				function(c)
					c.default.nodeAtag = "missing"
				end,
			},
			{
				"unknown default task tag",
				function(c)
					c.default.taskAtag = "missing"
				end,
			},
			{
				"unknown control parent",
				function(c)
					c.nodes.main.tasks.run.parents_c = { "missing" }
				end,
			},
			{
				"unknown data parent",
				function(c)
					c.nodes.main.tasks.run.parents_d = { input = "missing" }
				end,
			},
			{
				"unknown API task",
				function(c)
					c.nodes.main.apis = { api = { ttag = "missing" } }
				end,
			},
			{
				"control parent in another node",
				function(c)
					c.nodes.other = { tasks = { remote = {} } }
					c.nodes.main.tasks.run.parents_c = { "remote" }
				end,
			},
			{
				"task self cycle",
				function(c)
					c.nodes.main.tasks.run.parents_c = { "run" }
				end,
			},
			{
				"task cycle with an isolated task",
				function(c)
					c.nodes.main.tasks = { a = { parents_c = { "b" } }, b = { parents_c = { "a" } }, isolated = {} }
				end,
			},
			{
				"node self cycle",
				function(c)
					c.nodes.main.tasks.run.parents_d = { input = "main" }
				end,
			},
			{
				"node cycle with an isolated node",
				function(c)
					c.nodes.main.tasks.run.parents_d = { input = "other" }
					c.nodes.other = { tasks = { run = { parents_d = { input = "main" } } } }
					c.nodes.isolated = {}
				end,
			},
		}

		for _, case in ipairs(cases) do
			it("rejects " .. case[1], function()
				local config = makeConfig()
				case[2](config)
				assert.has_error(function()
					parse(config)
				end)
			end)
		end

		it("rejects a non-table configuration", function()
			assert.has_error(function()
				parse(nil)
			end)
			assert.has_error(function()
				parse(false)
			end)
		end)
	end)
end)
