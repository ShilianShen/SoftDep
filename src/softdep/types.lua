local types = require("softdep.tableshape").types

types.set = types.map_of(types.any, types.literal(true))
types.adjList = types.map_of(types.any, types.set)
types.stringSet = types.map_of(types.string, types.literal(true))
types.stringArray = types.array_of(types.string)
types.parentSets = types.map_of(types.string, types.stringSet)
types.childSets = types.map_of(types.string, types.stringSet)

types.accessLevels = types.map_of(
	types.string,
	types.shape({
		func = types.func,
	})
)
types.accessLeq = types.array_of(types.array_of(types.string))

return types
