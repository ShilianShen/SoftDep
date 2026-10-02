local methods = require("softdep.methods")
local build = require("softdep.build")
local check = require("softdep.check")
local softdep = {}

local function deepCopyAsTree(graph)
	if type(graph) ~= "table" then
		return graph
	end

	local result = {}

	for k, v in pairs(graph) do
		result[deepCopyAsTree(k)] = deepCopyAsTree(v)
	end

	return result
end

local nodeMetatable = {
	__call = function(api, ...)
		if api.func then
			api.func(api._node.data_a[api.atag], ...)
			if api.higher then
				api._node.dirty = true
			end
		end
		if api.ttag then
			api._node.tasks[api.ttag].dirty = true
		end
	end,
}

---@param graph softdep.Graph
local function bind(graph)
	graph.spread = methods.spreadGraph
	graph.update = methods.updateGraph
	graph.newModule = methods.newModule

	return graph
end

function softdep.newGraph(config)
	local declarationOk, declarationResult = check.graphDeclaration(config)
	if not declarationOk then
		error(declarationResult, 2)
	end

	config = deepCopyAsTree(config)
	local graphOk, graphResult = build(config)
	if not graphOk or type(graphResult) == "string" then
		error("TODO", 2)
	end
	local graph = graphResult

	bind(graph)
	return graph
end

return softdep
