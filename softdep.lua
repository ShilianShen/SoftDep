package.preload["adopt"] = function(...)
	local function adopt(vertices, pkey, ckey)
		assert(type(vertices) == "table")
		assert(type(pkey) == "string")
		assert(type(ckey) == "string")
		for tag, vertex in pairs(vertices) do
			assert(type(tag) == "string")
			assert(type(vertex) == "table")
			assert(type(vertex[pkey] == "table"))
			for ptag, _ in pairs(vertex[pkey]) do
				assert(type(ptag) == "string")
				assert(vertices[ptag] ~= nil)
			end
		end

		for _, vertex in pairs(vertices) do
			vertex[ckey] = {}
		end

		for tag, vertex in pairs(vertices) do
			for ptag, _ in pairs(vertex[pkey]) do
				local parent = vertices[ptag]
				vertex[pkey][ptag] = parent
				parent[ckey][tag] = vertex
			end
		end
	end

	return adopt
end

package.preload["kahn"] = function(...)
	local function kahn(vertices, pkey)
		assert(type(vertices) == "table")
		assert(type(pkey) == "string")
		for tag, vertex in pairs(vertices) do
			assert(type(tag) == "string")
			assert(type(vertex) == "table")
			assert(type(vertex[pkey]) == "table")
			for ptag, _ in pairs(vertex[pkey]) do
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
			for ptag, _ in pairs(vertex[pkey]) do
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

	return kahn
end

package.preload["spread"] = function(...)
	local function spread(graph)
		for _, ntag in ipairs(graph.nodeOrder) do
			local node = graph.nodes[ntag]
			for _, ttag in ipairs(node.taskOrder) do
				local task = node.tasks[ttag]
				if task.dirty then
					for _, ctask in pairs(task.children) do
						ctask.dirty = true
					end
					if task.access == "writable" then
						node.dirty = true
					end
				end
			end
			if node.dirty then
				for _, cnode in pairs(node.children) do
					for _, ctask in pairs(cnode.tasks) do
						for catag, cntag in pairs(ctask.args) do
							if cntag == ntag then
								ctask.dirty = true
								break
							end
						end
					end
				end
			end
		end
	end

	return spread
end

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

local kahn = require("kahn")
local adopt = require("adopt")

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
		args = shallowCopy(args or {}),
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
		taskOrder = {},
		dirty = true,
	}, MT)

	for ttag, task in pairs(tasks) do
		node.tasks[ttag] = newTask(task.func, task.args, task.parents, task.access)
		for _, ntag in pairs(task.args) do
			node.parents[ntag] = true
		end
	end

	node.taskOrder = kahn(node.tasks, "parents")
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
	graph.nodeOrder = kahn(graph.nodes, "parents")
	adopt(graph.nodes, "parents", "children")
	graph.ready = true
end

local spread = require("spread")

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
