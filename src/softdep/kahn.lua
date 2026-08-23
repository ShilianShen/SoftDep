local function count(t)
	local n = 0
	for _, _ in pairs(t) do
		n = n + 1
	end
	return n
end

local function kahn(parentSets, childSets)
	local indegrees = {}
	local stack = {}
	local order = {}

	for v, _ in pairs(parentSets) do
		indegrees[v] = count(parentSets[v])
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
