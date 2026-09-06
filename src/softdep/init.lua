local Access = require("softdep.Access")
local types = require("softdep.types")
local check = require("softdep.check")
local MathSet = require("softdep.MathSet")
local parse = require("softdep.parse")
local softdep = {}

function softdep.newGraph(config)
	local access = Access.newAccess(config.access.levels, config.access.leq)
end

softdep.parse = parse

return softdep
