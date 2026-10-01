local MathGraph = {}
local MathSet = require("softdep.MathSet")

---@alias softdep.Vertex string
---@alias softdep.Vertices softdep.Set
---@alias softdep.Edge [string, string]
---@alias softdep.Edges softdep.Edge[]
---@alias softdep.AdjList table<string, softdep.Set>

---@param vertices softdep.Vertices
---@param edges softdep.Edges
---@return boolean, nil|string
function MathGraph.checkEdges(vertices, edges)
	for _, edge in ipairs(edges) do
		local a, b = edge[1], edge[2]
		if #edge ~= 2 then
			return false, "TODO"
		elseif vertices[a] == nil then
			return false, "TODO"
		elseif vertices[b] == nil then
			return false, "TODO"
		end
	end
	return true
end

---@param adjList softdep.AdjList
---@return boolean, nil|string
function MathGraph.checkAdjList(adjList)
	for v1, _ in pairs(adjList) do
		for v2, _ in pairs(adjList[v1]) do
			if adjList[v2] == nil then
				return false, "TODO"
			end
		end
	end
	return true
end

---@param adjList softdep.AdjList
---@param uniqueness boolean|nil
---@return boolean, nil|string
function MathGraph.checkDAG(adjList, uniqueness)
	if not MathGraph.checkAdjList(adjList) then
		return false, "TODO"
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
			return false, "TODO"
		end

		local vtag = table.remove(stack)
		if vtag == nil then
			return false, "TODO"
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
	do
		local ok, result = MathGraph.checkEdges(vertices, edges)
		if not ok then
			error(result, 2)
		end
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
	do
		local ok, result = MathGraph.checkAdjList(adjList)
		if not ok then
			error(result, 2)
		end
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
	do
		local ok, result = MathGraph.checkAdjList(adjList)
		if not ok then
			error(result, 2)
		end
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
	do
		local ok, result = MathGraph.checkAdjList(adjList)
		if not ok then
			error(result, 2)
		end
	end

	do
		local ok, result = MathGraph.checkDAG(adjList, uniqueness)
		if not ok then
			error(result, 2)
		end
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
