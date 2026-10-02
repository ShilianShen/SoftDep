local MathSet = require("softdep.MathSet")
local MathGraph = require("softdep.MathGraph")
local Access = require("softdep.Access")
local function pass(...) end

---@param taskDeclaration softdep.declaration.Task
---@param access softdep.Access
---@param taskDefaultAtag string
---@param node softdep.Node
---@return boolean, softdep.Task|string
local function createTask(taskDeclaration, access, taskDefaultAtag, node)
	local task = {
		func = taskDeclaration.func or pass,
		auto = taskDeclaration.auto or pass,
		atag = taskDeclaration.atag or taskDefaultAtag,
		dirty = true,
		count = 0,
	}
	if access.levels[task.atag] == nil then
		return false, "TODO"
	end
	return true, task
end

---@param apiDeclaration softdep.declaration.Api
---@param tasks table<string, softdep.Task>
---@param access softdep.Access
---@param apiDefaultAtag string
---@param node softdep.Node
---@return boolean, softdep.Api|string
local function createApi(apiDeclaration, tasks, access, apiDefaultAtag, node)
	local api = {
		func = apiDeclaration.func,
		ttag = apiDeclaration.ttag,
		atag = apiDeclaration.atag or apiDefaultAtag,
	}
	if api.ttag ~= nil and tasks[api.ttag] == nil then
		return false, "TODO"
	end
	if access.levels[api.atag] == nil then
		return false, "TODO"
	end
	return true, api
end

---@param nodeDeclaration softdep.declaration.Node
---@param access softdep.Access
---@param nodeDefaultAtag string
---@param taskDefaultAtag string
---@param apiDefaultAtag string
---@return boolean, softdep.Node|string
local function createNode(nodeDeclaration, access, nodeDefaultAtag, taskDefaultAtag, apiDefaultAtag)
	local node = {
		atag = nodeDeclaration.atag or nodeDefaultAtag,
		data = {},
		dirty = true,
		count = 0,
	}

	if access.levels[node.atag] == nil then
		return false, "TODO"
	end
	if access.levels[node.atag].os then
		return false, "TODO"
	end

	---@type table<string, softdep.Task>
	node.tasks = {}

	---@type table<string, table>
	node.data_a = {}
	for atag, level in pairs(access.levels) do
		node.data_a[atag] = level.func(node.data)
		if type(node.data_a[atag]) ~= "table" then
			return false, "TODO"
		end
	end

	---@type softdep.AdjList
	node.parents_c = {}

	for ttag, taskDeclaration in pairs(nodeDeclaration.tasks or {}) do
		local taskOk, taskResult = createTask(taskDeclaration, access, taskDefaultAtag, node)
		if not taskOk or type(taskResult) == "string" then
			return false, "TODO"
		end
		node.tasks[ttag] = taskResult
		node.parents_c[ttag] = MathSet.arr2set(taskDeclaration.parents_c or {})
	end

	local adjListOk, adjListResult = MathGraph.checkAdjList(node.parents_c)
	if not adjListOk then
		return false, "TODO"
	end

	node.children_c = MathGraph.revAdjList(node.parents_c)

	local dagOk, degResult = MathGraph.checkDAG(node.children_c, true)
	if not dagOk then
		return false, "TODO"
	end

	node.order = MathGraph.sort(node.children_c, true)

	---@type table<string, softdep.Api>
	node.apis = {}
	for itag, apiDeclaration in pairs(nodeDeclaration.apis or {}) do
		local apiOk, apiResult = createApi(apiDeclaration, node.tasks, access, apiDefaultAtag, node)
		if not apiOk or type(apiResult) == "string" then
			return false, "TODO"
		end
		node.apis[itag] = apiResult
	end

	return true, node
end

---@param graphDeclaration softdep.declaration.Graph
---@return boolean, softdep.Graph|string
local function createGraph(graphDeclaration)
	local graph = {}

	local accessEdgesOk, accessEdgesResult =
		Access.checkEdges(graphDeclaration.access.levels, graphDeclaration.access.lt)

	if not accessEdgesOk then
		return false, "TODO"
	end

	graph.access = Access.newAccess(graphDeclaration.access.levels, graphDeclaration.access.lt)

	local default = graphDeclaration.default
	if graph.access.levels[default.nodeAtag] == nil then
		return false, "TODO"
	end
	if graph.access.levels[default.taskAtag] == nil then
		return false, "TODO"
	end
	if graph.access.levels[default.apiAtag] == nil then
		return false, "TODO"
	end

	---@type table<string, softdep.Node>
	graph.nodes = {}
	for ntag, nodeDeclaration in pairs(graphDeclaration.nodes or {}) do
		local nodeOk, nodeResult =
			createNode(nodeDeclaration, graph.access, default.nodeAtag, default.taskAtag, default.apiAtag)
		if not nodeOk or type(nodeResult) == "string" then
			return false, "TODO"
		end
		graph.nodes[ntag] = nodeResult
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

	local adjListOk, adjListResult = MathGraph.checkAdjList(graph.parents_n)
	if not adjListOk then
		return false, "TODO"
	end

	graph.children_n = MathGraph.revAdjList(graph.parents_n)

	local dagOk, dagResult = MathGraph.checkDAG(graph.children_n, false)
	if not dagOk then
		return false, "TODO"
	end

	graph.order = MathGraph.sort(graph.children_n, false)

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

	return true, graph
end

return createGraph
