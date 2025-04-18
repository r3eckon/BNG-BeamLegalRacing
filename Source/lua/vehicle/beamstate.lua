-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- BEAMLR EDITED

local M = {}

local max, min, floor = math.max, math.min, math.floor

M.damage = 0
M.damageExt = 0
M.lowpressure = false
M.deformGroupDamage = {}
M.deformGroupsTriggerBeam = {}

M.activeParts = {}

M.monetaryDamage = 0

M.nodeNameMap = {}
M.tagBeamMap = {}
M.linkTagBeamMap = {}

local partDamageData
local lastDisplayedDamage = 0

local delayedPrecompBeams
local delayedPrecompTorsionbar
local initTimer = 0

local collTriState = {}

local wheelBrokenBeams = {}

local beamDamageTracker = {}
local beamDamageTrackerDirty = false

local breakGroupCache = {}
local brokenBreakGroups = {}
local triangleBreakGroupCache = {}
local couplerBreakGroupCache = {}
local couplerBreakGroupCacheOrig = {}
local couplerCache = {}
local couplerTags = {}
local externalCouplerVisibilityTags

local autoCouplingActive = false
local autoCouplingTimer = 0
local autoCouplingTimeoutTimer = 0
local autoCouplingVisibleTags

local attachedCouplers = {}
local transmitCouplers = {}
local recievedElectrics = {}
local hasActiveCoupler = false
local skeletonStateTimer = 0.25

local beamBodyPartLookup = nil
local partBeams = nil
local invBodyPartBeamCount = nil
local bodyPartDamageTracker = nil

local planets = {}
local planetTimers = {}

local function setPartCondition(partName, partTypeData, odometer, integrity, visual)
  if type(integrity) == "number" then
    local integrityValue = integrity
    integrity = {
      jbeam = {}
    }
  -- local partBreakGroups = {}
  -- for _, partType in ipairs(partTypeData) do
  --   local split = split(partType, ":")
  --   if split[1] == "jbeam" and split[2] == "breakGroup" then
  --     local breakGroupName = split[3]
  --     table.insert(partBreakGroups, breakGroupName)
  --   end
  -- end

  -- local breakGroupCount = #partBreakGroups
  -- local numberOfBrokenBreakGroups = breakGroupCount * (1 - integrityValue)
  -- local wholeNumberOfBrokenBreakGroups = floor(numberOfBrokenBreakGroups)
  -- local shuffledBreakGroups = arrayShuffle(partBreakGroups)
  -- for i = 1, wholeNumberOfBrokenBreakGroups do
  --   table.insert(integrity.jbeam.brokenBreakGroups, shuffledBreakGroups[i])
  -- end
  end

  if type(visual) == "number" then
    visual = {
      jbeam = {}
    }
  end

  if visual and visual.jbeam and visual.jbeam.needsReplacement then
  --partCondition.setPartMeshColor(partName, 170, 160, 160, 255, 255, 255, 255, 255, 255, 255, 255, 255) -- make the part look primered
  end
end

local function getPartCondition(partName, partTypeData)
  local canProvideCondition = false
  local partCondition = {integrityValue = 1, integrityState = {}, visualValue = 1, visualState = {}}

  if partTypeData then
    local breakGroupCount = 0
    local brokenBreakGroupCount = 0
    local hasFlexbodies = false
    local hasDamageableBeams = false
    local damageableBeams = {}
    for _, partType in ipairs(partTypeData) do
      local split = split(partType, ":")
      if split[1] == "jbeam" then
        if split[2] == "breakGroup" then
          local breakGroupName = split[3]
          breakGroupCount = breakGroupCount + 1
          if brokenBreakGroups[breakGroupName] then
            brokenBreakGroupCount = brokenBreakGroupCount + 1
          end
        end
        if split[2] == "flexbody" then
          hasFlexbodies = true
        end
        if split[2] == "beamDamage" then
          table.insert(damageableBeams, tonumber(split[3]))
          hasDamageableBeams = true
        end
      end
    end
    if hasFlexbodies and (breakGroupCount > 0 or hasDamageableBeams) then
      local brokenBeamCount = 0
      local deformedBeamCount = 0
      for _, beamCid in ipairs(damageableBeams) do
        local beamDamage = beamDamageTracker[beamCid] or 0
        if beamDamage >= 0.01 then
          deformedBeamCount = deformedBeamCount + 1
        end
        if beamDamage >= 0.9 then
          brokenBeamCount = brokenBeamCount + 1
        end
      end
      --thresholds for when a part is considered too broken and needs replacements
      local tooMuchBeamDamage = deformedBeamCount > (#damageableBeams * 0.01)
      local tooManyBrokenBeams = brokenBeamCount > 2
      local tooManyBreakGroupsBroken = breakGroupCount > 0 and (brokenBreakGroupCount > 1 or (brokenBreakGroupCount == breakGroupCount))
      --print(string.format("%q: Breakgroups: %s, broken beams: %s/%s, deformed beams: %s/%s", partName, brokenBreakGroupCount, brokenBeamCount, #damageableBeams, deformedBeamCount, #damageableBeams))

      if tooManyBreakGroupsBroken or tooMuchBeamDamage or tooManyBrokenBeams then
        partCondition.visualState.needsReplacement = true
        partCondition.integrityValue = 0
        canProvideCondition = true
      end
    end
  end

  return partCondition, canProvideCondition
end

local function luaBreakBeam(id)
  beamDamageTracker[id] = 1
  beamDamageTrackerDirty = true
end

local function breakBreakGroup(g)
  if g == nil then
    return
  end

  brokenBreakGroups[g] = true

  -- hide props if they use
  props.hidePropsInBreakGroup(g)

  -- break all beams in that group
  local bg = breakGroupCache[g]
  if bg then
    breakGroupCache[g] = nil
    for _, bcid in ipairs(bg) do
      obj:breakBeam(bcid)
      luaBreakBeam(bcid)
    end
  end

  -- break all couplers
  bg = couplerBreakGroupCache[g]
  if bg then
    couplerBreakGroupCache[g] = nil
    for _, ccid in ipairs(bg) do
      obj:detachCoupler(ccid, math.huge)
    end
  end

  --break triangle breakgroups matching the beam breakgroup
  bg = triangleBreakGroupCache[g]
  if bg then
    for _, ctid in ipairs(bg) do
      obj:breakCollisionTriangle(ctid)
      collTriState[ctid] = nil
    end
    triangleBreakGroupCache[g] = nil
  end
end

local function breakMaterial(beam)
  material.switchBrokenMaterial(beam)

  local deformGroup = beam.deformGroup
  if deformGroup then
    if type(deformGroup) == "table" then
      for _, g in ipairs(deformGroup) do
        M.deformGroupsTriggerBeam[g] = M.deformGroupsTriggerBeam[g] or beam.cid
      end
    else
      M.deformGroupsTriggerBeam[deformGroup] = M.deformGroupsTriggerBeam[deformGroup] or beam.cid
    end
  end
end

local function broadcastCouplerVisibility(visibleTags)
  BeamEngine:queueAllObjectLua("beamstate.setCouplerVisiblityExternal(" .. tostring(obj:getId()) .. "," .. serialize(visibleTags) .. ")")
end

M.debugDraw = nop
local function debugDraw(focusPos)
  -- highlight all coupling nodes
  for _, coupler in pairs(couplerCache) do
    if not coupler.couplerLock and not coupler.couplerWeld and ((coupler.couplerTag and externalCouplerVisibilityTags[coupler.couplerTag]) or (coupler.tag and externalCouplerVisibilityTags[coupler.tag])) then
      obj.debugDrawProxy:drawNodeSphere(coupler.cid, 0.15, getContrastColor(stringHash(coupler.couplerTag or coupler.tag), 150))
    end
  end
end

local function setCouplerVisiblityExternal(sourceObjectID, visibleTags)
  externalCouplerVisibilityTags = nil
  if visibleTags then
    externalCouplerVisibilityTags = visibleTags
    M.debugDraw = debugDraw
  else
    M.debugDraw = nop
  end
end

local function activateAutoCoupling(_nodetag)
  if not hasActiveCoupler then
    return
  end
  local nodeTags
  local forwardToCouplingsExtension = true
  if type(_nodetag) == "string" then
    nodeTags = {[_nodetag] = true}
    forwardToCouplingsExtension = false
  elseif type(_nodetag) == "table" then
    nodeTags = {}
    for _, tag in ipairs(_nodetag) do
      nodeTags[tag] = true
    end
    forwardToCouplingsExtension = false
  end

  autoCouplingActive = true
  autoCouplingTimeoutTimer = 0
  autoCouplingTimer = 0

  local visibleTags
  if not nodeTags then
    visibleTags = {}
    for _, c in pairs(couplerCache) do
      if not c.couplerWeld and not c.couplerLock and c.couplerTag then
        visibleTags[c.couplerTag] = true
      end
    end
  else
    visibleTags = nodeTags
  end
  autoCouplingVisibleTags = visibleTags
  broadcastCouplerVisibility(visibleTags)
  if forwardToCouplingsExtension then
    extensions.couplings.onBeamstateActivateAutoCoupling()
  end
end

local function disableAutoCoupling()
  autoCouplingActive = false
  autoCouplingTimeoutTimer = 0
  autoCouplingTimer = 0
  autoCouplingVisibleTags = nil
  broadcastCouplerVisibility(false)
  extensions.couplings.onBeamstateDisableAutoLatching()
end

local function sendObjectCouplingChange()
  obj:queueGameEngineLua(string.format("onObjectCouplingChange(%s,%s)", objectId, serialize(attachedCouplers)))
end

local function attachCouplers(_nodetag)
  local nodetag = _nodetag or ""
  for _, val in pairs(couplerCache) do
    if (val.couplerWeld ~= true and val.couplerTag and (_nodetag == nil or val.couplerTag == nodetag)) and val.cid then
      obj:attachCoupler(val.cid, val.couplerTag or "", val.couplerStrength or 1000000, val.couplerRadius or 0.2, val.couplerLockRadius or 0.025, val.couplerLatchSpeed or 0.3, val.couplerTargets or 0)
    end
  end
end

local function couplerExists(_nodetag)
  return couplerTags[_nodetag]
end

local function detachCouplers(_nodetag, forceLocked, forceWelded)
  local nodetag = _nodetag or ""
  for _, val in pairs(couplerCache) do
    if ((val.couplerLock ~= true or forceLocked) and (val.couplerWeld ~= true or forceWelded) and val.couplerTag and (_nodetag == nil or val.couplerTag == nodetag)) and val.cid then
      obj:detachCoupler(val.cid, 0)
      obj:queueGameEngineLua(string.format("onCouplerDetach(%s,%s)", obj:getId(), val.cid))
    end
  end
  extensions.couplings.onBeamstateDetachCouplers()
end

local function isCouplerAttached(nodeTag)
  -- check for manual coupler
  for nid, c in pairs(couplerCache) do
    if not c.couplerWeld and not c.couplerLock and c.couplerTag and (nodeTag == nil or c.couplerTag == nodeTag) then
      if attachedCouplers[nid] ~= nil then
        return true
      end
    end
  end

  -- relaxed check
  --we need to be careful with couplers within the same vehicle here, in the attached method we transfer the locked/welded meta data from primary to secondary couplers,
  --otherwise we'd detect the secondary one as "attached" here even if it's locked or welded
  for nid, _ in pairs(attachedCouplers) do
    if couplerCache[nid] and not couplerCache[nid].couplerWeld and not couplerCache[nid].couplerLock and (nodeTag == nil or couplerCache[nid].couplerTag == nodeTag) then
      return true
    end
  end

  return false
end

-- this is called on keypress (L)
local function toggleCouplers(_nodetag, forceLocked, forceWelded, forceAutoCoupling)
  if not _nodetag or (_nodetag and forceAutoCoupling) then
    local externalAutoCouplingActive = extensions.couplings.isAutoCouplingActive()
    if autoCouplingActive or externalAutoCouplingActive then
      obj:stopLatching()
      disableAutoCoupling()
    else
      local externalIsCouplerAttached = extensions.couplings.isCouplerAttached()
      if (isCouplerAttached() or externalIsCouplerAttached) and not _nodetag then
        detachCouplers()
      else
        activateAutoCoupling(_nodetag)
      end
    end
  else
    local isAttached = false
    for cid, coupler in pairs(couplerCache) do
      if coupler.couplerTag == _nodetag then
        isAttached = isAttached or attachedCouplers[cid] ~= nil
      end
    end

    if isAttached then
      detachCouplers(_nodetag, forceLocked, forceWelded)
    else
      attachCouplers(_nodetag)
    end
  end
end

local function couplerFound(nodeId, obj2id, obj2nodeId)
  --print(string.format("coupler found %s.%s->%s.%s", obj:getId(), nodeId, obj2id, obj2nodeId))
end

--this is called twice by electrics.lua, once before all the rest of vlua gfx runs and once after.
--The first call passes true as the "retainReceivedElectrics" param so that we still have our electrics for the second call.
--"retainReceivedElectrics" param is chosen in this particular way to maintain backwards compat with possible other code not under our control
local function updateRemoteElectrics(retainReceivedElectrics)
  for i = 1, #recievedElectrics do
    tableMerge(electrics.values, recievedElectrics[i])
  end
  if not retainReceivedElectrics then
    table.clear(recievedElectrics)
  end
end

local function sendExportCouplerData(obj2Id, obj2nodeId, data)
  obj:queueObjectLuaCommand(obj2Id, "beamstate.exportCouplerData(" .. tostring(obj2nodeId) .. ", " .. serialize(data) .. ")")
  M.updateRemoteElectrics = updateRemoteElectrics
end

local function onCouplerAttached(nodeId, obj2id, obj2nodeId, attachSpeed, attachEnergy)
  --check if we are dealing with couplers within the same vehicle
  local sameId = objectId == obj2id
  local sameTag = couplerCache[nodeId] and couplerCache[obj2nodeId] and (couplerCache[obj2nodeId].tag == couplerCache[nodeId].couplerTag)
  if sameId and sameTag then
    --if we do, we need to make sure that both the primary and the secondary coupler have the same lock/welded meta data
    --without this, the secondary coupler will be detected as "attached" even though it's supposed to be ignored if locked/welded
    couplerCache[obj2nodeId].couplerLock = couplerCache[obj2nodeId].couplerLock or couplerCache[nodeId].couplerLock
    couplerCache[obj2nodeId].couplerWeld = couplerCache[obj2nodeId].couplerWeld or couplerCache[nodeId].couplerWeld
  end

  if autoCouplingActive and (couplerCache[nodeId] and autoCouplingVisibleTags and autoCouplingVisibleTags[couplerCache[nodeId].couplerTag]) then
    disableAutoCoupling()
  end
  attachedCouplers[nodeId] = transmitCouplers[nodeId] or {}
  attachedCouplers[nodeId].obj2id = obj2id
  attachedCouplers[nodeId].obj2nodeId = obj2nodeId

  -- figure out the electrics state
  local n = v.data.nodes[nodeId]
  if n and (n.importElectrics or n.importInputs) then
    local data = {electrics = n.importElectrics, inputs = n.importInputs}
    --print("couplerAttached -> beamstate.exportCouplerData("..tostring(obj2nodeId)..", "..serialize(data)..")")
    -- obj:queueObjectLuaCommand(obj2id, "beamstate.exportCouplerData(" .. tostring(obj2nodeId) .. ", " .. serialize(data) .. ")")
    -- M.updateRemoteElectrics = updateRemoteElectrics
    sendExportCouplerData(obj2id, obj2nodeId, data)
  end

  local breakGroups = type(n.breakGroup) == "table" and n.breakGroup or {n.breakGroup}
  for _, g in pairs(breakGroups) do
    couplerBreakGroupCache[g] = couplerBreakGroupCacheOrig[g]
  end

  --print(string.format("coupler attached %s.%s->%s.%s", obj:getId(),nodeId,obj2id, obj2nodeId))
  if objectId < obj2id then
    obj:queueGameEngineLua(string.format("onCouplerAttached(%s,%s,%s,%s)", objectId, obj2id, nodeId, obj2nodeId))
  end
end

local function onCouplerDetached(nodeId, obj2id, obj2nodeId)
  --print(string.format("coupler detached %s.%s->%s.%s", obj:getId(),nodeId,obj2id, obj2nodeId))
  attachedCouplers[nodeId] = nil
  transmitCouplers[nodeId] = nil

  local n = v.data.nodes[nodeId]
  if n.breakGroup and (n.breakGroupType == 0 or n.breakGroupType == nil) then
    if type(n.breakGroup) ~= "table" and couplerBreakGroupCache[n.breakGroup] == nil then
      -- shortcircuit in case of broken single breakGroup
    else
      local breakGroups = type(n.breakGroup) == "table" and n.breakGroup or {n.breakGroup}
      for _, g in pairs(breakGroups) do
        breakBreakGroup(g)
      end
    end
  end

  if objectId < obj2id then
    obj:queueGameEngineLua(string.format("onCouplerDetached(%s,%s,%s,%s)", objectId, obj2id, nodeId, obj2nodeId))
  end
end

local function getCouplerOffset(couplerTag)
  if not v.data.nodes then
    return {}
  end
  local refPos = v.data.nodes[v.data.refNodes[0].ref].pos
  local couplerOffset = {}
  for _, c in pairs(couplerCache) do
    if c.couplerTag == couplerTag or c.tag == couplerTag or couplerTag == "" or not couplerTag then
      local pos = v.data.nodes[c.cid].pos
      couplerOffset[c.cid] = {x = pos.x - refPos.x, y = pos.y - refPos.y, z = pos.z - refPos.z, couplerTag = c.couplerTag, tag = c.tag}
    end
  end
  return couplerOffset
end

-- called from the vehicle that wants to import electrics
local function exportCouplerData(nodeid, dataList)
  --print(obj:getId() .. "<-exportCouplerData(" .. nodeid .. "," .. dumps(dataList) .. ")")
  transmitCouplers[nodeid] = attachedCouplers[nodeid] or {}

  --merge possibly existing electrics/inputs with the newly requested ones. This is necessary if external systems require syncing that isn't defined in jbeam directly
  transmitCouplers[nodeid].exportElectrics = transmitCouplers[nodeid].exportElectrics or {}
  for _, electric in ipairs(dataList.electrics or {}) do
    table.insert(transmitCouplers[nodeid].exportElectrics, electric)
  end

  transmitCouplers[nodeid].exportInputs = transmitCouplers[nodeid].exportInputs or {}
  for _, input in ipairs(dataList.inputs or {}) do
    table.insert(transmitCouplers[nodeid].exportInputs, input)
  end
end

-- called by the host that provides the electrics
local function importCouplerData(nodeId, data)
  --print(obj:getId() .. "<-importCouplerData(" .. nodeId .. "," .. dumps(data) .. ")")

  --If we are not connected anymore to the vehicle that this data came from, we need to ignore it.
  --This is very important as the coupler detach can be broadcasted _before_ queued data from the other vehicle can reach this one.
  --In some systems that do cleanup work in the detach event, this stray data can cause havoc, so here we ignore it.
  if not attachedCouplers[nodeId] then
    table.clear(recievedElectrics)
    return
  end

  if data.electrics then
    table.insert(recievedElectrics, data.electrics)
  end
  if data.inputs then
    for k, v in pairs(data.inputs) do
      input.event(k, v, 2)
    end
  end
end

local function sendUISkeletonState()
  if not playerInfo.firstPlayerSeated then
    return
  end
  guihooks.trigger("VehicleSkeletonState", beamDamageTracker)
end

local function deflateTire(wheelid)
  local wheel = v.data.wheels[wheelid]
  M.lowpressure = true

  local brokenBeams = wheelBrokenBeams[wheelid] or 1
  local pressureGroupPressure = 200000
  if wheel.pressureGroup ~= nil then
    if v.data.pressureGroups[wheel.pressureGroup] ~= nil then
      pressureGroupPressure = obj:getGroupPressure(v.data.pressureGroups[wheel.pressureGroup])

      if brokenBeams > 4 then
        obj:deflatePressureGroup(v.data.pressureGroups[wheel.pressureGroup])
        obj:changePressureGroupDrag(v.data.pressureGroups[wheel.pressureGroup], 0)
      elseif brokenBeams == 1 then
        obj:setGroupPressure(v.data.pressureGroups[wheel.pressureGroup], (0.1 * 6894.757 + 101325))
      end
    end
  end

  if brokenBeams == 1 then
    if wheels.wheels[wheelid] then
      wheels.wheels[wheelid].isTireDeflated = true
    end
    guihooks.message({txt = "vehicle.beamstate.tireDeflated", context = {wheelName = wheel.name}}, 5, "vehicle.damage.deflated." .. wheel.name)
    damageTracker.setDamage("wheels", "tire" .. wheel.name, true)
    extensions.hook("onTireDeflated", wheelid)

    local tireBurstVolume = linearScale(pressureGroupPressure, 0, 1000000, 0, 1)
    local tireBurstColor = wheels.wheels[wheelid] and linearScale(wheels.wheels[wheelid].tireVolume, 0, 1, 0, 5) or 0
    obj:playSFXOnceCT("event:>Vehicle>Failures>tire_burst", wheel.node1, tireBurstVolume, 1, tireBurstColor, 0)

    M.damageExt = M.damageExt + 1000
    if wheel.treadNodes ~= nil and wheel.treadBeams ~= nil then
      for _, nodecid in pairs(wheel.treadNodes) do
        local frictionCoef = v.data.nodes[nodecid].frictionCoef
        local slidingFrictionCoef = v.data.nodes[nodecid].slidingFrictionCoef
        if frictionCoef then
          local rnd1, rnd2 = math.random(20, 50), math.random(25, 60)
          obj:setNodeFrictionSlidingCoefs(nodecid, frictionCoef * rnd1 * 0.01, (slidingFrictionCoef or frictionCoef) * rnd2 * 0.01)
        end
      end

      for _, beamcid in pairs(wheel.treadBeams) do
        obj:setBeamSpringDamp(beamcid, v.data.beams[beamcid].beamSpring * 0.1, 2, -1, -1)
      end
    end

    if wheel.sideBeams ~= nil then
      for _, beamcid in pairs(wheel.sideBeams) do
        obj:setBeamSpringDamp(beamcid, 0, 10, -1, -1)
      end
    end

    if wheel.peripheryBeams ~= nil then
      for _, beamcid in pairs(wheel.peripheryBeams) do
        obj:setBeamSpringDamp(beamcid, v.data.beams[beamcid].beamSpring * 0.1, 2, -1, -1)
      end
    end

    if wheel.reinfBeams ~= nil then
      for _, beamcid in pairs(wheel.reinfBeams) do
        obj:setBeamSpringDamp(beamcid, 0, 0.7, 0, 0)
      end
    end

    if wheel.pressuredBeams ~= nil then
      for _, beamcid in pairs(wheel.pressuredBeams) do
        obj:setBeamPressureRel(beamcid, 0, math.huge, -1, -1)
      end
    end
  end

  wheelBrokenBeams[wheelid] = brokenBeams + 1
end

local function delPlanetI(i)
  local pe = #planets - 4
  for j = 0, 4 do
    planets[i + j] = planets[pe + j]
  end
  for j = 1, 5 do
    table.remove(planets)
  end

  for j = 1, #planetTimers do
    if planetTimers[j][1] == i then
      if planetTimers[#planetTimers][1] == pe then
        planetTimers[j][2] = planetTimers[#planetTimers][2]
        table.remove(planetTimers)
      else
        table.remove(planetTimers, j)
      end
      break
    end
  end
end

local function delPlanet(center, radius, mass)
  for i = 1, #planets - 4, 5 do
    if planets[i] == center.x and planets[i + 1] == center.y and planets[i + 2] == center.z and planets[i + 3] == radius and planets[i + 4] == mass then
      delPlanetI(i)
      obj:setPlanets(planets)
      break
    end
  end
end

local function addPlanet(center, radius, mass, dt)
  if dt ~= nil then
    for pt = 1, #planetTimers do
      local i = planetTimers[pt][1]
      if planets[i] == center.x and planets[i + 1] == center.y and planets[i + 2] == center.z and planets[i + 3] == radius and planets[i + 4] == mass then
        if dt == 0 then
          delPlanetI(i)
          obj:setPlanets(planets)
        else
          planetTimers[pt][2] = dt
        end
        return
      end
    end

    if dt == 0 then
      return
    end
    table.insert(planetTimers, {#planets + 1, dt})
  end
  table.insert(planets, center.x)
  table.insert(planets, center.y)
  table.insert(planets, center.z)
  table.insert(planets, radius)
  table.insert(planets, mass)
  obj:setPlanets(planets)
end

local function setPlanets(p)
  table.clear(planets)
  table.clear(planetTimers)
  for i = 1, #p - 2, 3 do
    table.insert(planets, p[i].x)
    table.insert(planets, p[i].y)
    table.insert(planets, p[i].z)
    table.insert(planets, p[i + 1])
    table.insert(planets, p[i + 2])
  end
  obj:setPlanets(planets)
end

local function updateGFX(dt)
  -- Planet timers
  local pEnd = #planetTimers
  local i = 1
  while i <= pEnd do
    local t = planetTimers[i][2]
    t = t - dt
    if t <= 0 then
      delPlanetI(i)
      pEnd = pEnd - 1
      obj:setPlanets(planets)
    else
      planetTimers[i][2] = t
      i = i + 1
    end
  end

  -- Damage
  M.damage = obj:getDissipatedEnergy() + M.damageExt

  local damageSum = 0
  for k, partData in pairs(partDamageData) do
    local partValue = partData.value
    local brokenCoef = clamp(partData.beamsBroken / partData.brokenBeamsThreshold, 0, 1)
    local deformedCoef = (clamp(partData.beamsDeformed / partData.deformedBeamsThreshold, 0, 1))
    local damageCoef = max(brokenCoef, deformedCoef)
    damageSum = damageSum + partValue * damageCoef
  end
  if damageSum > lastDisplayedDamage * 1.05 then
    --guihooks.message(string.format("Car Damage: $%.2f", damageSum), 5, "vehicle.damageSum")
    lastDisplayedDamage = damageSum
  end

  if beamDamageTrackerDirty then
    skeletonStateTimer = skeletonStateTimer - dt
    if skeletonStateTimer < 0 then
      sendUISkeletonState()
      skeletonStateTimer = 0.25
      beamDamageTrackerDirty = false
    end
  end

  if autoCouplingActive then
    autoCouplingTimeoutTimer = autoCouplingTimeoutTimer + dt
    if autoCouplingTimeoutTimer > 60 then
      disableAutoCoupling()
    end
    autoCouplingTimer = (autoCouplingActive and autoCouplingTimer <= 0.5) and autoCouplingTimer + dt or 0
    if autoCouplingTimer > 0.5 then
      for nodeTag, _ in pairs(autoCouplingVisibleTags) do
        attachCouplers(nodeTag)
      end
    end
  end

  -- transmit data
  for _, coupler in pairs(transmitCouplers) do
    if coupler.obj2id then
      local data = {}
      if coupler.exportElectrics then
        data.electrics = {}
        for _, v in pairs(coupler.exportElectrics) do
          data.electrics[v] = electrics.values[v]
        end
      end
      if coupler.exportInputs then
        data.inputs = {}
        for _, v in pairs(coupler.exportInputs) do
          data.inputs[v] = electrics.values[v] or input[v]
        end
      end
      obj:queueObjectLuaCommand(coupler.obj2id, string.format("beamstate.importCouplerData(%s, %s)", coupler.obj2nodeId, serialize(data)))
    end
  end
end

M.update = nop
local function update(dtSim)
  local finished_precomp = true
  initTimer = initTimer + dtSim
  if delayedPrecompBeams then
    for _, b in ipairs(delayedPrecompBeams) do
      local tratio = initTimer / b.beamPrecompressionTime
      finished_precomp = finished_precomp and tratio >= 1
      obj:setPrecompressionRatio(b.cid, 1 + (b.beamPrecompression - 1) * min(tratio, 1))
    end
  end

  if delayedPrecompTorsionbar then
    for _, t in ipairs(delayedPrecompTorsionbar) do
      local tratio = initTimer / t.precompressionTime
      finished_precomp = finished_precomp and tratio >= 1
      obj:setTorsionbarPrecompressionAngle(t.cid, t.precompressionAngle * min(tratio, 1))
    end
  end

  if finished_precomp then
    M.update = nop
    delayedPrecompBeams = nil
    delayedPrecompTorsionbar = nil
    updateCorePhysicsStepEnabled()
  end
end

local function registerExternalCouplerBreakGroup(breakGroup, cid)
  couplerBreakGroupCache[breakGroup] = couplerBreakGroupCache[breakGroup] or {}
  table.insert(couplerBreakGroupCache[breakGroup], cid)
end

local function beamBroken(id, energy)
  --beamDamageTracker[id] = 0
  --beamDamageTrackerDirty = true

  local bodyPart = beamBodyPartLookup[id]
  if bodyPart then
    bodyPartDamageTracker[bodyPart] = bodyPartDamageTracker[bodyPart] + 1
    local damage = bodyPartDamageTracker[bodyPart] * invBodyPartBeamCount[bodyPart]
    if damage > 0.001 then
      damageTracker.setDamage("body", bodyPart, damage)
    end
  end

  luaBreakBeam(id)
  if v.data.beams[id] ~= nil then
    local beam = v.data.beams[id]
    if beam.partOrigin and partDamageData[beam.partOrigin] then
      partDamageData[beam.partOrigin].beamsBroken = partDamageData[beam.partOrigin].beamsBroken + 1
    end

    -- Check for punctured tire
    if beam.wheelID ~= nil then
      deflateTire(beam.wheelID)
    elseif beam.pressureGroupId then
      obj:deflatePressureGroup(v.data.pressureGroups[beam.pressureGroupId])
    end

    -- Break coll tris
    if beam.collTris and not beam.disableTriangleBreaking then --allow beams to disable triangle breaking
      for _, ctid in ipairs(beam.collTris) do
        if collTriState[ctid] then
          collTriState[ctid] = collTriState[ctid] - 1
          if collTriState[ctid] <= 1 or beam.wheelID then
            obj:breakCollisionTriangle(ctid)
          end
        end
      end
    end

    -- Break the meshes
    if beam.disableMeshBreaking == nil or not beam.disableMeshBreaking then
      obj:breakMeshes(id)
    end

    -- Break rails
    obj:breakRails(id)

    -- breakgroup handling
    if beam.breakGroup then
      if type(beam.breakGroup) ~= "table" and breakGroupCache[beam.breakGroup] == nil then
        -- shortcircuit in case of broken single breakGroup
      else
        local breakGroups = type(beam.breakGroup) == "table" and beam.breakGroup or {beam.breakGroup}
        for _, g in ipairs(breakGroups) do
          if breakGroupCache[g] then
            props.hidePropsInBreakGroup(g)

            -- breakGroupType = 0 breaks the group
            -- breakGroupType = 1 does not break the group but will be broken by the group
            if beam.breakGroupType == 0 or beam.breakGroupType == nil then
              breakBreakGroup(g)
            end
          end
        end
      end
    end

    if beam.deformSwitches then
      breakMaterial(beam)
    end

    --experimental particle code: spawn plastic chunk particles when a beam connecting to plastic nodes breaks
    local breakNode1 = v.data.nodes[beam.id1].cid
    local breakNode2 = v.data.nodes[beam.id2].cid
    local particleType = 55 + math.floor(math.random(3)) --choose random particle number between 56 and 58 for plastic chunks
    local particleType_deformGroup1 = 68
    local particleType_deformGroup2 = 69
    local particleCount_deformGroup1 = 15
    local particleCount_deformGroup2 = 15
    if v.data.nodes[beam.id1].nodeMaterial == 3 or v.data.nodes[beam.id2].nodeMaterial == 3 then --check for plastic nodes connected to the beam
      obj:addParticleByNodesRelative(breakNode1, breakNode2, math.random(1), particleType, 0, 1)
    end
    if v.data.nodes[beam.id1].nodeMaterial == 6 or v.data.nodes[beam.id2].nodeMaterial == 6 then --check if it's a wooden prop, like the piano
      particleType_deformGroup1 = 12
      particleType_deformGroup2 = 12
      particleCount_deformGroup1 = 2
      particleCount_deformGroup2 = 2
    end
    if beam.deformGroup and beam.breakGroup then --check if beam is part of a breakgroup and a deformgroup, indicating that it's glass or wood
      obj:addParticleByNodesRelative(breakNode1, breakNode2, math.random(1), particleType_deformGroup1, (math.random(1) / 5), particleCount_deformGroup1) --spawn glass or wood particles
      obj:addParticleByNodesRelative(breakNode1, breakNode2, math.random(1), particleType_deformGroup2, (math.random(1) / 5), particleCount_deformGroup2)
    end
  else
    --print ("beam "..id.." just broke")
  end
end

local function searchForActiveParts(part, activeParts)
  if part.active then
    table.insert(activeParts, part.partName)
  end
  if part.parts then
    for _, subSlot in pairs(part.parts) do
      for _, subPart in pairs(subSlot) do
        searchForActiveParts(subPart, activeParts)
      end
    end
  end
end

local function updateCollTris()
  local vehicle = v.data
  if vehicle.beams and vehicle.triangles then
    local beamIndex = table.new(0, #vehicle.beams)

    for _, beam in pairs(vehicle.beams) do
      local b1, b2 = beam.id1, beam.id2
      if type(b1) == "number" and type(b2) == "number" then
        beamIndex[min(b1, b2) + max(b1, b2) * 1e+8] = beam
      end
    end

    for _, tri in pairs(vehicle.triangles) do
      local t1, t2, t3 = tri.id1, tri.id2, tri.id3
      if type(t1) == "number" and type(t2) == "number" and type(t3) == "number" then
        local beamCount = 0
        local bi = beamIndex[min(t1, t2) + max(t1, t2) * 1e+8]
        local tcid = tri.cid
        if bi then
          local coltris = bi.collTris or table.new(2, 0)
          table.insert(coltris, tcid)
          bi.collTris = coltris
          beamCount = beamCount + 1
        end
        bi = beamIndex[min(t1, t3) + max(t1, t3) * 1e+8]
        if bi then
          local coltris = bi.collTris or table.new(2, 0)
          table.insert(coltris, tcid)
          bi.collTris = coltris
          beamCount = beamCount + 1
        end
        bi = beamIndex[min(t2, t3) + max(t2, t3) * 1e+8]
        if bi then
          local coltris = bi.collTris or table.new(2, 0)
          table.insert(coltris, tcid)
          bi.collTris = coltris
          beamCount = beamCount + 1
        end
        tri.beamCount = beamCount
      end
    end
  end
end

local function isTriangleBroken(triId)
  return collTriState[triId] == nil
end

local function init()
  M.damage = 0
  M.damageExt = 0
  wheelBrokenBeams = {}
  couplerBreakGroupCache = {}

  table.clear(beamDamageTracker)
  skeletonStateTimer = 0.25
  beamDamageTrackerDirty = false

  updateCollTris()

  triangleBreakGroupCache = {}
  local pressureBeams = {}

  -- Reset colltris
  if v.data.triangles then
    collTriState = {}
    for _, t in pairs(v.data.triangles) do
      if t.cid and t.beamCount then
        collTriState[t.cid] = t.beamCount
        --handle triangle breakgroups
        if t.breakGroup then
          local breakGroups = type(t.breakGroup) == "table" and t.breakGroup or {t.breakGroup}
          for _, g in pairs(breakGroups) do
            triangleBreakGroupCache[g] = triangleBreakGroupCache[g] or {}
            table.insert(triangleBreakGroupCache[g], t.cid)
          end
        end
        if t.pressureGroup then
          pressureBeams[min(t.id1, t.id2) + max(t.id1, t.id2) * 1e+8] = t.pressureGroup
          pressureBeams[min(t.id1, t.id3) + max(t.id1, t.id3) * 1e+8] = t.pressureGroup
          pressureBeams[min(t.id2, t.id3) + max(t.id2, t.id3) * 1e+8] = t.pressureGroup
        end
      end
    end
  end

  breakGroupCache = {}
  brokenBreakGroups = {}
  M.deformGroupDamage = {}
  table.clear(M.deformGroupsTriggerBeam)
  initTimer = 0

  autoCouplingActive = false
  autoCouplingTimer = 0
  autoCouplingTimeoutTimer = 0

  table.clear(attachedCouplers)
  transmitCouplers = {}
  recievedElectrics = {}
  M.updateRemoteElectrics = nop

  table.clear(couplerCache)
  couplerTags = {}
  hasActiveCoupler = false

  table.clear(M.nodeNameMap)

  local xMin, xMax, yMin, yMax = math.huge, -math.huge, math.huge, -math.huge

  for _, n in pairs(v.data.nodes or {}) do
    if n.name then
      M.nodeNameMap[n.name] = n.cid
    end
    local posx, posy = n.pos.x, n.pos.y
    xMin = min(posx, xMin)
    xMax = max(posx, xMax)
    yMin = min(posy, yMin)
    yMax = max(posy, yMax)

    if n.couplerTag or n.tag then
      couplerTags[n.couplerTag or n.tag] = true

      if n.cid then
        local data = shallowcopy(n)
        couplerCache[n.cid] = data
        hasActiveCoupler = n.couplerTag ~= nil or hasActiveCoupler

        if n.breakGroup then
          local breakGroups = type(n.breakGroup) == "table" and n.breakGroup or {n.breakGroup}
          for _, g in pairs(breakGroups) do
            couplerBreakGroupCache[g] = couplerBreakGroupCache[g] or {}
            table.insert(couplerBreakGroupCache[g], n.cid)
          end
        end
      end
    end
  end

  couplerBreakGroupCacheOrig = shallowcopy(couplerBreakGroupCache)

  for _, c in pairs(couplerCache) do
    if c.couplerStartRadius and c.cid then
      obj:attachCoupler(c.cid, c.couplerTag or "", c.couplerStrength or 1000000, c.couplerStartRadius, c.couplerLockRadius or 0.025, c.couplerLatchSpeed or 0.3, c.couplerTargets or 0)
    end
  end

  M.monetaryDamage = 0
  lastDisplayedDamage = 0
  partDamageData = {}

  M.activeParts = {}
  for _, slot in pairs(v.data.slotMap or {}) do
    for _, part in pairs(slot) do
      searchForActiveParts(part, M.activeParts)
    end
  end

  local partValueSum = 0

  for partName, part in pairs(v.data.activeParts or {}) do
    if part then
      local beamCount = tableSize(part.beams)
      local partValue = 0
      local name = "Unknown"
      if part.information then
        partValue = part.information.value or partValue
        name = part.information.name or name
      end
      partDamageData[partName] = {
        beamsBroken = 0,
        beamsDeformed = 0,
        beamCount = beamCount,
        currentDamage = 0,
        brokenBeamsThreshold = max(beamCount * 0.01, 1),
        deformedBeamsThreshold = max(beamCount * 0.75, 1),
        value = partValue,
        name = name
      }
      partValueSum = partValueSum + partValue
    else
      --log('E', 'beamstate', 'unable to get part: ' .. tostring(partName))
    end
  end

  partBeams = {}
  beamBodyPartLookup = {}
  bodyPartDamageTracker = {FL = 0, FR = 0, ML = 0, MR = 0, RL = 0, RR = 0}
  invBodyPartBeamCount = {FL = 0, FR = 0, ML = 0, MR = 0, RL = 0, RR = 0}
  table.clear(M.tagBeamMap)
  table.clear(M.linkTagBeamMap)

  local xRange = xMax - xMin
  local yRange = yMax - yMin
  local yRangeThird = yRange / 3
  local xRangeHalf = xRange * 0.5
  local yGroup1 = yMin + yRangeThird
  local yGroup2 = yGroup1 + yRangeThird
  local xGroup1 = xMin + xRangeHalf
  local nodes = v.data.nodes

  if v.data.beams then
    for bid, b in pairs(v.data.beams) do
      if b.tag then
        if type(b.tag) == "string" then
          M.tagBeamMap[b.tag] = M.tagBeamMap[b.tag] or {}
          table.insert(M.tagBeamMap[b.tag], bid)
        elseif type(b.tag) == "table" then
          for _, tag in b.tag do
            M.tagBeamMap[tag] = M.tagBeamMap[tag] or {}
            table.insert(M.tagBeamMap[tag], bid)
          end
        end
      end

      if b.linkTag then
        if type(b.linkTag) == "string" then
          M.linkTagBeamMap[b.linkTag] = M.linkTagBeamMap[b.linkTag] or {}
          table.insert(M.linkTagBeamMap[b.linkTag], bid)
        elseif type(b.tag) == "table" then
          for _, tag in b.linkTag do
            M.linkTagBeamMap[tag] = M.linkTagBeamMap[tag] or {}
            table.insert(M.linkTagBeamMap[tag], bid)
          end
        end
      end

      local pbId = pressureBeams[min(b.id1, b.id2) + max(b.id1, b.id2) * 1e+8]
      if pbId and v.data.pressureGroups[pbId] then
        b.pressureGroupId = pbId
      end

      if b.breakGroup then
        local breakGroups = type(b.breakGroup) == "table" and b.breakGroup or {b.breakGroup}
        for _, g in pairs(breakGroups) do
          if not breakGroupCache[g] then
            breakGroupCache[g] = table.new(2, 0)
          end
          table.insert(breakGroupCache[g], b.cid)
        end
      end

      if b.deformGroup then
        local deformGroups = type(b.deformGroup) == "table" and b.deformGroup or {b.deformGroup}
        for _, g in pairs(deformGroups) do
          local group = M.deformGroupDamage[g] or {eventCount = 0, damage = 0, maxEvents = 0, invMaxEvents = 0}
          group.maxEvents = group.maxEvents + 1 / max(b.deformationTriggerRatio or 1, 0.01)
          group.invMaxEvents = 1 / group.maxEvents
          M.deformGroupDamage[g] = group
        end
      end

      if type(b.beamPrecompressionTime) == "number" and b.beamPrecompressionTime > 0 then
        delayedPrecompBeams = delayedPrecompBeams or {}
        table.insert(delayedPrecompBeams, b)
      end

      if not b.wheelID then
        local beamNode1Pos = nodes[b.id1].pos
        local beamNode2Pos = nodes[b.id2].pos
        local beamPosX = (beamNode1Pos.x + beamNode2Pos.x) * 0.5
        local beamPosY = (beamNode1Pos.y + beamNode2Pos.y) * 0.5
        local yChar = beamPosY <= yGroup1 and "F" or (beamPosY <= yGroup2 and "M" or "R")
        local xChar = beamPosX <= xGroup1 and "R" or "L"
        local bodyPart = yChar .. xChar
        beamBodyPartLookup[b.cid] = bodyPart
        invBodyPartBeamCount[bodyPart] = invBodyPartBeamCount[bodyPart] + 1
      end

      local bpo = b.partOrigin
      if bpo and partDamageData[bpo] then
        partDamageData[bpo].beamCount = partDamageData[bpo].beamCount + 1
        partBeams[bpo] = partBeams[bpo] or table.new(2, 0)
        table.insert(partBeams[bpo], b.cid)
      end
    end
  end

  if v.data.torsionbars then
    for _, t in pairs(v.data.torsionbars) do
      if type(t.precompressionTime) == "number" and t.precompressionTime > 0 then
        delayedPrecompTorsionbar = delayedPrecompTorsionbar or {}
        table.insert(delayedPrecompTorsionbar, t)
      end
    end
  end

  if (not tableIsEmpty(delayedPrecompBeams)) or (not tableIsEmpty(delayedPrecompTorsionbar)) then
    M.update = update
  end

  for k, v in pairs(invBodyPartBeamCount) do
    invBodyPartBeamCount[k] = 1 / v
    damageTracker.setDamage("body", k, 0)
  end
end

-- only being called if the beam has deform triggers
local function beamDeformed(id, ratio)
  --log('D', "beamstate.beamDeformed","beam "..id.." deformed with ratio "..ratio)
  beamDamageTracker[id] = ratio
  beamDamageTrackerDirty = true

  local bodyPart = beamBodyPartLookup[id]
  if bodyPart then
    bodyPartDamageTracker[bodyPart] = bodyPartDamageTracker[bodyPart] + ratio
    local damage = bodyPartDamageTracker[bodyPart] * invBodyPartBeamCount[bodyPart]
    if damage > 0.001 then
      damageTracker.setDamage("body", bodyPart, damage)
    end
  end

  local b = v.data.beams[id]
  if b then
    if b.partOrigin and partDamageData[b.partOrigin] then
      partDamageData[b.partOrigin].beamsDeformed = partDamageData[b.partOrigin].beamsDeformed + 1
    end

    if b.deformSwitches then
      material.switchBrokenMaterial(b)
    end

    local deformGroup = b.deformGroup
    if deformGroup then
      if type(deformGroup) == "table" then
        for _, g in ipairs(deformGroup) do
          M.deformGroupsTriggerBeam[g] = M.deformGroupsTriggerBeam[g] or b.cid
          local group = M.deformGroupDamage[g]
          group.eventCount = group.eventCount + 1
          group.damage = group.eventCount * group.invMaxEvents
        end
      else
        M.deformGroupsTriggerBeam[deformGroup] = M.deformGroupsTriggerBeam[deformGroup] or b.cid
        local group = M.deformGroupDamage[deformGroup]
        group.eventCount = group.eventCount + 1
        group.damage = group.eventCount * group.invMaxEvents
      end
    end
  end
end

local function reset()
  init()
  M.lowpressure = false
end

local function breakAllBreakgroups()
  for _, b in pairs(v.data.beams) do
    if b.breakGroup ~= nil then
      obj:breakBeam(b.cid)
    end
  end
  --break groups that ONLY exist with couplers in them
  for breakgroup, _ in pairs(couplerBreakGroupCache) do
    breakBreakGroup(breakgroup)
  end
end

local function breakHinges()
  for _, b in pairs(v.data.beams) do
    if b.breakGroup ~= nil then
      local breakGroups = type(b.breakGroup) == "table" and b.breakGroup or {b.breakGroup}
      -- multiple break groups
      for _, g in pairs(breakGroups) do
        if type(g) == "string" and (string.find(g, "hinge") ~= nil or string.find(g, "latch") ~= nil) then
          --log('D', "beamstate.breakHinges","  breaking hinge beam "..k.. " as in breakgroup ".. b.breakGroup)
          obj:breakBeam(b.cid)
          break
        end
      end
    end
  end

  --break groups that ONLY exist with couplers in them
  for breakgroup, _ in pairs(couplerBreakGroupCache) do
    if type(breakgroup) == "string" and (string.find(breakgroup, "hinge") ~= nil or string.find(breakgroup, "latch") ~= nil) then
      breakBreakGroup(breakgroup)
    end
  end
end

local function deflateTires()
  for i, _ in pairs(wheels.wheels) do
    deflateTire(i)
  end
end

local function deflateRandomTire()
  local inflatedTires = {}
  for k, v in pairs(wheels.wheels) do
    if not v.isTireDeflated then
      table.insert(inflatedTires, k)
    end
  end
  if not tableIsEmpty(inflatedTires) then
    deflateTire(inflatedTires[math.floor(math.random(tableSize(inflatedTires)))])
  end
end

local function triggerDeformGroup(group)
  if group == nil then
    return
  end
  for _, b in pairs(v.data.beams) do
    if b.deformSwitches ~= nil then
      local deformSwitchesT = type(b.deformSwitches) == "table" and b.deformSwitches or {b.deformSwitches}
      for _, g in pairs(deformSwitchesT) do
        if g.deformGroup == group then
          breakMaterial(b)
          return
        end
      end
    end
  end
end

local function addDamage(damage)
  M.damageExt = M.damageExt + damage
end

local function sendUISkeleton()
  local data = {}
  for _, beam in pairs(v.data.beams) do
    local n1 = v.data.nodes[beam.id1]
    local n2 = v.data.nodes[beam.id2]
    -- only beams with deformationTriggerRatio will actually change ...
    --if beam.deformationTriggerRatio then
    data[beam.cid + 1] = {n1.pos, n2.pos}
    --end
  end
  if not playerInfo.firstPlayerSeated then
    return
  end
  guihooks.trigger("VehicleSkeleton", data)
  sendUISkeletonState()
end

local function hasCouplers(couplerTag)
  for _, val in pairs(couplerCache) do
    if (val.couplerWeld ~= true and val.couplerTag) and val.cid and (couplerTag == nil or val.couplerTag == couplerTag or val.tag == couplerTag) then
      return true
    end
  end

  return false
end

local function save(filename)
  if filename == nil then
    filename = v.data.vehicleDirectory .. "/vehicle.save.json"
  end
  -- TODO: color
  local save = {}
  save.format = "v2"
  save.model = v.data.model --.vehicleDirectory:gsub("vehicles/", ""):gsub("/", "")
  save.parts = v.userPartConfig
  save.vars = v.userVars
  save.vehicleDirectory = v.data.vehicleDirectory
  save.nodeCount = tableSizeC(v.data.nodes)
  save.beamCount = tableSizeC(v.data.beams)
  save.luaState = serialize(serializePackages("save"))
  save.hydros = {}
  for _, h in pairs(hydros.hydros) do
    table.insert(save.hydros, h.state)
  end

  save.nodes = {}
  for _, node in pairs(v.data.nodes) do
    local d = {obj:getNodePosition(node.cid):toTable()}
    if math.abs(obj:getOriginalNodeMass(node.cid) - obj:getNodeMass(node.cid)) > 0.1 then
      table.insert(d, obj:getNodeMass(node.cid))
    end
    save.nodes[node.cid + 1] = d
  end
  save.beams = {}
  for _, beam in pairs(v.data.beams) do
    local d = {
      obj:getBeamRestLength(beam.cid),
      obj:beamIsBroken(beam.cid),
      obj:getBeamDeformation(beam.cid)
    }
    save.beams[beam.cid + 1] = d
  end
  jsonWriteFile(filename, save, true)
end

local function load(filename)
  if filename == nil then
    filename = v.data.vehicleDirectory .. "/vehicle.save.json"
  end

  local save = jsonReadFile(filename)

  -- satefy checks
  if not save or save.nodeCount ~= tableSizeC(v.data.nodes) or save.beamCount ~= tableSizeC(v.data.beams) or save.vehicleDirectory ~= v.data.vehicleDirectory or save.format ~= "v2" then
    log("E", "save", "unable to load vehicle: invalid vehicle loaded?")
    return
  end

  importPersistentData(save.luaState)

  for k, h in pairs(save.hydros) do
    hydros.hydros[k].state = h
  end

  for cid, node in pairs(save.nodes) do
    cid = tonumber(cid) - 1
    obj:setNodePosition(cid, vec3(node[1]))
    if #node > 1 then
      obj:setNodeMass(cid, node[2])
    end
  end

  for cid, beam in pairs(save.beams) do
    cid = tonumber(cid) - 1
    obj:setBeamLength(cid, beam[1])
    if beam[2] == true then
      obj:breakBeam(cid)
    end
    if beam[3] > 0 then
      -- deformation: do not call c++ at all, its just used on the lua side anyways
      --print('deformed: ' .. tostring(cid) .. ' = ' .. tostring(beam[3]))
      beamDeformed(cid, beam[3])
    end
  end

  obj:commitLoad()
end

local function getVehicleState(...)
  -- fake delay, to be used only during development, to emulate possible framerate issues in slower computers and prevent abuse this API
  log("W", "", "getVehicleState delay")
  local timer, fakeDelay = HighPerfTimer(), 1
  while fakeDelay > 0 do
    fakeDelay = fakeDelay - timer:stopAndReset() / 1000
  end

  local pos = obj:getPosition()
  local front = obj:getDirectionVector()
  local up = obj:getDirectionVectorUp()
  local vehicleState = {objId = obj:getId(), partsCondition = partCondition.getConditions(), itemId = v.config.itemId, pos = pos, front = front, up = up}
  return vehicleState, ...
end

local function getPartDamageData()
  local damageData = {}
  for partName, partData in pairs(partDamageData) do
    local brokenCoef = clamp(partData.beamsBroken / partData.brokenBeamsThreshold, 0, 1)
    local deformedCoef = (clamp(partData.beamsDeformed / partData.deformedBeamsThreshold, 0, 1))
    local damageScore = max(brokenCoef, deformedCoef)
    if damageScore > 0 then
      damageData[partName] = {name = partData.name, damage = damageScore}
    end
  end
  return damageData
end

local function exportPartDamageData()
  local damageData = getPartDamageData()
  dumpToFile("partDamage.json", damageData)
end

local function isPhysicsStepUsed()
  return M.update == update
end

-- BeamLR Additions
local function getPartDamageTable()
return partDamageData
end

-- BeamLR interface
M.getPartDamageTable = getPartDamageTable

-- public interface
M.beamBroken = beamBroken
M.reset = reset
M.init = init
M.deflateTire = deflateTire
M.updateGFX = updateGFX
M.beamDeformed = beamDeformed
M.breakAllBreakgroups = breakAllBreakgroups
M.breakHinges = breakHinges
M.deflateTires = deflateTires
M.deflateRandomTire = deflateRandomTire
M.breakBreakGroup = breakBreakGroup
M.triggerDeformGroup = triggerDeformGroup
M.addDamage = addDamage
M.activateAutoCoupling = activateAutoCoupling
M.disableAutoCoupling = disableAutoCoupling
M.couplerFound = couplerFound
M.onCouplerAttached = onCouplerAttached
M.onCouplerDetached = onCouplerDetached
M.getCouplerOffset = getCouplerOffset
M.setCouplerVisiblityExternal = setCouplerVisiblityExternal
M.exportCouplerData = exportCouplerData
M.importCouplerData = importCouplerData
M.sendExportCouplerData = sendExportCouplerData
M.updateRemoteElectrics = nop
M.hasCouplers = hasCouplers
M.registerExternalCouplerBreakGroup = registerExternalCouplerBreakGroup
M.isTriangleBroken = isTriangleBroken

M.load = load
M.save = save

-- Input
M.toggleCouplers = toggleCouplers
M.attachCouplers = attachCouplers
M.detachCouplers = detachCouplers
M.couplerExists = couplerExists

-- for the UI
M.requestSkeletonState = sendUISkeletonState
M.requestSkeleton = sendUISkeleton

M.addPlanet = addPlanet
M.delPlanet = delPlanet
M.setPlanets = setPlanets

M.getVehicleState = getVehicleState
M.getPartDamageData = getPartDamageData
M.exportPartDamageData = exportPartDamageData
M.isPhysicsStepUsed = isPhysicsStepUsed
M.deformedBeams = beamDamageTracker
M.couplerCache = couplerCache
M.attachedCouplers = attachedCouplers

M.setPartCondition = setPartCondition
M.getPartCondition = getPartCondition

return M
