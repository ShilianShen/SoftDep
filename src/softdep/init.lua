local softdep = {}

local MT = {
	__newindex = function(t, key)
		assert(false)
	end,
}

local access = require("src.softdep.access")

return softdep
