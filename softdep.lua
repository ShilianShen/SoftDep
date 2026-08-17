local softdep = {}

softdep.ACCESS = {
	none = "none",
	readonly = "readonly",
	writable = "writable",
}

local function sort(nodes, pkey)
	assert(type(nodes) == "table")
	assert(type(pkey) == "string")
	for _, node in pairs(nodes) do
		assert(type(node) == "table")
		assert(node[pkey] == nil or type(node[pkey]) == "table")
		for _, pname in pairs(node[pkey] or {}) do
			assert(type(pname) == "string")
		end
	end

	local infos = {}
	for name, _ in pairs(nodes) do
		infos[name] = { indegree = 0, children = {} }
	end
	for name, node in pairs(nodes) do
		for _, pname in pairs(node[pkey] or {}) do
			infos[name].indegree = infos[name].indegree + 1
			infos[pname].children[name] = true
		end
	end

	local queue = {}
	for name, _ in pairs(nodes) do
		if infos[name].indegree == 0 then
			table.insert(queue, name)
		end
	end

	local order = {}
	while #queue > 0 do
		local name = table.remove(queue)
		for cname, _ in pairs(infos[name].children) do
			infos[name].children[cname] = nil
			infos[cname].indegree = infos[cname].indegree - 1
			if infos[cname].indegree == 0 then
				table.insert(queue, cname)
			end
		end
		table.insert(order, name)
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

	node.order = sort(tasks, "deps")

	return node
end

local function extendGraph(graph, tag, data, tasks, access)
	assert(graph.nodes[tag] == nil)
	graph.nodes[tag] = newNode(data, tasks, access)
	graph.order = sort(graph.nodes, "deps")
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
