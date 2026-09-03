local types = require("softdep.types")
local check = require("softdep.check")
local MathGraph = require("softdep.MathGraph")
local MathSet = require("softdep.MathSet")

local function getUpperBounds(reachAdjList, subset)
	check(2, types.adjList(reachAdjList))
	check(2, types.set(subset))

	local upperBounds = {}
	for v2, _ in pairs(reachAdjList) do
		local ok = true
		for v1, _ in pairs(subset) do
			ok = ok and reachAdjList[v1][v2]
		end
		if ok then
			upperBounds[v2] = true
		end
	end
	return upperBounds
end

local function getLowerBounds(reachAdjList, subset)
	check(2, types.adjList(reachAdjList))
	check(2, types.set(subset))

	local lowerBounds = {}
	for v1, _ in pairs(reachAdjList) do
		local ok = true
		for v2, _ in pairs(subset) do
			ok = ok and reachAdjList[v1][v2]
		end
		if ok then
			lowerBounds[v1] = true
		end
	end
	return lowerBounds
end

local function getClosure(reachAdjList, subset)
	check(2, types.adjList(reachAdjList))
	check(2, types.set(subset))

	return getLowerBounds(reachAdjList, getUpperBounds(reachAdjList, subset))
end

local function DM(adjList)
	check(2, types.adjList(adjList))

	local reachAdjList = MathGraph.reachAdjList(adjList, true)

	local lattice = {}

	for subset in MathSet.allSubsets(MathSet.tab2set(adjList)) do
		local closure = getClosure(reachAdjList, subset)
		if MathSet.equal(subset, closure) then
			lattice[subset] = true
		end
	end

	return lattice
end

return DM
