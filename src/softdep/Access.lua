local DM = require("softdep.DM")
local MathGraph = require("softdep.MathGraph")
local MathSet = require("softdep.MathSet")
local types = require("softdep.types")
local check = require("softdep.check")

local Access = {}

function MathSet.cup(...)
	local args = { ... }
	for _, arg in ipairs(args) do
		check(2, types.set(arg))
	end

	local set = {}
	for _, arg in ipairs(args) do
		for k, _ in pairs(arg) do
			set[k] = true
		end
	end
	return set
end

function MathSet.cap(...)
	local args = { ... }
	for _, arg in ipairs(args) do
		check(2, types.set(arg))
	end

	local set = {}
	for k, _ in pairs(table.remove(args)) do
		set[k] = true
	end
	for _, arg in ipairs(args) do
		for k, _ in pairs(set) do
			if not arg[k] then
				set[k] = nil
			end
		end
	end
	return set
end

function Access.getKey(A)
	check(2, types.accessLatticeLevels(A))

	local keys = MathSet.set2arr(A)
	table.sort(keys)
	local key = table.concat(keys, ";")
	return key
end

function Access.load(levels, leq)
	check(2, types.accessPosetLevels(levels))
	check(2, types.accessLeq(leq))

	local adjList = MathGraph.edges2AdjList(MathSet.tab2set(levels), leq)
	Access.reachAdjList = MathGraph.reachAdjList(adjList)
	Access.revReachAdjList = MathGraph.revAdjList(Access.reachAdjList)
	for v, _ in pairs(Access.reachAdjList) do
		Access.reachAdjList[v][v] = true
		Access.revReachAdjList[v][v] = true
	end
	Access.lattice = DM(adjList)
	Access._levels = levels

	Access.levels = {}
	for A, _ in pairs(Access.lattice) do
		local key = Access.getKey(A)
		Access.levels[key] = { set = A }
	end

	for a, info in pairs(levels) do
		local A = Access.revReachAdjList[a]
		local key = Access.getKey(A)
		Access.levels[key].func = info.func
	end
end

function Access.join(...)
	local args = { ... }
	for i = 1, #args do
		local arg = args[i]
		if Access.levels[arg] then
			args[i] = Access.levels[arg].set
		elseif Access._levels[arg] then
			args[i] = Access.revReachAdjLis[arg]
		else
			check(2, false, "no")
		end
	end

	local A = MathSet.cup(table.unpack(args))
	return Access.getKey(A)
end

function Access.meet(...)
	local args = { ... }
	for i = 1, #args do
		local arg = args[i]
		if Access.levels[arg] then
			args[i] = Access.levels[arg].set
		elseif Access._levels[arg] then
			args[i] = Access.revReachAdjLis[arg]
		else
			check(2, false, "no")
		end
	end

	local A = MathSet.cap(table.unpack(args))
	return Access.getKey(A)
end

return Access
