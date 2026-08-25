local softdraw = {
	theme = {
		dirty = { 0.95, 0.25, 0.20 },
		clean = { 0.20, 0.90, 0.35 },
		light = { 0.85, 0.92, 0.85 },
		dark = { 0.03, 0.05, 0.04 },
		font = love.graphics.newFont(12),
	},
	memory = {
		ntag = nil,
        ttag = nil,
	},
}
local Content = require("extensions.softdraw.Content")

local function getNodeContent(node, X, Y, W, H)
	local content = Content.newContent(node.tasks, node.parents_c, node.children_c, node.order, X, Y, W, H)
	for ttag, task in pairs(node.tasks) do
		content.vertices[ttag].ct = task.dirty and "dirty" or "clean"
	end
	return content
end

local function getGraphContent(graph, X, Y, W, H)
	local content = Content.newContent(graph.nodes, graph.parents_n, graph.children_n, graph.order, X, Y, W, H)
	for ntag, node in pairs(graph.nodes) do
		content.vertices[ntag].ct = node.dirty and "dirty" or "clean"
	end
	return content
end

function softdraw.drawGraphNode(graph, X, Y, W, H)
	X = X or 0
	Y = Y or 0
	W = W or love.graphics.getWidth()
	H = H or love.graphics.getHeight()

	local graphContent = getGraphContent(graph, X, Y, W / 2, H)
	local nodeContent = nil
	local ntag = softdraw.memory.ntag

	local mouseX, mouseY = love.mouse.getPosition()
	for vtag, vertex in pairs(graphContent.vertices) do
		local w = softdraw.theme.font:getWidth(vertex.t)
		local h = softdraw.theme.font:getHeight()
		local dx = (mouseX - vertex.x) / w + 0.5
		local dy = (mouseY - vertex.y) / h + 0.5
		if 0 < dx and dx < 1 and 0 < dy and dy < 1 then
			ntag = vtag
		end
	end
	softdraw.memory.ntag = ntag

	if ntag then
		local node = graph.nodes[ntag]
		nodeContent = getNodeContent(node, X + W / 2, Y, W / 2, H)
		for ttag, task in pairs(node.tasks) do
			local v2 = nodeContent.vertices[ttag]
			for _, dtag in pairs(node.parents_d[ttag]) do
				local v1 = graphContent.vertices[dtag]
				local edge = Content.newEdge(v1.x, v1.y, v2.x, v2.y)
				edge.s = "dot"
				edge.t = graph.nodes[dtag].access
				table.insert(nodeContent.edges, edge)
			end
			local v1 = graphContent.vertices[ntag]
			local edge = Content.newEdge(v1.x, v1.y, v2.x, v2.y)
			edge.s = "dot"
			edge.t = task.access
			table.insert(nodeContent.edges, edge)
		end
	end

	if nodeContent ~= nil then
		nodeContent:draw(softdraw.theme)
	end
	graphContent:draw(softdraw.theme)
end

return softdraw
