local softdep = {}

local ACCESS = {
	none = "none",
	readonly = "readonly",
	writable = "writable",
}

local MT = {
	__newindex = function(t, key)
		assert(false)
	end,
}

local kahn = require("src.softdep.kahn")
local adopt = require("src.softdep.adopt")
local spread = require("src.softdep.spread")

local function array2set(array)
	assert(type(array) == "table")
	local set = {}
	for _, value in ipairs(array) do
		set[value] = true
	end
	return set
end

local function shallowCopy(a)
	assert(type(a) == "table")
	local b = {}
	for key, value in pairs(a) do
		b[key] = value
	end
	return b
end

local function isArray(t)
	if t == nil or type(t) ~= "table" then
		return false
	end
	local count = 0
	for _, _ in pairs(t) do
		count = count + 1
	end
	return count == #t
end

local function newTask(func, args, parents, access)
	assert(type(func) == "function")
	assert(args == nil or type(args) == "table")
	for atag, ntag in pairs(args or {}) do
		assert(type(atag) == "string")
		assert(type(ntag) == "string")
	end
	assert(parents == nil or isArray(parents))
	for _, ttag in pairs(parents or {}) do
		assert(type(ttag) == "string")
	end
	assert(access == nil or type(access) == "string")
	access = access or "writable"
	assert(ACCESS[access] ~= nil)

	local task = setmetatable({
		func = func,
		data = false,
		args = shallowCopy(args or {}),
		_args = {},
		parents = array2set(parents or {}),
		children = {},
		dirty = true,
		access = access,
	}, MT)

	return task
end

local function newNode(data, tasks, access)
	assert(data == nil or type(data) == "table")
	assert(tasks == nil or type(tasks) == "table")
	assert(access == nil or type(access) == "string")
	access = access or "none"
	assert(ACCESS[access] ~= nil)

	local node = setmetatable({
		data = data or {},
		tasks = {},
		access = access,
		parents = {},
		children = {},
		ttagOrder = {},
		dirty = true,
	}, MT)

	for ttag, task in pairs(tasks) do
		node.tasks[ttag] = newTask(task.func, task.args, task.parents, task.access)
		for _, ntag in pairs(task.args) do
			node.parents[ntag] = true
		end
	end

	node.ttagOrder = kahn(node.tasks, "parents")
	adopt(node.tasks, "parents", "children")

	return node
end

local function extendGraph(graph, ntag, data, tasks, access)
	assert(graph ~= nil)
	assert(graph.ready == false)
	assert(graph.nodes[ntag] == nil)
	graph.nodes[ntag] = newNode(data, tasks, access)
end

local function loadGraph(graph)
	assert(graph ~= nil)
	assert(not graph.ready)

	graph.ntagOrder = kahn(graph.nodes, "parents")

	adopt(graph.nodes, "parents", "children")

	graph.taskOrder = {}
	for _, ntag in ipairs(graph.ntagOrder) do
		local node = graph.nodes[ntag]
		for _, ttag in ipairs(node.ttagOrder) do
			local task = node.tasks[ttag]
			task.data = node.data
			for atag, antag in pairs(task.args) do
				task._args[atag] = graph.nodes[antag].data
			end
			table.insert(graph.taskOrder, task)
		end
	end

	graph.ready = true
end

local function tickGraph(graph)
	assert(graph ~= nil)
	assert(graph.ready)

	spread(graph)

	for _, task in ipairs(graph.taskOrder) do
		if task.dirty then
			task.func(task.data, task._args)
			task.dirty = false
		end
	end
end

function softdep.newGraph()
	local graph = setmetatable({
		nodes = {},
		extend = extendGraph,
		tick = tickGraph,
		load = loadGraph,
		ntagOrder = {},
		taskOrder = {},
		ready = false,
	}, MT)
	return graph
end

return softdep
