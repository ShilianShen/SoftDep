local MathSet = {}

---@alias softdep.Set table<string, true>

---@param arr string[]
---@return softdep.Set
function MathSet.arr2set(arr)
	local set = {}
	for _, v in ipairs(arr) do
		set[v] = true
	end
	return set
end

---@param set softdep.Set
---@param data table
---@return table
function MathSet.set2tab(set, data)
	local tab = {}
	for k, _ in pairs(set) do
		tab[k] = data[k]
	end
	return tab
end

---@param tab table
---@return softdep.Set
function MathSet.tab2set(tab)
	local set = {}
	for k, _ in pairs(tab) do
		set[k] = true
	end
	return set
end

---@param set softdep.Set
---@return integer
function MathSet.count(set)
	local count = 0
	for _, _ in pairs(set) do
		count = count + 1
	end
	return count
end

return MathSet
