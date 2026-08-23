local decreaseOnly = {
	__newindex = function()
		assert(false)
	end,
}
return decreaseOnly
