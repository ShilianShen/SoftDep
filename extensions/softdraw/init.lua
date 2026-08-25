local softdraw = {
	theme = require("extensions.softdraw.theme"),
	memory = {
		graph = nil,
		graphContent = nil,
		node = nil,
		nodeContent = nil,
	},
}
local newContent = require("extensions.softdraw.newContent")

local function stylizeNode(content, node)
	for ttag, task in pairs(node.tasks) do
		if task.dirty then
			content.vertices[ttag].ct = softdraw.theme.dirty
		else
			content.vertices[ttag].ct = softdraw.theme.clean
		end
	end
end

local function stylizeGraph(content, graph)
	for ntag, node in pairs(graph.nodes) do
		if node.dirty then
			content.vertices[ntag].ct = softdraw.theme.dirty
		else
			content.vertices[ntag].ct = softdraw.theme.clean
		end
	end
end

function softdraw.drawNode(node, X, Y, W, H)
	X = X or 0
	Y = Y or 0
	W = W or love.graphics.getWidth()
	H = H or love.graphics.getHeight()

	local content = newContent(node.tasks, node.parents_c, node.children_c, node.order, X, Y, W, H)
	stylizeNode(content, node)
	content:draw()

	return content
end

function softdraw.drawGraph(graph, X, Y, W, H)
	X = X or 0
	Y = Y or 0
	W = W or love.graphics.getWidth()
	H = H or love.graphics.getHeight()

	local content = newContent(graph.nodes, graph.parents_n, graph.children_n, graph.order, X, Y, W, H)
	stylizeGraph(content, graph)
	content:draw()

	return content
end

function softdraw.drawGraphNode(graph, X, Y, W, H)
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
