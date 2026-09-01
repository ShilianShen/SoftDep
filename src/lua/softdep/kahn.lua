local MathSet = require("softdep.MathSet")
local adopt = require("softdep.adopt")
local shapes = require("softdep.shapes")

local function kahn(parentSets, _)
	assert(shapes.parentSets(parentSets))
	local childSets = adopt(parentSets)
	local indegrees = {}
	local stack = {}
	local order = {}

	for v, _ in pairs(parentSets) do
		indegrees[v] = MathSet.count(parentSets[v])
		if indegrees[v] == 0 then
			table.insert(stack, v)
		end
	end

	for _, _ in pairs(parentSets) do
		local v = table.remove(stack)
		for c, _ in pairs(childSets[v]) do
			indegrees[c] = indegrees[c] - 1
			if indegrees[c] == 0 then
				table.insert(stack, c)
			end
		end
		table.insert(order, v)
	end

	return order
end

return kahn
