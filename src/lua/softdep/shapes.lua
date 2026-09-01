local types = require("libs.tableshape").types
local shapes = {}

shapes.set = types.map_of(types.string, types.literal(true))
shapes.parentSets = types.map_of(types.string, shapes.set)
shapes.childSets = types.map_of(types.string, shapes.set)

return shapes
