-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local im  = ui_imgui
local ime = ui_flowgraph_editor

local C = {}

C.name = 'ParkingMarkers BLR'
C.description = 'Creates Markers for a parking spot. (BLR PATCHED)'
C.category = 'repeat_instant'

C.author = 'BeamNG'
C.pinSchema = {
  { dir = 'in', type = 'flow', name = 'clear', description = "Triggering this will remove the markers.", impulse = true },
  { dir = 'in', type = 'number', name = 'vehId', description = "Id of the Vehicle to colour the markers." },
  { dir = 'in', type = 'vec3', name = 'position', description = "The position of this spot." },
  { dir = 'in', type = 'quat', name = 'rotation', description = "The rotation of this spot." },
  { dir = 'in', type = 'vec3', name = 'scale', description = "The scale of this spot." },
  { dir = 'in', type = 'bool', name = 'onlyForward', hidden = true, default = false, hardcoded = true, description = "If the vehicle can only park forward.." },
  { dir = 'in', type = 'bool', name = 'visibleMarkers', hidden = true, default = true, hardcoded = true, description = "Show visible markers." },
  { dir = 'in', type = 'bool', name = 'staticMarkers', hidden = true, default = false, hardcoded = true, description = "If true, markers are not aligned to terrain." },
  { dir = 'in', type = 'number', name = 'stop_timer', hidden = true, hardcoded = true, default = 1, description = "Time until a vehicle is considered parked." },
  { dir = 'in', type = 'color', name = 'color_out', hidden = true, hardcoded = true, default = { 1, 0, 0, 1 }, description = "Color when Inside" },
  { dir = 'in', type = 'color', name = 'color_in', hidden = true, hardcoded = true, default = { 1, 0.5, 0, 1 }, description = "Color when Outside" },
  { dir = 'out', type = 'flow', name = 'inside', description = "Outflow for this node." },
  {dir = 'out', type = 'flow', name = 'outside', description = "Outflow for this node."},
  {dir = 'out', type = 'flow', name = 'partlyInside', description = "Outflow for this node."},
  {dir = 'out', type = 'flow', name = 'stopped', description = "Outflow when the vehicle does not move for stop_timer seconds. (defaults to 1)"},
  {dir = 'out', type = 'flow', name = 'stopping', description = "When the vehicle is currently stopping.", hidden=true},
  {dir = 'out', type = 'number', name = 'stoppedPercent', description = "How much time has passed to stop the vehicle.", hidden=true},
  { dir = 'out', type = 'number', name = 'dotAngle', description = "Alignment of the Vehicle. 1 is perfectly aligned, 0 is right angle." },
  { dir = 'out', type = 'bool', name = 'forward', description = "True if the vehicle is parked forward, false if it is parked backwards." },
  { dir = 'out', type = 'number', name = 'sideDistance', description = "Distance in the left/right direction from the vehicle center to the position in." },
  { dir = 'out', type = 'number', name = 'forwardDistance', description = "Distance in the front/back direction from the vehicle center to the position in." },
  { dir = 'out', type = 'number', name = 'sideDistanceRelative', description = "left/right direction from the vehicle center to the position in." , hidden=true},
  { dir = 'out', type = 'number', name = 'forwardDistanceRelative', description = "front/back direction from the vehicle center to the position in.", hidden=true },
}
C.color = ui_flowgraph_editor.nodeColors.scene
C.icon = ui_flowgraph_editor.nodeIcons.scene
C.tags = { 'parking markers blr', }
local markerIndexCorrection = { { 3, 4, 2, 1 }, { 1, 2, 4, 3 } }
local zerosTable3 = {0,0,0}
local onesTable3 = {1,1,1}
local zerosTable4 = {0,0,0,0}
local vecX = vec3(1,0,0)
local vecY = vec3(0,1,0)
local vecZ = vec3(0,0,1)

C.legacyPins = {
  _in = {
    reset = 'clear'
  }
}

function C:init(mgr, ...)
  self.triggerName = nil
  self.oldPos = nil
  self.oldScl = nil
  self.data.debug = false
  self.triggerObj = nil
  self.markerObjects = {}
  self.stopTimer = 1
end

function C:_executionStarted()
  self.stopTimer = 1
  self._changed = true
end

function C:_executionStopped()
  self.stopTimer = 1
  self._changed = true
  if not self.triggerName then return end
  local checkPoint = scenetree[self.triggerName]
  if checkPoint then
    if editor and editor.onRemoveSceneTreeObjects then
      editor.onRemoveSceneTreeObjects({checkPoint:getId()})
    end
    checkPoint:delete()
    self.triggerName = nil
    self.oldPos = nil
    self.oldScl = nil
    self.oldRot = nil
    self.triggerObj = nil
  end
  for _, obj in ipairs(self.markerObjects) do
    if editor and editor.onRemoveSceneTreeObjects then
      editor.onRemoveSceneTreeObjects({obj:getId()})
    end
    obj:delete()
  end
  table.clear(self.markerObjects)
end

function C:onClientEndMission()
  self:_executionStopped()
end


function C:work(args)
  if self.pinIn.clear.value then
    self:_executionStopped()
    for _, p in pairs(self.pinOut) do p.value = nil end
  end
  if self.pinIn.flow.value then
    self:manageTrigger()
    self:updateMarkerPositions()
    self:checkParking()
  end
end

local function setLinear4F(linear4F, values)
  linear4F.x = values[1]
  linear4F.y = values[2]
  linear4F.z = values[3]
  linear4F.w = values[4] or 1
end

local tpos = vec3()
local sc = vec3()
local tr = quat()
local defaultClrIn = {1,0.5,0,1}
local defaultClrOut = {1,0,0,1}
local markerColor = ColorF(1,1,1,1):asLinear4F()

function C:checkParking()
  local veh
  if self.pinIn.vehId.value then
    veh = scenetree.findObjectById(self.pinIn.vehId.value)
  else
    veh = be:getPlayerVehicle(0)
  end
  if not veh then return end
  local vehicleData = map.objects[veh:getId()]

  tpos:setFromTable(self.pinIn.position.value or zerosTable3)
  sc:setFromTable(self.pinIn.position.value or onesTable3)

  local ob = veh:getSpawnWorldOOBB()
  local vDirVec=veh:getDirectionVector()
  local rotationValues = self.pinIn.rotation.value or zerosTable4
  tr:set(rotationValues[1], rotationValues[2], rotationValues[3], rotationValues[4])
  local yVec = tr * vecY

  local trigger = Sim.upcast(self.triggerObj)
  local front = ((vDirVec:dot(yVec) > 0) and 1 or 0) + 1
  self.pinOut.inside.value = true
  self.pinOut.partlyInside.value = false
  local contained = false
  local clrIn = self.pinIn.color_in.value or defaultClrIn
  local clrOut = self.pinIn.color_out.value or defaultClrOut

  vDirVec:normalize()
  local zVec, yVec, xVec = tr*vecZ, tr*vecY, tr*vecX
  local fwdAligned = vDirVec:projectToOriginPlane(zVec); fwdAligned:normalize()
  self.pinOut.dotAngle.value = math.abs(fwdAligned:dot(yVec))
  self.pinOut.forward.value = fwdAligned:dot(yVec) > 0

  for i = 0, 3 do
    contained = trigger:isPointContained(ob:getPoint(i*2))
      and trigger:isPointContained(ob:getPoint(i*2+1))
      and (self.pinIn.onlyForward.value and (fwdAligned:dot(yVec) > 0) or (not self.pinIn.onlyForward.value))
    local clr = contained and clrIn or clrOut
    if self.pinIn.visibleMarkers.value then
      setLinear4F(markerColor, clr)
      self.markerObjects[markerIndexCorrection[front][i+1]].instanceColor = markerColor
    end
    self.pinOut.inside.value = self.pinOut.inside.value and contained
    self.pinOut.partlyInside.value = self.pinOut.partlyInside.value or contained
  end

  if self.pinIn.onlyForward.value and self.pinIn.visibleMarkers.value then
    local rot = quat(self.pinIn.rotation.value)
    local x, y = rot * vec3(1,0,0), rot * vec3(0,1,0)
    local scl = vec3(self.pinIn.scale.value or {1,1,1})
    local d = scl.x*0.5-1
    local w = scl.y*0.5-1
    local pos = (tpos-x*d-y*w)
    local a = vec3(castRay(pos+vec3(0,0,2), pos-vec3(0,0,10)).pt) + vec3(0,0,0.3)
    pos = (tpos+x*d-y*w)
    local b = vec3(castRay(pos+vec3(0,0,2), pos-vec3(0,0,10)).pt)+ vec3(0,0,0.3)
    pos = (tpos+y*w)
    local c = vec3(castRay(pos+vec3(0,0,2), pos-vec3(0,0,10)).pt)+ vec3(0,0,0.3)
    local clr = clrIn
    if not contained then
      clr = clrOut
    end
    debugDrawer:drawTriSolid(
      b,
      a,
      c,
      ColorI(clr[1]*255,clr[2]*255,clr[3]*255,64))
  end

  local bbCenter = ob:getCenter()
  local alignedOffset = (bbCenter - tpos):projectToOriginPlane(zVec)
  self.pinOut.sideDistance.value = math.abs(alignedOffset:dot(xVec))
  self.pinOut.forwardDistance.value = math.abs(alignedOffset:dot(yVec))

  self.pinOut.sideDistanceRelative.value = math.abs(alignedOffset:dot(xVec)) / sc.x
  self.pinOut.forwardDistanceRelative.value = math.abs(alignedOffset:dot(yVec)) / sc.y

  self.pinOut.stopping.value = false
  if self.pinOut.inside.value and vehicleData.vel:length() <= 0.075 then
    self.stopTimer = self.stopTimer-self.mgr.dtSim
    self.pinOut.stoppedPercent.value = 1-clamp(self.stopTimer / (self.pinIn.stop_timer.value or 1), 0, 1)
    self.pinOut.stopping.value = true
  else
    self.stopTimer = self.pinIn.stop_timer.value or 1
    self.pinOut.stopping.value = false
    self.pinOut.stoppedPercent.value = 0
  end
  self.pinOut.stopped.value = self.stopTimer < 0
  if self.stopTimer < 0 then
    self.pinOut.stopping.value = false
  end
  self.pinOut.outside.value = not self.pinOut.inside.value
end


function C:drawCustomProperties()
  local reason = nil
  return reason
end

function C:drawMiddle(builder, style)
  builder:Middle()
  if self.data.filterName ~= "" then
    im.Text("Trigger Name")
    ui_flowgraph_editor.tooltip("Trigger Name: " .. tostring(self.triggerName))
  end
end

function C:createCornerMarker(markerName)
  local marker =  createObject('TSStatic')
  marker:setField('shapeName', 0, "art/shapes/interface/position_marker.dae")
  marker:setPosition(vec3(0, 0, 0))
  marker.scale = vec3(1, 1, 1)
  marker:setField('rotation', 0, '1 0 0 0')
  marker.useInstanceRenderData = true
  marker:setField('instanceColor', 0, '1 1 1 0')
  marker:setField('collisionType', 0, "Collision Mesh")
  marker:setField('decalType', 0, "Collision Mesh")
  marker:setField('playAmbient', 0, "1")
  marker:setField('allowPlayerStep', 0, "1")
  marker:setField('canSave', 0, "0")
  marker:setField('canSaveDynamicFields', 0, "1")
  marker:setField('renderNormals', 0, "0")
  marker:setField('meshCulling', 0, "0")
  marker:setField('originSort', 0, "0")
  marker:setField('forceDetail', 0, "-1")
  marker.canSave = false
  marker:registerObject(markerName)
  if scenetree and scenetree.MissionGroup then
    scenetree.MissionGroup:addObject(marker)
  end
  return marker
end

function C:createMarkers()
  for i = 0, 3 do
    local name = "rectMarker_" .. tostring(os.time()) .. "_" .. self.id .. "_" .. i
    table.insert(self.markerObjects, self:createCornerMarker(name))
  end
end
local qOff = quatFromEuler(0,0,math.pi/2)*quatFromEuler(0,math.pi/2,math.pi/2)
function C:updateMarkerPositions()
  if not self._changed then return end
  local tpos = vec3(self.pinIn.position.value or zerosTable3)
  local pos = vec3(0,0,0)
  local tr = self.pinIn.rotation.value or zerosTable4
  tr = quat(tr[1],tr[2],tr[3],tr[4])
  local scl = vec3(self.pinIn.scale.value or {1,1,1})

  local r
  local zVec,yVec,xVec = tr*vec3(0,0,1), tr*vec3(0,1,0), tr*vec3(1,0,0)

  local d = scl.x*0.5
  local w = scl.y*0.5
  -- local bext = ob:getHalfExtents()
  -- if bext.x*1.25 < d then d = bext.x*1.25 end
  -- if bext.y*1.25 < w then w = bext.y*1.25 end
  local corner, found, hit
  for k,marker in pairs(self.markerObjects)do

    if k == 1 then --top left
      corner = (tpos-xVec*d+yVec*w)
      r = quatFromEuler(0, 0, math.rad(90))
    elseif k == 2 then --Top Right
      corner = (tpos+xVec*d+yVec*w)
      r = quatFromEuler(0, 0, math.rad(180))
    elseif k == 3 then --Bottom Right
      corner = (tpos+xVec*d-yVec*w)
      r = quatFromEuler(0, 0, math.rad(270))
    elseif k == 4 then --Botton Left
      corner = (tpos-xVec*d-yVec*w)
      r =  quatFromEuler(0, 0, 0)
    end
    found = false
    hit = nil
    if not self.pinIn.staticMarkers.value then
      for i = 1, scl.z do
        if not hit then
          hit = Engine.castRay((corner+zVec*i), (corner-zVec*i*2), true, false)
          if hit then
            found = true
            i = scl.z+1
          end
        end
      end
      if not hit then
        hit = {pt = (pos-zVec*scl.z*2), norm = zVec:normalized()}
      end
      pos = vec3(hit.pt) + zVec*0.05
      r =   r* qOff*quatFromDir(vec3(hit.norm), yVec)
    else
      pos = corner + zVec*0.05
      r = r*qOff *quatFromDir(zVec, yVec)
    end
    marker:setPosRot(pos.x, pos.y, pos.z, r.x,r.y,r.z,r.w)
    marker:setField('instanceColor', 0, "1 0 0 1")
  end

end

function C:manageTrigger()
  if self.triggerName == nil then
    --create Trigger
    local name = "rectMarkerTrigger_" .. tostring(os.time()) .. "_" .. self.id
    local checkPoint = createObject('BeamNGTrigger')
    checkPoint.loadMode = 1
    checkPoint:setField("triggerType", 0, "Box")
    checkPoint:registerObject(name)
    checkPoint.debug = self.data.debug
    local pos = self.pinIn.position.value or zerosTable3
    pos = vec3(pos[1],pos[2],pos[3])
    checkPoint:setPosition(pos)
    self.oldPos = self.pinIn.position.value

    local scl = self.pinIn.scale.value or {1,1,1}
    scl = vec3(scl[1],scl[2],scl[3])

    checkPoint:setScale(scl)
    self.oldScl = self.pinIn.scale.value

    local rot = self.pinIn.rotation.value or zerosTable4
    rot = quat(rot[1],rot[2],rot[3],rot[4])
    rot = rot:toTorqueQuat()
    checkPoint:setField('rotation', 0, rot.x .. ' ' .. rot.y .. ' ' .. rot.z .. ' ' .. rot.w)
    self.oldRot = self.pinIn.rotation.value

    self.triggerName = name
    self.triggerObj = checkPoint
    if self.pinIn.visibleMarkers.value then
      self:createMarkers()
    end
    self._changed = true
  else
    self._changed = false
    if self.pinIn.position.value and self.oldPos then
      if self.oldPos[1] ~= self.pinIn.position.value[1] or self.oldPos[2] ~= self.pinIn.position.value[2] or self.oldPos[3] ~= self.pinIn.position.value[3] then
        local checkPoint = self.triggerObj
        local pos = self.pinIn.position.value or zerosTable3
        pos = vec3(pos[1],pos[2],pos[3])
        checkPoint:setPosition(pos)
        self.oldPos = self.pinIn.position.value
        self._changed = true
      end
    end
    if self.pinIn.scale.value and self.oldScl then
      if self.pinIn.scale.value ~= self.oldScl then
        local checkPoint = self.triggerObj
        local scl = self.pinIn.scale.value or {1,1,1}
        scl = vec3(scl[1],scl[2],scl[3])
        checkPoint:setScale(scl)
        self.oldScl = self.pinIn.scale.value
        self._changed = true
      end
    end
    if self.pinIn.rotation.value and self.oldRot then
      if self.pinIn.rotation.value ~= self.oldRot then
        local checkPoint = self.triggerObj
        local rot = self.pinIn.rotation.value or zerosTable4
        rot = quat(rot[1],rot[2],rot[3],rot[4])
        rot = rot:toTorqueQuat()
        checkPoint:setField('rotation', 0, rot.x .. ' ' .. rot.y .. ' ' .. rot.z .. ' ' .. rot.w)
        self.oldRot = self.pinIn.rotation.value
        self._changed = true
      end
    end

  end
end

function C:_onSerialize(res)

end

function C:_onDeserialized(res)

end

return _flowgraph_createNode(C)
