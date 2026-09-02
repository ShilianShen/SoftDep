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

function MathSet.equal(set1, set2)
	check(2, types.set(set1))
	check(2, types.set(set2))
	local set = {}
	for v, _ in pairs(set1) do
		set[v] = true
	end
	for v, _ in pairs(set2) do
		if not set[v] then
			return false
		end
		set[v] = nil
	end
	for _, _ in pairs(set) do
		return false
	end
	return true
end

function MathSet.isSubset(subset, set)
	check(2, types.set(subset))
	check(2, types.set(set))
	local diff = {}
	for v, _ in pairs(set) do
		diff[v] = true
	end
	for v, _ in pairs(subset) do
		if not diff[v] then
			return false
		end
		diff[v] = nil
	end
	return true
end

function MathSet.allSubsets(set)
	check(2, types.set(set))

	local arr = MathSet.set2arr(set)
	local n = #arr
	local mask = 0
	local limit = 2 ^ n

	return function()
		if mask >= limit then
			return nil
		end

		local subset = {}
		local value = mask

		for i = 1, n do
			if value % 2 == 1 then
				subset[#subset + 1] = arr[i]
			end
			value = math.floor(value / 2)
		end

		mask = mask + 1

		return MathSet.arr2set(subset)
	end
end

return MathSet
