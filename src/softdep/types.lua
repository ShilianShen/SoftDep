local types = require("softdep.tableshape").types

function types.opt_map_of(...)
	return types.map_of(...):is_optional()
end

types.set = types.map_of(types.any, types.literal(true))
types.adjList = types.map_of(types.any, types.set)

types.stringSet = types.map_of(types.string, types.literal(true))
types.stringArray = types.array_of(types.string)
types.stringAdjList = types.map_of(types.string, types.stringSet)

types.parentSets = types.map_of(types.string, types.stringSet)
types.childSets = types.map_of(types.string, types.stringSet)

types.accessLevels = types.map_of(
	types.string,
	types.shape({
		func = types.func,
		os = types.boolean,
	})
)
types.accessLt = types.array_of(types.array_of(types.string))

return types
