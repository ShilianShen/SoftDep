local DM = require("softdep.DM")
local MathGraph = require("softdep.MathGraph")
local MathSet = require("softdep.MathSet")
local types = require("softdep.types")
local check = require("softdep.check")
local bit = require("softdep.bit")

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
		join = Access.join,
		meet = Access.meet,
	}
	local set = MathSet.tab2set(levels)
	local arr = MathSet.set2arr(set)
	table.sort(arr)
	check(2, #arr < Access.maxCount)
	local adjList = MathGraph.edges2AdjList(MathSet.tab2set(levels), leq)
	local lattice = DM.DM(adjList)
	local revReachAdjList = MathGraph.revAdjList(MathGraph.reachAdjList(adjList, true))

	access.levels = levels
	access.poset = {}
	access.closures = {}

	for i, atag in ipairs(arr) do
		local bitmask = 2 ^ (i - 1)
		access.poset[atag] = bitmask
	end

	local p2l = {}
	for atag, pmask in pairs(access.poset) do
		local lmask = pmask
		for latag, _ in pairs(revReachAdjList[atag]) do
			lmask = bit.bor(lmask, access.poset[latag])
		end
		p2l[pmask] = lmask
	end
	for atag, pmask in pairs(access.poset) do
		access.poset[atag] = p2l[pmask]
	end
	p2l = nil

	access.lattice = {}
	for atags, _ in pairs(lattice) do
		local lmask = 0
		for atag, _ in pairs(atags) do
			lmask = bit.bor(lmask, access.poset[atag])
		end
		access.lattice[lmask] = true
	end

	local top
	local bot

	for lmask in pairs(access.lattice) do
		top = top and bit.bor(top, lmask) or lmask
		bot = bot and bit.band(bot, lmask) or lmask
	end

	assert(top and access.lattice[top])
	assert(bot and access.lattice[bot])

	for atag, mask in pairs(access.poset) do
		if top == mask then
			access.top = atag
		end
		if bot == mask then
			access.bot = atag
		end
	end

	check(2, access.top ~= nil, "top should be explicitly declared")
	check(2, access.bot ~= nil, "bot should be explicitly declared")

	return access
end

local function makeArg(access, arg)
	if access.lattice[arg] then
		return arg
	elseif access.poset[arg] then
		return access.poset[arg]
	else
		check(2, false, "unknown access level: " .. tostring(arg))
	end
end

local function closure(access, mask)
	local result

	if access.closures[mask] then
		return access.closures[mask]
	end

	for lmask in pairs(access.lattice) do
		if bit.band(mask, lmask) == mask then
			result = result and bit.band(result, lmask) or lmask
		end
	end

	assert(result and access.lattice[result])

	access.closures[mask] = result

	return result
end

function Access.join(access, ...)
	local args = { ... }
	check(2, #args > 0, "expected at least one access level")

	for i = 1, #args do
		args[i] = makeArg(access, args[i])
	end

	local mask = table.remove(args)

	for _, arg in ipairs(args) do
		mask = bit.bor(mask, arg)
	end

	mask = closure(access, mask)

	assert(access.lattice[mask])

	return mask
end

function Access.meet(access, ...)
	local args = { ... }
	check(2, #args > 0, "expected at least one access level")

	for i = 1, #args do
		args[i] = makeArg(access, args[i])
	end

	local mask = table.remove(args)

	for _, arg in ipairs(args) do
		mask = bit.band(mask, arg)
	end

	assert(access.lattice[mask])

	return mask
end

return Access
