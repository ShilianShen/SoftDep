local softdep = {}

softdep.ACCESS = {
	none = "none",
	readonly = "readonly",
	writable = "writable",
}

local function kahn(nodes, pkey)
	assert(type(nodes) == "table")
	assert(type(pkey) == "string")
	for _, node in pairs(nodes) do
		assert(type(node) == "table")
		assert(node[pkey] == nil or type(node[pkey]) == "table")
		for _, ptag in pairs(node[pkey] or {}) do
			assert(type(ptag) == "string")
		end
	end

	local infos = {}
	local stack = {}
	local order = {}
	local count = 0

	for tag, _ in pairs(nodes) do
		infos[tag] = { indegree = 0, children = {} }
		count = count + 1
	end

	for tag, node in pairs(nodes) do
		for _, ptag in pairs(node[pkey] or {}) do
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

local function newTask(func, args, deps)
	assert(type(func) == "function")
	assert(args == nil or type(args) == "table")
	assert(deps == nil or type(deps) == "table")

	local task = {
		func = func,
		args = {},
		deps = {},
		dirty = true,
	}

	for key, value in pairs(args or {}) do
		task.args[key] = value
	end

	for _, dep in ipairs(deps or {}) do
		table.insert(task.deps, dep)
	end

	return task
end

local function newNode(data, tasks, access)
	assert(data == nil or type(data) == "table")
	assert(tasks == nil or type(tasks) == "table")
	assert(access == nil or type(access) == "string")
	assert(softdep.ACCESS[access] ~= nil)

	local node = {
		data = data,
		tasks = {},
		access = access,
		deps = {},
	}

	for name, task in pairs(tasks) do
		node.tasks[name] = newTask(task.func, task.args, task.deps)
		for _, key in pairs(task.args) do
			table.insert(node.deps, key)
		end
	end

	node.order = kahn(tasks, "deps")

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
	local graph = {
		nodes = {},
		extend = extendGraph,
		tick = tickGraph,
	}
	return graph
end

return softdep
