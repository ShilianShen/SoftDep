local types = require("softdep.types")
local check = require("softdep.check")
local MathGraph = {}
local MathSet = require("softdep.MathSet")

function MathGraph.isEdges(vertices, edges)
	if not types.set(vertices) then
		return false
	end

	if not types.edges(edges) then
		return false
	end

	for _, edge in ipairs(edges) do
		local a, b = edge[1], edge[2]
		if vertices[a] == nil then
			return false
		end
		if vertices[b] == nil then
			return false
		end
	end

	return true
end

function MathGraph.isAdjList(adjList)
	if not types.adjList(adjList) then
		return false
	end

	for v1, _ in pairs(adjList) do
		for v2, _ in pairs(adjList[v1]) do
			if adjList[v2] == nil then
				return false
			end
		end
	end

	return true
end

function MathGraph.isDAG(adjList)
	check(2, MathGraph.isAdjList(adjList))

	local revAdjList = MathGraph.revAdjList(adjList)
	local indegrees = {}
	local stack = {}

	for vtag, _ in pairs(revAdjList) do
		indegrees[vtag] = MathSet.count(revAdjList[vtag])
		if indegrees[vtag] == 0 then
			table.insert(stack, vtag)
		end
	end

	for _, _ in pairs(adjList) do
		local vtag = table.remove(stack)
		if vtag == nil then
			return false
		end

		for ctag, _ in pairs(adjList[vtag]) do
			indegrees[ctag] = indegrees[ctag] - 1
			if indegrees[ctag] == 0 then
				table.insert(stack, ctag)
			end
		end
	end

	return true
end

function MathGraph.edges2AdjList(vertices, edges)
	check(2, MathGraph.isEdges(vertices, edges))

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
	check(2, MathGraph.isAdjList(adjList))

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
	check(2, MathGraph.isAdjList(adjList))
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

-- The topological order is intentionally unspecified.
-- Do not sort zero-indegree vertices: callers must not rely on
-- ordering constraints that are not represented by the DAG.
function MathGraph.sort(adjList)
	check(2, MathGraph.isAdjList(adjList))

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
		local i = math.random(#stack)
		local vtag = table.remove(stack, i)
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
