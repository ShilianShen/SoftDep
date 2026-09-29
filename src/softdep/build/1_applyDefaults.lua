local function pass(...) end

---@class softdep.b1.InputTask
---@field func function|nil
---@field auto function|nil
---@field atag string|nil
---@field parents_c string[]|nil
---@field parents_d table<string, string>|nil

---@class softdep.b1.InputApi
---@field func function|nil
---@field ttag string|nil
---@field atag string|nil

---@class softdep.b1.InputNode
---@field atag string|nil
---@field tasks table<string, softdep.b1.InputTask>|nil
---@field apis table<string, softdep.b1.InputApi>|nil

---@class softdep.b1.InputGraph
---@field access {levels: table<string, softdep.AccessLevel>, lt: softdep.Edges[]}
---@field nodes table<string, softdep.b1.InputNode>|nil
---@field default {nodeAtag: string, taskAtag: string, apiAtag: string}

---@class softdep.b1.OutputTask
---@field func function
---@field auto function
---@field atag string
---@field parents_c string[]
---@field parents_d table<string, string>

---@class softdep.b1.OutputApi
---@field func function|nil
---@field ttag string|nil
---@field atag string

---@class softdep.b1.OutputNode
---@field atag string
---@field tasks table<string, softdep.b1.OutputTask>
---@field apis table<string, softdep.b1.OutputApi>

---@class softdep.b1.OutputGraph
---@field access {levels: table<string, softdep.AccessLevel>, lt: softdep.Edges[]}
---@field nodes table<string, softdep.b1.OutputNode>

---@param graph softdep.b1.InputGraph
---@return softdep.b1.OutputGraph
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
    return graph
end

return applyDefaults
