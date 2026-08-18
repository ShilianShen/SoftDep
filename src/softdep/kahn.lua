local function kahn(vertices, pkey)
	assert(type(vertices) == "table")
	assert(type(pkey) == "string")
	for tag, vertex in pairs(vertices) do
		assert(type(tag) == "string")
		assert(type(vertex) == "table")
		assert(type(vertex[pkey]) == "table")
		for ptag, _ in pairs(vertex[pkey]) do
			assert(type(ptag) == "string")
		end
	end

	local infos = {}
	local stack = {}
	local order = {}
	local count = 0

	for tag, _ in pairs(vertices) do
		infos[tag] = { indegree = 0, children = {} }
		count = count + 1
	end

	for tag, vertex in pairs(vertices) do
		for ptag, _ in pairs(vertex[pkey]) do
			assert(infos[ptag] ~= nil)
			assert(infos[ptag].children[tag] ~= true)
			infos[tag].indegree = infos[tag].indegree + 1
			infos[ptag].children[tag] = true
		end
		if infos[tag].indegree == 0 then
			table.insert(stack, tag)
		end
	end

	for _ = 1, count do
		assert(#stack ~= 0)
		local tag = table.remove(stack)
		for ctag, _ in pairs(infos[tag].children) do
			infos[ctag].indegree = infos[ctag].indegree - 1
			if infos[ctag].indegree == 0 then
				table.insert(stack, ctag)
			end
		end
		table.insert(order, vertices[tag])
	end

	return order
end

return kahn
