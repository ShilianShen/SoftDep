local methods = {}

---@param graph softdep.Graph
function methods.spread(graph)
	for _, ntag in ipairs(graph.order_n) do
		local node = graph.nodes[ntag]

		for _, ttag in ipairs(node.order_c) do
			local task = node.tasks[ttag]

			if not task.dirty and task.auto(node.data_const) then
				task.dirty = true
			end

            if not task.dirty and node.dirty and task.back then
                task.dirty = true
            end

			if task.dirty then
				for cttag, _ in pairs(node.children_c[ttag]) do
					node.tasks[cttag].dirty = true
				end
				if not task.back then
					node.dirty = true
				end
			end
		end

		if node.dirty then
			for cntag, _ in pairs(graph.children_d[ntag]) do
				local cnode = graph.nodes[cntag]
				for cttag, _ in pairs(graph.children_d[ntag][cntag]) do
					local ctask = cnode.tasks[cttag]
					ctask.dirty = true
				end
			end
		end
	end
end

---@param graph softdep.Graph
function methods.update(graph)
	methods.spread(graph)

	for _, ntag in ipairs(graph.order_n) do
		local node = graph.nodes[ntag]

		for _, ttag in ipairs(node.order_cf) do
			local task = node.tasks[ttag]

			if task.dirty then
				task.func(node.data_a[task.atag], graph._data[ntag][ttag])
				task.dirty = false
				task.count = task.count + 1
			end
		end
	end

	for i = #graph.order_n, 1, -1 do
		local ntag = graph.order_n[i]
		local node = graph.nodes[ntag]

		for _, ttag in ipairs(node.order_cb) do
			local task = node.tasks[ttag]

			if task.dirty then
				task.func(node.data_a[task.atag], graph._data[ntag][ttag])
				task.dirty = false
				task.count = task.count + 1
			end
		end

		if node.dirty then
			node.dirty = false
			node.count = node.count + 1
		end
	end
end

return methods
