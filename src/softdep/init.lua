local build = require("softdep.build")
local bind = require("softdep.bind")
local softdep = {}

function softdep.newGraph(config)
	local graph = build(config)
    bind(graph)
	return graph
end

return softdep
