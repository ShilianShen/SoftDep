local MathGraph = require("softdep.MathGraph")
local MathSet = require("softdep.MathSet")
local types = require("softdep.types")
local check = require("softdep.check")

local methods = {}

function methods.leq(access, atag1, atag2)
	return access.reachAdjList[atag1][atag2]
end

function methods.geq(access, atag1, atag2)
	return access.reachAdjList[atag2][atag1]
end

function methods.eq(_, atag1, atag2)
	return atag1 == atag2
end

function methods.lt(access, atag1, atag2)
	return atag1 ~= atag2 and access.reachAdjList[atag1][atag2]
end

function methods.gt(access, atag1, atag2)
	return atag1 ~= atag2 and access.reachAdjList[atag2][atag1]
end

local function newAccess(levels, lt)
	check(2, types.accessLevels(levels))
	check(2, types.accessLt(lt))

	for _, edge in ipairs(lt) do
		check(2, #edge == 2, "access relation must contain exactly two levels")

		local a, b = edge[1], edge[2]
		check(2, levels[a] ~= nil, "unknown access level in lt: " .. tostring(a))
		check(2, levels[b] ~= nil, "unknown access level in lt: " .. tostring(b))

		local A, B = levels[a], levels[b]
		check(2, not (A.os and not B.os), "order-sensitive shouldn't less than order-insensitive")
	end

	local atagSet = MathSet.tab2set(levels)
	local adjList = MathGraph.edges2AdjList(atagSet, lt)
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

	for k, v in pairs(methods) do
		assert(access[k] == nil)
		access[k] = v
	end

	return access
end

return newAccess
