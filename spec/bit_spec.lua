package.path = "src/?.lua;" .. "src/?/init.lua;" .. package.path

local assert = require("luassert")
local bit = require("softdep.bit")

describe("bit", function()
	describe("API", function()
		local functions = {
			"tobit",
			"tohex",
			"bnot",
			"band",
			"bor",
			"bxor",
			"lshift",
			"rshift",
			"arshift",
			"rol",
			"ror",
			"bswap",
		}

		for _, name in ipairs(functions) do
			it("provides bit." .. name, function()
				assert.are.equal("function", type(bit[name]))
			end)
		end
	end)

	describe("tobit", function()
		it("keeps values in the positive signed range", function()
			assert.are.equal(0, bit.tobit(0))
			assert.are.equal(1, bit.tobit(1))
			assert.are.equal(255, bit.tobit(255))
			assert.are.equal(65535, bit.tobit(65535))
			assert.are.equal(2147483647, bit.tobit(2147483647))
		end)

		it("converts the unsigned high half to signed int32", function()
			assert.are.equal(-2147483648, bit.tobit(2147483648))
			assert.are.equal(-2147483647, bit.tobit(2147483649))
			assert.are.equal(-2, bit.tobit(4294967294))
			assert.are.equal(-1, bit.tobit(4294967295))
		end)

		it("wraps positive values modulo 2^32", function()
			assert.are.equal(0, bit.tobit(4294967296))
			assert.are.equal(1, bit.tobit(4294967297))
			assert.are.equal(255, bit.tobit(4294967551))
			assert.are.equal(-1, bit.tobit(8589934591))
		end)

		it("wraps negative values modulo 2^32", function()
			assert.are.equal(-1, bit.tobit(-1))
			assert.are.equal(-2, bit.tobit(-2))
			assert.are.equal(-2147483648, bit.tobit(-2147483648))
			assert.are.equal(2147483647, bit.tobit(-2147483649))
			assert.are.equal(0, bit.tobit(-4294967296))
			assert.are.equal(-1, bit.tobit(-4294967297))
		end)

		it("wraps multiple uint32 ranges", function()
			assert.are.equal(0, bit.tobit(4294967296 * 2))
			assert.are.equal(1, bit.tobit(4294967296 * 2 + 1))
			assert.are.equal(-1, bit.tobit(4294967296 * 2 - 1))
			assert.are.equal(0, bit.tobit(-4294967296 * 2))
			assert.are.equal(-1, bit.tobit(-4294967296 * 2 - 1))
		end)

		it("handles larger exact integer values", function()
			assert.are.equal(1234, bit.tobit(1099511627776 + 1234))
			assert.are.equal(-1234, bit.tobit(-1099511627776 - 1234))
		end)

		it("accepts numeric strings", function()
			assert.are.equal(0, bit.tobit("0"))
			assert.are.equal(1, bit.tobit("1"))
			assert.are.equal(-1, bit.tobit("-1"))
			assert.are.equal(255, bit.tobit("255"))
			assert.are.equal(-1, bit.tobit("4294967295"))
		end)

		it("rejects missing arguments", function()
			assert.has_error(function()
				bit.tobit()
			end)
		end)

		it("rejects invalid arguments", function()
			assert.has_error(function()
				bit.tobit(nil)
			end)

			assert.has_error(function()
				bit.tobit(false)
			end)

			assert.has_error(function()
				bit.tobit(true)
			end)

			assert.has_error(function()
				bit.tobit({})
			end)

			assert.has_error(function()
				bit.tobit(function() end)
			end)

			assert.has_error(function()
				bit.tobit("invalid")
			end)
		end)
	end)

	describe("uint32 normalization", function()
		local values = {
			0,
			1,
			-1,
			127,
			255,
			65535,
			2147483647,
			2147483648,
			2147483649,
			4294967294,
			4294967295,
			4294967296,
			4294967297,
			-2147483648,
			-2147483649,
			-4294967296,
			-4294967297,
			1099511627776 + 1234,
			-1099511627776 - 1234,
		}

		it("is consistent through unary identity operations", function()
			for _, value in ipairs(values) do
				local expected = bit.tobit(value)

				assert.are.equal(expected, bit.band(value))
				assert.are.equal(expected, bit.bor(value))
				assert.are.equal(expected, bit.bxor(value))
			end
		end)

		it("is consistent through boolean identity operations", function()
			for _, value in ipairs(values) do
				local expected = bit.tobit(value)

				assert.are.equal(expected, bit.band(value, -1))
				assert.are.equal(expected, bit.bor(value, 0))
				assert.are.equal(expected, bit.bxor(value, 0))
			end
		end)

		it("is consistent through zero shifts", function()
			for _, value in ipairs(values) do
				local expected = bit.tobit(value)

				assert.are.equal(expected, bit.lshift(value, 0))
				assert.are.equal(expected, bit.rshift(value, 0))
				assert.are.equal(expected, bit.arshift(value, 0))
			end
		end)

		it("is consistent through zero rotations", function()
			for _, value in ipairs(values) do
				local expected = bit.tobit(value)

				assert.are.equal(expected, bit.rol(value, 0))
				assert.are.equal(expected, bit.ror(value, 0))
			end
		end)

		it("normalizes string arguments consistently", function()
			assert.are.equal(255, bit.band("255", "-1"))
			assert.are.equal(255, bit.bor("255", "0"))
			assert.are.equal(255, bit.bxor("255", "0"))
			assert.are.equal(255, bit.lshift("255", "0"))
			assert.are.equal(255, bit.rshift("255", "0"))
			assert.are.equal(255, bit.arshift("255", "0"))
			assert.are.equal(255, bit.rol("255", "0"))
			assert.are.equal(255, bit.ror("255", "0"))
		end)
	end)

	describe("tohex", function()
		it("uses eight lowercase digits by default", function()
			assert.are.equal("00000000", bit.tohex(0))
			assert.are.equal("00000001", bit.tohex(1))
			assert.are.equal("ffffffff", bit.tohex(-1))
			assert.are.equal("80000000", bit.tohex(2147483648))
			assert.are.equal("7fffffff", bit.tohex(2147483647))
			assert.are.equal("12345678", bit.tohex(0x12345678))
			assert.are.equal("abcdef01", bit.tohex(0xabcdef01))
		end)

		it("supports widths from one to eight", function()
			assert.are.equal("8", bit.tohex(0x12345678, 1))
			assert.are.equal("78", bit.tohex(0x12345678, 2))
			assert.are.equal("678", bit.tohex(0x12345678, 3))
			assert.are.equal("5678", bit.tohex(0x12345678, 4))
			assert.are.equal("45678", bit.tohex(0x12345678, 5))
			assert.are.equal("345678", bit.tohex(0x12345678, 6))
			assert.are.equal("2345678", bit.tohex(0x12345678, 7))
			assert.are.equal("12345678", bit.tohex(0x12345678, 8))
		end)

		it("uses uppercase output for negative widths", function()
			assert.are.equal("8", bit.tohex(0x12345678, -1))
			assert.are.equal("78", bit.tohex(0x12345678, -2))
			assert.are.equal("678", bit.tohex(0x12345678, -3))
			assert.are.equal("5678", bit.tohex(0x12345678, -4))
			assert.are.equal("45678", bit.tohex(0x12345678, -5))
			assert.are.equal("345678", bit.tohex(0x12345678, -6))
			assert.are.equal("2345678", bit.tohex(0x12345678, -7))
			assert.are.equal("12345678", bit.tohex(0x12345678, -8))
			assert.are.equal("ABCDEF01", bit.tohex(0xabcdef01, -8))
		end)

		it("pads with zeroes", function()
			assert.are.equal("0", bit.tohex(0, 1))
			assert.are.equal("00", bit.tohex(0, 2))
			assert.are.equal("0000", bit.tohex(0, 4))
			assert.are.equal("00000000", bit.tohex(0, 8))
			assert.are.equal("01", bit.tohex(1, 2))
			assert.are.equal("0001", bit.tohex(1, 4))
			assert.are.equal("00000001", bit.tohex(1, 8))
		end)

		it("truncates high bits according to width", function()
			assert.are.equal("f", bit.tohex(-1, 1))
			assert.are.equal("ff", bit.tohex(-1, 2))
			assert.are.equal("ffff", bit.tohex(-1, 4))
			assert.are.equal("8", bit.tohex(0x12345678, 1))
			assert.are.equal("78", bit.tohex(0x12345678, 2))
			assert.are.equal("5678", bit.tohex(0x12345678, 4))
		end)

		it("clamps positive widths larger than eight", function()
			assert.are.equal("12345678", bit.tohex(0x12345678, 9))
			assert.are.equal("12345678", bit.tohex(0x12345678, 32))
			assert.are.equal("12345678", bit.tohex(0x12345678, 100))
		end)

		it("clamps negative widths smaller than minus eight", function()
			assert.are.equal("12345678", bit.tohex(0x12345678, -9))
			assert.are.equal("12345678", bit.tohex(0x12345678, -32))
			assert.are.equal("12345678", bit.tohex(0x12345678, -100))
			assert.are.equal("ABCDEF01", bit.tohex(0xabcdef01, -100))
		end)

		it("returns an empty string for zero width", function()
			assert.are.equal("", bit.tohex(0, 0))
			assert.are.equal("", bit.tohex(0x12345678, 0))
			assert.are.equal("", bit.tohex(-1, 0))
		end)

		it("normalizes width as int32", function()
			assert.are.equal("8", bit.tohex(0x12345678, 0xffffffff))
			assert.are.equal("78", bit.tohex(0x12345678, 0xfffffffe))
			assert.are.equal("12345678", bit.tohex(0x12345678, 0x100000008))
			assert.are.equal("", bit.tohex(0x12345678, 0x100000000))
		end)

		it("normalizes the value modulo 2^32", function()
			assert.are.equal("ffffffff", bit.tohex(0xffffffff))
			assert.are.equal("00000000", bit.tohex(0x100000000))
			assert.are.equal("00000001", bit.tohex(0x100000001))
			assert.are.equal("ffffffff", bit.tohex(-1))
			assert.are.equal("fffffffe", bit.tohex(-2))
			assert.are.equal("00000000", bit.tohex(-0x100000000))
			assert.are.equal("ffffffff", bit.tohex(-0x100000001))
		end)

		it("accepts numeric strings", function()
			assert.are.equal("00000001", bit.tohex("1"))
			assert.are.equal("000000ff", bit.tohex("255"))
			assert.are.equal("ff", bit.tohex(255, "2"))
			assert.are.equal("FF", bit.tohex(255, "-2"))
		end)

		it("rejects missing first argument", function()
			assert.has_error(function()
				bit.tohex()
			end)
		end)

		it("rejects explicit nil width", function()
			assert.has_error(function()
				bit.tohex(1, nil)
			end)
		end)

		it("rejects invalid values", function()
			assert.has_error(function()
				bit.tohex(false)
			end)

			assert.has_error(function()
				bit.tohex(true)
			end)

			assert.has_error(function()
				bit.tohex({})
			end)

			assert.has_error(function()
				bit.tohex("invalid")
			end)
		end)

		it("rejects invalid widths", function()
			assert.has_error(function()
				bit.tohex(1, false)
			end)

			assert.has_error(function()
				bit.tohex(1, true)
			end)

			assert.has_error(function()
				bit.tohex(1, {})
			end)

			assert.has_error(function()
				bit.tohex(1, "invalid")
			end)
		end)
	end)

	describe("bnot", function()
		it("inverts all bits", function()
			assert.are.equal(-1, bit.bnot(0))
			assert.are.equal(0, bit.bnot(-1))
			assert.are.equal(-2, bit.bnot(1))
			assert.are.equal(1, bit.bnot(-2))
			assert.are.equal(-305419897, bit.bnot(0x12345678))
		end)

		it("is its own inverse", function()
			local values = {
				0,
				1,
				-1,
				0x12345678,
				0x80000000,
				0xffffffff,
			}

			for _, value in ipairs(values) do
				assert.are.equal(bit.tobit(value), bit.bnot(bit.bnot(value)))
			end
		end)

		it("rejects missing arguments", function()
			assert.has_error(function()
				bit.bnot()
			end)
		end)
	end)

	describe("band", function()
		it("normalizes a single argument", function()
			assert.are.equal(0, bit.band(0))
			assert.are.equal(1, bit.band(1))
			assert.are.equal(-1, bit.band(0xffffffff))
			assert.are.equal(-2147483648, bit.band(0x80000000))
		end)

		it("operates on two arguments", function()
			assert.are.equal(0, bit.band(0xf0, 0x0f))
			assert.are.equal(0x08, bit.band(0x18, 0x0f))
			assert.are.equal(0x78, bit.band(0x12345678, 0xff))
			assert.are.equal(-2147483648, bit.band(-1, 0x80000000))
		end)

		it("operates on multiple arguments", function()
			assert.are.equal(7, bit.band(-1, 15, 7))
			assert.are.equal(0, bit.band(255, 15, 240))
			assert.are.equal(1, bit.band(255, 127, 63, 31, 15, 7, 3, 1))
		end)

		it("supports early zero results", function()
			assert.are.equal(0, bit.band(0, -1))
			assert.are.equal(0, bit.band(255, 0, -1))
			assert.are.equal(0, bit.band(255, 15, 0, -1))
		end)

		it("rejects zero arguments", function()
			assert.has_error(function()
				bit.band()
			end)
		end)

		it("rejects invalid arguments", function()
			assert.has_error(function()
				bit.band(1, false)
			end)

			assert.has_error(function()
				bit.band(1, {})
			end)
		end)
	end)

	describe("bor", function()
		it("normalizes a single argument", function()
			assert.are.equal(0, bit.bor(0))
			assert.are.equal(1, bit.bor(1))
			assert.are.equal(-1, bit.bor(0xffffffff))
			assert.are.equal(-2147483648, bit.bor(0x80000000))
		end)

		it("operates on two arguments", function()
			assert.are.equal(15, bit.bor(5, 10))
			assert.are.equal(255, bit.bor(240, 15))
			assert.are.equal(-2147483647, bit.bor(0x80000000, 1))
		end)

		it("operates on multiple arguments", function()
			assert.are.equal(15, bit.bor(1, 2, 4, 8))
			assert.are.equal(255, bit.bor(1, 2, 4, 8, 16, 32, 64, 128))
		end)

		it("rejects zero arguments", function()
			assert.has_error(function()
				bit.bor()
			end)
		end)

		it("rejects invalid arguments", function()
			assert.has_error(function()
				bit.bor(1, false)
			end)

			assert.has_error(function()
				bit.bor(1, {})
			end)
		end)
	end)

	describe("bxor", function()
		it("normalizes a single argument", function()
			assert.are.equal(0, bit.bxor(0))
			assert.are.equal(1, bit.bxor(1))
			assert.are.equal(-1, bit.bxor(0xffffffff))
			assert.are.equal(-2147483648, bit.bxor(0x80000000))
		end)

		it("operates on two arguments", function()
			assert.are.equal(255, bit.bxor(240, 15))
			assert.are.equal(0, bit.bxor(-1, -1))
			assert.are.equal(-1, bit.bxor(0, -1))
			assert.are.equal(267390960, bit.bxor(2779115760, 2857762560))
		end)

		it("operates on multiple arguments", function()
			assert.are.equal(0, bit.bxor(1, 2, 3))
			assert.are.equal(15, bit.bxor(1, 2, 4, 8))
			assert.are.equal(0, bit.bxor(255, 255, 1, 1))
		end)

		it("rejects zero arguments", function()
			assert.has_error(function()
				bit.bxor()
			end)
		end)

		it("rejects invalid arguments", function()
			assert.has_error(function()
				bit.bxor(1, false)
			end)

			assert.has_error(function()
				bit.bxor(1, {})
			end)
		end)
	end)

	describe("lshift", function()
		it("shifts left", function()
			assert.are.equal(1, bit.lshift(1, 0))
			assert.are.equal(2, bit.lshift(1, 1))
			assert.are.equal(256, bit.lshift(1, 8))
			assert.are.equal(65536, bit.lshift(1, 16))
			assert.are.equal(-2147483648, bit.lshift(1, 31))
		end)

		it("discards overflowing bits", function()
			assert.are.equal(0, bit.lshift(0x80000000, 1))
			assert.are.equal(-1126240256, bit.lshift(0x89abcdef, 12))
			assert.are.equal(-2, bit.lshift(-1, 1))
		end)

		it("masks shift counts to five bits", function()
			assert.are.equal(1, bit.lshift(1, 32))
			assert.are.equal(2, bit.lshift(1, 33))
			assert.are.equal(256, bit.lshift(1, 40))
			assert.are.equal(-2147483648, bit.lshift(1, -1))
			assert.are.equal(1, bit.lshift(1, -32))
		end)

		it("normalizes large shift counts", function()
			assert.are.equal(1, bit.lshift(1, 0x100000000))
			assert.are.equal(2, bit.lshift(1, 0x100000001))
			assert.are.equal(-2147483648, bit.lshift(1, 0xffffffff))
		end)

		it("rejects missing arguments", function()
			assert.has_error(function()
				bit.lshift()
			end)

			assert.has_error(function()
				bit.lshift(1)
			end)
		end)
	end)

	describe("rshift", function()
		it("shifts right logically", function()
			assert.are.equal(1, bit.rshift(256, 8))
			assert.are.equal(0x00800000, bit.rshift(0x80000000, 8))
			assert.are.equal(16777215, bit.rshift(-256, 8))
			assert.are.equal(563900, bit.rshift(0x89abcdef, 12))
			assert.are.equal(1, bit.rshift(-1, 31))
		end)

		it("fills with zeroes", function()
			assert.are.equal(1073741824, bit.rshift(0x80000000, 1))
			assert.are.equal(2147483647, bit.rshift(-1, 1))
		end)

		it("masks shift counts to five bits", function()
			assert.are.equal(-1, bit.rshift(-1, 32))
			assert.are.equal(2147483647, bit.rshift(-1, 33))
			assert.are.equal(1, bit.rshift(0x80000000, -1))
			assert.are.equal(-1, bit.rshift(-1, -32))
		end)

		it("rejects missing arguments", function()
			assert.has_error(function()
				bit.rshift()
			end)

			assert.has_error(function()
				bit.rshift(1)
			end)
		end)
	end)

	describe("arshift", function()
		it("shifts positive values", function()
			assert.are.equal(1, bit.arshift(256, 8))
			assert.are.equal(0x123456, bit.arshift(0x12345678, 8))
		end)

		it("sign extends negative values", function()
			assert.are.equal(-1, bit.arshift(-256, 8))
			assert.are.equal(-1073741824, bit.arshift(0x80000000, 1))
			assert.are.equal(-484676, bit.arshift(0x89abcdef, 12))
			assert.are.equal(-1, bit.arshift(0x80000000, 31))
			assert.are.equal(-1, bit.arshift(-1, 31))
		end)

		it("masks shift counts to five bits", function()
			assert.are.equal(-2147483648, bit.arshift(0x80000000, 32))

			assert.are.equal(-1073741824, bit.arshift(0x80000000, 33))

			assert.are.equal(-1, bit.arshift(0x80000000, -1))
		end)

		it("rejects missing arguments", function()
			assert.has_error(function()
				bit.arshift()
			end)

			assert.has_error(function()
				bit.arshift(1)
			end)
		end)
	end)

	describe("rol", function()
		it("rotates left", function()
			assert.are.equal(0x12345678, bit.rol(0x12345678, 0))
			assert.are.equal(0x2468acf0, bit.rol(0x12345678, 1))
			assert.are.equal(1164411171, bit.rol(0x12345678, 12))
		end)

		it("wraps high bits to the low end", function()
			assert.are.equal(1, bit.rol(0x80000000, 1))
			assert.are.equal(3, bit.rol(0xc0000000, 2))
		end)

		it("masks rotate counts to five bits", function()
			assert.are.equal(0x12345678, bit.rol(0x12345678, 32))

			assert.are.equal(bit.rol(0x12345678, 8), bit.rol(0x12345678, 40))

			assert.are.equal(bit.rol(0x12345678, 31), bit.rol(0x12345678, -1))
		end)

		it("is inverted by ror", function()
			local values = {
				0,
				1,
				-1,
				0x12345678,
				0x80000000,
				0xabcdef01,
			}

			for _, value in ipairs(values) do
				for shift = 0, 31 do
					assert.are.equal(bit.tobit(value), bit.ror(bit.rol(value, shift), shift))
				end
			end
		end)

		it("rejects missing arguments", function()
			assert.has_error(function()
				bit.rol()
			end)

			assert.has_error(function()
				bit.rol(1)
			end)
		end)
	end)

	describe("ror", function()
		it("rotates right", function()
			assert.are.equal(0x12345678, bit.ror(0x12345678, 0))
			assert.are.equal(0x091a2b3c, bit.ror(0x12345678, 1))
			assert.are.equal(1736516421, bit.ror(0x12345678, 12))
		end)

		it("wraps low bits to the high end", function()
			assert.are.equal(-2147483648, bit.ror(1, 1))
			assert.are.equal(-2147483647, bit.ror(3, 1))
		end)

		it("masks rotate counts to five bits", function()
			assert.are.equal(0x12345678, bit.ror(0x12345678, 32))

			assert.are.equal(bit.ror(0x12345678, 8), bit.ror(0x12345678, 40))

			assert.are.equal(bit.ror(0x12345678, 31), bit.ror(0x12345678, -1))
		end)

		it("is inverted by rol", function()
			local values = {
				0,
				1,
				-1,
				0x12345678,
				0x80000000,
				0xabcdef01,
			}

			for _, value in ipairs(values) do
				for shift = 0, 31 do
					assert.are.equal(bit.tobit(value), bit.rol(bit.ror(value, shift), shift))
				end
			end
		end)

		it("rejects missing arguments", function()
			assert.has_error(function()
				bit.ror()
			end)

			assert.has_error(function()
				bit.ror(1)
			end)
		end)
	end)

	describe("bswap", function()
		it("swaps byte order", function()
			assert.are.equal(0, bit.bswap(0))
			assert.are.equal(0x78563412, bit.bswap(0x12345678))
			assert.are.equal(0x12345678, bit.bswap(0x78563412))
			assert.are.equal(-2147483648, bit.bswap(0x80))
			assert.are.equal(128, bit.bswap(0x80000000))
			assert.are.equal(-1, bit.bswap(-1))
		end)

		it("is its own inverse", function()
			local values = {
				0,
				1,
				-1,
				255,
				65535,
				0x12345678,
				0xabcdef01,
				0x80000000,
				0x7fffffff,
			}

			for _, value in ipairs(values) do
				assert.are.equal(bit.tobit(value), bit.bswap(bit.bswap(value)))
			end
		end)

		it("rejects missing arguments", function()
			assert.has_error(function()
				bit.bswap()
			end)
		end)
	end)

	describe("boolean identities", function()
		local values = {
			0,
			1,
			-1,
			0x12345678,
			0xabcdef01,
			0x80000000,
			0x7fffffff,
		}

		it("satisfies x and x equals x", function()
			for _, value in ipairs(values) do
				assert.are.equal(bit.tobit(value), bit.band(value, value))
			end
		end)

		it("satisfies x or x equals x", function()
			for _, value in ipairs(values) do
				assert.are.equal(bit.tobit(value), bit.bor(value, value))
			end
		end)

		it("satisfies x xor x equals zero", function()
			for _, value in ipairs(values) do
				assert.are.equal(0, bit.bxor(value, value))
			end
		end)

		it("satisfies x xor all ones equals not x", function()
			for _, value in ipairs(values) do
				assert.are.equal(bit.bnot(value), bit.bxor(value, -1))
			end
		end)

		it("satisfies De Morgan laws", function()
			for _, a in ipairs(values) do
				for _, b in ipairs(values) do
					assert.are.equal(bit.bnot(bit.band(a, b)), bit.bor(bit.bnot(a), bit.bnot(b)))

					assert.are.equal(bit.bnot(bit.bor(a, b)), bit.band(bit.bnot(a), bit.bnot(b)))
				end
			end
		end)
	end)

	describe("argument validation", function()
		local invalid = {
			false,
			true,
			{},
			function() end,
			"invalid",
		}

		it("rejects invalid unary arguments", function()
			for _, value in ipairs(invalid) do
				assert.has_error(function()
					bit.tobit(value)
				end)

				assert.has_error(function()
					bit.bnot(value)
				end)

				assert.has_error(function()
					bit.bswap(value)
				end)
			end
		end)

		it("rejects invalid boolean arguments", function()
			for _, value in ipairs(invalid) do
				assert.has_error(function()
					bit.band(1, value)
				end)

				assert.has_error(function()
					bit.bor(1, value)
				end)

				assert.has_error(function()
					bit.bxor(1, value)
				end)
			end
		end)

		it("rejects invalid shift arguments", function()
			for _, value in ipairs(invalid) do
				assert.has_error(function()
					bit.lshift(1, value)
				end)

				assert.has_error(function()
					bit.rshift(1, value)
				end)

				assert.has_error(function()
					bit.arshift(1, value)
				end)

				assert.has_error(function()
					bit.rol(1, value)
				end)

				assert.has_error(function()
					bit.ror(1, value)
				end)
			end
		end)
	end)
end)

if jit then
	describe("LuaJIT compatibility", function()
		local native = require("softdep.bit")

		local values = {
			0,
			1,
			-1,
			2,
			-2,
			127,
			128,
			255,
			256,
			65535,
			65536,
			2147483647,
			2147483648,
			2147483649,
			305419896,
			2271560481,
			2882400001,
			4294967294,
			4294967295,
			4294967296,
			4294967297,
			-2147483648,
			-2147483649,
			-4294967296,
			-4294967297,
			1099511627776 + 1234,
			-1099511627776 - 1234,
		}

		local shifts = {
			-65,
			-64,
			-63,
			-33,
			-32,
			-31,
			-16,
			-8,
			-1,
			0,
			1,
			7,
			8,
			15,
			16,
			24,
			30,
			31,
			32,
			33,
			40,
			63,
			64,
			65,
			0xffffffff,
			0x100000000,
			0x100000001,
		}

		local widths = {
			-100,
			-32,
			-9,
			-8,
			-7,
			-4,
			-2,
			-1,
			0,
			1,
			2,
			4,
			7,
			8,
			9,
			32,
			100,
			0xffffffff,
			0xfffffffe,
			0x100000000,
			0x100000008,
		}

		it("matches tobit", function()
			for _, value in ipairs(values) do
				assert.are.equal(native.tobit(value), bit.tobit(value))
			end
		end)

		it("matches tohex default width", function()
			for _, value in ipairs(values) do
				assert.are.equal(native.tohex(value), bit.tohex(value))
			end
		end)

		it("matches tohex explicit widths", function()
			for _, value in ipairs(values) do
				for _, width in ipairs(widths) do
					assert.are.equal(native.tohex(value, width), bit.tohex(value, width))
				end
			end
		end)

		it("matches bnot", function()
			for _, value in ipairs(values) do
				assert.are.equal(native.bnot(value), bit.bnot(value))
			end
		end)

		it("matches bswap", function()
			for _, value in ipairs(values) do
				assert.are.equal(native.bswap(value), bit.bswap(value))
			end
		end)

		it("matches binary boolean operations", function()
			for _, a in ipairs(values) do
				for _, b in ipairs(values) do
					assert.are.equal(native.band(a, b), bit.band(a, b))

					assert.are.equal(native.bor(a, b), bit.bor(a, b))

					assert.are.equal(native.bxor(a, b), bit.bxor(a, b))
				end
			end
		end)

		it("matches n-ary boolean operations", function()
			local vectors = {
				{ 1, 2, 4 },
				{ -1, 255, 15 },
				{ 0x12345678, 255, 15 },
				{ 0x80000000, 1, 255 },
				{ 0xffffffff, 0x12345678, 0x89abcdef },
				{ 1, 2, 4, 8 },
				{ 255, 127, 63, 31, 15 },
			}

			for _, v in ipairs(vectors) do
				assert.are.equal(native.band(unpack(v)), bit.band(unpack(v)))

				assert.are.equal(native.bor(unpack(v)), bit.bor(unpack(v)))

				assert.are.equal(native.bxor(unpack(v)), bit.bxor(unpack(v)))
			end
		end)

		it("matches left shifts", function()
			for _, value in ipairs(values) do
				for _, shift in ipairs(shifts) do
					assert.are.equal(native.lshift(value, shift), bit.lshift(value, shift))
				end
			end
		end)

		it("matches logical right shifts", function()
			for _, value in ipairs(values) do
				for _, shift in ipairs(shifts) do
					assert.are.equal(native.rshift(value, shift), bit.rshift(value, shift))
				end
			end
		end)

		it("matches arithmetic right shifts", function()
			for _, value in ipairs(values) do
				for _, shift in ipairs(shifts) do
					assert.are.equal(native.arshift(value, shift), bit.arshift(value, shift))
				end
			end
		end)

		it("matches left rotations", function()
			for _, value in ipairs(values) do
				for _, shift in ipairs(shifts) do
					assert.are.equal(native.rol(value, shift), bit.rol(value, shift))
				end
			end
		end)

		it("matches right rotations", function()
			for _, value in ipairs(values) do
				for _, shift in ipairs(shifts) do
					assert.are.equal(native.ror(value, shift), bit.ror(value, shift))
				end
			end
		end)

		it("matches numeric string conversion", function()
			local string_values = {
				"0",
				"1",
				"-1",
				"255",
				"2147483647",
				"2147483648",
				"4294967295",
				"4294967296",
			}

			for _, value in ipairs(string_values) do
				assert.are.equal(native.tobit(value), bit.tobit(value))

				assert.are.equal(native.tohex(value), bit.tohex(value))

				assert.are.equal(native.bnot(value), bit.bnot(value))

				assert.are.equal(native.bswap(value), bit.bswap(value))
			end
		end)

		it("matches zero argument errors", function()
			assert.has_error(function()
				native.band()
			end)

			assert.has_error(function()
				bit.band()
			end)

			assert.has_error(function()
				native.bor()
			end)

			assert.has_error(function()
				bit.bor()
			end)

			assert.has_error(function()
				native.bxor()
			end)

			assert.has_error(function()
				bit.bxor()
			end)
		end)

		it("matches missing argument errors", function()
			local native_calls = {
				function()
					native.tobit()
				end,
				function()
					native.tohex()
				end,
				function()
					native.bnot()
				end,
				function()
					native.lshift()
				end,
				function()
					native.lshift(1)
				end,
				function()
					native.rshift()
				end,
				function()
					native.rshift(1)
				end,
				function()
					native.arshift()
				end,
				function()
					native.arshift(1)
				end,
				function()
					native.rol()
				end,
				function()
					native.rol(1)
				end,
				function()
					native.ror()
				end,
				function()
					native.ror(1)
				end,
				function()
					native.bswap()
				end,
			}

			local local_calls = {
				function()
					bit.tobit()
				end,
				function()
					bit.tohex()
				end,
				function()
					bit.bnot()
				end,
				function()
					bit.lshift()
				end,
				function()
					bit.lshift(1)
				end,
				function()
					bit.rshift()
				end,
				function()
					bit.rshift(1)
				end,
				function()
					bit.arshift()
				end,
				function()
					bit.arshift(1)
				end,
				function()
					bit.rol()
				end,
				function()
					bit.rol(1)
				end,
				function()
					bit.ror()
				end,
				function()
					bit.ror(1)
				end,
				function()
					bit.bswap()
				end,
			}

			for i = 1, #native_calls do
				assert.has_error(native_calls[i])
				assert.has_error(local_calls[i])
			end
		end)

		it("matches explicit nil tohex width errors", function()
			assert.has_error(function()
				native.tohex(1, nil)
			end)

			assert.has_error(function()
				bit.tohex(1, nil)
			end)
		end)
	end)
end
