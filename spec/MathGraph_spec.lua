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
			end)
		end)

		it("rejects a self cycle", function()
			local adjList = {
				a = {
					a = true,
				},
			}

			assert.has_error(function()
				MathGraph.sort(adjList)
			end)
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
			end)
		end)

		it("handles an empty graph", function()
			assert.are.same({}, MathGraph.sort({}))
		end)
	end)
end)
