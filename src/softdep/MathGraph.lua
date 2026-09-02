local types = require("softdep.types")
local check = require("softdep.check")
local MathGraph = {}

function MathGraph.edges2AdjList(vertices, edges)
	check(2, types.set(vertices))
	check(2, types.array(edges))

	local adjList = {}

	for v, _ in pairs(vertices) do
		adjList[v] = {}
	end

	for _, e in ipairs(edges) do
		adjList[e[1]][e[2]] = true
	end

	return adjList
end

function MathGraph.revAdjList(adjList)
	check(2, types.adjList(adjList))

	local revAdjList = {}

	for v, _ in pairs(adjList) do
		revAdjList[v] = {}
	end

	for v1, _ in pairs(adjList) do
		for v2, _ in pairs(adjList[v1]) do
			revAdjList[v2][v1] = true
		end
	end

	return revAdjList
end

return MathGraph
