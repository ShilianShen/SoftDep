package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local Access = require("softdep.Access")
local MathGraph = require("softdep.MathGraph")

local function levels(...)
	local result = {}
	for _, tag in ipairs({ ... }) do
		result[tag] = { func = function() end, os = false }
	end
	return result
end

local function diamond()
	return Access.newAccess(levels("bottom", "left", "right", "top"), {
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
		local access = Access.newAccess(levels("only"), {})
		assert.are.equal("only", access.top)
		assert.are.equal("only", access.bot)
		assert.is_true(access:leq("only", "only"))
		assert.is_false(access:lt("only", "only"))
	end)

	it("preserves level definitions and does not modify input relations", function()
		local definitions = levels("a", "b")
		local originalA, originalB = definitions.a, definitions.b
		local relations = { { "a", "b" } }
		local access = Access.newAccess(definitions, relations)
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
				assert.has_error(function()
					access[method](access, "missing", "top")
				end)
				assert.has_error(function()
					access[method](access, "bottom", "missing")
				end)
			end)
		end
	end)

	describe("validation", function()
		local cases = {
			{ "unknown source", levels("a"), { { "missing", "a" } } },
			{ "unknown target", levels("a"), { { "a", "missing" } } },
			{ "self-loop", levels("a"), { { "a", "a" } } },
			{
				"cycle",
				levels("a", "b", "c"),
				{ { "a", "b" }, { "b", "c" }, { "c", "a" } },
			},
			{ "empty levels", {}, {} },
			{
				"multiple tops",
				levels("a", "b", "c"),
				{ { "a", "b" }, { "a", "c" } },
			},
			{
				"missing bottom",
				levels("a", "b", "c"),
				{ { "a", "c" }, { "b", "c" } },
			},
			{ "disconnected levels", levels("a", "b"), {} },
		}
		for _, case in ipairs(cases) do
			it("rejects " .. case[1], function()
				assert.has_error(function()
					Access.newAccess(case[2], case[3])
				end)
			end)
		end

		it("rejects multiple bottom candidates reported by reachability", function()
			-- A valid DAG cannot naturally have two vertices that both reach every
			-- vertex. Stub the collaborator so this defensive branch remains tested.
			local originalReachAdjList = MathGraph.reachAdjList
			MathGraph.reachAdjList = function()
				return {
					a = { a = true, b = true },
					b = { a = true, b = true },
				}
			end

			local ok, err = pcall(function()
				Access.newAccess(levels("a", "b"), { { "a", "b" } })
			end)
			MathGraph.reachAdjList = originalReachAdjList

			assert.is_false(ok)
			assert.matches("access relation has multiple bot candidates", err, 1, true)
		end)
	end)

	describe("order sensitivity", function()
		for _, flags in ipairs({ { false, false }, { false, true }, { true, true } }) do
			it("allows os=" .. tostring(flags[1]) .. " below os=" .. tostring(flags[2]), function()
				local definitions = levels("a", "b")
				definitions.a.os, definitions.b.os = flags[1], flags[2]
				assert.is_true(Access.newAccess(definitions, { { "a", "b" } }):lt("a", "b"))
			end)
		end

		it("rejects an order-sensitive level below an order-insensitive level", function()
			local definitions = levels("a", "b")
			definitions.a.os = true
			assert.has_error(function()
				Access.newAccess(definitions, { { "a", "b" } })
			end)
		end)
	end)
end)
