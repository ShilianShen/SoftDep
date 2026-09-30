local MathSet = require("softdep.MathSet")
local MathGraph = require("softdep.MathGraph")
local Access = require("softdep.Access")
local function pass(...) end

---@param taskDeclaration softdep.declaration.Task
---@param accessLevels softdep.AccessLevel[]
---@param taskDefaultAtag string
---@return softdep.Task
local function newTask(taskDeclaration, accessLevels, taskDefaultAtag)
	local task = {
		func = taskDeclaration.func or pass,
		auto = taskDeclaration.auto or pass,
		atag = taskDeclaration.atag or taskDefaultAtag,
		dirty = true,
		count = 0,
	}
	if accessLevels[task.atag] == nil then
		error("TODO", 2)
	end
	return task
end

---@param apiDeclaration softdep.declaration.Api
---@param tasks table<string, softdep.Task>
---@param accessLevels softdep.AccessLevel[]
---@param apiDefaultAtag string
---@return softdep.Api
local function newApi(apiDeclaration, tasks, accessLevels, apiDefaultAtag)
	local api = {
		func = apiDeclaration.func,
		ttag = apiDeclaration.ttag,
		atag = apiDeclaration.atag or apiDefaultAtag,
	}
	if api.ttag ~= nil and tasks[api.ttag] == nil then
		error("TODO", 2)
	end
	if accessLevels[api.atag] == nil then
		error("TODO", 2)
	end
	return api
end

---@param nodeDeclaration softdep.declaration.Node
---@param accessLevels softdep.AccessLevel[]
---@param nodeDefaultAtag string
---@param taskDefaultAtag string
---@param apiDefaultAtag string
---@return softdep.Node
local function newNode(nodeDeclaration, accessLevels, nodeDefaultAtag, taskDefaultAtag, apiDefaultAtag)
	local node = {
		atag = nodeDeclaration.atag or nodeDefaultAtag,
		data = {},
		dirty = true,
		count = 0,
	}

	if accessLevels[node.atag] == nil then
		error("TODO", 2)
	end
	if accessLevels[node.atag].os then
		error("TODO", 2)
	end

	---@type table<string, softdep.Task>
	node.tasks = {}

	---@type table<string, table>
	node.data_a = {}
	for atag, level in pairs(accessLevels) do
		node.data_a[atag] = level.func(node.data)
	end

	---@type softdep.AdjList
	node.parents_c = {}

	for ttag, taskDeclaration in pairs(nodeDeclaration.tasks or {}) do
		local ok, result = pcall(newTask, taskDeclaration, accessLevels, taskDefaultAtag)
		if not ok then
			error("TODO", 2)
		end
		node.tasks[ttag] = result
		node.parents_c[ttag] = MathSet.arr2set(taskDeclaration.parents_c or {})
	end

	do
		local ok, result = pcall(MathGraph.revAdjList, node.parents_c)
		if not ok then
			error("TODO", 2)
		end
		node.children_c = result
	end
	do
		local ok, result = pcall(MathGraph.sort, node.children_c, true)
		if not ok then
			error("TODO", 2)
		end
		node.order = result
	end

	---@type table<string, softdep.Api>
	node.apis = {}
	for itag, apiDeclaration in pairs(nodeDeclaration.apis or {}) do
		local ok, result = pcall(newApi, apiDeclaration, node.tasks, accessLevels, apiDefaultAtag)
		if not ok then
			error("TODO", 2)
		end
		node.apis[itag] = result
	end

	return node
end

---@param graphDeclaration softdep.declaration.Graph
---@return softdep.Graph
local function newGraph(graphDeclaration)
	local graph = {}

	do
		local ok, result = pcall(Access.newAccess, graphDeclaration.access.levels, graphDeclaration.access.lt)
		if not ok then
			error("TODO", 2)
		end
		graph.access = result
	end

	---@type table<string, softdep.Node>
	graph.nodes = {}
	local default = graphDeclaration.default
	for ntag, nodeDeclaration in pairs(graphDeclaration.nodes or {}) do
		local ok, result =
			pcall(newNode, nodeDeclaration, graph.access.levels, default.nodeAtag, default.taskAtag, default.apiAtag)
		if not ok then
			error("TODO", 2)
		end
		graph.nodes[ntag] = result
	end

	---@type softdep.AdjList
	graph.parents_n = {}
	for ntag, nodeDeclaration in pairs(graphDeclaration.nodes or {}) do
		---@type softdep.Set
		local parents_n = {}
		for ttag, taskDeclaration in pairs(nodeDeclaration.tasks or {}) do
			for _, pntag in pairs(taskDeclaration.parents_d or {}) do
				parents_n[pntag] = true
			end
		end
		graph.parents_n[ntag] = parents_n
	end

	do
		local ok, result = pcall(MathGraph.revAdjList, graph.parents_n)
		if not ok then
			error("TODO", 2)
		end
		graph.children_n = result
	end
	do
		local ok, result = pcall(MathGraph.sort, graph.children_n)
		if not ok then
			error("TODO", 2)
		end
		graph.order = result
	end

	---@type table<string, table<string, table<string, string>>>
	graph.parents_d = {}
	for ntag, nodeDeclaration in pairs(graphDeclaration.nodes or {}) do
		graph.parents_d[ntag] = {}
		for ttag, taskDeclaration in pairs(nodeDeclaration.tasks or {}) do
			graph.parents_d[ntag][ttag] = taskDeclaration.parents_d or {}
		end
	end

	---@type table<string, softdep.AdjList>
	graph.children_d = {}
	for ntag, _ in pairs(graph.nodes) do
		graph.children_d[ntag] = {}
		for cntag, _ in pairs(graph.children_n[ntag]) do
			graph.children_d[ntag][cntag] = {}
		end
	end
	for ntag, _ in pairs(graph.parents_d) do
		for ttag, _ in pairs(graph.parents_d[ntag]) do
			for _, pntag in pairs(graph.parents_d[ntag][ttag]) do
				graph.children_d[pntag][ntag][ttag] = true
			end
		end
	end

	return graph
end

return newGraph
