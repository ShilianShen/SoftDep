local MathGraph = require("softdep.MathGraph")
local MathSet = require("softdep.MathSet")
local assertOk = require("softdep.assertOk")

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

--- Preconditions:
--- - self.levels[atag1] ~= nil
--- - self.levels[atag2] ~= nil
---
---@param atag1 string
---@param atag2 string
---@return boolean
function Access:leq(atag1, atag2)
	assertIncluded(self, atag1, atag2)
	return self.reachAdjList[atag1][atag2]
end

--- Preconditions:
--- - self.levels[atag1] ~= nil
--- - self.levels[atag2] ~= nil
---
---@param atag1 string
---@param atag2 string
---@return boolean
function Access:geq(atag1, atag2)
	assertIncluded(self, atag1, atag2)
	return self.reachAdjList[atag2][atag1]
end

--- Preconditions:
--- - self.levels[atag1] ~= nil
--- - self.levels[atag2] ~= nil
---
---@param atag1 string
---@param atag2 string
---@return boolean
function Access:eq(atag1, atag2)
	assertIncluded(self, atag1, atag2)
	return atag1 == atag2
end

--- Preconditions:
--- - self.levels[atag1] ~= nil
--- - self.levels[atag2] ~= nil
---
---@param atag1 string
---@param atag2 string
---@return boolean
function Access:lt(atag1, atag2)
	assertIncluded(self, atag1, atag2)
	return atag1 ~= atag2 and self.reachAdjList[atag1][atag2]
end

--- Preconditions:
--- - self.levels[atag1] ~= nil
--- - self.levels[atag2] ~= nil
---
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

	local edgesOk, edgesResult = MathGraph.checkEdges(atagSet, edges)
	if not edgesOk then
		return false, edgesResult
	end

	for i, edge in ipairs(edges) do
		local A = levels[edge[1]]
		local B = levels[edge[2]]
		if A.os and not B.os then
			return false,
				string.format(
					"edge %d places order-sensitive access level %q below order-insensitive access level %q",
					i,
					edge[1],
					edge[2]
				)
		end
	end

	local adjList = MathGraph.edges2AdjList(atagSet, edges)

	local dagOk, dagResult = MathGraph.checkDAG(adjList)
	if not dagOk then
		return false, dagResult
	end

	local reachAdjList = MathGraph.reachAdjList(adjList, true)
	do
		local n = MathSet.count(atagSet)
		local top = nil
		local bot = nil
		for atag, _ in pairs(atagSet) do
			local m = MathSet.count(reachAdjList[atag])
			if m == 1 then
				if top then
					return false, string.format("expected a unique top access level; found both %q and %q", top, atag)
				end
				top = atag
			end
			if m == n then
				if bot then
					return false, string.format("expected a unique bottom access level; found both %q and %q", bot, atag)
				end
				bot = atag
			end
		end
		if not top then
			return false, "expected a top access level; none found"
		end
		if not bot then
			return false, "expected a bottom access level; none found"
		end
	end

	return true
end

--- Preconditions:
--- - Access.checkEdges(levels, edges)
---
---@param levels table<string, softdep.AccessLevel>
---@param edges softdep.Edges
---@return softdep.Access
function Access.newAccess(levels, edges)
	assertOk(Access.checkEdges(levels, edges))

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

return Access
