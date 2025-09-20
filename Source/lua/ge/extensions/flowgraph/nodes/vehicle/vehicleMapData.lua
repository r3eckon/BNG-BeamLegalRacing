-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- BEAMLR FIXED 

local im  = ui_imgui

local C = {}

C.name = 'Get Vehicle Data'
C.description = 'Provides vehicle position, direction, and other properties from the map object data.'
C.color = ui_flowgraph_editor.nodeColors.vehicle
C.icon = ui_flowgraph_editor.nodeIcons.vehicle
C.category = 'repeat_instant'

C.pinSchema = {
  { dir = 'in', type = 'number', name = 'vehId', default = 0, description = "Vehicle ID. If not present, player vehicle will be used." },
  { dir = 'out', type = 'vec3', name = 'position', description = "Vehicle refnode position." },
  { dir = 'out', type = 'vec3', name = 'dirVec', description = "Vehicle forward direction vector." },
  { dir = 'out', type = 'vec3', name = 'dirVecUp', hidden = true, description = "Vehicle up direction vector." },
  { dir = 'out', type = 'quat', name = 'rotation', hidden = true, description = "Vehicle object rotation." },
  { dir = 'out', type = 'number', name = 'velocity', description = "Velocity of the vehicle in m/s." },
  { dir = 'out', type = 'vec3', name = 'velocityVector', hidden = true, description = "Velocity vector of the vehicle." },
  { dir = 'out', type = 'bool', name = 'active', hidden = true, description = "True if the vehicle is active (visible versus invisible)." },
  { dir = 'out', type = 'number', name = 'damage', description = "Amount of damage (Not monetary value!)." },
  { dir = 'out', type = 'number', name = 'newAPIDamage', description = "Amount of damage with the new API" }
}

C.tags = {'telemetry', 'damage', 'velocity', 'position', 'direction', 'info'}

function C:init(mgr, ...)
end

local vehId, vehicleData
local vehQuat = quat()

function C:work(args)
  vehId = -1
  if self.pinIn.vehId.value then
    local veh = scenetree.findObjectById(self.pinIn.vehId.value)
    if veh then vehId = self.pinIn.vehId.value end
  else
    vehId = be:getPlayerVehicleID(0)
  end
  vehicleData = map.objects[vehId]
  if not vehId then return end

  if vehicleData then
    self.pinOut.active.value = vehicleData.active
    self.pinOut.newAPIDamage.value = scenetree.findObjectById(vehId):getSectionDamageSum()
    self.pinOut.damage.value = vehicleData.damage
    if self.pinOut.dirVec:isUsed() then
      self.pinOut.dirVec.value = vehicleData.dirVec:toTable()
    end
    if self.pinOut.dirVecUp:isUsed() then
      self.pinOut.dirVecUp.value = vehicleData.dirVecUp:toTable()
    end
    if self.pinOut.position:isUsed() then
      self.pinOut.position.value = vehicleData.pos:toTable()
    end
    if self.pinOut.velocityVector:isUsed() then
      self.pinOut.velocityVector.value = vehicleData.vel:toTable()
    end
    if self.pinOut.velocity:isUsed() then
      self.pinOut.velocity.value = vehicleData.vel:length()
    end
    if self.pinOut.rotation:isUsed() then 
	  -- BEAMLR FIX START
	  vehQuat:setFromDir(vehicleData.dirVec, vehicleData.dirVecUp)
      self.pinOut.rotation:valueSetQuat(vehQuat)
	  -- BEAMLR FIX END
    end
  end
end

return _flowgraph_createNode(C)
