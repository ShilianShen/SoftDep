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

softdep.newConfig = require("src.softdep.newConfig")
softdep.newTheory = require("src.softdep.newTheory")
softdep.newEngine = require("src.softdep.newEngine")

return softdep
