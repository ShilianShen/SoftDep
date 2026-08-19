local function spread(graph)
	for _, ntag in ipairs(graph.ntagOrder) do
		local node = graph.nodes[ntag]
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
		if dirty then
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
