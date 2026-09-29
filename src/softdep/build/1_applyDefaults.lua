local function pass(...) end

local function applyDefaults(graph)
	graph.nodes = graph.nodes or {}
	for _, node in pairs(graph.nodes) do
		node.atag = node.atag or graph.default.nodeAtag
		node.tasks = node.tasks or {}
		node.apis = node.apis or {}
		for _, task in pairs(node.tasks) do
			task.func = task.func or pass
			task.auto = task.auto or pass
			task.atag = task.atag or graph.default.taskAtag
			task.parents_c = task.parents_c or {}
			task.parents_d = task.parents_d or {}
		end
		for _, api in pairs(node.apis) do
			api.atag = api.atag or graph.default.apiAtag
		end
	end
	graph.default = nil
end

return applyDefaults
