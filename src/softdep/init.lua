local bind = require("softdep.bind")
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
