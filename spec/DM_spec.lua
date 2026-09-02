package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path
local assert = require("luassert")
local DM = require("softdep.DM")

local function setKey(set)
	local arr = {}
	for v, _ in pairs(set) do
		arr[#arr + 1] = tostring(v)
	end
	table.sort(arr)
	return table.concat(arr, ",")
end

local function latticeKeys(lattice)
	local keys = {}
	for subset, _ in pairs(lattice) do
		keys[#keys + 1] = setKey(subset)
	end
	table.sort(keys)
	return keys
end

describe("DM", function()
	it("returns one closed subset for an empty graph", function()
		local adjList = {}

		local lattice = DM(adjList)

		assert.same({ "" }, latticeKeys(lattice))
	end)

	it("returns the singleton for a one-vertex graph", function()
		local adjList = {
			a = {},
		}

		local lattice = DM(adjList)

		assert.same({
			"a",
		}, latticeKeys(lattice))
	end)

	it("returns all principal closed sets for a two-element chain", function()
		local adjList = {
			a = { b = true },
			b = {},
		}

		local lattice = DM(adjList)

		assert.same({
			"a",
			"a,b",
		}, latticeKeys(lattice))
	end)

	it("completes a two-element antichain", function()
		local adjList = {
			a = {},
			b = {},
		}

		local lattice = DM(adjList)

		assert.same({
			"",
			"a",
			"a,b",
			"b",
		}, latticeKeys(lattice))
	end)

	it("handles a three-element chain", function()
		local adjList = {
			a = { b = true },
			b = { c = true },
			c = {},
		}

		local lattice = DM(adjList)

		assert.same({
			"a",
			"a,b",
			"a,b,c",
		}, latticeKeys(lattice))
	end)

	it("handles transitive edges that are not explicitly present", function()
		local adjList = {
			a = { b = true },
			b = { c = true },
			c = {},
		}

		local lattice = DM(adjList)
		local keys = latticeKeys(lattice)

		assert.same({
			"a",
			"a,b",
			"a,b,c",
		}, keys)
	end)

	it("completes a V-shaped poset", function()
		local adjList = {
			a = { c = true },
			b = { c = true },
			c = {},
		}

		local lattice = DM(adjList)

		assert.same({
			"",
			"a",
			"a,b,c",
			"b",
		}, latticeKeys(lattice))
	end)

	it("completes an inverted V-shaped poset", function()
		local adjList = {
			a = { b = true, c = true },
			b = {},
			c = {},
		}

		local lattice = DM(adjList)

		assert.same({
			"a",
			"a,b",
			"a,b,c",
			"a,c",
		}, latticeKeys(lattice))
	end)

	it("rejects an invalid adjacency list", function()
		assert.has_error(function()
			DM({
				a = { b = false },
			})
		end)
	end)
end)
