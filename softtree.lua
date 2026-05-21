local softtree = {}

local NODE_MT = {
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

local function _newNode(parentTags, entity, load, update, run)
	local node = {
		parentTags = parentTags or {},
		entity = entity or {},
		params = {},
		stale = true,
		dirty = true,
		loadCount = 0,
		updateCount = 0,
		depth = 0,

		load = load,
		update = update,
		run = run,

		parents = {},
		children = {},
	}
	node.const = _getConst(node.entity)
	setmetatable(node, NODE_MT)
	return node
end

local function _setDepth(tree)
	tree.depth = 0
	for i, node in ipairs(tree.nodeArray) do
		node.depth = 1
		if #node.parentTags == 0 then
			node.depth = 1
		end
		for _, parent in pairs(node.parents) do
			node.depth = math.max(node.depth, parent.depth + 1)
		end
		tree.depth = math.max(tree.depth, node.depth)
	end
end

local function _setParentsAndChildren(nodeDict)
	for _, node in pairs(nodeDict) do
		node.parents = {}
		node.children = {}
	end
	for tag, node in pairs(nodeDict) do
		for paramTag, parentTag in pairs(node.parentTags) do
			local parent = nodeDict[parentTag]
			parent.children[tag] = node
			node.parents[parentTag] = parent
			node.params[paramTag] = parent.const
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
		inDegree[node] = #node.parentTags
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
				for _, child in pairs(node.children) do
					inDegree[child] = inDegree[child] - 1
				end
			end
		end
	end

	assert(sorted == count)

	return array
end

local function _activateFunc(node, funcname)
	if node[funcname] ~= nil then
		node[funcname](node.entity, node.params)
		if funcname == "load" then
			node.loadCount = node.loadCount + 1
		elseif funcname == "update" then
			node.updateCount = node.updateCount + 1
		end
	end
end

local function insert(tree, tag, parentTags, entity, load, update, run)
	if type(tag) == "table" then
		tag, parentTags, entity, load, update, run = tag.tag, tag.parentTags, tag.entity, tag.load, tag.update, tag.run
	end
	local node = _newNode(parentTags, entity, load, update, run)
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

local function spread(tree)
	for _, node in ipairs(tree.nodeArray) do
		if node.stale then
			for _, child in pairs(node.children) do
				child.stale = true
				child.dirty = true
			end
		elseif node.dirty then
			for _, child in pairs(node.children) do
				child.dirty = true
			end
		end
	end
end

local function tick(tree)
	if tree.stale then
		_setParentsAndChildren(tree.nodeDict)
		tree.nodeArray = _getOptimizedNodeArray(tree.nodeDict)
		_setDepth(tree)
		tree.stale = false
	end

	spread(tree)

	for _, node in ipairs(tree.nodeArray) do
		if node.stale then
			_activateFunc(node, "load")
			node.stale = false
			node.dirty = true
		end
		if node.dirty then
			_activateFunc(node, "update")
			node.dirty = false
		end
		_activateFunc(node, "run")
	end
end

local function getTagged(tree, tag)
	return tree.nodeDict[tag].entity
end

local function setStale(tree, tag)
	tree.nodeDict[tag].stale = true
end

local function setDirty(tree, tag)
	tree.nodeDict[tag].dirty = true
end

local function getMermaid(tree)
	local mermaid = { "graph" }
	for tag, node in pairs(tree.nodeDict) do
		table.insert(mermaid, string.format('%p["%s"]', node, tag))
		for _, parentTag in ipairs(node.parentTags) do
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

		setStale = setStale,
		setDirty = setDirty,
		spread = spread,
	}
	tree:insert("root", nil, {})
	return tree
end

return softtree
