package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local MathGraph = require("softdep.MathGraph")

describe("MathGraph", function()
	local invalidEdges = {
		{ "missing vertices", nil, {} },
		{ "non-table vertices", false, {} },
		{ "non-set vertices", { a = false }, {} },
		{ "missing edges", {} },
		{ "non-table edges", {}, false },
		{ "non-table edge", { a = true }, { false } },
		{ "short edge", { a = true }, { { "a" } } },
		{ "long edge", { a = true }, { { "a", "a", "a" } } },
		{ "unknown source", { a = true }, { { "missing", "a" } } },
		{ "unknown target", { a = true }, { { "a", "missing" } } },
	}

	local invalidAdjLists = {
		{ "missing adjacency list" },
		{ "non-table adjacency list", false },
		{ "non-table neighbors", { a = false } },
		{ "non-set neighbors", { a = { a = false } } },
		{ "non-boolean membership", { a = { a = 1 } } },
		{ "unknown neighbor", { a = { missing = true } } },
	}

	describe("isEdges", function()
		it("accepts empty graphs and isolated vertices", function()
			assert.is_true(MathGraph.isEdges({}, {}))
			assert.is_true(MathGraph.isEdges({ a = true }, {}))
		end)

		it("accepts directed edges, duplicates and self edges", function()
			assert.is_true(MathGraph.isEdges({ a = true, b = true }, {
				{ "a", "b" },
				{ "a", "b" },
				{ "b", "a" },
				{ "a", "a" },
			}))
		end)

		it("preserves distinct vertex types and table identity", function()
			local key, other = {}, {}
			local vertices = { [1] = true, ["1"] = true, [false] = true, [key] = true }
			assert.is_true(MathGraph.isEdges(vertices, { { 1, "1" }, { "1", false }, { false, key } }))
			assert.is_false(MathGraph.isEdges(vertices, { { key, other } }))
		end)

		for _, case in ipairs(invalidEdges) do
			it("returns false for " .. case[1], function()
				assert.is_false(MathGraph.isEdges(case[2], case[3]))
			end)
		end
	end)

	describe("isAdjList", function()
		it("accepts empty graphs and isolated vertices", function()
			assert.is_true(MathGraph.isAdjList({}))
			assert.is_true(MathGraph.isAdjList({ a = {}, b = {} }))
		end)

		it("accepts directed edges, cycles and self edges", function()
			assert.is_true(MathGraph.isAdjList({ a = { b = true }, b = {} }))
			assert.is_true(MathGraph.isAdjList({ a = { b = true }, b = { a = true } }))
			assert.is_true(MathGraph.isAdjList({ a = { a = true } }))
		end)

		it("preserves distinct vertex types and table identity", function()
			local key, other = {}, {}
			assert.is_true(MathGraph.isAdjList({
				[1] = { ["1"] = true },
				["1"] = { [false] = true },
				[false] = { [key] = true },
				[key] = {},
			}))
			assert.is_false(MathGraph.isAdjList({ [key] = { [other] = true } }))
		end)

		for _, case in ipairs(invalidAdjLists) do
			it("returns false for " .. case[1], function()
				assert.is_false(MathGraph.isAdjList(case[2]))
			end)
		end
	end)

	describe("validation", function()
		for _, case in ipairs(invalidEdges) do
			it("edges2AdjList rejects " .. case[1], function()
				assert.has_error(
					function()
						MathGraph.edges2AdjList(case[2], case[3])
					end,
					"MathGraph.edges2AdjList: expected vertices to be a set with all values equal to true and edges to be an array of vertex pairs whose endpoints belong to vertices"
				)
			end)
		end

		for _, name in ipairs({ "isDAG", "revAdjList", "reachAdjList", "sort" }) do
			for _, case in ipairs(invalidAdjLists) do
				it(name .. " rejects " .. case[1], function()
					assert.has_error(
						function()
							MathGraph[name](case[2], false)
						end,
						"MathGraph."
							.. name
							.. ": expected adjList to map every vertex to a set of neighbors with all values equal to true and no unknown vertices"
					)
				end)
			end
		end

		it("reachAdjList requires an explicit boolean reflexive argument", function()
			assert.has_error(function()
				MathGraph.reachAdjList({})
			end, "MathGraph.reachAdjList: expected reflexive to be a boolean")
			for _, value in ipairs({ 0, "false", {} }) do
				assert.has_error(function()
					MathGraph.reachAdjList({}, value)
				end, "MathGraph.reachAdjList: expected reflexive to be a boolean")
			end
		end)
	end)

	describe("isDAG", function()
		local cases = {
			{ "empty graph", {}, true },
			{ "isolated vertices", { a = {}, b = {} }, true },
			{ "chain", { a = { b = true }, b = { c = true }, c = {} }, true },
			{ "diamond", { a = { b = true, c = true }, b = { d = true }, c = { d = true }, d = {} }, true },
			{ "disconnected DAG", { a = { b = true }, b = {}, c = { d = true }, d = {}, e = {} }, true },
			{ "self cycle", { a = { a = true } }, false },
			{ "cycle", { a = { b = true }, b = { c = true }, c = { a = true } }, false },
			{ "disconnected cycle", { a = { b = true }, b = {}, c = { d = true }, d = { c = true } }, false },
			{ "cycle after a root", { a = { b = true }, b = { c = true }, c = { b = true } }, false },
		}

		for _, case in ipairs(cases) do
			it("classifies a " .. case[1], function()
				assert.are.equal(case[3], MathGraph.isDAG(case[2]))
			end)
		end
	end)

	it("supports numeric, boolean and table vertices throughout graph operations", function()
		local key = {}
		local vertices = { [1] = true, ["1"] = true, [false] = true, [key] = true }
		local adjList = MathGraph.edges2AdjList(vertices, { { 1, "1" }, { "1", false }, { false, key } })
		assert.are.same(
			{ [1] = { ["1"] = true }, ["1"] = { [false] = true }, [false] = { [key] = true }, [key] = {} },
			adjList
		)
		assert.is_true(MathGraph.isDAG(adjList))
		assert.are.same({ 1, "1", false, key }, MathGraph.sort(adjList))
		assert.is_true(MathGraph.revAdjList(adjList)[key][false])
		assert.is_true(MathGraph.reachAdjList(adjList, false)[1][key])
	end)

	for _, name in ipairs({ "isDAG", "revAdjList", "reachAdjList", "sort" }) do
		it(name .. " does not modify the input adjacency list", function()
			local adjList = { a = { b = true }, b = { c = true }, c = {}, d = {} }
			MathGraph[name](adjList, true)
			assert.are.same({ a = { b = true }, b = { c = true }, c = {}, d = {} }, adjList)
		end)
	end

	for _, name in ipairs({ "revAdjList", "reachAdjList" }) do
		it(name .. " returns independent neighbor sets", function()
			local adjList = { a = { b = true }, b = {}, c = {} }
			local first = MathGraph[name](adjList, false)
			local second = MathGraph[name](adjList, false)
			first.a.extra = true
			first.b.extra = true
			assert.is_nil(first.c.extra)
			assert.is_nil(second.a.extra)
			assert.is_nil(second.b.extra)
			assert.are.same({ a = { b = true }, b = {}, c = {} }, adjList)
		end)
	end
	describe("edges2AdjList", function()
		it("creates an adjacency list from vertices and edges", function()
			local vertices = {
				a = true,
				b = true,
				c = true,
			}

			local edges = {
				{ "a", "b" },
				{ "a", "c" },
				{ "b", "c" },
			}

			assert.are.same({
				a = {
					b = true,
					c = true,
				},
				b = {
					c = true,
				},
				c = {},
			}, MathGraph.edges2AdjList(vertices, edges))
		end)

		it("creates empty sets for isolated vertices", function()
			local vertices = {
				a = true,
				b = true,
				c = true,
			}

			assert.are.same({
				a = {},
				b = {},
				c = {},
			}, MathGraph.edges2AdjList(vertices, {}))
		end)

		it("handles an empty graph", function()
			assert.are.same({}, MathGraph.edges2AdjList({}, {}))
		end)

		it("ignores duplicate edges", function()
			local vertices = {
				a = true,
				b = true,
			}

			local edges = {
				{ "a", "b" },
				{ "a", "b" },
			}

			assert.are.same({
				a = {
					b = true,
				},
				b = {},
			}, MathGraph.edges2AdjList(vertices, edges))
		end)
	end)

	describe("revAdjList", function()
		it("reverses all edges", function()
			local adjList = {
				a = {
					b = true,
					c = true,
				},
				b = {
					c = true,
				},
				c = {},
			}

			assert.are.same({
				a = {},
				b = {
					a = true,
				},
				c = {
					a = true,
					b = true,
				},
			}, MathGraph.revAdjList(adjList))
		end)

		it("preserves isolated vertices", function()
			local adjList = {
				a = {},
				b = {},
			}

			assert.are.same({
				a = {},
				b = {},
			}, MathGraph.revAdjList(adjList))
		end)

		it("preserves self edges", function()
			local adjList = {
				a = {
					a = true,
				},
				b = {},
			}

			assert.are.same(adjList, MathGraph.revAdjList(adjList))
		end)

		it("handles an empty graph", function()
			assert.are.same({}, MathGraph.revAdjList({}))
		end)

		it("is its own inverse", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {
					c = true,
				},
				c = {
					a = true,
				},
				d = {},
			}

			assert.are.same(adjList, MathGraph.revAdjList(MathGraph.revAdjList(adjList)))
		end)
	end)

	describe("reachAdjList", function()
		it("preserves direct reachability", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {},
				c = {},
			}

			local reach = MathGraph.reachAdjList(adjList, false)

			assert.is_true(reach.a.b)
			assert.is_nil(reach.a.a)
			assert.is_nil(reach.a.c)
			assert.is_nil(reach.b.a)
		end)

		it("adds transitive reachability", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {
					c = true,
				},
				c = {
					d = true,
				},
				d = {},
			}

			local reach = MathGraph.reachAdjList(adjList, false)

			assert.are.same({
				a = {
					b = true,
					c = true,
					d = true,
				},
				b = {
					c = true,
					d = true,
				},
				c = {
					d = true,
				},
				d = {},
			}, reach)
		end)

		it("does not add unrelated vertices", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {},
				c = {},
			}

			local reach = MathGraph.reachAdjList(adjList, false)

			assert.is_nil(reach.a.c)
			assert.is_nil(reach.c.a)
			assert.is_nil(reach.c.b)
		end)

		it("does not add reflexive reachability when reflexive is false", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {},
				c = {},
			}

			local reach = MathGraph.reachAdjList(adjList, false)

			assert.is_nil(reach.a.a)
			assert.is_nil(reach.b.b)
			assert.is_nil(reach.c.c)
		end)

		it("adds reflexive reachability when reflexive is true", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {},
				c = {},
			}

			local reach = MathGraph.reachAdjList(adjList, true)

			assert.is_true(reach.a.a)
			assert.is_true(reach.b.b)
			assert.is_true(reach.c.c)
			assert.is_true(reach.a.b)
		end)

		it("finds reflexive reachability caused by a cycle", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {
					c = true,
				},
				c = {
					a = true,
				},
			}

			local reach = MathGraph.reachAdjList(adjList, false)

			assert.are.same({
				a = {
					a = true,
					b = true,
					c = true,
				},
				b = {
					a = true,
					b = true,
					c = true,
				},
				c = {
					a = true,
					b = true,
					c = true,
				},
			}, reach)
		end)

		it("handles an empty graph", function()
			assert.are.same({}, MathGraph.reachAdjList({}, false))
			assert.are.same({}, MathGraph.reachAdjList({}, true))
		end)

		it("does not modify the input adjacency list", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {
					c = true,
				},
				c = {},
			}

			local original = {
				a = {
					b = true,
				},
				b = {
					c = true,
				},
				c = {},
			}

			MathGraph.reachAdjList(adjList, true)

			assert.are.same(original, adjList)
		end)
	end)

	describe("sort", function()
		local function positions(order)
			local result = {}

			for i, vertex in ipairs(order) do
				result[vertex] = i
			end

			return result
		end

		it("returns every vertex exactly once", function()
			local adjList = {
				a = {
					b = true,
					c = true,
				},
				b = {
					d = true,
				},
				c = {
					d = true,
				},
				d = {},
			}

			local order = MathGraph.sort(adjList)

			assert.are.equal(4, #order)

			local pos = positions(order)

			assert.is_not_nil(pos.a)
			assert.is_not_nil(pos.b)
			assert.is_not_nil(pos.c)
			assert.is_not_nil(pos.d)
		end)

		it("places every parent before its children", function()
			local adjList = {
				a = {
					b = true,
					c = true,
				},
				b = {
					d = true,
				},
				c = {
					d = true,
				},
				d = {},
			}

			local order = MathGraph.sort(adjList)
			local pos = positions(order)

			assert.is_true(pos.a < pos.b)
			assert.is_true(pos.a < pos.c)
			assert.is_true(pos.b < pos.d)
			assert.is_true(pos.c < pos.d)
		end)

		it("sorts a linear dependency chain", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {
					c = true,
				},
				c = {
					d = true,
				},
				d = {},
			}

			assert.are.same({ "a", "b", "c", "d" }, MathGraph.sort(adjList))
		end)

		it("handles isolated vertices", function()
			local adjList = {
				a = {},
				b = {},
				c = {},
			}

			local order = MathGraph.sort(adjList)
			local pos = positions(order)

			assert.are.equal(3, #order)
			assert.is_not_nil(pos.a)
			assert.is_not_nil(pos.b)
			assert.is_not_nil(pos.c)
		end)

		it("handles disconnected DAG components", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {},
				c = {
					d = true,
				},
				d = {},
				e = {},
			}

			local order = MathGraph.sort(adjList)
			local pos = positions(order)

			assert.are.equal(5, #order)
			assert.is_true(pos.a < pos.b)
			assert.is_true(pos.c < pos.d)
			assert.is_not_nil(pos.e)
		end)

		it("rejects a cycle", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {
					c = true,
				},
				c = {
					a = true,
				},
			}

			assert.has_error(function()
				MathGraph.sort(adjList)
			end, "MathGraph.sort: expected a DAG; adjList contains a cycle")
		end)

		it("rejects a self cycle", function()
			local adjList = {
				a = {
					a = true,
				},
			}

			assert.has_error(function()
				MathGraph.sort(adjList)
			end, "MathGraph.sort: expected a DAG; adjList contains a cycle")
		end)

		it("rejects a cycle in one disconnected component", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {},
				c = {
					d = true,
				},
				d = {
					c = true,
				},
			}

			assert.has_error(function()
				MathGraph.sort(adjList)
			end, "MathGraph.sort: expected a DAG; adjList contains a cycle")
		end)

		it("handles an empty graph", function()
			assert.are.same({}, MathGraph.sort({}))
		end)
	end)
end)
