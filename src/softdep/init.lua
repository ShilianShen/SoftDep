local methods = require("softdep.methods")
local build = require("softdep.build")
local check = require("softdep.check")
local const = require("softdep.const")
local softdep = {
	methods = methods,
	const = const,
}

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

local mt = {
	__index = methods,
}

---@param declaration softdep.declaration.Graph
---@return softdep.Graph
function softdep.newGraph(declaration)
	local declarationOk, declarationResult = check.graphDeclaration(declaration)
	if not declarationOk then
		error(declarationResult, 2)
	end

	declaration = deepCopyAsTree(declaration)

	local graphOk, graphResult = build(declaration)
	if not graphOk or type(graphResult) == "string" then
		error("failed to build graph", 2)
	end

	local graph = graphResult

	setmetatable(graph, mt)
	return graph
end

return softdep
