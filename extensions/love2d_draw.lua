local font1 = love.graphics.newFont(24)
local font2 = love.graphics.newFont(12)
local highColor = { 0.9, 0.8, 0.2 }
local darkColor = { 0, 0, 0 }
local basicTheme = {
	nightColor = { 0.1, 0.1, 0.12 },
	lightColor = { 0.95, 0.95, 0.9 },
	cleanColor = { 0.2, 0.5, 0.3 },
	dirtyColor = { 0.6, 0.2, 0.2 },
}
local smooth = 0
local scaleMax, scaleMin = 1, 0.5
local infoDict = {}
local infoArray = {}
local mouseX, mouseY = 0, 0
local bufferT = 1
local winW, winH = 0, 0
local time = 0
local tree = {}
local darkTheme = {}
local highTheme = {}
local entityDepth = 4
local entityIndent = 16
for key, color in pairs(basicTheme) do
	local dark = {}
	local high = {}
	for i = 1, 3 do
		dark[i] = (color[i] + darkColor[i]) / 2
		high[i] = color[i]
	end
	darkTheme[key] = dark
	highTheme[key] = high
end
highTheme.lightColor = highColor

local function lcomp(k1, k2)
	local t1 = type(k1)
	local t2 = type(k2)
	if t1 == t2 then
		return tostring(k1) < tostring(k2)
	else
		return t1 < t2
	end
end

local function lpairs(t)
	local keys = {}
	for k in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys, lcomp)

	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

local function dump(tab, depth, result)
	result = result or { "{" }
	for key, value in lpairs(tab) do
		if string.sub(key, 1, 1) == "_" then
		elseif type(value) == "table" and depth > 0 then
			table.insert(result, key .. " = {")
			dump(value, depth - 1, result)
		else
			table.insert(result, key .. " = " .. tostring(value))
		end
	end
	table.insert(result, "}")
	return result
end

local function merge(t1, t2)
	local t = {}
	for k, v in pairs(t1) do
		t[k] = v
	end
	for k, v in pairs(t2) do
		t[k] = v
	end
	return t
end

local function compTag(tag1, tag2)
	local value1, count1 = 0, 1
	local value2, count2 = 0, 1
	for parentTag, _ in pairs(tree.nodeDict[tag1]._parents) do
		value1 = value1 + infoDict[parentTag].i
		count1 = count1 + 1
	end
	for parentTag, _ in pairs(tree.nodeDict[tag2]._parents) do
		value2 = value2 + infoDict[parentTag].i
		count2 = count2 + 1
	end
	value1 = value1 * count2
	value2 = value2 * count1
	if value1 == value2 then
		return tag1 < tag2
	else
		return value1 < value2
	end
end

local function compInfo(info1, info2)
	return info1.s < info2.s
end

local function calc()
	-- remove
	for tag, _ in pairs(infoDict) do
		if tree.nodeDict[tag] == nil then
			infoDict[tag] = nil
		end
	end

	-- insert
	for tag, node in pairs(tree.nodeDict) do
		if infoDict[tag] == nil then
			infoDict[tag] = {
				node = node,
				text = love.graphics.newText(font1, tag),
				t = {},
			}
			for _, task in lpairs(node.tasks) do
				table.insert(infoDict[tag].t, {
					t = 0,
					n = 0,
				})
			end
		end
	end

	-- mesh
	local mesh = {}
	for tag, node in pairs(tree.nodeDict) do
		mesh[node.depth] = mesh[node.depth] or {}
		table.insert(mesh[node.depth], tag)
		infoDict[tag].i = #mesh[node.depth]
	end

	-- sort
	for i = 1, #mesh do
		table.sort(mesh[i], compTag)
		for j = 1, #mesh[i] do
			infoDict[mesh[i][j]].i = j
		end
	end

	-- calc
	local nodeH = winH / (tree.depth + 1)
	local k = 1
	for i = 1, #mesh do
		local nodeW = winW / (#mesh[i] + 1) * k
		for j = 1, #mesh[i] do
			local tag = mesh[i][j]
			local info = infoDict[tag]
			local node = info.node
			info.x = j * nodeW + winW * (1 - k)
			info.y = i * nodeH
			info.d = ((mouseX - info.x) / nodeW) ^ 2 + ((mouseY - info.y) / nodeH) ^ 2
			info.s = scaleMax + (scaleMin - scaleMax) * math.tanh(info.d / 2)
			info.w = info.s * info.text:getWidth()
			info.h = info.s * info.text:getHeight()
			info.r = info.s * font1:getHeight() / 2
			local t = 1
			for _, task in lpairs(node.tasks) do
				local jnfo = info.t[t]
				jnfo.t = jnfo.n ~= task.callCount and time or (jnfo.t or 0)
				jnfo.n = task.callCount
				t = t + 1
			end
		end
	end

	infoArray = {}
	for _, info in pairs(infoDict) do
		table.insert(infoArray, info)
	end
	table.sort(infoArray, compInfo)
end

local function drawEntity(node, theme, pos)
	local strings = dump(node, entityDepth)
	local h = font2:getHeight() * #strings
	local x, y = 0, (love.graphics.getHeight() - h) * (1 - pos) / 2
	love.graphics.setFont(font2)
	for _, string in ipairs(strings) do
		x = x - (string == "}" and entityIndent or 0)
		love.graphics.setColor(theme.nightColor)
		love.graphics.rectangle("fill", x, y, font2:getWidth(string), font2:getHeight())
		love.graphics.setColor(theme.lightColor)
		love.graphics.print(string, x, y)
		y = y + font2:getHeight()
		x = x + (string.match(string, "{") and entityIndent or 0)
	end
end

local function drawEdge(info1, info2, theme)
	love.graphics.setColor(theme.lightColor)
	local dy = smooth * (info2.y - info1.y)
	local vertices = { info1.x, info1.y, info1.x, info1.y + dy, info2.x, info2.y - dy, info2.x, info2.y }
	local curve = love.math.newBezierCurve(vertices)
	love.graphics.line(curve:render())
end

local function drawNode(info, theme)
	love.graphics.setColor(theme.nightColor)
	love.graphics.circle("fill", info.x, info.y, info.r)

	love.graphics.setColor(theme.lightColor)
	love.graphics.circle("line", info.x, info.y, info.r)

	love.graphics.setColor(theme.cleanColor)
	love.graphics.rectangle("fill", info.x, info.y, info.w, info.h)

	love.graphics.setColor(theme.dirtyColor)
	for i, task in ipairs(info.t) do
		love.graphics.rectangle(
			"fill",
			info.x,
			info.y + info.h * (i - 1) / #info.t,
			info.w * math.max(0, 1 - (time - task.t) / bufferT),
			info.h / #info.t
		)
	end

	love.graphics.setColor(theme.lightColor)
	love.graphics.draw(info.text, info.x, info.y, 0, info.s, info.s)
end

local function draw()
	local target = nil
	for tag, info in pairs(infoDict) do
		local dist = (mouseX - info.x) ^ 2 + (mouseY - info.y) ^ 2
		if dist < info.r ^ 2 then
			target = tag
		end
	end

	local theme = target == nil and basicTheme or darkTheme
	for tag, node in pairs(tree.nodeDict) do
		local info1 = infoDict[tag]
		for tag2, _ in pairs(node._children) do
			local info2 = infoDict[tag2]
			drawEdge(info1, info2, theme)
		end
	end
	for _, info in ipairs(infoArray) do
		drawNode(info, theme)
	end

	if target ~= nil then
		local info = infoDict[target]
		drawEntity(info.node, basicTheme, (info.y - mouseY) / info.r * 1.5)
		love.graphics.setLineWidth(2)
		for tag2, _ in pairs(merge(info.node._children, info.node._parents)) do
			local info2 = infoDict[tag2]
			drawEdge(info, info2, highTheme)
		end
		for tag2, _ in pairs(merge(info.node._children, info.node._parents)) do
			local info2 = infoDict[tag2]
			drawNode(info2, highTheme)
		end
		drawNode(info, highTheme)
	end
end

local function call(_tree)
	winW, winH = love.graphics.getDimensions()
	mouseX, mouseY = love.mouse.getPosition()
	tree = _tree
	time = love.timer.getTime()
	love.graphics.push("all")
	love.graphics.setLineWidth(1)
	calc()
	draw()
	love.graphics.pop()
end

return call
