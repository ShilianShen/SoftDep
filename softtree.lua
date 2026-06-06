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
		task._params = {} -- dict
		task._parents = {} -- array
		task._children = {} -- array
	end
	local node = {
		entity = entity or {},
		depth = 0,
		tasks = tasks,
		_parents = {}, -- dict
		_children = {}, -- dict
	}
	node._const = _getConst(node.entity)
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
		for _, task in pairs(node.tasks) do
			task._params = {}
			task._parents = {}
			task._children = {}
		end
	end

	for tag, node in pairs(nodeDict) do
		for taskname, task in pairs(node.tasks) do
			for paramTag, parentTag in pairs(task.params) do
				local parentNode = nodeDict[parentTag]
				parentNode._children[tag] = node
				node._parents[parentTag] = parentNode

				local parentTask = parentNode.tasks[taskname]
				task._params[paramTag] = parentNode._const
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
		for _, _ in pairs(node._parents) do
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

local function tick(tree, taskname)
	if tree.stale then
		_setParentsAndChildren(tree.nodeDict)
		tree.nodeArray = _getOptimizedNodeArray(tree.nodeDict)
		_setDepth(tree)
		tree.stale = false
	end

	for _, node in ipairs(tree.nodeArray) do
		local task = node.tasks[taskname]
		if task ~= nil and task.dirty then
			task.func(node.entity, task._params)
			task.callCount = task.callCount + 1
			for _, subtask in ipairs(task._children or {}) do
				subtask.dirty = true
			end
			task.dirty = false
		end
	end
end

local function getTagged(tree, tag)
	return tree.nodeDict[tag].entity
end

local function setDirty(tree, tag, taskname)
	local node = tree.nodeDict[tag]
	local task = node.tasks[taskname]
	task.dirty = true
end

local function getMermaid(tree)
	local mermaid = { "graph" }
	for tag, node in pairs(tree.nodeDict) do
		table.insert(mermaid, string.format('%p["%s"]', node, tag))
		for parentTag, _ in ipairs(node._parents) do
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
