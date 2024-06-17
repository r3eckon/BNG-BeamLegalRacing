-- USING IMGUI TO DRAW INJURY CORNERS
-- THANKS TO DaddelZeit FOR THE SUGGESTION 


local M = {}

-- Shortcut to the imgui extension (lua/common/extensions/ui/imgui_gen.lua)
local im = ui_imgui

-- White UV pixel, otherwise we might not be able to add color
-- This is needed since ImGui always has to sample a texture for any vertex
local whiteTexelUV = im.GetFontTexUvWhitePixel()

local function drawMultiColorShape(drawlist, vert, col)
	im.ImDrawList_PrimReserve(drawlist, #vert, #vert)
	for i=1,#vert do
		im.ImDrawList_PrimVtx(drawlist, vert[i], whiteTexelUV, col[i])
	end
end

local function drawFeatheredCorner(drawlist, x,y,sizeX,sizeY,dirX,dirY, alpha)

local red = im.GetColorU322(im.ImVec4(1,0,0,0.5 * alpha))
local transparentRed = im.GetColorU322(im.ImVec4(1,0,0,0))

local verts = {}
local cols = {}

verts[1] = im.ImVec2(x, y)
verts[2] = im.ImVec2(x + (sizeX * dirX), y + (sizeY * dirY) / 2)
verts[3] = im.ImVec2(x + (sizeX * dirX) / 2, y + (sizeY * dirY))
	
verts[4] = im.ImVec2(x, y)
verts[5] = im.ImVec2(x + (sizeX * dirX) / 2, y + (sizeY * dirY))
verts[6] = im.ImVec2(x, y + (sizeY * dirY) * 2)
	
verts[7] = im.ImVec2(x, y)
verts[8] = im.ImVec2(x + (sizeX * dirX), y + (sizeY * dirY) / 2)
verts[9] = im.ImVec2(x + (sizeX * dirX) * 2, y)
	
cols[1] = red
cols[2] = transparentRed
cols[3] = transparentRed
cols[4] = red
cols[5] = transparentRed
cols[6] = transparentRed
cols[7] = red
cols[8] = transparentRed
cols[9] = transparentRed

drawMultiColorShape(drawlist, verts, cols)
end



local itime = 0
local enabled = false
local alpha = 0

local function onPreRender()
	if not enabled then return end

    -- Get drawlist
    local drawlist = im.GetBackgroundDrawList1()

    -- Get viewport for Pos/Size
    local viewport = im.GetMainViewport()
    -- The drawlist's 0x0 is always the top left corner of the screen
    -- The viewport's position is an offset we need to add
    local viewportPos = viewport.Pos
    local viewportSize = viewport.Size

    -- Adjust to screen size
    local triangleSize = im.ImVec2(viewportSize.y / 4, viewportSize.y / 4)

    -- Send draw command
	drawFeatheredCorner(drawlist, viewportPos.x, viewportPos.y, triangleSize.x, triangleSize.y, 1,1, alpha)
	drawFeatheredCorner(drawlist, viewportPos.x + viewportSize.x, viewportPos.y, triangleSize.x, triangleSize.y, -1,1, alpha)
	drawFeatheredCorner(drawlist, viewportPos.x + viewportSize.x, viewportPos.y + viewportSize.y, triangleSize.x, triangleSize.y, -1,-1, alpha)
	drawFeatheredCorner(drawlist, viewportPos.x, viewportPos.y + viewportSize.y, triangleSize.x, triangleSize.y, 1,-1, alpha)
end

local function clear()
local drawlist = im.GetBackgroundDrawList1()
im.ImDrawList__ResetForNewFrame(drawlist)
end

local function setAlpha(a)
alpha = a
end

local function fadeOut(speed)
alpha = math.max(0,alpha - speed)
return alpha <= 0
end

local function toggle(t)
enabled = t
if not t then 
setAlpha(0) 
clear()
end
end

M.fadeOut = fadeOut
M.toggle = toggle
M.setAlpha = setAlpha
M.clear = clear
M.onPreRender = onPreRender

return M