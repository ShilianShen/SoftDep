local Content = require("softdraw.Content")
local softdraw = {
	theme = {
		background = { 0.025, 0.025, 0.025 },

		text = { 0.88, 0.88, 0.84 },
		border = { 0.72, 0.72, 0.68 },
		surface = { 0.055, 0.055, 0.050 },

		accent = { 0.95, 0.78, 0.20 },
		accent_text = { 1.00, 0.84, 0.28 },
		accent_border = { 0.72, 0.58, 0.12 },
		accent_surface = { 0.12, 0.10, 0.04 },

		warning = { 0.95, 0.40, 0.18 },
		success = { 0.40, 0.85, 0.45 },

		font = love.graphics.newFont(12),
	},
	memory = {
		ntag = nil,
		ttag = nil,
	},
}

local function getNodeContent(node, X, Y, W, H)
	local content = Content.newContent(node.tasks, node.parents_c, node.children_c, node.order, X, Y, W, H)
	for ttag, task in pairs(node.tasks) do
		content.vertices[ttag].textColor = task.dirty and "warning" or "success"
	end
	return content
end

local function getGraphContent(graph, X, Y, W, H)
	local content = Content.newContent(graph.nodes, graph.parents_n, graph.children_n, graph.order, X, Y, W, H)
	for ntag, node in pairs(graph.nodes) do
		content.vertices[ntag].textColor = node.dirty and "warning" or "success"
	end
	return content
end

local function getFocus(content)
	local mouseX, mouseY = love.mouse.getPosition()
	for vtag, vertex in pairs(content.vertices) do
		local w = softdraw.theme.font:getWidth(vertex.text)
		local h = softdraw.theme.font:getHeight()
		local dx = (mouseX - vertex.x) / w + 0.5
		local dy = (mouseY - vertex.y) / h + 0.5
		if 0 < dx and dx < 1 and 0 < dy and dy < 1 then
			return vtag
		end
	end
end

local function draw(graph, X, Y, W, H)
	X = X or 0
	Y = Y or 0
	W = W or love.graphics.getWidth()
	H = H or love.graphics.getHeight()

	love.graphics.setColor(softdraw.theme.background)
	love.graphics.rectangle("fill", X, Y, W, H)

	local graphContent = getGraphContent(graph, X, Y, W / 2, H)
	local nodeContent = nil

	local ntag = getFocus(graphContent)
	if ntag ~= softdraw.memory.ntag and ntag ~= nil then
		softdraw.memory.ttag = nil
	end

	softdraw.memory.ntag = ntag or softdraw.memory.ntag
	ntag = softdraw.memory.ntag

	if ntag then
		graphContent.vertices[ntag].borderColor = "accent_border"
		graphContent.vertices[ntag].surfaceColor = "accent_surface"
		local node = graph.nodes[ntag]
		nodeContent = getNodeContent(node, X + W / 2, Y, W / 2, H)
		softdraw.memory.ttag = getFocus(nodeContent) or softdraw.memory.ttag
		local ttag = softdraw.memory.ttag

		if ttag then
			nodeContent.vertices[ttag].borderColor = "accent_border"
			nodeContent.vertices[ttag].surfaceColor = "accent_surface"
			local task = node.tasks[ttag]
			local v2 = nodeContent.vertices[ttag]
			for _, dtag in pairs(node.parents_d[ttag]) do
				local v1 = graphContent.vertices[dtag]
				local edge = Content.newEdge(v1.x, v1.y, v2.x, v2.y)
				edge.style = "dot"
				edge.text = graph.nodes[dtag].access
				table.insert(nodeContent.edges, edge)
			end
			local v1 = graphContent.vertices[ntag]
			local edge = Content.newEdge(v1.x, v1.y, v2.x, v2.y)
			edge.style = "dot"
			edge.text = task.access
			table.insert(nodeContent.edges, edge)
		end
	end

	if nodeContent ~= nil then
		nodeContent:draw(softdraw.theme)
	end
	graphContent:draw(softdraw.theme)
end

function softdraw.draw(...)
	love.graphics.push("all")
	draw(...)
	love.graphics.pop()
end

return softdraw
