local function spreadInNode(node)
	local dirty = false
	for _, ttag in ipairs(node.ttagOrder) do
		local task = node.tasks[ttag]
		if task.dirty then
			for _, ctask in pairs(task.children) do
				ctask.dirty = true
			end
			if task.access == "writable" then
				dirty = true
			end
		end
	end
	return dirty
end

local function spreadOutNode(ntag, node)
	for _, cnode in pairs(node.children) do
		for _, task in pairs(cnode.tasks) do
			for _, cntag in pairs(task.args) do
				if cntag == ntag then
					task.dirty = true
					break
				end
			end
		end
	end
end

local function spread(graph)
	for _, ntag in ipairs(graph.ntagOrder) do
		local node = graph.nodes[ntag]
		local dirty = spreadInNode(node)
		if dirty then
			spreadOutNode(ntag, node)
		end
	end
end

return spread
