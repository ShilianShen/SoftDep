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

local function makeK22()
	return Access.newAccess(
		makeLevels({
			"bot",
			"a",
			"b",
			"c",
			"d",
			"top",
		}),
		{
			{ "bot", "a" },
			{ "bot", "b" },

			{ "a", "c" },
			{ "a", "d" },
			{ "b", "c" },
			{ "b", "d" },

			{ "c", "top" },
			{ "d", "top" },
		}
	)
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

		it("sets top and bottom for a single access level", function()
			local access = Access.newAccess(makeLevels({ "a" }), {})

			assert.are.equal("a", access.top)
			assert.are.equal("a", access.bot)
		end)

		it("assigns masks deterministically by sorted name", function()
			local access = Access.newAccess(makeLevels({ "c", "a", "b" }), {
				{ "a", "b" },
				{ "b", "c" },
			})

			assert.are.equal(1, access.poset.a)
			assert.are.equal(3, access.poset.b)
			assert.are.equal(7, access.poset.c)
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

			levels.insensitive.os = false
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
			local access = Access.newAccess(makeLevels({ "a", "b" }), {
				{ "a", "b" },
			})

			assert.is_nil(next(access.closures))
		end)

		it("creates independent instances", function()
			local first = Access.newAccess(makeLevels({ "a", "b", "c" }), {
				{ "a", "b" },
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

			assert.are.equal("c", first.top)
			assert.are.equal("a", first.bot)

			assert.are.equal("y", second.top)
			assert.are.equal("x", second.bot)
		end)

		it("rejects a poset without an explicit bottom", function()
			assert.has_error(function()
				Access.newAccess(makeLevels({ "a", "b", "top" }), {
					{ "a", "top" },
					{ "b", "top" },
				})
			end, "bot should be explicitly declared")
		end)

		it("rejects a poset without an explicit top", function()
			assert.has_error(function()
				Access.newAccess(makeLevels({ "bot", "a", "b" }), {
					{ "bot", "a" },
					{ "bot", "b" },
				})
			end, "top should be explicitly declared")
		end)

		it("rejects a poset without explicit top or bottom", function()
			assert.has_error(function()
				Access.newAccess(makeLevels({ "a", "b" }), {})
			end)
		end)

		it("rejects access levels at maxCount", function()
			local oldMaxCount = Access.maxCount
			Access.maxCount = 3

			local ok, err = pcall(function()
				assert.has_error(function()
					Access.newAccess(makeLevels({ "a", "b", "c" }), {
						{ "a", "b" },
						{ "b", "c" },
					})
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
					Access.newAccess(makeLevels({ "a", "b" }), {
						{ "a", "b" },
					})
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
			assert.are.equal("c", access.top)
			assert.are.equal("a", access.bot)
		end)

		it("preserves the order in the bit representation", function()
			assert.are.equal(access.poset.a, bit.band(access.poset.a, access.poset.b))

			assert.are.equal(access.poset.b, bit.band(access.poset.b, access.poset.c))
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
		it("rejects an implicit bottom", function()
			assert.has_error(function()
				Access.newAccess(makeLevels({ "a", "b", "c" }), {
					{ "a", "c" },
					{ "b", "c" },
				})
			end, "bot should be explicitly declared")
		end)
	end)

	describe("inverted V-shaped poset", function()
		it("rejects an implicit top", function()
			assert.has_error(function()
				Access.newAccess(makeLevels({ "a", "b", "c" }), {
					{ "a", "b" },
					{ "a", "c" },
				})
			end, "top should be explicitly declared")
		end)
	end)

	describe("diamond poset", function()
		local access

		setup(function()
			access = Access.newAccess(
				makeLevels({
					"bot",
					"a",
					"b",
					"top",
				}),
				{
					{ "bot", "a" },
					{ "bot", "b" },
					{ "a", "top" },
					{ "b", "top" },
				}
			)
		end)

		it("sets explicitly declared top and bottom", function()
			assert.are.equal("top", access.top)
			assert.are.equal("bot", access.bot)
		end)

		it("computes the join of incomparable elements", function()
			assert.are.equal(access.poset.top, access:join("a", "b"))
		end)

		it("computes the meet of incomparable elements", function()
			assert.are.equal(access.poset.bot, access:meet("a", "b"))
		end)

		it("keeps the original order", function()
			assert.are.equal(access.poset.a, access:join("bot", "a"))
			assert.are.equal(access.poset.b, access:join("bot", "b"))

			assert.are.equal(access.poset.a, access:meet("a", "top"))
			assert.are.equal(access.poset.b, access:meet("b", "top"))
		end)
	end)

	describe("K2,2 completion", function()
		local access

		setup(function()
			access = makeK22()
		end)

		it("sets explicitly declared top and bottom", function()
			assert.are.equal("top", access.top)
			assert.are.equal("bot", access.bot)
		end)

		it("creates the expected middle completion element", function()
			local fromJoin = access:join("a", "b")
			local fromMeet = access:meet("c", "d")

			assert.are.equal(fromJoin, fromMeet)
			assert.is_true(access.lattice[fromJoin])

			assert.is_false(fromJoin == access.poset.bot)
			assert.is_false(fromJoin == access.poset.a)
			assert.is_false(fromJoin == access.poset.b)
			assert.is_false(fromJoin == access.poset.c)
			assert.is_false(fromJoin == access.poset.d)
			assert.is_false(fromJoin == access.poset.top)
		end)

		it("closes the union of upper incomparable elements", function()
			local raw = bit.bor(access.poset.c, access.poset.d)

			assert.is_nil(access.lattice[raw])
			assert.are.equal(access.poset.top, access:join("c", "d"))
		end)

		it("keeps top and bottom outside the middle completion element", function()
			local middle = access:join("a", "b")

			assert.are.equal(access.poset.top, access:join(middle, "top"))
			assert.are.equal(access.poset.bot, access:meet(middle, "bot"))
		end)

		it("satisfies basic lattice laws", function()
			assertBasicLatticeLaws(access)
		end)

		it("is associative", function()
			assertAssociativity(access)
		end)
	end)

	describe("closure cache", function()
		it("caches a computed closure", function()
			local access = makeK22()
			local raw = bit.bor(access.poset.c, access.poset.d)

			assert.is_nil(access.lattice[raw])
			assert.is_nil(access.closures[raw])

			local result = access:join("c", "d")

			assert.are.equal(access.poset.top, result)
			assert.are.equal(result, access.closures[raw])
			assert.are.equal(result, access:join("c", "d"))
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

		it("rejects a raw mask outside the lattice", function()
			local completion = makeK22()
			local raw = bit.bor(completion.poset.c, completion.poset.d)

			assert.is_nil(completion.lattice[raw])

			assert.has_error(function()
				completion:join(raw)
			end)

			assert.has_error(function()
				completion:meet(raw)
			end)
		end)
	end)
end)
