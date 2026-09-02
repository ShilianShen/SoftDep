package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path
local assert = require("luassert")
local MathGraph = require("softdep.MathGraph")

describe("MathGraph", function()
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

			local reach = MathGraph.reachAdjList(adjList)

			assert.is_true(reach.a.b)
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

			local reach = MathGraph.reachAdjList(adjList)

			assert.is_true(reach.a.b)
			assert.is_true(reach.a.c)
			assert.is_true(reach.a.d)

			assert.is_true(reach.b.c)
			assert.is_true(reach.b.d)

			assert.is_true(reach.c.d)

			assert.is_nil(reach.b.a)
			assert.is_nil(reach.c.a)
			assert.is_nil(reach.d.a)
		end)

		it("does not add unrelated vertices", function()
			local adjList = {
				a = {
					b = true,
				},
				b = {},
				c = {},
			}

			local reach = MathGraph.reachAdjList(adjList)

			assert.is_nil(reach.a.c)
			assert.is_nil(reach.c.a)
			assert.is_nil(reach.c.b)
		end)

		it("handles an empty graph", function()
			assert.are.same({}, MathGraph.reachAdjList({}))
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
			end)
		end)

		it("handles an empty graph", function()
			assert.are.same({}, MathGraph.sort({}))
		end)
	end)
end)
