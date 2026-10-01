---@param ok boolean
---@param result string|nil
local function assertOk(ok, result)
	if not ok then
		error(result, 3)
	end
end

return assertOk
