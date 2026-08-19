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

softdep.newConfigGraph = require("src.softdep.newConfigGraph")
softdep.newTheoryGraph = require("src.softdep.newTheoryGraph")
softdep.newEngineGraph = require("src.softdep.newEngineGraph")

return softdep
