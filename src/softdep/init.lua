local softdep = {}

local ACCESS = {
	none = "none",
	readonly = "readonly",
	writable = "writable",
}

local MT = {
	__newindex = function(t, key)
		assert(false)
	end,
}

local newConfig = require("src.softdep.newConfig")
local newTheory = require("src.softdep.newTheory")
local newEngine = require("src.softdep.newEngine")

function softdep.newGraph(nodes)
	local config = newConfig(nodes)
	local theory = newTheory(config)
	local engine = newEngine(theory)
	setmetatable(engine, MT)
	return engine
end

return softdep
