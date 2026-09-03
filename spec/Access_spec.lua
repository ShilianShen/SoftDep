package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path
local assert = require("luassert")

local function freshAccess()
	package.loaded["softdep.Access"] = nil
	return require("softdep.Access")
end

local function expectErrorContains(text, fn)
	local ok, err = pcall(fn)
	assert.is_false(ok)
	assert.is_truthy(string.find(tostring(err), text, 1, true))
end

local function chainLevels()
	local low = function()
		return "low"
	end

	local mid = function()
		return "mid"
	end

	local high = function()
		return "high"
	end

	return {
		low = { func = low },
		mid = { func = mid },
		high = { func = high },
	}, low, mid, high
end

local function loadChain(Access)
	local levels, low, mid, high = chainLevels()

	Access.load(levels, {
		{ "low", "mid" },
		{ "mid", "high" },
	})

	return low, mid, high
end

describe("Access", function()
	it("builds stable keys from string sets", function()
		local Access = freshAccess()

		assert.are.equal("alpha;beta;gamma", Access.getKey({
			gamma = true,
			alpha = true,
			beta = true,
		}))

		assert.are.equal("", Access.getKey({}))
	end)

	it("rejects original level names containing semicolons", function()
		local Access = freshAccess()

		expectErrorContains("shouldn't have ;", function()
			Access.load({
				["a;b"] = {
					func = function() end,
				},
			}, {})
		end)
	end)

	it("loads a chain and attaches functions to principal ideals", function()
		local Access = freshAccess()
		local low, mid, high = loadChain(Access)

		assert.are.equal(low, Access.levels["low"].func)
		assert.are.equal(mid, Access.levels["low;mid"].func)
		assert.are.equal(high, Access.levels["high;low;mid"].func)

		assert.same({
			low = true,
		}, Access.levels["low"].set)

		assert.same({
			low = true,
			mid = true,
		}, Access.levels["low;mid"].set)

		assert.same({
			low = true,
			mid = true,
			high = true,
		}, Access.levels["high;low;mid"].set)
	end)

	it("computes joins in a chain", function()
		local Access = freshAccess()
		loadChain(Access)

		assert.are.equal(
			"low;mid",
			Access.join("low", "mid")
		)

		assert.are.equal(
			"high;low;mid",
			Access.join("low", "high")
		)

		assert.are.equal(
			"low;mid",
			Access.join("mid", "mid")
		)

		assert.are.equal(
			"high;low;mid",
			Access.join("low;mid", "high")
		)
	end)

	it("computes meets in a chain", function()
		local Access = freshAccess()
		loadChain(Access)

		assert.are.equal(
			"low",
			Access.meet("low", "mid")
		)

		assert.are.equal(
			"low;mid",
			Access.meet("mid", "high")
		)

		assert.are.equal(
			"low;mid",
			Access.meet("mid", "mid")
		)

		assert.are.equal(
			"low",
			Access.meet("low", "high;low;mid")
		)
	end)

	it("adds a missing top through DM completion", function()
		local Access = freshAccess()

		local bottom = function() end
		local left = function() end
		local right = function() end

		Access.load({
			bottom = { func = bottom },
			left = { func = left },
			right = { func = right },
		}, {
			{ "bottom", "left" },
			{ "bottom", "right" },
		})

		assert.are.equal(
			"bottom;left;right",
			Access.join("left", "right")
		)

		assert.are.equal(
			"bottom",
			Access.meet("left", "right")
		)

		assert.is_nil(
			Access.levels["bottom;left;right"].func
		)

		assert.same({
			bottom = true,
			left = true,
			right = true,
		}, Access.levels["bottom;left;right"].set)
	end)

	it("adds empty bottom and full top for an antichain", function()
		local Access = freshAccess()

		Access.load({
			x = {
				func = function() end,
			},
			y = {
				func = function() end,
			},
		}, {})

		assert.are.equal(
			"x;y",
			Access.join("x", "y")
		)

		assert.are.equal(
			"",
			Access.meet("x", "y")
		)

		assert.same(
			{},
			Access.levels[""].set
		)

		assert.same({
			x = true,
			y = true,
		}, Access.levels["x;y"].set)
	end)

	it("accepts generated lattice keys as operands", function()
		local Access = freshAccess()

		Access.load({
			bottom = {
				func = function() end,
			},
			left = {
				func = function() end,
			},
			right = {
				func = function() end,
			},
		}, {
			{ "bottom", "left" },
			{ "bottom", "right" },
		})

		local top = Access.join("left", "right")

		assert.are.equal(
			top,
			Access.join(top, "left")
		)

		assert.are.equal(
			"bottom;left",
			Access.meet(top, "left")
		)
	end)

	it("rejects empty join and meet calls", function()
		local Access = freshAccess()
		loadChain(Access)

		expectErrorContains(
			"expected at least one access level",
			function()
				Access.join()
			end
		)

		expectErrorContains(
			"expected at least one access level",
			function()
				Access.meet()
			end
		)
	end)

	it("rejects unknown access levels", function()
		local Access = freshAccess()
		loadChain(Access)

		expectErrorContains(
			"unknown access level: missing",
			function()
				Access.join("missing")
			end
		)

		expectErrorContains(
			"unknown access level: missing",
			function()
				Access.meet("missing")
			end
		)
	end)

	it("replaces previous state when reloaded", function()
		local Access = freshAccess()
		loadChain(Access)

		Access.load({
			only = {
				func = function() end,
			},
		}, {})

		assert.is_nil(Access.levels["low"])
		assert.are.equal("only", Access.join("only"))

		expectErrorContains(
			"unknown access level: low",
			function()
				Access.join("low")
			end
		)
	end)
end)