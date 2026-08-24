local softdraw = {
	theme = {
		dirty = { 0.95, 0.25, 0.20 },
		clean = { 0.20, 0.90, 0.35 },
		light = { 0.85, 0.92, 0.85 },
		dark = { 0.03, 0.05, 0.04 },
		font = love.graphics.newFont(12),
	},
	memory = {
		node = nil,
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
		love.graphics.rectangle("fill", x - 1, y - 1, w + 2, h + 2)
		love.graphics.setColor(vertex.cf)
		love.graphics.rectangle("line", x - 1, y - 1, w + 2, h + 2)
		love.graphics.setColor(vertex.ct)
		love.graphics.draw(vertex.t, x, y)
	end
end

function softdraw.drawNode(node, X, Y, W, H)
	X = X or 0
	Y = Y or 0
	W = W or love.graphics.getWidth()
	H = H or love.graphics.getHeight()

	local content = newContent(node.tasks, node.parents_c, node.children_c, node.order, X, Y, W, H)
	for ttag, task in pairs(node.tasks) do
		if task.dirty then
			content.vertices[ttag].ct = softdraw.theme.dirty
		else
			content.vertices[ttag].ct = softdraw.theme.clean
		end
	end
	drawContent(content)
	return content
end

function softdraw.drawGraph(graph, X, Y, W, H)
	X = X or 0
	Y = Y or 0
	W = W or love.graphics.getWidth()
	H = H or love.graphics.getHeight()

	local content = newContent(graph.nodes, graph.parents_n, graph.children_n, graph.order, X, Y, W, H)
	for ntag, node in pairs(graph.nodes) do
		if node.dirty then
			content.vertices[ntag].ct = softdraw.theme.dirty
		else
			content.vertices[ntag].ct = softdraw.theme.clean
		end
	end
	drawContent(content)
	return content
end

function softdraw.drawGraphNode(graph)
	X = X or 0
	Y = Y or 0
	W = W or love.graphics.getWidth()
	H = H or love.graphics.getHeight()
	local graphContent = softdraw.drawGraph(graph, X, Y, W / 2, H)
	local mouseX, mouseY = love.mouse.getPosition()
	for ntag, vertex in pairs(graphContent.vertices) do
		local w, h = vertex.t:getDimensions()
		local dx = (mouseX - vertex.x) / w + 0.5
		local dy = (mouseY - vertex.y) / h + 0.5
		if 0 < dx and dx < 1 and 0 < dy and dy < 1 then
			softdraw.memory.node = graph.nodes[ntag]
		end
	end
	if softdraw.memory.node ~= nil then
		softdraw.drawNode(softdraw.memory.node, X + W / 2, Y, W / 2, H)
	end
end

return softdraw
