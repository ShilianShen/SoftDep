local function getChildSets(parentSets)
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

return getChildSets
