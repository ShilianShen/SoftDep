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

local function newTask(func, args, deps)
	assert(type(func) == "function")
	assert(args == nil or type(args) == "table")
	for _, tag in pairs(args or {}) do
		assert(type(tag) == "string")
	end
	assert(deps == nil or type(deps) == "table")
	for index, tag in pairs(deps or {}) do
		assert(type(index) == "number")
		assert(type(tag) == "string")
	end

	local task = setmetatable({
		func = func,
		args = shallowCopy(args or {}),
		deps = shallowCopy(deps or {}),
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
		data = data,
		tasks = {},
		access = access,
		deps = {},
		order = {},
	}, MT)

	for tag, task in pairs(tasks) do
		node.tasks[tag] = newTask(task.func, task.args, task.deps)
		for _, key in pairs(task.args) do
			table.insert(node.deps, key)
		end
	end

	node.order = kahn(node.tasks, "deps")

	return node
end

local function extendGraph(graph, tag, data, tasks, access)
	assert(graph.nodes[tag] == nil)
	graph.nodes[tag] = newNode(data, tasks, access)
	graph.order = kahn(graph.nodes, "deps")
end

local function tickGraph(graph)
	for _, nkey in ipairs(graph.order) do
		local node = graph.nodes[nkey]
		for _, tkey in ipairs(node.order) do
			local task = node.tasks[tkey]
			local args = {}
			for akey, key in pairs(task.args) do
				args[akey] = graph.nodes[key].data
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
		order = {},
	}, MT)
	return graph
end

return softdep
