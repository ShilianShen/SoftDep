local function getChildren(parents)
	local children = {}
	for v, _ in pairs(parents) do
		children[v] = {}
	end
	for v, _ in pairs(parents) do
		for _, p in pairs(parents[v]) do
            table.insert(children[p], v)
		end
	end
	return children
end

return getChildren
