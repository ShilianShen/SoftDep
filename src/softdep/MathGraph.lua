local MathGraph = {}
local MathSet = require("softdep.MathSet")

---@alias softdep.Vertex string
---@alias softdep.Vertices softdep.Set
---@alias softdep.Edge [string, string]
---@alias softdep.Edges softdep.Edge[]
---@alias softdep.AdjList table<string, softdep.Set>

---@param vertices softdep.Vertices
---@param edges softdep.Edges
---@return boolean
function MathGraph.isEdges(vertices, edges)
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

---@param adjList softdep.AdjList
---@return boolean
function MathGraph.isAdjList(adjList)
	for v1, _ in pairs(adjList) do
		for v2, _ in pairs(adjList[v1]) do
			if adjList[v2] == nil then
				return false
			end
		end
	end

	return true
end

---@param adjList softdep.AdjList
---@param uniqueness boolean|nil
---@return boolean
function MathGraph.isDAG(adjList, uniqueness)
	if not MathGraph.isAdjList(adjList) then
		error(
			"MathGraph.isDAG: expected adjList to map every vertex to a set of neighbors with all values equal to true and no unknown vertices",
			2
		)
	end

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
		if not (not uniqueness or #stack == 1) then
			error("MathGraph.isDAG: expected a unique topological order when uniqueness is enabled", 2)
		end

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

---@param vertices softdep.Set
---@param edges softdep.Edges
---@return softdep.AdjList
function MathGraph.edges2AdjList(vertices, edges)
	if not MathGraph.isEdges(vertices, edges) then
		error(
			"MathGraph.edges2AdjList: expected vertices to be a set with all values equal to true and edges to be an array of vertex pairs whose endpoints belong to vertices",
			2
		)
	end

	local adjList = {}

	for v, _ in pairs(vertices) do
		adjList[v] = {}
	end

	for _, e in ipairs(edges) do
		adjList[e[1]][e[2]] = true
	end

	return adjList
end

---@param adjList softdep.AdjList
---@return softdep.AdjList
function MathGraph.revAdjList(adjList)
	if not MathGraph.isAdjList(adjList) then
		error(
			"MathGraph.revAdjList: expected adjList to map every vertex to a set of neighbors with all values equal to true and no unknown vertices",
			2
		)
	end

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

---@param adjList softdep.AdjList
---@param reflexive boolean
---@return softdep.AdjList
function MathGraph.reachAdjList(adjList, reflexive)
	if not MathGraph.isAdjList(adjList) then
		error(
			"MathGraph.reachAdjList: expected adjList to map every vertex to a set of neighbors with all values equal to true and no unknown vertices",
			2
		)
	end

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

--- The topological order is intentionally unspecified.
--- Do not sort zero-indegree vertices: callers must not rely on
--- ordering constraints that are not represented by the DAG.
---@param adjList softdep.AdjList
---@param uniqueness boolean|nil
---@return string[]
function MathGraph.sort(adjList, uniqueness)
	if not MathGraph.isAdjList(adjList) then
		error(
			"MathGraph.sort: expected adjList to map every vertex to a set of neighbors with all values equal to true and no unknown vertices",
			2
		)
	end

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
        if not (#stack > 0) then
            error("MathGraph.sort: expected a DAG; adjList contains a cycle", 2)
        end
        if not (not uniqueness or #stack == 1) then
            error("MathGraph.sort: expected a unique topological order when uniqueness is enabled", 2)
        end

		local i = math.random(#stack)
		local vtag = table.remove(stack, i)

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
