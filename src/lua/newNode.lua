local deepCopy = require("src.lua.deepCopy")
local decreaseOnly = require("src.lua.decreaseOnly")
local getChildSets = require("src.lua.getChildSets")
local kahn = require("src.lua.kahn")
local MathSet = require("src.lua.MathSet")

local function tick(node, parents_n)
	for _, ttag in ipairs(node.order) do
		local task = node.T[ttag]
		if task.dirty then
			local parents = {}
			for atag, ntag in pairs(node.parents_d[ttag]) do
				parents[atag] = parents_n[ntag].d
			end
			for ctag, _ in pairs(node.children_c[ttag]) do
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
		children_c = {},
		order = false,

		dirty = true,
		tick = tick,
	}, decreaseOnly)

	local parentSets_c = {}
	for ttag, t in pairs(T) do
		node.T[ttag] = { func = t.func, dirty = true, a = t.access }
		parentSets_c[ttag] = MathSet.arr2set(t.parents_c) or {}
		node.parents_d[ttag] = deepCopy(t.parents_d) or {}
	end
	local childSets_c = getChildSets(parentSets_c)

	for ttag, _ in pairs(node.T) do
		node.parents_c[ttag] = MathSet.set2tab(parentSets_c[ttag], node.T)
		node.children_c[ttag] = MathSet.set2tab(childSets_c[ttag], node.T)
	end

	node.order = kahn(parentSets_c, childSets_c)

	return node
end

return newNode
