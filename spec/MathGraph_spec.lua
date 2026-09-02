package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path
local assert = require("luassert")
local MathGraph = require("softdep.MathGraph")

describe("MathGraph", function()
	describe("edges2AdjList", function()
		it("converts edges to an adjacency list", function()
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

			assert.same({
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

		it("preserves isolated vertices", function()
			local vertices = {
				a = true,
				b = true,
				c = true,
			}

			local edges = {
				{ "a", "b" },
			}

			assert.same({
				a = {
					b = true,
				},
				b = {},
				c = {},
			}, MathGraph.edges2AdjList(vertices, edges))
		end)

		it("handles an empty graph", function()
			assert.same({}, MathGraph.edges2AdjList({}, {}))
		end)

		it("handles vertices with no edges", function()
			assert.same(
				{
					a = {},
					b = {},
				},
				MathGraph.edges2AdjList({
					a = true,
					b = true,
				}, {})
			)
		end)

		it("deduplicates duplicate edges", function()
			local vertices = {
				a = true,
				b = true,
			}

			local edges = {
				{ "a", "b" },
				{ "a", "b" },
			}

			assert.same({
				a = {
					b = true,
				},
				b = {},
			}, MathGraph.edges2AdjList(vertices, edges))
		end)

		it("rejects an invalid vertex set", function()
			assert.has_error(function()
				MathGraph.edges2AdjList({
					a = false,
				}, {})
			end)
		end)

		it("rejects invalid edges", function()
			assert.has_error(function()
				MathGraph.edges2AdjList({}, "not an array")
			end)
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

			assert.same({
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
				a = {
					b = true,
				},
				b = {},
				c = {},
			}

			assert.same({
				a = {},
				b = {
					a = true,
				},
				c = {},
			}, MathGraph.revAdjList(adjList))
		end)

		it("handles an empty adjacency list", function()
			assert.same({}, MathGraph.revAdjList({}))
		end)

		it("reverses a self-loop to itself", function()
			local adjList = {
				a = {
					a = true,
				},
			}

			assert.same({
				a = {
					a = true,
				},
			}, MathGraph.revAdjList(adjList))
		end)

		it("rejects an invalid adjacency list", function()
			assert.has_error(function()
				MathGraph.revAdjList({
					a = {
						b = false,
					},
				})
			end)
		end)
	end)
end)
