local types = require("softdep.types")
local types = require("softdep.tableshape").types
local check = require("softdep.check")

local function adopt(parentSets)
	check(2, types.parentSets(parentSets))

	local ChildSets = {}
	for v, _ in pairs(parentSets) do
		ChildSets[v] = {}
	end

	for v, _ in pairs(parentSets) do
		for p, _ in pairs(parentSets[v]) do
			ChildSets[p][v] = true
		end
	end
	return ChildSets
end

return adopt
