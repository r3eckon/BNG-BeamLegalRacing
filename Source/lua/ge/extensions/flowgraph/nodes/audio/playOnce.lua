-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
-- BEAMLR EDITED TO ALLOW STOPPING LOOPED SOUNDS

local im = ui_imgui

local C = {}

C.name = 'Play Sound'
C.icon = "audiotrack"
C.description = 'Plays an audio sample.'
C.category = 'dynamic_p_duration' -- is by definition f_duration, but no feedback is possible atm
C.dynamicMode = 'repeat'

C.pinSchema = {

  { dir = 'in', type = 'string', name = 'file', default = 'event:UI_Checkpoint', description = 'Source for audio sample to play.' },
  { dir = 'in', type = 'string', name = 'channel', hidden = true, description = 'Channel to play audio on.' },

  { dir = 'in', type = 'number', name = 'volume', hidden = true, default = 1, hardcoded = true, description = 'Volume to play sound at.' },
  { dir = 'in', type = 'number', name = 'pitch', hidden = true, default = 1, hardcoded = true, description = 'Pitch to play sound in.' },
  { dir = 'in', type = 'number', name = 'fadeInTime', hidden = true, default = -1, hardcoded = true, description = 'Fade in time for sound.' },
  { dir = 'in', type = 'number', name = 'fadeOutTime', hidden = true, default = -1, hardcoded = true, description = 'Fade out time for sound.' },
  { dir = 'in', type = 'bool', name = 'unique', hidden = true, default = false, hardcoded = true, description = 'TODO' },

  { dir = 'out', type = 'number', name = 'sourceID', hidden = false, hardcoded = false, description = 'Source ID' }
  
}

C.legacyPins = {
  _in = {
    source = 'file'
  }
}

C.tags = { 'sound', 'audio', 'volume' }

function C:postInit()
  self.pinInLocal.file.allowFiles = {
    { "Json Prefab Files", ".prefab.json" },
  }

  self.pinInLocal.volume.numericSetup = {
    min = 0,
    max = 1,
    type = 'float',
    gizmo = 'slider',
  }
end

function C:workOnce()
  self:playSound()
end

function C:work()
  if self.dynamicMode == 'repeat' then
    self:playSound()
  end
end

function C:playSound()
  local data = {}
  data.volume = self.pinIn.volume.value or 1
  data.pitch = self.pinIn.pitch.value or 1
  data.fadeInTime = self.pinIn.fadeInTime.value or -1
  data.fadeOutTime = self.pinIn.fadeOutTime.value or -1
  data.unique = self.pinIn.unique.value or false

  data.sampleSource = self.pinIn.file.value or 'event:UI_Checkpoint'
  data.channel = self.pinIn.channel.value or 'AudioGui'

  local res = Engine.Audio.playOnce(data.channel, data.sampleSource, data)
  self.pinOut.sourceID.value = res.sourceId
end

return _flowgraph_createNode(C)
