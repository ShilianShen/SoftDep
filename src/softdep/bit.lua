local bit = {}

local floor = math.floor
local ceil = math.ceil
local sub = string.sub
local concat = table.concat

local UINT32 = 4294967296
local INT32 = 2147483648

local POW2 = {
	[0] = 1,
}

for i = 1, 32 do
	POW2[i] = POW2[i - 1] * 2
end

local function checknumber(x, level)
	x = tonumber(x)

	if x == nil then
		error("number expected", (level or 1) + 1)
	end

	return x
end

local function touint32(x)
	x = checknumber(x, 2)

	if x >= 0 then
		x = floor(x)
	else
		x = ceil(x)
	end

	return x % UINT32
end

local function tosigned32(x)
	x = x % UINT32

	if x >= INT32 then
		return x - UINT32
	end

	return x
end

local function shiftcount(n)
	return touint32(n) % 32
end

local function binary_op(a, b, op)
	a = touint32(a)
	b = touint32(b)

	local result = 0
	local p = 1

	for _ = 1, 32 do
		local aa = a % 2
		local bb = b % 2

		if op(aa, bb) then
			result = result + p
		end

		a = floor(a / 2)
		b = floor(b / 2)
		p = p * 2
	end

	return result
end

local function op_and(a, b)
	return a == 1 and b == 1
end

local function op_or(a, b)
	return a == 1 or b == 1
end

local function op_xor(a, b)
	return a ~= b
end

function bit.tobit(x)
	return tosigned32(touint32(x))
end

function bit.tohex(x, ...)
	local u = touint32(x)
	local n

	if select("#", ...) == 0 then
		n = 8
	else
		n = tosigned32(touint32(select(1, ...)))
	end

	local digits

	if n < 0 then
		n = -n
		digits = "0123456789ABCDEF"
	else
		digits = "0123456789abcdef"
	end

	if n > 8 then
		n = 8
	end

	local result = {}

	for i = n, 1, -1 do
		local d = u % 16
		result[i] = sub(digits, d + 1, d + 1)
		u = floor(u / 16)
	end

	return concat(result)
end

function bit.bnot(x)
	return tosigned32(UINT32 - 1 - touint32(x))
end

function bit.band(...)
	local n = select("#", ...)

	if n == 0 then
		error("number expected", 2)
	end

	local result = touint32(select(1, ...))

	for i = 2, n do
		result = binary_op(result, select(i, ...), op_and)

		if result == 0 then
			return 0
		end
	end

	return tosigned32(result)
end

function bit.bor(...)
	local n = select("#", ...)

	if n == 0 then
		error("number expected", 2)
	end

	local result = touint32(select(1, ...))

	for i = 2, n do
		result = binary_op(result, select(i, ...), op_or)
	end

	return tosigned32(result)
end

function bit.bxor(...)
	local n = select("#", ...)

	if n == 0 then
		error("number expected", 2)
	end

	local result = touint32(select(1, ...))

	for i = 2, n do
		result = binary_op(result, select(i, ...), op_xor)
	end

	return tosigned32(result)
end

function bit.lshift(x, n)
	local u = touint32(x)
	n = shiftcount(n)

	if n == 0 then
		return tosigned32(u)
	end

	u = (u % POW2[32 - n]) * POW2[n]

	return tosigned32(u)
end

function bit.rshift(x, n)
	local u = touint32(x)
	n = shiftcount(n)

	if n == 0 then
		return tosigned32(u)
	end

	return tosigned32(floor(u / POW2[n]))
end

function bit.arshift(x, n)
	local s = tosigned32(touint32(x))
	n = shiftcount(n)

	if n == 0 then
		return s
	end

	return tosigned32(floor(s / POW2[n]))
end

function bit.rol(x, n)
	local u = touint32(x)
	n = shiftcount(n)

	if n == 0 then
		return tosigned32(u)
	end

	local left = (u % POW2[32 - n]) * POW2[n]
	local right = floor(u / POW2[32 - n])

	return tosigned32(left + right)
end

function bit.ror(x, n)
	local u = touint32(x)
	n = shiftcount(n)

	if n == 0 then
		return tosigned32(u)
	end

	local right = floor(u / POW2[n])
	local left = (u % POW2[n]) * POW2[32 - n]

	return tosigned32(left + right)
end

function bit.bswap(x)
	local u = touint32(x)

	local b1 = u % 256
	u = floor(u / 256)

	local b2 = u % 256
	u = floor(u / 256)

	local b3 = u % 256
	u = floor(u / 256)

	local b4 = u % 256

	return tosigned32(b1 * 16777216 + b2 * 65536 + b3 * 256 + b4)
end

return bit
