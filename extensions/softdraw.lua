local softdraw = {}

local function getDist(parents, order)
	local depth = {}
	for _, vtag in ipairs(order) do
		depth[vtag] = 1
		for ptag, _ in pairs(parents[vtag]) do
			depth[vtag] = math.max(depth[vtag], depth[ptag] + 1)
		end
	end

	local depthDist = {}
	for vtag, d in pairs(depth) do
		depthDist[d] = depthDist[d] or {}
		table.insert(depthDist[d], vtag)
	end

	return depthDist
end

function softdraw.drawNode(node, X, Y, W, H)
	X = X or 0
	Y = Y or 0
	W = W or love.graphics.getWidth()
	H = H or love.graphics.getHeight()

	local dist = getDist(node.parents_c, node.order)
	local info = {}

	love.graphics.setColor(1, 1, 1, 1)
	local D = #dist
	for j = 1, D do
		local B = #dist[j]
		for i = 1, B do
			local x = X + W / B * (i - 0.5)
			local y = Y + H / D * (j - 0.5)
			local tag = dist[j][i]
			love.graphics.circle("line", x, y, 8)
			love.graphics.print(tag, x, y)
			info[tag] = { x = x, y = y }
		end
	end

	for ttag, _ in pairs(node.tasks) do
		local x1 = info[ttag].x
		local y1 = info[ttag].y
		for ctag, _ in pairs(node.children_c[ttag]) do
			local x2 = info[ctag].x
			local y2 = info[ctag].y
			love.graphics.line(x1, y1, x2, y2)
		end
	end
end

local function drawGraph(graph) end

return softdraw
