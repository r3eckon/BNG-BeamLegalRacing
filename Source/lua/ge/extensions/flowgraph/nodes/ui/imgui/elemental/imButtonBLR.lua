-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- BEAMLR EDITED FOR TRANSLATIONS

local im  = ui_imgui
local extensions = require("extensions")
local C = {}

C.name = 'im Button BLR'
C.color = ui_flowgraph_editor.nodeColors.ui
C.icon = ui_flowgraph_editor.nodeIcons.ui
C.description = "Displays a button in an imgui window."
C.category = 'repeat_instant'

C.pinSchema = {
    { dir = 'out', type = 'flow', name = 'down', description = 'When button is clicked.', impulse = true },
    { dir = 'out', type = 'flow', name = 'hold', hidden = true, description = 'When button is down.' },
    { dir = 'out', type = 'flow', name = 'up', hidden = true, description = 'When button is released.' },
    { dir = 'in', type = 'any', name = 'text', description = 'Defines the text displayed on the button.' },
}

C.tags = {'imgui'}

function C:_executionStarted()
  for _, p in pairs(self.pinOut) do
    p.value = false
  end
end

function C:work()
  local avail = im.GetContentRegionAvail()
  im.Button(extensions.blrlocales.translate(tostring(self.pinIn.text.value or "Button"))  ..'##'.. tostring(self.id), im.ImVec2(avail.x, 0))

  if im.IsItemHovered() then
    local down = im.IsMouseClicked(0)
    local hold = im.IsMouseDown(0)
    local up =   im.IsMouseReleased(0)
    if (down or hold or up) then
      if down then hold = false up = false end
      if hold then down = false up = false end
      if up then down = false hold = false end
    end
    self.pinOut.down.value = down
    self.pinOut.hold.value = hold
    self.pinOut.up.value = up
  else
    self.pinOut.down.value = false
    self.pinOut.hold.value = false
    self.pinOut.up.value = false
  end
end

return _flowgraph_createNode(C)
