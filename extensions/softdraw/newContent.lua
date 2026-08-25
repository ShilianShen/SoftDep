local style = require("extensions.softdraw.style")

local function getDist(parents, order)
	local depth = {}
	for _, vtag in ipairs(order) do
		depth[vtag] = 1
		for ptag, _ in pairs(parents[vtag]) do
			depth[vtag] = math.max(depth[vtag], depth[ptag] + 1)
		end
	end

	local dist = {}
	for vtag, d in pairs(depth) do
		dist[d] = dist[d] or {}
		table.insert(dist[d], vtag)
	end

	return dist
end

local function _newContent(vertices, parents, children, order, X, Y, W, H)
	local content = {}
	content.dist = getDist(parents, order)

	content.vertices = {}
	local D = #content.dist
	for j = 1, D do
		local B = #content.dist[j]
		for i = 1, B do
			local vtag = content.dist[j][i]
			content.vertices[vtag] = {
				x = X + W / B * (i - 0.5),
				y = Y + H / D * (j - 0.5),
				cb = "dark",
				cl = "light",
				ct = "light",
				t = vtag,
			}
		end
	end

	content.edges = {}
	for vtag, _ in pairs(vertices) do
		local x1 = content.vertices[vtag].x
		local y1 = content.vertices[vtag].y
		for ctag, _ in pairs(children[vtag]) do
			local x2 = content.vertices[ctag].x
			local y2 = content.vertices[ctag].y
			local edge = {
				x1 = x1,
				y1 = y1,
				x2 = x2,
				y2 = y2,
				cl = "light",
				cb = "dark",
				ct = "light",
				t = "",
				s = "line",
			}
			table.insert(content.edges, edge)
		end
	end

	return content
end

local function drawContent(content, theme)
	for _, edge in ipairs(content.edges) do
		local w = theme.font:getWidth(edge.t)
		local h = theme.font:getHeight()
		local x = (edge.x1 + edge.x2 - w) / 2
		local y = (edge.y1 + edge.y2 - h) / 2
		love.graphics.setColor(theme[edge.cl])
		style[edge.s](edge.x1, edge.y1, edge.x2, edge.y2)
		love.graphics.setColor(theme[edge.cb])
		love.graphics.rectangle("fill", x, y, w, h)
		love.graphics.setColor(theme[edge.ct])
		love.graphics.print(edge.t, x, y)
	end

	for _, vertex in pairs(content.vertices) do
		local w = theme.font:getWidth(vertex.t)
		local h = theme.font:getHeight()
		local x = vertex.x - w / 2
		local y = vertex.y - h / 2
		love.graphics.setColor(theme[vertex.cb])
		love.graphics.rectangle("fill", x - 1, y - 1, w + 2, h + 2)
		love.graphics.setColor(theme[vertex.cl])
		love.graphics.rectangle("line", x - 1, y - 1, w + 2, h + 2)
		love.graphics.setColor(theme[vertex.ct])
		love.graphics.print(vertex.t, x, y)
	end
end

local function newContent(...)
	local content = _newContent(...)
	content.draw = drawContent
	return content
end

return newContent
