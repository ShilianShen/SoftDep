package.path = "src/lua/?.lua;" .. "src/lua/?/init.lua;" .. package.path
local kahn = require("softdep.kahn")
kahn({ a = { b = true } })
