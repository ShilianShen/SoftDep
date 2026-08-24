local softdraw = {
	theme = {
		dirty = { 1, 0, 0 },
		clean = { 0, 1, 0 },
		light = { 1, 1, 1 },
		dark = { 0, 0, 0 },
		font = love.graphics.newFont(12),
	},
}

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

local function newContent(vertices, parents, children, order, X, Y, W, H)
	X = X or 0
	Y = Y or 0
	W = W or love.graphics.getWidth()
	H = H or love.graphics.getHeight()

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
				cb = softdraw.theme.dark,
				cf = softdraw.theme.light,
				ct = softdraw.theme.light,
				t = love.graphics.newText(softdraw.theme.font, vtag),
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
				c = softdraw.theme.light,
			}
			table.insert(content.edges, edge)
		end
	end

	return content
end

local function drawContent(content)
	for _, edge in ipairs(content.edges) do
		love.graphics.setColor(edge.c)
		love.graphics.line(edge.x1, edge.y1, edge.x2, edge.y2)
	end

	for _, vertex in pairs(content.vertices) do
		local w, h = vertex.t:getDimensions()
		local x = vertex.x - w / 2
		local y = vertex.y - h / 2

		love.graphics.setColor(vertex.cb)
		love.graphics.rectangle("fill", x, y, w, h)
		love.graphics.setColor(vertex.cf)
		love.graphics.rectangle("line", x, y, w, h)
		love.graphics.setColor(vertex.ct)
		love.graphics.draw(vertex.t, x, y)
	end
end

function softdraw.drawNode(node, X, Y, W, H)
	local content = newContent(node.tasks, node.parents_c, node.children_c, node.order, X, Y, W, H)
	for ttag, task in pairs(node.tasks) do
		if task.dirty then
			content.vertices[ttag].cf = softdraw.theme.dirty
		else
			content.vertices[ttag].cf = softdraw.theme.clean
		end
	end
	drawContent(content)
end

function softdraw.drawGraph(graph, X, Y, W, H)
	local content = newContent(graph.nodes, graph.parents_n, graph.children_n, graph.order, X, Y, W, H)
	drawContent(content)
end

return softdraw
