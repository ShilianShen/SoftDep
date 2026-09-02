local types = require("softdep.types")
local check = require("softdep.check")
local MathSet = {}

function MathSet.arr2set(arr)
	check(2, types.array(arr))
	local set = {}
	for _, v in ipairs(arr) do
		set[v] = true
	end
	return set
end

function MathSet.set2arr(set)
	check(2, types.set(set))
	local arr = {}
	for k, _ in pairs(set) do
		table.insert(arr, k)
	end
	return arr
end

function MathSet.set2tab(set, data)
	check(2, types.set(set))
	local tab = {}
	for k, _ in pairs(set) do
		tab[k] = data[k]
	end
	return tab
end

function MathSet.count(set)
	check(2, types.set(set))
	local count = 0
	for _, _ in pairs(set) do
		count = count + 1
	end
	return count
end

return MathSet
