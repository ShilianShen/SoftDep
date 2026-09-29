local function pass(...) end

---@class softdep.b1.InputTask
---@field func function|nil
---@field auto function|nil
---@field atag string|nil
---@field parents_c string[]|nil
---@field parents_d table<string, string>|nil

---@class softdep.b1.OutputTask
---@field func function
---@field auto function
---@field atag string
---@field parents_c string[]
---@field parents_d table<string, string>

---@param task softdep.b1.InputTask
---@param taskAtag string
---@return softdep.b1.OutputTask
local function getTask(task, taskAtag)
	return {
		func = task.func or pass,
		auto = task.auto or pass,
		atag = task.atag or taskAtag,
		parents_c = task.parents_c or {},
		parents_d = task.parents_d or {},
	}
end

---@class softdep.b1.InputApi
---@field func function|nil
---@field ttag string|nil
---@field atag string|nil

---@class softdep.b1.OutputApi
---@field func function|nil
---@field ttag string|nil
---@field atag string

---@param api softdep.b1.InputApi
---@param apiAtag string
---@return softdep.b1.OutputApi
local function getApi(api, apiAtag)
	return {
		func = api.func,
		ttag = api.ttag,
		atag = api.atag or apiAtag,
	}
end

---@class softdep.b1.InputNode
---@field atag string|nil
---@field tasks table<string, softdep.b1.InputTask>|nil
---@field apis table<string, softdep.b1.InputApi>|nil

---@class softdep.b1.OutputNode
---@field atag string
---@field tasks table<string, softdep.b1.OutputTask>
---@field apis table<string, softdep.b1.OutputApi>

---@param node softdep.b1.InputNode
---@param nodeAtag string
---@return softdep.b1.OutputNode
local function getNode(node, nodeAtag, taskAtag, apiAtag)
	local result = {
		tasks = {},
		apis = {},
		atag = node.atag or nodeAtag,
	}
	for ttag, task in pairs(node.tasks or {}) do
		result.tasks[ttag] = getTask(task, taskAtag)
	end
	for atag, api in pairs(node.apis or {}) do
		result.apis[atag] = getApi(api, apiAtag)
	end
	return result
end

---@class softdep.b1.InputGraph
---@field access {levels: table<string, softdep.AccessLevel>, lt: softdep.Edges[]}
---@field nodes table<string, softdep.b1.InputNode>|nil
---@field default {nodeAtag: string, taskAtag: string, apiAtag: string}

---@class softdep.b1.OutputGraph
---@field access {levels: table<string, softdep.AccessLevel>, lt: softdep.Edges[]}
---@field nodes table<string, softdep.b1.OutputNode>

---@param graph softdep.b1.InputGraph
---@return softdep.b1.OutputGraph
local function getGraph(graph)
	local result = {
		access = graph.access,
		nodes = {},
	}
	for ntag, node in pairs(graph.nodes or {}) do
		result.nodes[ntag] = getNode(node, graph.default.nodeAtag, graph.default.taskAtag, graph.default.apiAtag)
	end
	return result
end

return getGraph
