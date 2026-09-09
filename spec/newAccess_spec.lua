package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local newAccess = require("softdep.newAccess")

local function levels(...)
	local result = {}
	for _, tag in ipairs({ ... }) do
		result[tag] = { func = function() end, os = false }
	end
	return result
end

local function diamond()
	return newAccess(levels("bottom", "left", "right", "top"), {
		{ "bottom", "left" },
		{ "bottom", "right" },
		{ "left", "top" },
		{ "right", "top" },
	})
end

describe("newAccess", function()
	it("finds bounds and computes reflexive, transitive reachability", function()
		local access = diamond()
		assert.are.equal("bottom", access.bot)
		assert.are.equal("top", access.top)
		assert.are.same({
			bottom = { bottom = true, left = true, right = true, top = true },
			left = { left = true, top = true },
			right = { right = true, top = true },
			top = { top = true },
		}, access.reachAdjList)
	end)

	it("allows one level to be both bounds", function()
		local access = newAccess(levels("only"), {})
		assert.are.equal("only", access.top)
		assert.are.equal("only", access.bot)
		assert.is_true(access:leq("only", "only"))
		assert.is_false(access:lt("only", "only"))
	end)

	it("preserves level definitions and does not modify input relations", function()
		local definitions = levels("a", "b")
		local originalA, originalB = definitions.a, definitions.b
		local relations = { { "a", "b" } }
		local access = newAccess(definitions, relations)
		assert.are.equal(originalA, access.levels.a)
		assert.are.equal(originalB, access.levels.b)
		assert.are.same({ a = originalA, b = originalB }, definitions)
		assert.are.same({ { "a", "b" } }, relations)
	end)

	describe("comparisons", function()
		-- Expected truth values in leq, geq, eq, lt, gt order.
		local cases = {
			{ "equal levels", "left", "left", { true, true, true, false, false } },
			{ "direct relation", "bottom", "left", { true, false, false, true, false } },
			{ "transitive relation", "bottom", "top", { true, false, false, true, false } },
			{ "reverse relation", "top", "bottom", { false, true, false, false, true } },
			{ "incomparable levels", "left", "right", { false, false, false, false, false } },
			{ "reverse incomparable levels", "right", "left", { false, false, false, false, false } },
		}
		for _, case in ipairs(cases) do
			it("compares " .. case[1], function()
				local access = diamond()
				for i, method in ipairs({ "leq", "geq", "eq", "lt", "gt" }) do
					-- Unrelated levels may return nil: the API uses set membership.
					assert.are.equal(case[4][i], not not access[method](access, case[2], case[3]), method)
				end
			end)
		end

		for _, method in ipairs({ "leq", "geq", "eq", "lt", "gt" }) do
			it("validates both arguments to " .. method, function()
				local access = diamond()
				for _, invalid in ipairs({ "missing", 42, false }) do
					assert.has_error(function()
						access[method](access, invalid, "top")
					end, "unknown access level: " .. tostring(invalid))
					assert.has_error(function()
						access[method](access, "bottom", invalid)
					end, "unknown access level: " .. tostring(invalid))
				end
				assert.has_error(function()
					access[method](access, nil, "top")
				end, "unknown access level: nil")
				assert.has_error(function()
					access[method](access, "bottom", nil)
				end, "unknown access level: nil")
			end)
		end
	end)

	describe("validation", function()
		local levelsMessage =
			"newAccess: expected levels to map strings to tables with a function field func and a boolean field os"
		local ltMessage = "newAccess: expected lt to be an array of arrays of strings"
		local cases = {
			{ "missing levels", nil, {}, levelsMessage },
			{ "non-table levels", false, {}, levelsMessage },
			{ "non-string level tags", { [1] = { func = function() end, os = false } }, {}, levelsMessage },
			{ "missing func", { a = { os = false } }, {}, levelsMessage },
			{ "invalid func", { a = { func = true, os = false } }, {}, levelsMessage },
			{ "missing os", { a = { func = function() end } }, {}, levelsMessage },
			{ "invalid os", { a = { func = function() end, os = 1 } }, {}, levelsMessage },
			{ "missing relations", levels("a"), nil, ltMessage },
			{ "non-table relations", levels("a"), false, ltMessage },
			{ "non-table edge", levels("a"), { "a" }, ltMessage },
			{ "non-string endpoint", levels("a"), { { "a", 1 } }, ltMessage },
			{ "empty edge", levels("a"), { {} }, "access relation must contain exactly two levels" },
			{ "short edge", levels("a"), { { "a" } }, "access relation must contain exactly two levels" },
			{ "long edge", levels("a"), { { "a", "a", "a" } }, "access relation must contain exactly two levels" },
			{ "unknown source", levels("a"), { { "missing", "a" } }, "unknown access level in lt: missing" },
			{ "unknown target", levels("a"), { { "a", "missing" } }, "unknown access level in lt: missing" },
			{ "self-loop", levels("a"), { { "a", "a" } }, "access relation must be acyclic" },
			{
				"cycle",
				levels("a", "b", "c"),
				{ { "a", "b" }, { "b", "c" }, { "c", "a" } },
				"access relation must be acyclic",
			},
			{ "empty levels", {}, {}, "top should be explicitly declared" },
			{
				"multiple tops",
				levels("a", "b", "c"),
				{ { "a", "b" }, { "a", "c" } },
				"access relation has multiple top candidates",
			},
			{
				"missing bottom",
				levels("a", "b", "c"),
				{ { "a", "c" }, { "b", "c" } },
				"bot should be explicitly declared",
			},
			{ "disconnected levels", levels("a", "b"), {}, "access relation has multiple top candidates" },
		}
		for _, case in ipairs(cases) do
			it("rejects " .. case[1], function()
				assert.has_error(function()
					newAccess(case[2], case[3])
				end, case[4])
			end)
		end
	end)

	describe("order sensitivity", function()
		for _, flags in ipairs({ { false, false }, { false, true }, { true, true } }) do
			it("allows os=" .. tostring(flags[1]) .. " below os=" .. tostring(flags[2]), function()
				local definitions = levels("a", "b")
				definitions.a.os, definitions.b.os = flags[1], flags[2]
				assert.is_true(newAccess(definitions, { { "a", "b" } }):lt("a", "b"))
			end)
		end

		it("rejects an order-sensitive level below an order-insensitive level", function()
			local definitions = levels("a", "b")
			definitions.a.os = true
			assert.has_error(function()
				newAccess(definitions, { { "a", "b" } })
			end, "order-sensitive shouldn't less than order-insensitive")
		end)
	end)
end)
