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

local function kahn(vertices, pkey)
	assert(type(vertices) == "table")
	assert(type(pkey) == "string")
	for _, vertex in pairs(vertices) do
		assert(type(vertex) == "table")
		assert(vertex[pkey] == nil or type(vertex[pkey]) == "table")
		for _, ptag in pairs(vertex[pkey] or {}) do
			assert(type(ptag) == "string")
		end
	end

	local infos = {}
	local stack = {}
	local order = {}
	local count = 0

	for tag, _ in pairs(vertices) do
		infos[tag] = { indegree = 0, children = {} }
		count = count + 1
	end

	for tag, vertex in pairs(vertices) do
		for _, ptag in pairs(vertex[pkey] or {}) do
			assert(infos[ptag] ~= nil)
			assert(infos[ptag].children[tag] ~= true)
			infos[tag].indegree = infos[tag].indegree + 1
			infos[ptag].children[tag] = true
		end
		if infos[tag].indegree == 0 then
			table.insert(stack, tag)
		end
	end

	for _ = 1, count do
		assert(#stack ~= 0)
		local tag = table.remove(stack)
		for ctag, _ in pairs(infos[tag].children) do
			infos[ctag].indegree = infos[ctag].indegree - 1
			if infos[ctag].indegree == 0 then
				table.insert(stack, ctag)
			end
		end
		table.insert(order, tag)
	end

	return order
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

local function newTask(func, args, deps)
	assert(type(func) == "function")
	assert(args == nil or type(args) == "table")
	for atag, ntag in pairs(args or {}) do
		assert(type(atag) == "string")
		assert(type(ntag) == "string")
	end
	assert(deps == nil or isArray(deps))
	for _, ttag in pairs(deps or {}) do
		assert(type(ttag) == "string")
	end

	local task = setmetatable({
		func = func,
		args = shallowCopy(args or {}),
		taskDeps = shallowCopy(deps or {}),
		dirty = true,
	}, MT)

	return task
end

local function newNode(data, tasks, access)
	assert(data == nil or type(data) == "table")
	assert(tasks == nil or type(tasks) == "table")
	assert(access == nil or type(access) == "string")
	assert(ACCESS[access] ~= nil)

	local node = setmetatable({
		data = data or {},
		tasks = {},
		access = access,
		nodeDeps = {},
		taskOrder = {},
		dirty = true,
	}, MT)

	for ttag, task in pairs(tasks) do
		node.tasks[ttag] = newTask(task.func, task.args, task.deps)
		for _, ntag in pairs(task.args) do
			table.insert(node.nodeDeps, ntag)
		end
	end

	node.taskOrder = kahn(node.tasks, "taskDeps")

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
	graph.nodeOrder = kahn(graph.nodes, "nodeDeps")
	graph.ready = true
end

local function tickGraph(graph)
	assert(graph ~= nil)
	assert(graph.ready)
	for _, ntag in ipairs(graph.nodeOrder) do
		local node = graph.nodes[ntag]
		for _, ttag in ipairs(node.taskOrder) do
			local task = node.tasks[ttag]
			local args = {}
			for atag, nptag in pairs(task.args) do
				args[atag] = graph.nodes[nptag].data
			end
			task.func(node.data, args)
		end
	end
end

function softdep.newGraph()
	local graph = setmetatable({
		nodes = {},
		extend = extendGraph,
		tick = tickGraph,
		load = loadGraph,
		nodeOrder = {},
		taskOrder = {},
		ready = false,
	}, MT)
	return graph
end

return softdep
