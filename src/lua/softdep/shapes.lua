local types = require("softdep.tableshape").types
local shapes = {}

shapes.set = types.map_of(types.any, types.literal(true))
shapes.stringSet = types.map_of(types.string, types.literal(true))
shapes.parentSets = types.map_of(types.string, shapes.stringSet)
shapes.childSets = types.map_of(types.string, shapes.stringSet)

return shapes
