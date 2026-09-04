package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local Access = require("softdep.Access")
local bit = require("softdep.bit")

local function makeLevels(names)
	local levels = {}

	for _, name in ipairs(names) do
		levels[name] = {
			func = function() end,
			os = false,
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
		it("has the expected default maximum count", function()
			assert.are.equal(16, Access.maxCount)
		end)

		it("loads a single access level", function()
			local levels = makeLevels({ "a" })

			Access.load(levels, {})

			assert.are.equal(levels, Access.levels)
			assert.is_not_nil(Access.poset.a)
			assert.is_true(Access.lattice[Access.poset.a])
		end)

		it("loads isolated access levels", function()
			Access.load(makeLevels({ "a", "b", "c" }), {})

			assert.is_not_nil(Access.poset.a)
			assert.is_not_nil(Access.poset.b)
			assert.is_not_nil(Access.poset.c)

			assert.is_true(Access.lattice[Access.poset.a])
			assert.is_true(Access.lattice[Access.poset.b])
			assert.is_true(Access.lattice[Access.poset.c])
		end)

		it("assigns tags deterministically by sorted name", function()
			Access.load(makeLevels({ "c", "a", "b" }), {})

			assert.are.equal(1, Access.poset.a)
			assert.are.equal(2, Access.poset.b)
			assert.are.equal(4, Access.poset.c)
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

		it("rejects order-sensitive below order-insensitive", function()
			local levels = makeLevels({ "sensitive", "insensitive" })

			levels.sensitive.os = true
			levels.insensitive.os = false

			assert.has_error(function()
				Access.load(levels, {
					{ "sensitive", "insensitive" },
				})
			end)
		end)

		it("allows order-insensitive below order-sensitive", function()
			local levels = makeLevels({ "insensitive", "sensitive" })

			levels.insensitive.os = false
			levels.sensitive.os = true

			assert.has_no.errors(function()
				Access.load(levels, {
					{ "insensitive", "sensitive" },
				})
			end)
		end)

		it("allows order-sensitive levels to be ordered", function()
			local levels = makeLevels({ "a", "b" })

			levels.a.os = true
			levels.b.os = true

			assert.has_no.errors(function()
				Access.load(levels, {
					{ "a", "b" },
				})
			end)
		end)

		it("allows order-insensitive levels to be ordered", function()
			local levels = makeLevels({ "a", "b" })

			assert.has_no.errors(function()
				Access.load(levels, {
					{ "a", "b" },
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

		it("resets closure cache", function()
			Access.load(makeLevels({ "a", "b", "c" }), {
				{ "a", "c" },
				{ "b", "c" },
			})

			Access.join("a", "b")

			assert.is_not_nil(next(Access.closures))

			Access.load(makeLevels({ "x" }), {})

			assert.is_nil(next(Access.closures))
		end)

		it("rejects access levels at maxCount", function()
			local oldMaxCount = Access.maxCount
			Access.maxCount = 3

			local ok, err = pcall(function()
				assert.has_error(function()
					Access.load(makeLevels({ "a", "b", "c" }), {})
				end)
			end)

			Access.maxCount = oldMaxCount

			if not ok then
				error(err)
			end
		end)

		it("accepts access levels below maxCount", function()
			local oldMaxCount = Access.maxCount
			Access.maxCount = 3

			local ok, err = pcall(function()
				assert.has_no.errors(function()
					Access.load(makeLevels({ "a", "b" }), {})
				end)
			end)

			Access.maxCount = oldMaxCount

			if not ok then
				error(err)
			end
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

		it("preserves the order in the bit representation", function()
			assert.are.equal(Access.poset.a, bit.band(Access.poset.a, Access.poset.b))

			assert.are.equal(Access.poset.b, bit.band(Access.poset.b, Access.poset.c))
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

		it("accepts mixed names and lattice masks", function()
			assert.are.equal(Access.poset.c, Access.join(Access.poset.a, "b", Access.poset.c))

			assert.are.equal(Access.poset.a, Access.meet(Access.poset.c, "b", Access.poset.a))
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

		it("caches closures", function()
			local raw = bit.bor(Access.poset.a, Access.poset.b)

			Access.closures = {}

			assert.is_nil(Access.closures[raw])

			local result = Access.join("a", "b")

			assert.are.equal(result, Access.closures[raw])
			assert.are.equal(result, Access.join("a", "b"))
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

	describe("disconnected poset", function()
		setup(function()
			Access.load(makeLevels({ "a", "b" }), {})
		end)

		it("creates bottom and top completion elements", function()
			local bottom = Access.meet("a", "b")
			local top = Access.join("a", "b")

			assert.are.equal(0, bottom)
			assert.is_true(Access.lattice[bottom])
			assert.is_true(Access.lattice[top])

			assert.is_false(top == Access.poset.a)
			assert.is_false(top == Access.poset.b)
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

		it("rejects raw masks outside the lattice", function()
			Access.load(makeLevels({ "a", "b", "c" }), {
				{ "a", "c" },
				{ "b", "c" },
			})

			local raw = bit.bor(Access.poset.a, Access.poset.b)

			assert.is_nil(Access.lattice[raw])

			assert.has_error(function()
				Access.join(raw)
			end)

			assert.has_error(function()
				Access.meet(raw)
			end)
		end)
	end)
end)
