local deepCopy = require("src.lua.deepCopy")
local decreaseOnly = require("src.lua.decreaseOnly")
local getChildSets = require("src.lua.getChildSets")
local kahn = require("src.lua.kahn")
local MathSet = require("src.lua.MathSet")

local function tick(node, parents_n)
	for _, ttag in ipairs(node.order) do
		local task = node.tasks[ttag]
		if task.dirty then
			local parents_d = {}
			for atag, ntag in pairs(node.parents_d[ttag]) do
				parents_d[atag] = parents_n[ntag].data
			end
			for ctag, _ in pairs(node.children_c[ttag]) do
				node.tasks[ctag].dirty = true
			end
			task.func(node.data, parents_d)
			task.dirty = false
		end
	end
end

local function newNode(data, tasks, access)
	local node = setmetatable({
		data = data or {},
		tasks = {},
		access = access or "none",

		parents_c = {},
		parents_d = {},
		children_c = {},
		order = false,

		dirty = true,
		tick = tick,
	}, decreaseOnly)

	local parentSets_c = {}
	for ttag, t in pairs(tasks) do
		node.tasks[ttag] = { func = t.func, dirty = true, a = t.access }
		parentSets_c[ttag] = MathSet.arr2set(t.parents_c) or {}
		node.parents_d[ttag] = deepCopy(t.parents_d) or {}
	end
	local childSets_c = getChildSets(parentSets_c)

	for ttag, _ in pairs(node.tasks) do
		node.parents_c[ttag] = MathSet.set2tab(parentSets_c[ttag], node.tasks)
		node.children_c[ttag] = MathSet.set2tab(childSets_c[ttag], node.tasks)
	end

	node.order = kahn(parentSets_c, childSets_c)

	return node
end

return newNode
