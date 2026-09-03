local DM = require("softdep.DM")
local MathGraph = require("softdep.MathGraph")
local MathSet = require("softdep.MathSet")
local types = require("softdep.types")
local check = require("softdep.check")

local Access = {}

function Access.getKey(A)
	check(2, types.stringSet(A))

	local keys = MathSet.set2arr(A)
	table.sort(keys)
	local key = table.concat(keys, ";")
	return key
end

function Access.load(levels, leq)
	check(2, types.accessPosetLevels(levels))
	check(2, types.accessLeq(leq))

	for key, _ in pairs(levels) do
		if string.find(key, ";", 1, true) then
			check(2, false, "shouldn't have ;")
		end
	end

	local adjList = MathGraph.edges2AdjList(MathSet.tab2set(levels), leq)
	Access.reachAdjList = MathGraph.reachAdjList(adjList, true)
	Access.revReachAdjList = MathGraph.revAdjList(Access.reachAdjList)

	Access.lattice = DM.DM(adjList)
	Access._levels = levels

	Access.levels = {}
	for A, _ in pairs(Access.lattice) do
		local key = Access.getKey(A)
		Access.levels[key] = { set = A }
	end

	for a, info in pairs(levels) do
		local A = Access.revReachAdjList[a]
		local key = Access.getKey(A)
		assert(Access.levels[key] ~= nil)
		Access.levels[key].func = info.func
	end
end

function Access.join(...)
	local args = { ... }
	check(2, #args > 0, "expected at least one access level")

	for i = 1, #args do
		local arg = args[i]
		if Access.levels[arg] then
			args[i] = Access.levels[arg].set
		elseif Access._levels[arg] then
			args[i] = Access.revReachAdjList[arg]
		else
			check(2, false, "unknown access level: " .. tostring(arg))
		end
	end

	local A = MathSet.cup(table.unpack(args))
	A = DM.getClosure(Access.reachAdjList, A)
	local key = Access.getKey(A)
	assert(Access.levels[key])
	return key
end

function Access.meet(...)
	local args = { ... }
	check(2, #args > 0, "expected at least one access level")

	for i = 1, #args do
		local arg = args[i]
		if Access.levels[arg] then
			args[i] = Access.levels[arg].set
		elseif Access._levels[arg] then
			args[i] = Access.revReachAdjList[arg]
		else
			check(2, false, "unknown access level: " .. tostring(arg))
		end
	end

	local A = MathSet.cap(table.unpack(args))
	local key = Access.getKey(A)
	assert(Access.levels[key])
	return key
end

return Access
