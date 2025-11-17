-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- BEAMLR EDITED FOR TRANSLATION FILES

local im  = ui_imgui

local extensions = require("extensions")

local C = {}

C.name = 'Flash Message BLR'
C.color = ui_flowgraph_editor.nodeColors.ui
C.icon = ui_flowgraph_editor.nodeIcons.ui
C.description = "Shows a Message in the middle of the screen. Make sure you have \"UI Layout\" node setup to see messages."
C.behaviour = { duration = true }
C.pinSchema = {
  { dir = 'in', type = 'flow', name = 'flow', description = 'Inflow for this node.' },
  { dir = 'out', type = 'flow', name = 'flow', description = "Outflow for this node." },
  { dir = 'in', type = 'bool', name = 'instant', hidden = true, description = 'If true, removed all previous messages and shows this instantly.' },
  { dir = 'in', type = 'any', name = 'message', description = 'Message to display.' },
  { dir = 'in', type = 'number', name = 'duration', default = 3, description = 'Duration for displaying the message.' },
  { dir = 'in', type = 'bool', name = 'biggerText', hidden = true, default = true, description = 'Defines if the message be displayed in a larger size.' },
}

C.tags = {'string','util', 'message'}

function C:init()
  self.helper = require('scenario/scenariohelper')
end

function C:work()
  if self.pinIn.instant.value then
    guihooks.trigger('ScenarioFlashMessageClear')
  end
  local msg = self.pinIn.message.value
  if type(msg) ~= 'table' then
    msg = extensions.blrlocales.translate(tostring(msg))
  end
  self.helper.flashUiMessage(msg, self.pinIn.duration.value or 3, self.pinIn.biggerText.value)
  self.pinOut.flow.value = self.pinIn.flow.value
end

return _flowgraph_createNode(C)
