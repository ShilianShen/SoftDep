local adopt = require("softdep.adopt")
local kahn = require("softdep.kahn")
local MathSet = require("softdep.MathSet")
local Access = require("softdep.Access")

local function pass(...) end

local function deepCopy(value, seen)
	if type(value) ~= "table" then
		return value
	end

	seen = seen or {}
	if seen[value] then
		return seen[value]
	end

	local copy = {}
	seen[value] = copy

	for key, item in pairs(value) do
		copy[deepCopy(key, seen)] = deepCopy(item, seen)
	end

	return copy
end

local function spread(node)
	local dirty = false
	for _, ttag in ipairs(node.order) do
		local task = node.tasks[ttag]
		if task.dirty then
			for ctag, _ in pairs(node.children_c[ttag]) do
				node.tasks[ctag].dirty = true
			end
			if Access[task.access] >= Access.writable then
				dirty = true
			end
		end
	end
	node.dirty = node.dirty or dirty
end

local function run(node, parents_n)
	for _, ttag in ipairs(node.order) do
		local task = node.tasks[ttag]
		if task.dirty then
			local parents_d = {}
			for atag, ntag in pairs(node.parents_d[ttag]) do
				local parent = parents_n[ntag]
				parents_d[atag] = parent.data_a[parent.access]
			end
			task.func(node.data_a[task.access], parents_d)
			task.count = task.count + 1
			task.dirty = false
		end
	end
end

local function newNode(data, tasks, access, api)
	local node = {
		data = data or {},
		tasks = {},
		access = access or "none",
		data_a = {},
		api = {},

		parents_c = {},
		parents_d = {},
		children_c = {},
		order = false,
		dirty = false,

		run = run,
		spread = spread,
	}

	for key, val in pairs(api or {}) do
		local func = val.func or pass
		local ttag = val.task
		node.api[key] = function(...)
			func(...)
			if ttag then
				node.tasks[ttag].dirty = true
			end
			node.dirty = true
		end
	end

	local parentSets_c = {}
	for ttag, t in pairs(tasks or {}) do
		node.tasks[ttag] = {
			func = t.func or pass,
			dirty = true,
			access = t.access or "writable",
			count = 0,
		}
		parentSets_c[ttag] = MathSet.arr2set(t.parents_c) or {}
		node.parents_d[ttag] = deepCopy(t.parents_d) or {}
	end
	local childSets_c = adopt(parentSets_c)

	for ttag, _ in pairs(node.tasks) do
		node.parents_c[ttag] = MathSet.set2tab(parentSets_c[ttag], node.tasks)
		node.children_c[ttag] = MathSet.set2tab(childSets_c[ttag], node.tasks)
	end

	node.order = kahn(parentSets_c, childSets_c)

	for atag, a in pairs(Access) do
		node.data_a[atag] = a.func(node.data)
	end

	return node
end

return newNode
