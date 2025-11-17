-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
-- BEAMLR EDITED VERSION FOR IMGUI LAYOUT LOADING
-- BEAMLR 1.19 FURTHER EDITED FOR TITLE TRANSLATION

local im  = ui_imgui

local ffi = require('ffi')
local extensions = require("extensions")

local C = {}

C.name = 'im Begin'
C.color = ui_flowgraph_editor.nodeColors.ui
C.icon = ui_flowgraph_editor.nodeIcons.ui
C.description = "Opens an imgui window. Make sure to end it with im End."
C.category = 'repeat_instant' -- technically once_instant, but unsure how to reset

C.todo = ""
C.pinSchema = {
    { dir = 'out', type = 'flow', name = 'wasClosed', description = 'Outflow once when the user attempts to close this window.', impulse = true },
    { dir = 'in', type = 'string', name = 'title', description = 'Defines the title of the window.' },
    { dir = 'in', type = 'number', name = 'width', hidden = true, default = 200, hardcoded = true, description = 'Defines the width of the window.' },
    { dir = 'in', type = 'number', name = 'height', hidden = true, default = 150, hardcoded = true, description = 'Defines the height of the window.' },
    { dir = 'in', type = 'number', name = 'posX', hidden = true, default = 100, hardcoded = true, description = 'Defines the x-position of the window.' },
    { dir = 'in', type = 'number', name = 'posY', hidden = true, default = 100, hardcoded = true, description = 'Defines the y-position of the window.' },
    { dir = 'in', type = 'string', name = 'anchor', hidden = true, default = "TL", hardcoded = true, description = 'Defines the anchor for the window. Can be TL (Top-Left), TR (Top-Right), BL (Bottom-Left) or BR (Bottom-Right).' },
}


function C:init()
  self.done = false

end


function C:_executionStarted()
  self.done = false
  for _, p in pairs(self.pinOut) do
    p.value = false
  end
end


function C:work()
  if not self.done then
    local w,h,x,y,anchor = self.pinIn.width.value, self.pinIn.height.value, self.pinIn.posX.value, self.pinIn.posY.value, self.pinIn.anchor.value
    w = w or 100
    h = h or 100
    x = x or 100
    y = y or 100
    anchor = anchor or 100
    im.SetNextWindowSize(im.ImVec2(w,h))
    if anchor == "TL" or anchor == "TR" or anchor == "BL" or anchor == "BR" then
      local canvasObject = scenetree.findObject("Canvas")
      if canvasObject then
        local windowPos
        local sPos = vec3(x, y)
        if anchor == "TL" then
          windowPos = canvasObject:clientToScreen(Point2I(x, y))
        elseif anchor == "TR" then
          windowPos = canvasObject:clientToScreen(Point2I(canvasObject:getWindowClientSize().x-x, y))
        elseif anchor == "BL" then
          windowPos = canvasObject:clientToScreen(Point2I(x, canvasObject:getWindowClientSize().y-y))
        elseif anchor == "BR" then
          windowPos = canvasObject:clientToScreen(Point2I(canvasObject:getWindowClientSize().x-x, canvasObject:getWindowClientSize().y-y))
        end
        if windowPos then
          im.SetNextWindowPos(im.ImVec2(windowPos.x, windowPos.y))
        end
      end
    end
    self.done = true
  end


  local bPtr = im.BoolPtr(true)
  local flags = nil
  if not self.pinIn.title.value then
    flags = im.WindowFlags_NoTitleBar
  end
  im.Begin((extensions.blrlocales.translate(self.pinIn.title.value) or "Title") ..'##'.. tostring(self.id), bPtr, flags)
  self.pinOut.wasClosed.value = not bPtr[0]
  extensions.blrutils.IMGUILayoutInit(self.pinIn.title.value or "Title")
end

return _flowgraph_createNode(C)
