local deepCopy = require("src.softdep.deepCopy")
local decreaseOnly = require("src.softdep.decreaseOnly")
local getChildren = require("src.softdep.getChildren")
local kahn = require("src.softdep.kahn")

local function tick(node, parents_n)
	for _, ttag in ipairs(node.order) do
		local task = node.T[ttag]
		if task.dirty then
			local parents = {}
			for atag, ntag in pairs(node.parents_d[ttag]) do
				parents[atag] = parents_n[ntag]
			end
			for _, ctag in pairs(node.children_c[ttag]) do
				node.T[ctag].dirty = true
			end
			task.func(node.d, parents)
			task.dirty = false
		end
	end
end

local function newNode(d, T, a)
	local node = setmetatable({
		d = d or {},
		T = {},
		a = a or "none",
		parents_c = {},
		parents_d = {},
		children_c = false,
		order = false,
		dirty = true,
		tick = tick,
	}, decreaseOnly)

	for ttag, t in pairs(T) do
		node.T[ttag] = { func = t.func, dirty = true, a = t.access }
		node.parents_c[ttag] = deepCopy(t.parents_c) or {}
		node.parents_d[ttag] = deepCopy(t.parents_d) or {}
	end
	node.children_c = getChildren(node.parents_c)

	node.order = kahn(node.parents_c, node.children_c)

	return node
end

return newNode
