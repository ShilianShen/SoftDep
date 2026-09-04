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

local function latticeMasks(access)
	local masks = {}

	for mask in pairs(access.lattice) do
		masks[#masks + 1] = mask
	end

	table.sort(masks)
	return masks
end

local function assertBasicLatticeLaws(access)
	local masks = latticeMasks(access)

	for _, x in ipairs(masks) do
		assert.are.equal(x, access:join(x))
		assert.are.equal(x, access:meet(x))

		assert.are.equal(x, access:join(x, x))
		assert.are.equal(x, access:meet(x, x))
	end

	for _, x in ipairs(masks) do
		for _, y in ipairs(masks) do
			local joinXY = access:join(x, y)
			local meetXY = access:meet(x, y)

			assert.is_true(access.lattice[joinXY])
			assert.is_true(access.lattice[meetXY])

			assert.are.equal(joinXY, access:join(y, x))
			assert.are.equal(meetXY, access:meet(y, x))

			assert.are.equal(x, access:join(x, meetXY))
			assert.are.equal(x, access:meet(x, joinXY))
		end
	end
end

local function assertAssociativity(access)
	local masks = latticeMasks(access)

	for _, x in ipairs(masks) do
		for _, y in ipairs(masks) do
			for _, z in ipairs(masks) do
				assert.are.equal(access:join(access:join(x, y), z), access:join(x, access:join(y, z)))

				assert.are.equal(access:meet(access:meet(x, y), z), access:meet(x, access:meet(y, z)))
			end
		end
	end
end

describe("softdep.Access", function()
	describe("newAccess", function()
		it("has the expected default maximum count", function()
			assert.are.equal(16, Access.maxCount)
		end)

		it("creates a single access level", function()
			local levels = makeLevels({ "a" })
			local access = Access.newAccess(levels, {})

			assert.are.equal(levels, access.levels)
			assert.is_not_nil(access.poset.a)
			assert.is_true(access.lattice[access.poset.a])
		end)

		it("provides join and meet methods", function()
			local access = Access.newAccess(makeLevels({ "a" }), {})

			assert.are.equal(Access.join, access.join)
			assert.are.equal(Access.meet, access.meet)
		end)

		it("sets top and bottom for a single level", function()
			local access = Access.newAccess(makeLevels({ "a" }), {})

			assert.are.equal(access.poset.a, access.top)
			assert.are.equal(access.poset.a, access.bot)
		end)

		it("creates isolated access levels", function()
			local access = Access.newAccess(makeLevels({ "a", "b", "c" }), {})

			assert.is_not_nil(access.poset.a)
			assert.is_not_nil(access.poset.b)
			assert.is_not_nil(access.poset.c)

			assert.is_true(access.lattice[access.poset.a])
			assert.is_true(access.lattice[access.poset.b])
			assert.is_true(access.lattice[access.poset.c])
		end)

		it("assigns tags deterministically by sorted name", function()
			local access = Access.newAccess(makeLevels({ "c", "a", "b" }), {})

			assert.are.equal(1, access.poset.a)
			assert.are.equal(2, access.poset.b)
			assert.are.equal(4, access.poset.c)
		end)

		it("rejects an edge with fewer than two elements", function()
			assert.has_error(function()
				Access.newAccess(makeLevels({ "a", "b" }), {
					{ "a" },
				})
			end)
		end)

		it("rejects an edge with more than two elements", function()
			assert.has_error(function()
				Access.newAccess(makeLevels({ "a", "b", "c" }), {
					{ "a", "b", "c" },
				})
			end)
		end)

		it("rejects an unknown left access level", function()
			assert.has_error(function()
				Access.newAccess(makeLevels({ "a" }), {
					{ "missing", "a" },
				})
			end)
		end)

		it("rejects an unknown right access level", function()
			assert.has_error(function()
				Access.newAccess(makeLevels({ "a" }), {
					{ "a", "missing" },
				})
			end)
		end)

		it("rejects order-sensitive below order-insensitive", function()
			local levels = makeLevels({ "sensitive", "insensitive" })

			levels.sensitive.os = true
			levels.insensitive.os = false

			assert.has_error(function()
				Access.newAccess(levels, {
					{ "sensitive", "insensitive" },
				})
			end)
		end)

		it("allows order-insensitive below order-sensitive", function()
			local levels = makeLevels({ "insensitive", "sensitive" })

			levels.sensitive.os = true

			assert.has_no.errors(function()
				Access.newAccess(levels, {
					{ "insensitive", "sensitive" },
				})
			end)
		end)

		it("allows order-sensitive levels to be ordered", function()
			local levels = makeLevels({ "a", "b" })

			levels.a.os = true
			levels.b.os = true

			assert.has_no.errors(function()
				Access.newAccess(levels, {
					{ "a", "b" },
				})
			end)
		end)

		it("allows order-insensitive levels to be ordered", function()
			assert.has_no.errors(function()
				Access.newAccess(makeLevels({ "a", "b" }), {
					{ "a", "b" },
				})
			end)
		end)

		it("starts with an empty closure cache", function()
			local access = Access.newAccess(makeLevels({ "a", "b" }), {})

			assert.is_nil(next(access.closures))
		end)

		it("creates independent instances", function()
			local first = Access.newAccess(makeLevels({ "a", "b", "c" }), {
				{ "a", "c" },
				{ "b", "c" },
			})

			local second = Access.newAccess(makeLevels({ "x", "y" }), {
				{ "x", "y" },
			})

			first:join("a", "b")

			assert.is_not_nil(next(first.closures))
			assert.is_nil(next(second.closures))

			assert.is_not_nil(first.poset.a)
			assert.is_nil(first.poset.x)

			assert.is_not_nil(second.poset.x)
			assert.is_nil(second.poset.a)
		end)

		it("rejects access levels at maxCount", function()
			local oldMaxCount = Access.maxCount
			Access.maxCount = 3

			local ok, err = pcall(function()
				assert.has_error(function()
					Access.newAccess(makeLevels({ "a", "b", "c" }), {})
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
					Access.newAccess(makeLevels({ "a", "b" }), {})
				end)
			end)

			Access.maxCount = oldMaxCount

			if not ok then
				error(err)
			end
		end)
	end)

	describe("chain", function()
		local access

		setup(function()
			access = Access.newAccess(makeLevels({ "a", "b", "c" }), {
				{ "a", "b" },
				{ "b", "c" },
			})
		end)

		it("embeds all access levels into the lattice", function()
			assert.is_true(access.lattice[access.poset.a])
			assert.is_true(access.lattice[access.poset.b])
			assert.is_true(access.lattice[access.poset.c])
		end)

		it("sets top and bottom", function()
			assert.are.equal(access.poset.c, access.top)
			assert.are.equal(access.poset.a, access.bot)
		end)

		it("computes joins", function()
			assert.are.equal(access.poset.b, access:join("a", "b"))
			assert.are.equal(access.poset.c, access:join("a", "c"))
			assert.are.equal(access.poset.c, access:join("b", "c"))
			assert.are.equal(access.poset.c, access:join("a", "b", "c"))
		end)

		it("computes meets", function()
			assert.are.equal(access.poset.a, access:meet("a", "b"))
			assert.are.equal(access.poset.a, access:meet("a", "c"))
			assert.are.equal(access.poset.b, access:meet("b", "c"))
			assert.are.equal(access.poset.a, access:meet("a", "b", "c"))
		end)

		it("accepts lattice masks as arguments", function()
			local b = access:join("a", "b")

			assert.are.equal(access.poset.b, b)
			assert.are.equal(access.poset.a, access:meet(b, "a"))
			assert.are.equal(access.poset.c, access:join(b, "c"))
		end)

		it("accepts mixed names and lattice masks", function()
			assert.are.equal(access.poset.c, access:join(access.poset.a, "b", access.poset.c))

			assert.are.equal(access.poset.a, access:meet(access.poset.c, "b", access.poset.a))
		end)

		it("is idempotent for single arguments", function()
			assert.are.equal(access.poset.a, access:join("a"))
			assert.are.equal(access.poset.b, access:join("b"))
			assert.are.equal(access.poset.c, access:join("c"))

			assert.are.equal(access.poset.a, access:meet("a"))
			assert.are.equal(access.poset.b, access:meet("b"))
			assert.are.equal(access.poset.c, access:meet("c"))
		end)
	end)

	describe("V-shaped poset", function()
		local access

		setup(function()
			access = Access.newAccess(makeLevels({ "a", "b", "c" }), {
				{ "a", "c" },
				{ "b", "c" },
			})
		end)

		it("sets top and bottom", function()
			assert.are.equal(access.poset.c, access.top)
			assert.are.equal(0, access.bot)
		end)

		it("closes the union of incomparable elements", function()
			local raw = bit.bor(access.poset.a, access.poset.b)

			assert.is_nil(access.lattice[raw])
			assert.are.equal(access.poset.c, access:join("a", "b"))
		end)

		it("caches closures", function()
			local raw = bit.bor(access.poset.a, access.poset.b)

			access.closures = {}

			assert.is_nil(access.closures[raw])

			local result = access:join("a", "b")

			assert.are.equal(result, access.closures[raw])
			assert.are.equal(result, access:join("a", "b"))
		end)

		it("computes the meet of incomparable elements", function()
			assert.are.equal(0, access:meet("a", "b"))
		end)

		it("absorbs lower elements into the upper element", function()
			assert.are.equal(access.poset.c, access:join("a", "c"))
			assert.are.equal(access.poset.c, access:join("b", "c"))

			assert.are.equal(access.poset.a, access:meet("a", "c"))
			assert.are.equal(access.poset.b, access:meet("b", "c"))
		end)
	end)

	describe("inverted V-shaped poset", function()
		local access

		setup(function()
			access = Access.newAccess(makeLevels({ "a", "b", "c" }), {
				{ "a", "b" },
				{ "a", "c" },
			})
		end)

		it("creates a new top element", function()
			assert.is_true(access.lattice[access.top])

			assert.is_false(access.top == access.poset.a)
			assert.is_false(access.top == access.poset.b)
			assert.is_false(access.top == access.poset.c)
		end)

		it("sets bottom", function()
			assert.are.equal(access.poset.a, access.bot)
		end)

		it("computes the common lower bound", function()
			assert.are.equal(access.poset.a, access:meet("b", "c"))
		end)

		it("keeps the original order", function()
			assert.are.equal(access.poset.b, access:join("a", "b"))
			assert.are.equal(access.poset.c, access:join("a", "c"))

			assert.are.equal(access.poset.a, access:meet("a", "b"))
			assert.are.equal(access.poset.a, access:meet("a", "c"))
		end)
	end)

	describe("K2,2 completion", function()
		local access

		setup(function()
			access = Access.newAccess(makeLevels({ "a", "b", "c", "d" }), {
				{ "a", "c" },
				{ "a", "d" },
				{ "b", "c" },
				{ "b", "d" },
			})
		end)

		it("creates the expected completion element", function()
			local fromJoin = access:join("a", "b")
			local fromMeet = access:meet("c", "d")

			assert.are.equal(fromJoin, fromMeet)
			assert.is_true(access.lattice[fromJoin])

			assert.is_false(fromJoin == access.poset.a)
			assert.is_false(fromJoin == access.poset.b)
			assert.is_false(fromJoin == access.poset.c)
			assert.is_false(fromJoin == access.poset.d)
		end)

		it("sets top and bottom", function()
			assert.are.equal(access:join("c", "d"), access.top)
			assert.are.equal(access:meet("a", "b"), access.bot)
		end)

		it("satisfies basic lattice laws", function()
			assertBasicLatticeLaws(access)
		end)

		it("is associative", function()
			assertAssociativity(access)
		end)
	end)

	describe("disconnected poset", function()
		local access

		setup(function()
			access = Access.newAccess(makeLevels({ "a", "b" }), {})
		end)

		it("creates completion top and bottom", function()
			assert.are.equal(access:join("a", "b"), access.top)
			assert.are.equal(access:meet("a", "b"), access.bot)

			assert.is_true(access.lattice[access.top])
			assert.is_true(access.lattice[access.bot])

			assert.are.equal(0, access.bot)
		end)
	end)

	describe("argument validation", function()
		local access

		setup(function()
			access = Access.newAccess(makeLevels({ "a", "b" }), {
				{ "a", "b" },
			})
		end)

		it("rejects join without arguments", function()
			assert.has_error(function()
				access:join()
			end)
		end)

		it("rejects meet without arguments", function()
			assert.has_error(function()
				access:meet()
			end)
		end)

		it("rejects an unknown join argument", function()
			assert.has_error(function()
				access:join("missing")
			end)
		end)

		it("rejects an unknown meet argument", function()
			assert.has_error(function()
				access:meet("missing")
			end)
		end)

		it("rejects an unknown numeric mask", function()
			assert.has_error(function()
				access:join(123456789)
			end)

			assert.has_error(function()
				access:meet(123456789)
			end)
		end)

		it("rejects raw masks outside the lattice", function()
			local v = Access.newAccess(makeLevels({ "a", "b", "c" }), {
				{ "a", "c" },
				{ "b", "c" },
			})

			local raw = bit.bor(v.poset.a, v.poset.b)

			assert.is_nil(v.lattice[raw])

			assert.has_error(function()
				v:join(raw)
			end)

			assert.has_error(function()
				v:meet(raw)
			end)
		end)
	end)
end)
