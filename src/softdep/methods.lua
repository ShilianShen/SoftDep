local MathSet = require("softdep.MathSet")
local methods = {}

---@param graph softdep.Graph
function methods.spreadGraph(graph)
	for _, ntag in ipairs(graph.order) do
		local node = graph.nodes[ntag]

		for _, ttag in ipairs(node.order) do
			local task = node.tasks[ttag]

			if not task.dirty and task.auto(node.data) then
				task.dirty = true
			end

			if task.dirty then
				for cttag, _ in pairs(node.children_c[ttag]) do
					node.tasks[cttag].dirty = true
				end
				if task.higher then
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
function methods.newModule(graph, ntagArr)
	local module = {
		ntagSet = MathSet.arr2set(ntagArr),
		parents_n = {},
	}
	for ntag, _ in pairs(module.ntagSet) do
		for pntag, _ in pairs(graph.parents_n[ntag]) do
			if not module.ntagSet[pntag] then
				module.parents_n[pntag] = true
			end
		end
	end
	return module
end

---@param graph softdep.Graph
function methods.updateGraph(graph, module)
	methods.spreadGraph(graph)
	if module ~= nil then
		for pntag, _ in pairs(module.parents_n) do
			local pnode = graph.nodes[pntag]
			if pnode.dirty then
				return
			end
		end
	end

	for _, ntag in ipairs(graph.order) do
		if module == nil or module.ntagSet[ntag] then
			local node = graph.nodes[ntag]

			for _, ttag in ipairs(node.order) do
				local task = node.tasks[ttag]

				if task.dirty then
					local parents_d = {}
					for pdtag, pntag in pairs(graph.parents_d[ntag][ttag]) do
						local pnode = graph.nodes[pntag]
						parents_d[pdtag] = pnode.data_a[pnode.atag]
					end

					task.func(node.data_a[task.atag], parents_d)
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
end

return methods
