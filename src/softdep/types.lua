local types = require("softdep.tableshape").types

types.set = types.map_of(types.any, types.literal(true))
types.stringSet = types.map_of(types.string, types.literal(true))
types.parentSets = types.map_of(types.string, types.stringSet)
types.childSets = types.map_of(types.string, types.stringSet)

return types
