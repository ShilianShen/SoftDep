package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local check = require("softdep.check")

local function identity(data)
	return data
end

local function declaration()
	return {
		access = {
			levels = {
				read = { func = identity, os = false },
				write = { func = identity, os = true },
			},
			edges = { { "read", "write" } },
		},
		nodes = {
			main = {
				atag = "read",
				tasks = {
					run = {
						func = function() end,
						auto = function() end,
						atag = "write",
						parents_c = {},
						parents_d = {},
						back = true,
					},
				},
				apis = {
					call = { func = function() end, ttag = "run", atag = "write", dirty = false },
				},
			},
		},
	}
end

describe("graph declaration check", function()
	it("accepts complete and minimal declarations", function()
		assert.is_true(check.graphDeclaration(declaration()))

		local minimal = declaration()
		minimal.nodes = nil
		assert.is_true(check.graphDeclaration(minimal))
	end)

	it("checks structure without checking graph semantics", function()
		local value = declaration()
		value.nodes.main.tasks.run.parents_c = { "missing" }
		assert.is_true(check.graphDeclaration(value))
	end)

	---@type [string, fun(value: table): any][]
	local invalidCases = {
		{ "non-table graph", function(_)
			return "graph"
		end },
		{ "unknown graph field", function(value)
			value.extra = true
		end },
		{ "obsolete default field", function(value)
			value.default = { nodeAtag = "read", taskAtag = "write", apiAtag = "write" }
		end },
		{ "missing access", function(value)
			value.access = nil
		end },
		{ "unknown access field", function(value)
			value.access.extra = true
		end },
		{ "non-table access levels", function(value)
			value.access.levels = false
		end },
		{ "non-string access tag", function(value)
			value.access.levels[1] = value.access.levels.read
		end },
		{ "non-table access level", function(value)
			value.access.levels.read = false
		end },
		{ "non-function access view", function(value)
			value.access.levels.read.func = true
		end },
		{ "non-boolean order sensitivity", function(value)
			value.access.levels.read.os = 0
		end },
		{ "non-table access relations", function(value)
			value.access.edges = false
		end },
		{ "non-array access relations", function(value)
			value.access.edges = { relation = { "read", "write" } }
		end },
		{ "access relation with wrong length", function(value)
			value.access.edges = { { "read" } }
		end },
		{ "access relation with non-string endpoint", function(value)
			value.access.edges = { { "read", false } }
		end },
		{ "non-table nodes", function(value)
			value.nodes = true
		end },
		{ "non-string node tag", function(value)
			value.nodes[1] = value.nodes.main
		end },
		{ "unknown node field", function(value)
			value.nodes.main.extra = true
		end },
		{ "invalid node access tag", function(value)
			value.nodes.main.atag = false
		end },
		{ "missing node access tag", function(value)
			value.nodes.main.atag = nil
		end },
		{ "non-table tasks", function(value)
			value.nodes.main.tasks = false
		end },
		{ "unknown task field", function(value)
			value.nodes.main.tasks.run.extra = true
		end },
		{ "invalid task function", function(value)
			value.nodes.main.tasks.run.func = {}
		end },
		{ "invalid automatic function", function(value)
			value.nodes.main.tasks.run.auto = "auto"
		end },
		{ "invalid task access tag", function(value)
			value.nodes.main.tasks.run.atag = 1
		end },
		{ "missing task access tag", function(value)
			value.nodes.main.tasks.run.atag = nil
		end },
		{ "non-boolean task back", function(value)
			value.nodes.main.tasks.run.back = "back"
		end },
		{ "missing task back", function(value)
			value.nodes.main.tasks.run.back = nil
		end },
		{ "sparse control dependencies", function(value)
			value.nodes.main.tasks.run.parents_c = { [2] = "run" }
		end },
		{ "non-string control dependency", function(value)
			value.nodes.main.tasks.run.parents_c = { true }
		end },
		{ "non-string data dependency alias", function(value)
			value.nodes.main.tasks.run.parents_d[1] = "main"
		end },
		{ "non-string data dependency target", function(value)
			value.nodes.main.tasks.run.parents_d.input = true
		end },
		{ "non-table APIs", function(value)
			value.nodes.main.apis = false
		end },
		{ "unknown API field", function(value)
			value.nodes.main.apis.call.extra = true
		end },
		{ "invalid API function", function(value)
			value.nodes.main.apis.call.func = "call"
		end },
		{ "invalid API task tag", function(value)
			value.nodes.main.apis.call.ttag = false
		end },
		{ "invalid API access tag", function(value)
			value.nodes.main.apis.call.atag = {}
		end },
		{ "missing API access tag", function(value)
			value.nodes.main.apis.call.atag = nil
		end },
		{ "non-boolean API dirty", function(value)
			value.nodes.main.apis.call.dirty = "dirty"
		end },
		{ "missing API dirty", function(value)
			value.nodes.main.apis.call.dirty = nil
		end },
	}

	for _, case in ipairs(invalidCases) do
		it("rejects " .. case[1], function()
			local original = declaration()
			local replacement = case[2](original)
			local value = replacement or original
			local ok = check.graphDeclaration(value)
			assert.is_false(ok)
		end)
	end
end)
