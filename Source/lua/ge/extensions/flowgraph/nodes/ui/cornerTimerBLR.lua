-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- BEAMLR EDITED FOR 

local im  = ui_imgui

local C = {}

C.name = 'Set UI Timer (BLR)'
C.color = ui_flowgraph_editor.nodeColors.ui
C.icon = ui_flowgraph_editor.nodeIcons.ui
C.behaviour = { duration = true }
C.description = "Sets the UI timer app to a specific value."
C.category = 'repeat_instant'
C.author = 'BeamNG'

C.pinSchema = {
  { dir = 'in', type = 'number', name = 'value', description = 'Time to show in seconds. If not connected, will clear the time.' },
  { dir = 'in', type = 'string', name = 'color', description = 'Color to use. leave empty for default (white)' },
  { dir = 'in', type = 'bool', name = 'useGenericMissionDataApp', description = 'If set, uses the "Generic Mission Data App".' },
  { dir = 'in', type = 'bool', name = 'raceMode', description = 'Toggles between race mode (12:34:567 format, shows lap time & delta) and regular clock (12:34:56 format) for BeamLR custom timer app' },
}
C.tags = {'string','util'}

function C:postInit()
  local temps = {}
  for _, clr in ipairs({'white','red','green','blue'}) do
    table.insert(temps, {label = clr, value = clr})
  end
  self.pinInLocal.color.hardTemplates = temps
end

local raceTimeData = {}
function C:work()
  if self.pinIn.useGenericMissionDataApp.value then
    if self.pinIn.value.value then
      guihooks.trigger('SetGenericMissionData',{
        title = "missions.missions.general.time",
        txt = self.pinIn.value.value,
        category = "cornerTimer_virtual",
        style = "time",
        order = 100,
      })
    else
      guihooks.trigger('SetGenericMissionData', {category = "cornerTimer_virtual", clear = true})
    end
    self.mgr.modules.ui.genericMissionDataChanged = true
  else
    if self.pinIn.value.value then
      raceTimeData.time = self.pinIn.value.value
      raceTimeData.timeColor = self.pinIn.color.value
	  raceTimeData.racemode = self.pinIn.raceMode.value
      guihooks.trigger('raceTime', raceTimeData)
    else
      guihooks.trigger('ScenarioResetTimer')
    end
  end
end


return _flowgraph_createNode(C)
