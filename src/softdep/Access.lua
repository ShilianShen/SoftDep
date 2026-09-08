local MathGraph = require("softdep.MathGraph")
local MathSet = require("softdep.MathSet")
local types = require("softdep.types")
local check = require("softdep.check")

local Access = {
	maxCount = 16,
}

function Access.newAccess(levels, leq)
	check(2, types.accessLevels(levels))
	check(2, types.accessLeq(leq))

	for _, edge in ipairs(leq) do
		check(2, #edge == 2, "access relation must contain exactly two levels")

		local a, b = edge[1], edge[2]
		check(2, levels[a] ~= nil, "unknown access level in leq: " .. tostring(a))
		check(2, levels[b] ~= nil, "unknown access level in leq: " .. tostring(b))

		local A, B = levels[a], levels[b]
		check(2, not (A.os and not B.os), "order-sensitive shouldn't less than order-insensitive")
	end

	local access = {
		leq = Access.leq,
		geq = Access.geq,
	}

	local adjList = MathGraph.edges2AdjList(MathSet.tab2set(levels), leq)
	check(2, MathGraph.isDAG(adjList), "access relation must be acyclic")

	access.reachAdjList = MathGraph.reachAdjList(adjList, true)
	access.levels = levels

	local n = MathSet.count(MathSet.tab2set(access.levels))
	for atag, _ in pairs(access.levels) do
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

	return access
end

function Access.leq(access, atag1, atag2)
	return access.reachAdjList[atag1][atag2]
end

function Access.geq(access, atag1, atag2)
	return access.reachAdjList[atag2][atag1]
end

return Access
