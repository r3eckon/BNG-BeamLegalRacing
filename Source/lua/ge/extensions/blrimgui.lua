local M = {}
local im = ui_imgui
local bid = 0


local function imText(text)
local avail = im.GetContentRegionAvail()
im.PushTextWrapPos(avail.x)
im.TextWrapped(tostring(text))
im.PopTextWrapPos()
end

local function imButton(text)
local avail = im.GetContentRegionAvail()
im.Button(tostring(text or "Button"), im.ImVec2(avail.x, 0))
if im.IsItemHovered() then
local down = im.IsMouseClicked(0)
if down then return true end
end
return false
end


M.imText = imText
M.imButton = imButton


return M