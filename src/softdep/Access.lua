local MathGraph = require("softdep.MathGraph")
local MathSet = require("softdep.MathSet")

---@class softdep.AccessLevel
---@field func function
---@field os boolean

---@class softdep.Access
---@field levels table<string, softdep.AccessLevel>
---@field reachAdjList softdep.AdjList
---@field top string
---@field bot string
local Access = {}

---@param access softdep.Access
---@param atag1 string
---@param atag2 string
local function assertIncluded(access, atag1, atag2)
	if access.levels[atag1] ~= nil and access.levels[atag2] ~= nil then
		return
	end

	local missing = access.levels[atag1] == nil and atag1 or atag2
	error("unknown access level: " .. tostring(missing), 3)
end

---@param atag1 string
---@param atag2 string
---@return boolean
function Access:leq(atag1, atag2)
	assertIncluded(self, atag1, atag2)
	return self.reachAdjList[atag1][atag2]
end

---@param atag1 string
---@param atag2 string
---@return boolean
function Access:geq(atag1, atag2)
	assertIncluded(self, atag1, atag2)
	return self.reachAdjList[atag2][atag1]
end

---@param atag1 string
---@param atag2 string
---@return boolean
function Access:eq(atag1, atag2)
	assertIncluded(self, atag1, atag2)
	return atag1 == atag2
end

---@param atag1 string
---@param atag2 string
---@return boolean
function Access:lt(atag1, atag2)
	assertIncluded(self, atag1, atag2)
	return atag1 ~= atag2 and self.reachAdjList[atag1][atag2]
end

---@param atag1 string
---@param atag2 string
---@return boolean
function Access:gt(atag1, atag2)
	assertIncluded(self, atag1, atag2)
	return atag1 ~= atag2 and self.reachAdjList[atag2][atag1]
end

---@param levels table<string, softdep.AccessLevel>
---@param edges softdep.Edges
---@return boolean, nil|string
function Access.checkEdges(levels, edges)
	local atagSet = MathSet.tab2set(levels)

	do
		local ok, result = MathGraph.checkEdges(atagSet, edges)
		if not ok then
			return false, result
		end
	end

	for _, edge in ipairs(edges) do
		local A = levels[edge[1]]
		local B = levels[edge[2]]
		if A.os and not B.os then
			return false, "TODO"
		end
	end

	local adjList = MathGraph.edges2AdjList(atagSet, edges)
	do
		local ok, result = MathGraph.checkDAG(adjList)
		if not ok then
			return false, result
		end
	end

	local reachAdjList = MathGraph.reachAdjList(adjList, true)
	do
		local n = MathSet.count(atagSet)
		local top = false
		local bot = false
		for atag, _ in pairs(atagSet) do
			local m = MathSet.count(reachAdjList[atag])
			if m == 1 then
				if top then
					return false, "TODO"
				end
				top = true
			end
			if m == n then
				if bot then
					return false, "TODO"
				end
				bot = true
			end
		end
		if not top then
			return false, "TODO"
		end
		if not bot then
			return false, "TODO"
		end
	end

	return true
end

---@param levels table<string, softdep.AccessLevel>
---@param edges softdep.Edges
---@return softdep.Access
function Access.newAccess(levels, edges)
	do
		local ok, result = Access.checkEdges(levels, edges)
		if not ok then
			error(result, 2)
		end
	end

	local atagSet = MathSet.tab2set(levels)
	local adjList = MathGraph.edges2AdjList(atagSet, edges)

	local access = {
		reachAdjList = MathGraph.reachAdjList(adjList, true),
		levels = levels,
	}

	local n = MathSet.count(atagSet)
	for atag, _ in pairs(atagSet) do
		local m = MathSet.count(access.reachAdjList[atag])
		if m == 1 then
			access.top = atag
		end
		if m == n then
			access.bot = atag
		end
	end

	for k, v in pairs(Access) do
		access[k] = v
	end

	return access
end

---@param levels table<string, softdep.AccessLevel>
---@param edges softdep.Edges
---@return softdep.Access|nil, string|nil
function Access.createAccess(levels, edges)
	local atagSet = MathSet.tab2set(levels)

	for _, edge in ipairs(edges) do
		local A = levels[edge[1]]
		local B = levels[edge[2]]
		if A.os and not B.os then
			return nil, "TODO"
		end
	end

	local adjList = MathGraph.edges2AdjList(atagSet, edges)

	do
		local ok, result = MathGraph.checkDAG(adjList)
		if not ok then
			return nil, result
		end
	end

	local reachAdjList = MathGraph.reachAdjList(adjList, true)
	do
		local n = MathSet.count(atagSet)
		local top = false
		local bot = false
		for atag, _ in pairs(atagSet) do
			local m = MathSet.count(reachAdjList[atag])
			if m == 1 then
				if top then
					return nil, "TODO"
				end
				top = true
			end
			if m == n then
				if bot then
					return nil, "TODO"
				end
				bot = true
			end
		end
		if not top then
			return nil, "TODO"
		end
		if not bot then
			return nil, "TODO"
		end
	end

	do
		local ok, result = Access.checkEdges(levels, edges)
		if not ok then
			return nil, result
		end
	end

	local access = {
		reachAdjList = MathGraph.reachAdjList(adjList, true),
		levels = levels,
	}

	local n = MathSet.count(atagSet)
	for atag, _ in pairs(atagSet) do
		local m = MathSet.count(access.reachAdjList[atag])
		if m == 1 then
			access.top = atag
		end
		if m == n then
			access.bot = atag
		end
	end

	for k, v in pairs(Access) do
		access[k] = v
	end

	return access, nil
end

return Access
