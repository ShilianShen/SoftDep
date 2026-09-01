package.path = "src/lua/?.lua;" .. "src/lua/?/init.lua;" .. package.path
local kahn = require("src.lua.softdep.kahn")
kahn(nil, nil)
