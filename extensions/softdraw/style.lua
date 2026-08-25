local style = {}

style.line = love.graphics.line

function style.dash(x1, y1, x2, y2, dashLength, gapLength)
	dashLength = dashLength or 10
	gapLength = gapLength or 6

	local dx, dy = x2 - x1, y2 - y1
	local length = math.sqrt(dx * dx + dy * dy)

	if length == 0 then
		return
	end

	local ux, uy = dx / length, dy / length
	local distance = 0

	while distance < length do
		local dashEnd = math.min(distance + dashLength, length)
		love.graphics.line(x1 + ux * distance, y1 + uy * distance, x1 + ux * dashEnd, y1 + uy * dashEnd)
		distance = distance + dashLength + gapLength
	end
end

function style.dot(x1, y1, x2, y2, spacing, radius)
	spacing = spacing or 4
	radius = radius or 1

	local dx, dy = x2 - x1, y2 - y1
	local length = math.sqrt(dx * dx + dy * dy)

	if length == 0 then
		love.graphics.circle("fill", x1, y1, radius)
		return
	end

	local ux, uy = dx / length, dy / length

	for distance = 0, length, spacing do
		love.graphics.circle("fill", x1 + ux * distance, y1 + uy * distance, radius)
	end
end

return style
