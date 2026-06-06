local softtree = {}

local _NODE_MT = {
	__newindex = function()
		error("Attempt to modify protected node field", 2)
	end,
	__metatable = false,
}

local function _getConst(t)
	local proxy = {}
	local mt = {
		__index = t,
		__newindex = function(_, k, v)
			error("Attempt to modify a read-only table", 2)
		end,
		__metatable = false,
	}
	return setmetatable(proxy, mt)
end

local function _newNode(entity, tasks)
	for _, task in pairs(tasks) do
		task.dirty = true
		task.callCount = 0
		task._params = {}
		task._parents = {}
		task._children = {}
	end
	local node = {
		entity = entity or {},
		stale = true,
		dirty = true,
		depth = 0,
		tasks = tasks,

		_params = {},
		_parents = {},
		_children = {},
	}
	node.const = _getConst(node.entity)
	setmetatable(node, _NODE_MT)
	setmetatable(node.tasks, _NODE_MT)
	return node
end

local function insert(tree, tag, entity, tasks)
	tasks = tasks or {}
	local node = _newNode(entity, tasks)
	tag = tag or tostring(entity)
	tree.nodeDict[tag] = node
	tree.stale = true
	tree.dirty = true
end

local function remove(tree, tag, entity)
	tag = tag or tostring(entity)
	if tree.nodeDict[tag] ~= nil then
		tree.nodeDict[tag] = nil
		tree.stale = true
	end
end

local function _setParentsAndChildren(nodeDict)
	for _, node in pairs(nodeDict) do
		node._parents = {}
		node._children = {}
		node._params = {}
	end

	for tag, node in pairs(nodeDict) do
		local params = {}
		for _, task in pairs(node.tasks) do
			for paramTag, parentTag in pairs(task.params) do
				params[parentTag] = true
				local parent = nodeDict[parentTag]
				parent._children[tag] = node
				node._parents[parentTag] = parent
			end
		end
		for _, parentTag in pairs(params) do
			table.insert(node._params, parentTag)
		end
	end

	for tag, node in pairs(nodeDict) do
		for taskname, task in pairs(node.tasks) do
			task._params = {}
			task._parents = {}
			task._children = {}
		end
	end

	for tag, node in pairs(nodeDict) do
		for taskname, task in pairs(node.tasks) do
			for paramTag, parentTag in pairs(task.params) do
				local parentNode = nodeDict[parentTag]
				local parentTask = parentNode.tasks[taskname]
				task._params[paramTag] = parentNode.const
				table.insert(parentTask._children, task)
				table.insert(task._parents, parentTask)
			end
		end
	end
end

local function _getOptimizedNodeArray(nodeDict)
	local inDegree = {}
	local sorted = 0
	local array = {}
	local count = 0

	for _, node in pairs(nodeDict) do
		array[#array + 1] = node
		inDegree[node] = 0
		for _, _ in ipairs(node._params) do
			inDegree[node] = inDegree[node] + 1
		end
		count = count + 1
	end

	local loop = true
	while loop do
		loop = false
		for i = sorted + 1, #array do
			local node = array[i]
			if inDegree[node] == 0 then
				loop = true
				sorted = sorted + 1
				array[i] = array[sorted]
				array[sorted] = node
				for _, child in pairs(node._children) do
					inDegree[child] = inDegree[child] - 1
				end
			end
		end
	end

	assert(sorted == count)

	return array
end

local function _setDepth(tree)
	tree.depth = 0
	for _, node in ipairs(tree.nodeArray) do
		node.depth = 1
		for _, parent in pairs(node._parents) do
			node.depth = math.max(node.depth, parent.depth + 1)
		end
		tree.depth = math.max(tree.depth, node.depth)
	end
end

local function _activateFunc(node, taskname)
	local task = node.tasks[taskname]
	if task ~= nil then
		task.func(node.entity, node.tasks[taskname]._params)
		task.callCount = task.callCount + 1
	end
end

local function tick(tree, taskname)
	if tree.stale then
		_setParentsAndChildren(tree.nodeDict)
		tree.nodeArray = _getOptimizedNodeArray(tree.nodeDict)
		_setDepth(tree)
		tree.stale = false
	end

	-- for _, node in ipairs(tree.nodeArray) do
	-- 	local task = node.tasks[taskname]
	-- 	if task ~= nil and task.dirty then
	-- 		task.func(node.entity, task._params)
	-- 		for _, subtask in ipairs(task.children) do
	-- 			subtask.dirty = true
	-- 		end
	-- 		task.dirty = false
	-- 	end
	-- end

	for _, node in ipairs(tree.nodeArray) do
		if node.stale then
			for _, child in pairs(node._children) do
				child.stale = true
				child.dirty = true
			end
			_activateFunc(node, "load")
			node.stale = false
			node.dirty = true
		end
		if node.dirty then
			for _, child in pairs(node._children) do
				child.dirty = true
			end
			_activateFunc(node, "update")
			node.dirty = false
		end
		_activateFunc(node, "run")
	end
end

local function getTagged(tree, tag)
	return tree.nodeDict[tag].entity
end

local function setDirty(tree, tag)
	tree.nodeDict[tag].dirty = true
end

local function getMermaid(tree)
	local mermaid = { "graph" }
	for tag, node in pairs(tree.nodeDict) do
		table.insert(mermaid, string.format('%p["%s"]', node, tag))
		for _, parentTag in ipairs(node._params) do
			local parent = tree.nodeDict[parentTag]
			if parent then
				table.insert(mermaid, string.format("%p", parent) .. "-->" .. string.format("%p", node))
			end
		end
	end
	return table.concat(mermaid, "\n")
end

function softtree.newTree()
	local tree = {
		stale = true,
		nodeDict = {},
		nodeArray = {},
		depth = 0,

		insert = insert,
		remove = remove,
		tick = tick,

		getTagged = getTagged,
		getMermaid = getMermaid,

		setDirty = setDirty,
	}
	return tree
end

return softtree
