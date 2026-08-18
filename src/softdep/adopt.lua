local function adopt(vertices, pkey, ckey)
	assert(type(vertices) == "table")
	assert(type(pkey) == "string")
	assert(type(ckey) == "string")
	for tag, vertex in pairs(vertices) do
		assert(type(tag) == "string")
		assert(type(vertex) == "table")
		assert(type(vertex[pkey] == "table"))
		for ptag, _ in pairs(vertex[pkey]) do
			assert(type(ptag) == "string")
			assert(vertices[ptag] ~= nil)
		end
	end

	for _, vertex in pairs(vertices) do
		vertex[ckey] = {}
	end

	for tag, vertex in pairs(vertices) do
		for ptag, _ in pairs(vertex[pkey]) do
			local parent = vertices[ptag]
			vertex[pkey][ptag] = parent
			parent[ckey][tag] = vertex
		end
	end
end

return adopt
