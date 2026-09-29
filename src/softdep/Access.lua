local MathGraph = require("softdep.MathGraph")
local MathSet = require("softdep.MathSet")
local check = require("softdep.check")

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
local function checkAtags(access, atag1, atag2)
	check(3, access.levels[atag1] ~= nil, "unknown access level: " .. tostring(atag1))
	check(3, access.levels[atag2] ~= nil, "unknown access level: " .. tostring(atag2))
end

---@param atag1 string
---@param atag2 string
---@return boolean
function Access:leq(atag1, atag2)
	checkAtags(self, atag1, atag2)
	return self.reachAdjList[atag1][atag2]
end

---@param atag1 string
---@param atag2 string
---@return boolean
function Access:geq(atag1, atag2)
	checkAtags(self, atag1, atag2)
	return self.reachAdjList[atag2][atag1]
end

---@param atag1 string
---@param atag2 string
---@return boolean
function Access:eq(atag1, atag2)
	checkAtags(self, atag1, atag2)
	return atag1 == atag2
end

---@param atag1 string
---@param atag2 string
---@return boolean
function Access:lt(atag1, atag2)
	checkAtags(self, atag1, atag2)
	return atag1 ~= atag2 and self.reachAdjList[atag1][atag2]
end

---@param atag1 string
---@param atag2 string
---@return boolean
function Access:gt(atag1, atag2)
	checkAtags(self, atag1, atag2)
	return atag1 ~= atag2 and self.reachAdjList[atag2][atag1]
end

---@param levels table<string, softdep.AccessLevel>
---@param edges softdep.Edges
---@return softdep.Access
function Access.newAccess(levels, edges)
	for _, edge in ipairs(edges) do
		check(2, #edge == 2, "access relation must contain exactly two levels")

		local a, b = edge[1], edge[2]
		check(2, levels[a] ~= nil, "unknown access level in lt: " .. tostring(a))
		check(2, levels[b] ~= nil, "unknown access level in lt: " .. tostring(b))

		local A, B = levels[a], levels[b]
		check(2, not (A.os and not B.os), "order-sensitive shouldn't less than order-insensitive")
	end

	local atagSet = MathSet.tab2set(levels)
	local adjList = MathGraph.edges2AdjList(atagSet, edges)
	check(2, MathGraph.isDAG(adjList), "access relation must be acyclic")

	local access = {
		reachAdjList = MathGraph.reachAdjList(adjList, true),
		levels = levels,
	}

	local n = MathSet.count(atagSet)
	for atag, _ in pairs(atagSet) do
		local m = MathSet.count(access.reachAdjList[atag])
		if m == 1 then
			check(2, access.top == nil, "access relation has multiple top candidates")
			access.top = atag
		end
		if m == n then
			check(2, access.bot == nil, "access relation has multiple bot candidates")
			access.bot = atag
		end
	end

	check(2, access.top ~= nil, "top should be explicitly declared")
	check(2, access.bot ~= nil, "bot should be explicitly declared")

	for k, v in pairs(Access) do
		access[k] = v
	end

	return access
end

return Access
