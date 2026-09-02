local function check(level, cond, msg)
	if not cond then
		error(msg, level + 1)
	end
end

return check
