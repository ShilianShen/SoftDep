local types = require("softdep.types")
local check = require("softdep.check")
local MathSet = {}

function MathSet.arr2set(arr)
	check(
		2,
		types.array(arr),
		"MathSet.arr2set: expected arr to be an array with consecutive integer keys starting at 1"
	)
	local set = {}
	for _, v in ipairs(arr) do
		set[v] = true
	end
	return set
end

function MathSet.set2tab(set, data)
	check(2, types.set(set), "MathSet.set2tab: expected set to be a table with all values equal to true")
	check(2, types.table(data), "MathSet.set2tab: expected data to be a table")
	local tab = {}
	for k, _ in pairs(set) do
		check(2, data[k] ~= nil, "MathSet.set2tab: missing key in data: " .. tostring(k))
		tab[k] = data[k]
	end
	return tab
end

function MathSet.tab2set(tab)
	check(2, types.table(tab), "MathSet.tab2set: expected tab to be a table")
	local set = {}
	for k, _ in pairs(tab) do
		set[k] = true
	end
	return set
end

function MathSet.count(set)
	check(2, types.set(set), "MathSet.count: expected set to be a table with all values equal to true")
	local count = 0
	for _, _ in pairs(set) do
		count = count + 1
	end
	return count
end

return MathSet
