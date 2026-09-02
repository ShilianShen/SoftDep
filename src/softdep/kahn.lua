local MathSet = require("softdep.MathSet")
local adopt = require("softdep.adopt")
local types = require("softdep.types")
local check = require("softdep.check")

local function kahn(parentSets)
	check(2, types.parentSets(parentSets))

	local childSets = adopt(parentSets)
	local indegrees = {}
	local stack = {}
	local order = {}

	for vtag, _ in pairs(parentSets) do
		indegrees[vtag] = MathSet.count(parentSets[vtag])
		if indegrees[vtag] == 0 then
			table.insert(stack, vtag)
		end
	end

	for _, _ in pairs(parentSets) do
		local vtag = table.remove(stack)
		check(2, vtag ~= nil, "not a DAG")

		for ctag, _ in pairs(childSets[vtag]) do
			indegrees[ctag] = indegrees[ctag] - 1
			if indegrees[ctag] == 0 then
				table.insert(stack, ctag)
			end
		end
		table.insert(order, vtag)
	end

	return order
end

return kahn
