local function getCount(t)
	local count = 0
	for _, _ in pairs(t) do
		count = count + 1
	end
	return count
end

local function kahn(parents, children)
	local indegrees = {}
	local stack = {}
	local order = {}

	for v, _ in pairs(parents) do
		indegrees[v] = getCount(parents[v])
		if indegrees[v] == 0 then
			table.insert(stack, v)
		end
	end

	for _, _ in pairs(parents) do
		local v = table.remove(stack)
		for _, c in pairs(children[v]) do
			indegrees[c] = indegrees[c] - 1
			table.insert(stack, c)
		end
		table.insert(order, v)
	end

	return order
end

return kahn
