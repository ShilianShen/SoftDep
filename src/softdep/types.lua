local types = require("softdep.tableshape").types

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
types.accessLeq = types.array_of(types.array_of(types.string))

types.newTaskArgs = types.shape({
	func = types.func,
	auto = types.func,
	access = types.string,
})
types.task = types.shape({
	func = types.func,
	auto = types.func,
	dirty = types.boolean,
	count = types.integer,
	access = types.string,
})

types.newNodeArgs = types.shape({
	data = types.table,
	tasks = types.map_of(types.string, types.task),
	access = types.string,
	apis = types.map_of(
		types.string,
		types.shape({
			func = types.func:is_optional(),
			ttag = types.string:is_optional(),
		})
	),
	parents_c = types.stringAdjList,
})
types.node = types.shape({
	data = types.table,
	tasks = types.map_of(types.string, types.task),
	access = types.string,
	apis = types.map_of(
		types.string,
		types.shape({
			func = types.func:is_optional(),
			ttag = types.string:is_optional(),
		})
	),
	data_a = types.map_of(types.string, types.table),
	order = types.array_of(types.string),
	dirty = types.boolean,
	parents_c = types.stringAdjList,
	children_c = types.stringAdjList,
})

types.newGraphArgs = types.shape({
	nodes = types.map_of(types.string, types.node),
	parents_n = types.stringAdjList,
})
types.newGraphArgs = types.shape({
	nodes = types.map_of(types.string, types.node),
	ready = types.boolean,
	order = types.array_of(types.string),
	children_n = types.stringAdjList,
	parents_n = types.stringAdjList,
})

return types
