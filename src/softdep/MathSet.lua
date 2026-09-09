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

function MathSet.set2tab(set, data)
	check(2, types.set(set))
	check(2, types.table(data))
	local tab = {}
	for k, _ in pairs(set) do
		check(2, data[k] ~= nil)
		tab[k] = data[k]
	end
	return tab
end

function MathSet.tab2set(tab)
	check(2, types.table(tab))
	local set = {}
	for k, _ in pairs(tab) do
		set[k] = true
	end
	return set
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
