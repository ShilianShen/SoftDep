package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path
local assert = require("luassert")
local Access = require("softdep.Access")
local bit = require("softdep.bit")

local function makeLevels(names)
	local levels = {}

	for _, name in ipairs(names) do
		levels[name] = {
			func = function() end,
		}
	end

	return levels
end

local function latticeMasks()
	local masks = {}

	for mask in pairs(Access.lattice) do
		masks[#masks + 1] = mask
	end

	table.sort(masks)
	return masks
end

local function assertBasicLatticeLaws()
	local masks = latticeMasks()

	for _, x in ipairs(masks) do
		assert.are.equal(x, Access.join(x))
		assert.are.equal(x, Access.meet(x))

		assert.are.equal(x, Access.join(x, x))
		assert.are.equal(x, Access.meet(x, x))
	end

	for _, x in ipairs(masks) do
		for _, y in ipairs(masks) do
			local joinXY = Access.join(x, y)
			local meetXY = Access.meet(x, y)

			assert.is_true(Access.lattice[joinXY])
			assert.is_true(Access.lattice[meetXY])

			assert.are.equal(joinXY, Access.join(y, x))
			assert.are.equal(meetXY, Access.meet(y, x))

			assert.are.equal(x, Access.join(x, meetXY))
			assert.are.equal(x, Access.meet(x, joinXY))
		end
	end
end

local function assertAssociativity()
	local masks = latticeMasks()

	for _, x in ipairs(masks) do
		for _, y in ipairs(masks) do
			for _, z in ipairs(masks) do
				assert.are.equal(Access.join(Access.join(x, y), z), Access.join(x, Access.join(y, z)))

				assert.are.equal(Access.meet(Access.meet(x, y), z), Access.meet(x, Access.meet(y, z)))
			end
		end
	end
end

describe("softdep.Access", function()
	describe("load", function()
		it("loads a single access level", function()
			Access.load(makeLevels({ "a" }), {})

			assert.is_not_nil(Access.poset.a)
			assert.is_true(Access.lattice[Access.poset.a])
		end)

		it("rejects an edge with fewer than two elements", function()
			assert.has_error(function()
				Access.load(makeLevels({ "a", "b" }), {
					{ "a" },
				})
			end)
		end)

		it("rejects an edge with more than two elements", function()
			assert.has_error(function()
				Access.load(makeLevels({ "a", "b", "c" }), {
					{ "a", "b", "c" },
				})
			end)
		end)

		it("rejects an unknown left access level", function()
			assert.has_error(function()
				Access.load(makeLevels({ "a" }), {
					{ "missing", "a" },
				})
			end)
		end)

		it("rejects an unknown right access level", function()
			assert.has_error(function()
				Access.load(makeLevels({ "a" }), {
					{ "a", "missing" },
				})
			end)
		end)

		it("replaces previously loaded state", function()
			Access.load(makeLevels({ "a", "b" }), {
				{ "a", "b" },
			})

			assert.is_not_nil(Access.poset.a)
			assert.is_not_nil(Access.poset.b)

			Access.load(makeLevels({ "x" }), {})

			assert.is_nil(Access.poset.a)
			assert.is_nil(Access.poset.b)
			assert.is_not_nil(Access.poset.x)
		end)

		it("rejects too many access levels", function()
			local names = {}

			for i = 1, 30 do
				names[i] = tostring(i)
			end

			assert.has_error(function()
				Access.load(makeLevels(names), {})
			end)
		end)
	end)

	describe("chain", function()
		setup(function()
			Access.load(makeLevels({ "a", "b", "c" }), {
				{ "a", "b" },
				{ "b", "c" },
			})
		end)

		it("embeds all access levels into the lattice", function()
			assert.is_true(Access.lattice[Access.poset.a])
			assert.is_true(Access.lattice[Access.poset.b])
			assert.is_true(Access.lattice[Access.poset.c])
		end)

		it("computes joins", function()
			assert.are.equal(Access.poset.b, Access.join("a", "b"))
			assert.are.equal(Access.poset.c, Access.join("a", "c"))
			assert.are.equal(Access.poset.c, Access.join("b", "c"))
			assert.are.equal(Access.poset.c, Access.join("a", "b", "c"))
		end)

		it("computes meets", function()
			assert.are.equal(Access.poset.a, Access.meet("a", "b"))
			assert.are.equal(Access.poset.a, Access.meet("a", "c"))
			assert.are.equal(Access.poset.b, Access.meet("b", "c"))
			assert.are.equal(Access.poset.a, Access.meet("a", "b", "c"))
		end)

		it("accepts lattice masks as arguments", function()
			local b = Access.join("a", "b")

			assert.are.equal(Access.poset.b, b)
			assert.are.equal(Access.poset.a, Access.meet(b, "a"))
			assert.are.equal(Access.poset.c, Access.join(b, "c"))
		end)

		it("is idempotent for single arguments", function()
			assert.are.equal(Access.poset.a, Access.join("a"))
			assert.are.equal(Access.poset.b, Access.join("b"))
			assert.are.equal(Access.poset.c, Access.join("c"))

			assert.are.equal(Access.poset.a, Access.meet("a"))
			assert.are.equal(Access.poset.b, Access.meet("b"))
			assert.are.equal(Access.poset.c, Access.meet("c"))
		end)
	end)

	describe("V-shaped poset", function()
		setup(function()
			Access.load(makeLevels({ "a", "b", "c" }), {
				{ "a", "c" },
				{ "b", "c" },
			})
		end)

		it("closes the union of incomparable elements", function()
			local raw = bit.bor(Access.poset.a, Access.poset.b)

			assert.is_nil(Access.lattice[raw])
			assert.are.equal(Access.poset.c, Access.join("a", "b"))
		end)

		it("computes the meet of incomparable elements", function()
			local bottom = Access.meet("a", "b")

			assert.is_true(Access.lattice[bottom])
			assert.are.equal(0, bottom)
		end)

		it("absorbs lower elements into the upper element", function()
			assert.are.equal(Access.poset.c, Access.join("a", "c"))
			assert.are.equal(Access.poset.c, Access.join("b", "c"))

			assert.are.equal(Access.poset.a, Access.meet("a", "c"))
			assert.are.equal(Access.poset.b, Access.meet("b", "c"))
		end)
	end)

	describe("inverted V-shaped poset", function()
		setup(function()
			Access.load(makeLevels({ "a", "b", "c" }), {
				{ "a", "b" },
				{ "a", "c" },
			})
		end)

		it("creates a new top element", function()
			local top = Access.join("b", "c")

			assert.is_true(Access.lattice[top])

			assert.is_false(top == Access.poset.a)
			assert.is_false(top == Access.poset.b)
			assert.is_false(top == Access.poset.c)
		end)

		it("computes the common lower bound", function()
			assert.are.equal(Access.poset.a, Access.meet("b", "c"))
		end)

		it("keeps the original order", function()
			assert.are.equal(Access.poset.b, Access.join("a", "b"))
			assert.are.equal(Access.poset.c, Access.join("a", "c"))

			assert.are.equal(Access.poset.a, Access.meet("a", "b"))
			assert.are.equal(Access.poset.a, Access.meet("a", "c"))
		end)
	end)

	describe("K2,2 completion", function()
		setup(function()
			Access.load(makeLevels({ "a", "b", "c", "d" }), {
				{ "a", "c" },
				{ "a", "d" },
				{ "b", "c" },
				{ "b", "d" },
			})
		end)

		it("creates the expected completion element", function()
			local fromJoin = Access.join("a", "b")
			local fromMeet = Access.meet("c", "d")

			assert.are.equal(fromJoin, fromMeet)
			assert.is_true(Access.lattice[fromJoin])

			assert.is_false(fromJoin == Access.poset.a)
			assert.is_false(fromJoin == Access.poset.b)
			assert.is_false(fromJoin == Access.poset.c)
			assert.is_false(fromJoin == Access.poset.d)
		end)

		it("satisfies basic lattice laws", function()
			assertBasicLatticeLaws()
		end)

		it("is associative", function()
			assertAssociativity()
		end)
	end)

	describe("argument validation", function()
		setup(function()
			Access.load(makeLevels({ "a", "b" }), {
				{ "a", "b" },
			})
		end)

		it("rejects join without arguments", function()
			assert.has_error(function()
				Access.join()
			end)
		end)

		it("rejects meet without arguments", function()
			assert.has_error(function()
				Access.meet()
			end)
		end)

		it("rejects an unknown join argument", function()
			assert.has_error(function()
				Access.join("missing")
			end)
		end)

		it("rejects an unknown meet argument", function()
			assert.has_error(function()
				Access.meet("missing")
			end)
		end)

		it("rejects an unknown numeric mask", function()
			assert.has_error(function()
				Access.join(123456789)
			end)

			assert.has_error(function()
				Access.meet(123456789)
			end)
		end)
	end)
end)
