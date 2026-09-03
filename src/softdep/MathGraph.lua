local types = require("softdep.types")
local check = require("softdep.check")
local MathGraph = {}
local MathSet = require("softdep.MathSet")

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

function MathGraph.reachAdjList(adjList, reflexive)
	check(2, types.adjList(adjList))
	check(2, types.boolean(reflexive))

	local reachAdjList = {}
	for v1, _ in pairs(adjList) do
		reachAdjList[v1] = {}
		for v2, _ in pairs(adjList[v1]) do
			reachAdjList[v1][v2] = true
		end
	end

	for v3, _ in pairs(adjList) do
		for v1, _ in pairs(adjList) do
			for v2, _ in pairs(adjList) do
				reachAdjList[v1][v2] = reachAdjList[v1][v2] or (reachAdjList[v1][v3] and reachAdjList[v3][v2])
			end
		end
	end

	if reflexive then
		for v, _ in pairs(adjList) do
			reachAdjList[v][v] = true
		end
	end

	return reachAdjList
end

function MathGraph.sort(adjList)
	check(2, types.adjList(adjList))

	local revAdjList = MathGraph.revAdjList(adjList)
	local indegrees = {}
	local stack = {}
	local order = {}

	for vtag, _ in pairs(revAdjList) do
		indegrees[vtag] = MathSet.count(revAdjList[vtag])
		if indegrees[vtag] == 0 then
			table.insert(stack, vtag)
		end
	end

	for _, _ in pairs(adjList) do
		local vtag = table.remove(stack)
		check(2, vtag ~= nil, "not a DAG")

		for ctag, _ in pairs(adjList[vtag]) do
			indegrees[ctag] = indegrees[ctag] - 1
			if indegrees[ctag] == 0 then
				table.insert(stack, ctag)
			end
		end
		table.insert(order, vtag)
	end

	return order
end

return MathGraph
