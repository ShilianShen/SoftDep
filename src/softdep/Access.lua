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
---@return softdep.Access
function Access.newAccess(levels, edges)
	for _, edge in ipairs(edges) do
		if #edge ~= 2 then
			error("access relation must contain exactly two levels", 2)
		end

		local a, b = edge[1], edge[2]
		if levels[a] == nil then
			error("unknown access level in lt: " .. tostring(a), 2)
		end
		if levels[b] == nil then
			error("unknown access level in lt: " .. tostring(b), 2)
		end

		local A, B = levels[a], levels[b]
		if A.os and not B.os then
			error("order-sensitive shouldn't less than order-insensitive", 2)
		end
	end

	local atagSet = MathSet.tab2set(levels)
	local adjList = MathGraph.edges2AdjList(atagSet, edges)
	if not MathGraph.isDAG(adjList) then
		error("access relation must be acyclic", 2)
	end

	local access = {
		reachAdjList = MathGraph.reachAdjList(adjList, true),
		levels = levels,
	}

	local n = MathSet.count(atagSet)
	for atag, _ in pairs(atagSet) do
		local m = MathSet.count(access.reachAdjList[atag])
		if m == 1 then
			if access.top ~= nil then
				error("access relation has multiple top candidates", 2)
			end
			access.top = atag
		end
		if m == n then
			if access.bot ~= nil then
				error("access relation has multiple bot candidates", 2)
			end
			access.bot = atag
		end
	end

	if access.top == nil then
		error("top should be explicitly declared", 2)
	end
	if access.bot == nil then
		error("bot should be explicitly declared", 2)
	end

	for k, v in pairs(Access) do
		access[k] = v
	end

	return access
end

return Access
