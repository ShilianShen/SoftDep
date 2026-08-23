local MathSet = {}

function MathSet.arr2set(arr)
	local set = {}
	for _, v in ipairs(arr or {}) do
		set[v] = true
	end
	return set
end

function MathSet.set2arr(set)
	local arr = {}
	for k, _ in pairs(set or {}) do
		table.insert(arr, k)
	end
	return arr
end

function MathSet.set2tab(set, data)
	local tab = {}
	for k, _ in pairs(set or {}) do
		tab[k] = data[k]
	end
	return tab
end

return MathSet
