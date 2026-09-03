package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path
local assert = require("luassert")
local DM = require("softdep.DM")

local function set(...)
	local result = {}
	for i = 1, select("#", ...) do
		result[select(i, ...)] = true
	end
	return result
end

local function setKey(value)
	local arr = {}
	for v, _ in pairs(value) do
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

local chainReach = {
	a = { a = true, b = true, c = true },
	b = { b = true, c = true },
	c = { c = true },
}

describe("DM.getUpperBounds", function()
	it("returns all vertices for an empty subset", function()
		assert.same(set("a", "b", "c"), DM.getUpperBounds(chainReach, {}))
	end)

	it("returns all upper bounds of one element", function()
		assert.same(set("b", "c"), DM.getUpperBounds(chainReach, set("b")))
	end)

	it("returns common upper bounds", function()
		assert.same(set("b", "c"), DM.getUpperBounds(chainReach, set("a", "b")))
	end)

	it("returns the maximum as its own only upper bound", function()
		assert.same(set("c"), DM.getUpperBounds(chainReach, set("c")))
	end)

	it("returns no upper bound for incomparable maximal elements", function()
		local reach = {
			a = { a = true },
			b = { b = true },
		}

		assert.same({}, DM.getUpperBounds(reach, set("a", "b")))
	end)

	it("rejects an invalid reachability adjacency list", function()
		assert.has_error(function()
			DM.getUpperBounds({
				a = { a = false },
			}, {})
		end)
	end)

	it("rejects an invalid subset", function()
		assert.has_error(function()
			DM.getUpperBounds(chainReach, {
				a = false,
			})
		end)
	end)
end)

describe("DM.getLowerBounds", function()
	it("returns all vertices for an empty subset", function()
		assert.same(set("a", "b", "c"), DM.getLowerBounds(chainReach, {}))
	end)

	it("returns all lower bounds of one element", function()
		assert.same(set("a", "b"), DM.getLowerBounds(chainReach, set("b")))
	end)

	it("returns common lower bounds", function()
		assert.same(set("a", "b"), DM.getLowerBounds(chainReach, set("b", "c")))
	end)

	it("returns the minimum as its own only lower bound", function()
		assert.same(set("a"), DM.getLowerBounds(chainReach, set("a")))
	end)

	it("returns no lower bound for incomparable minimal elements", function()
		local reach = {
			a = { a = true },
			b = { b = true },
		}

		assert.same({}, DM.getLowerBounds(reach, set("a", "b")))
	end)

	it("rejects an invalid reachability adjacency list", function()
		assert.has_error(function()
			DM.getLowerBounds({
				a = { a = false },
			}, {})
		end)
	end)

	it("rejects an invalid subset", function()
		assert.has_error(function()
			DM.getLowerBounds(chainReach, {
				a = false,
			})
		end)
	end)
end)

describe("DM.getClosure", function()
	it("closes the empty subset of a chain to its minimum", function()
		assert.same(set("a"), DM.getClosure(chainReach, {}))
	end)

	it("closes a middle element to its principal lower set", function()
		assert.same(set("a", "b"), DM.getClosure(chainReach, set("b")))
	end)

	it("closes the maximum to the whole chain", function()
		assert.same(set("a", "b", "c"), DM.getClosure(chainReach, set("c")))
	end)

	it("keeps the empty subset closed in a nonempty antichain", function()
		local reach = {
			a = { a = true },
			b = { b = true },
		}

		assert.same({}, DM.getClosure(reach, {}))
	end)

	it("closes two incomparable elements to the whole antichain", function()
		local reach = {
			a = { a = true },
			b = { b = true },
		}

		assert.same(set("a", "b"), DM.getClosure(reach, set("a", "b")))
	end)

	it("is idempotent", function()
		local closure = DM.getClosure(chainReach, set("b"))

		assert.same(closure, DM.getClosure(chainReach, closure))
	end)

	it("rejects an invalid subset", function()
		assert.has_error(function()
			DM.getClosure(chainReach, {
				a = false,
			})
		end)
	end)
end)

describe("DM.DM", function()
	it("returns one closed subset for an empty graph", function()
		local lattice = DM.DM({})

		assert.same({
			"",
		}, latticeKeys(lattice))
	end)

	it("returns the singleton for a one-vertex graph", function()
		local lattice = DM.DM({
			a = {},
		})

		assert.same({
			"a",
		}, latticeKeys(lattice))
	end)

	it("completes a two-element chain", function()
		local lattice = DM.DM({
			a = { b = true },
			b = {},
		})

		assert.same({
			"a",
			"a,b",
		}, latticeKeys(lattice))
	end)

	it("completes a two-element antichain", function()
		local lattice = DM.DM({
			a = {},
			b = {},
		})

		assert.same({
			"",
			"a",
			"a,b",
			"b",
		}, latticeKeys(lattice))
	end)

	it("uses transitive reachability", function()
		local lattice = DM.DM({
			a = { b = true },
			b = { c = true },
			c = {},
		})

		assert.same({
			"a",
			"a,b",
			"a,b,c",
		}, latticeKeys(lattice))
	end)

	it("completes a V-shaped poset", function()
		local lattice = DM.DM({
			a = { c = true },
			b = { c = true },
			c = {},
		})

		assert.same({
			"",
			"a",
			"a,b,c",
			"b",
		}, latticeKeys(lattice))
	end)

	it("completes an inverted V-shaped poset", function()
		local lattice = DM.DM({
			a = { b = true, c = true },
			b = {},
			c = {},
		})

		assert.same({
			"a",
			"a,b",
			"a,b,c",
			"a,c",
		}, latticeKeys(lattice))
	end)

	it("handles a diamond poset", function()
		local lattice = DM.DM({
			a = { b = true, c = true },
			b = { d = true },
			c = { d = true },
			d = {},
		})

		assert.same({
			"a",
			"a,b",
			"a,b,c,d",
			"a,c",
		}, latticeKeys(lattice))
	end)

	it("accepts redundant transitive edges", function()
		local lattice = DM.DM({
			a = { b = true, c = true },
			b = { c = true },
			c = {},
		})

		assert.same({
			"a",
			"a,b",
			"a,b,c",
		}, latticeKeys(lattice))
	end)

	it("rejects an invalid adjacency list", function()
		assert.has_error(function()
			DM.DM({
				a = { b = false },
			})
		end)
	end)
end)
