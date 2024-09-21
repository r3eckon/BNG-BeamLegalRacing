--[[
This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
If a copy of the bCDDL was not distributed with this
file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
This module contains a set of functions which manipulate behaviours of vehicles.
]]

local M = {}

--BEAMLR EDIT START
local extensions = require("extensions")
--BEAMLR EDIT END

local min, max, tableconcat = math.min, math.max, table.concat

-- these are defined in C, do not change the values
local NORMALTYPE = 0
local NODE_FIXED = 1
local NONCOLLIDABLE = 2
local BEAM_ANISOTROPIC = 1
local BEAM_BOUNDED = 2
local BEAM_PRESSURED = 3
local BEAM_LBEAM = 4
local BEAM_BROKEN = 5
local BEAM_SUPPORT = 7

local triTypeMap = {['NORMAL'] = NORMALTYPE, ['NONCOLLIDABLE'] = NONCOLLIDABLE}

local function checkNum(val, default)
  return type(val) == 'number' and val or (default or 0)
end

local function addBeamByData(vehicle, beam)
  -- some defaults
  beam.beamStrength = beam.beamStrength or vehicle.options.beamStrength or math.huge
  if type(beam.beamStrength) == 'string' then
    if tostring(beam.beamStrength) ~= tostring(tonumber(beam.beamStrength)) then
      log('E', "jbeam.pushToPhysics", "String value used on beamStrength property of beam on nodes: " ..(vehicle.nodes[beam.id1].name or '-')..' and '..(vehicle.nodes[beam.id2].name or '-') .. ': \'' .. tostring(beam.beamStrength) .. '\' = ' .. tonumber(beam.beamStrength))
    else
      log('W', "jbeam.pushToPhysics", "String value used on beamStrength property of beam on nodes: " ..(vehicle.nodes[beam.id1].name or '-')..' and '..(vehicle.nodes[beam.id2].name or '-') .. ': \'' .. tostring(beam.beamStrength) .. '\' = ' .. tonumber(beam.beamStrength))
    end
    beam.beamStrength = tonumber(beam.beamStrength)
  end
  -- BEAMLR EDIT START
  if(extensions.blrflags.get("garageSafeMode")) then
  beam.beamStrength = math.huge
  end
  -- BEAMLR EDIT END
  beam.beamSpring = beam.beamSpring or vehicle.options.beamSpring
  beam.beamDamp = beam.beamDamp or vehicle.options.beamDamp
  if type(beam.beamDamp) == 'string' then
    if tostring(beam.beamDamp) ~= tostring(tonumber(beam.beamDamp)) then
      log('E', "jbeam.pushToPhysics", "String value used on beamDamp property of beam on nodes: " ..(vehicle.nodes[beam.id1].name or '-')..' and '..(vehicle.nodes[beam.id2].name or '-') .. ': \'' .. tostring(beam.beamDamp) .. '\' = ' .. tonumber(beam.beamDamp))
    else
      log('W', "jbeam.pushToPhysics", "String value used on beamDamp property of beam on nodes: " ..(vehicle.nodes[beam.id1].name or '-')..' and '..(vehicle.nodes[beam.id2].name or '-') .. ': \'' .. tostring(beam.beamDamp) .. '\' = ' .. tonumber(beam.beamDamp))
    end
    beam.beamDamp = tonumber(beam.beamDamp)
  end
  beam.beamDeform = beam.beamDeform or vehicle.options.beamDeform
  if type(beam.beamDeform) == 'string' then
    if tostring(beam.beamDeform) ~= tostring(tonumber(beam.beamDeform)) then
      log('E', "jbeam.pushToPhysics", "String value used on beamDeform property of beam on nodes: " ..(vehicle.nodes[beam.id1].name or '-')..' and '..(vehicle.nodes[beam.id2].name or '-') .. ': \'' .. tostring(beam.beamDeform) .. '\' = ' .. tonumber(beam.beamDeform))
    else
      log('W', "jbeam.pushToPhysics", "String value used on beamDeform property of beam on nodes: " ..(vehicle.nodes[beam.id1].name or '-')..' and '..(vehicle.nodes[beam.id2].name or '-') .. ': \'' .. tostring(beam.beamDeform) .. '\' = ' .. tonumber(beam.beamDeform))
    end
    beam.beamDeform = tonumber(beam.beamDeform)
  end
  -- BEAMLR EDIT START
  if(extensions.blrflags.get("garageSafeMode")) then
  beam.beamDeform = math.huge
  end
  -- BEAMLR EDIT END
  beam.beamType = beam.beamType or NORMALTYPE
  beam.breakGroupType = beam.breakGroupType or 0

  -- error detection
  if type(beam.id1) == "string" or type(beam.id2) == "string" and tostring(beam.optional) == "true" then
    log('W', "jbeam.pushToPhysics","- beam not committed as node was not found: " .. tostring(beam.id1) .. " -> " .. tostring(beam.id2) .. ' : ' .. dumps(beam))
    beam.beamType = BEAM_BROKEN
    beam.id1, beam.id2 = 0, 0
  end

  if beam.id1 == beam.id2 and beam.beamType ~= BEAM_BROKEN then
    local msg = "beam has same node at both ends " ..(vehicle.nodes[beam.id1].name or '-')..' and '..(vehicle.nodes[beam.id2].name or '-') .. ', beam details are:\n'
    log('E', "jbeam.pushToPhysics", msg .. dumps(beam))
    beam.beamType = BEAM_BROKEN
  end

  local node1pos = vehicle.nodes[beam.id1].pos
  local node2pos = vehicle.nodes[beam.id2].pos

  if node1pos.x == node2pos.x and node1pos.y == node2pos.y and node1pos.z == node2pos.z and
  beam.wheelID == nil and tostring(beam.optional) ~= "true" and beam.beamType ~= BEAM_BROKEN then
    local msg = "zero size beam between nodes " ..(vehicle.nodes[beam.id1].name or '-')..' and '..(vehicle.nodes[beam.id2].name or '-') .. ', beam details are:\n'
    log('W', "jbeam.pushToPhysics", msg .. dumps(beam))
  end

  if type(beam.precompressionRange) == 'number' then
    local bL = vec3(node1pos):distance(node2pos)
    beam.beamPrecompression = max(0, (bL + beam.precompressionRange) / (bL + 1e-30))
  end
  beam.beamPrecompression = checkNum(beam.beamPrecompression, 1)
  local beamPrecompression = beam.beamPrecompression
  if type(beam.beamPrecompressionTime) == 'number' and beam.beamPrecompressionTime > 0 then
    if beam.beamPrecompression == 1 then
      beam.beamPrecompressionTime = nil
    else
      beamPrecompression = 1
    end
  end

  local deformLimit = type(beam.deformLimit) == 'number' and beam.deformLimit or math.huge
  local bid = obj:setBeam(beam.cid, beam.id1, beam.id2, beam.beamStrength, beam.beamSpring,
    beam.beamDamp, type(beam.dampCutoffHz) == 'number' and beam.dampCutoffHz or 0,
    beam.beamDeform, deformLimit, type(beam.deformLimitExpansion) == 'number' and beam.deformLimitExpansion or deformLimit, type(beam.deformLimitStress) == 'number' and beam.deformLimitStress or math.huge,
    beamPrecompression
  )

  if(beam.beamType == BEAM_ANISOTROPIC) then
    beam.springExpansion = beam.springExpansion or beam.beamSpring
    beam.dampExpansion = beam.dampExpansion or beam.beamDamp
    local longBound = type(beam.beamLongExtent) == 'number' and -max(0, beam.beamLongExtent) or max(0, beam.beamLongBound or math.huge)
    obj:setBeamAnisotropic(bid, beam.springExpansion, beam.dampExpansion,
      type(beam.transitionZone) == 'number' and beam.transitionZone or 0, longBound
    )
  elseif(beam.beamType == BEAM_BOUNDED) then
    local longBound = type(beam.longBoundRange) == 'number' and -max(0, beam.longBoundRange) or max(0, beam.beamLongBound or 1)
    local shortBound = type(beam.shortBoundRange) == 'number' and -max(0, beam.shortBoundRange) or max(0, beam.beamShortBound or 1)
    beam.beamLimitSpring = beam.beamLimitSpring or 1
    beam.beamLimitDamp = beam.beamLimitDamp or 1
    beam.beamLimitDampRebound = beam.beamLimitDampRebound or beam.beamLimitDamp
    beam.beamDampRebound = beam.beamDampRebound or beam.beamDamp
    beam.beamDampFast = beam.beamDampFast or beam.beamDamp
    beam.beamDampReboundFast = beam.beamDampReboundFast or beam.beamDampRebound
    beam.beamDampVelocitySplit = checkNum(beam.beamDampVelocitySplit, math.huge)

    obj:setBeamBounded(bid, longBound, shortBound, beam.beamLimitSpring, beam.beamLimitDamp, beam.beamLimitDampRebound,
      beam.beamDampRebound, beam.beamDampFast, beam.beamDampReboundFast,
      beam.beamDampVelocitySplit, checkNum(beam.beamDampVelocitySplitRebound, beam.beamDampVelocitySplit),
      type(beam.boundZone) == 'number' and beam.boundZone or 1
    )
  elseif(beam.beamType == BEAM_SUPPORT) then
    local longBound = type(beam.beamLongExtent) == 'number' and -max(0, beam.beamLongExtent) or max(0, beam.beamLongBound or 1)
    beam.springExpansion = 0
    beam.dampExpansion = 0
    obj:setBeamAnisotropic(bid, 0, 0, 0, longBound)
  elseif(beam.beamType == BEAM_PRESSURED) then
    if beam.pressure == nil and beam.pressurePSI == nil then beam.pressurePSI = 30 end
    beam.pressure = beam.pressure or (beam.pressurePSI * 6894.757 + 101325) -- From PSI to Pa
    beam.pressurePSI = (beam.pressure - 101325) / 6894.757
    beam.surface = beam.surface or 1
    beam.volumeCoef = beam.volumeCoef or 1

    if beam.maxPressure == nil and beam.maxPressurePSI == nil then beam.maxPressure = math.huge end
    beam.maxPressure = beam.maxPressure or (beam.maxPressurePSI * 6894.757 + 101325)
    beam.maxPressurePSI = (beam.maxPressure - 101325) / 6894.757
    if beam.maxPressure < 0 then beam.maxPressure = math.huge end
    obj:setBeamPressured(bid, beam.pressure, beam.surface, beam.volumeCoef, beam.maxPressure)
  elseif(beam.beamType == BEAM_LBEAM) then
    obj:setBeamLbeam(bid, beam.id3,
      type(beam.springExpansion) == 'number' and beam.springExpansion or beam.beamSpring,
      type(beam.dampExpansion) == 'number' and beam.dampExpansion or beam.beamDamp
    )
  end

  if beam.deformationTriggerRatio ~= nil and beam.deformationTriggerRatio ~= "" then
    obj:setBeamDeformationTriggerRatio(bid, tonumber(beam.deformationTriggerRatio))
  end
end

local function processNodes(vehicle)
  if vehicle.nodes == nil then return end
  for i = 0, tableSizeC(vehicle.nodes) - 1 do
    local node = vehicle.nodes[i]
    local ntype = NORMALTYPE
    if node.fixed == true then
      ntype = NODE_FIXED
    end

    local collision
    if node.collision ~= nil then
      collision = node.collision
    else
      collision = true
    end

    local selfCollision
    if node.selfCollision ~= nil then
      selfCollision = node.selfCollision
    else
      selfCollision = false
    end

    local staticCollision
    if node.staticCollision ~= nil then
      staticCollision = node.staticCollision
    else
      staticCollision = true
    end

    local frictionCoef = type(node.frictionCoef) == 'number' and node.frictionCoef or 1
    local slidingFrictionCoef = type(node.slidingFrictionCoef) == 'number' and node.slidingFrictionCoef or frictionCoef
    local noLoadCoef = type(node.noLoadCoef) == 'number' and node.noLoadCoef or 1
    local fullLoadCoef = type(node.fullLoadCoef) == 'number' and node.fullLoadCoef or 0
    local loadSensitivitySlope = type(node.loadSensitivitySlope) == 'number' and node.loadSensitivitySlope or 0

    local nodeWeight
    if type(node.nodeWeight) == 'number' then
      nodeWeight = node.nodeWeight
    else
      nodeWeight = vehicle.options.nodeWeight
      node.nodeWeight = nodeWeight
    end

    local nodeMaterialTypeID
    if node.nodeMaterial ~= nil then
      nodeMaterialTypeID = node.nodeMaterial
      if type(nodeMaterialTypeID) ~= "number" then
        --log('D', "jbeam.pushToPhysics","invalid node material id:"..tostring(nodeMaterialTypeID))
        nodeMaterialTypeID = vehicle.options.nodeMaterial or 0
      end
    else
      nodeMaterialTypeID = vehicle.options.nodeMaterial or 0
    end

    local pos = node.pos
    obj:setNode(node.cid, pos.x, pos.y, pos.z, nodeWeight, ntype, frictionCoef, slidingFrictionCoef, node.stribeckExponent or 1.75, node.stribeckVelMult or 1, noLoadCoef, fullLoadCoef, loadSensitivitySlope, node.softnessCoef or 0.5, node.treadCoef or 0.5, node.tag or '', node.couplerStrength or math.huge, node.firstGroup or -1, selfCollision, collision, staticCollision, nodeMaterialTypeID)

    if node.pairedNode then
      obj:setNodePair2WheelId(node.cid, node.pairedNode, node.pairedNode2 or -1, node.wheelID or -1)
    end
  end
end

local function processBeams(vehicle)
  if vehicle.beams == nil then return end

  local keybase = {1,'\0',3,'\0',5}
  local dedup = {}
  for i, beam in pairs(vehicle.beams) do
    if beam.breakGroup == '' then beam.breakGroup = nil end
    if beam.deformGroup == '' then beam.deformGroup = nil end
    if beam.beamSpring ~= 0 and beam.deformGroup == nil and beam.beamType ~= BEAM_BOUNDED and beam.optional ~= true then
      local bType = beam.beamType or NORMALTYPE
      if type(bType) == "string" then bType = NORMALTYPE end

      keybase[1], keybase[3], keybase[5] = min(beam.id1, beam.id2), max(beam.id1, beam.id2), bType
      local key = tableconcat(keybase)
      if dedup[key] ~= nil then
        local msg = "duplicated beam between nodes: "..(vehicle.nodes[beam.id1].name or '-')..' and '..(vehicle.nodes[beam.id2].name or '-')
        log('W', "jbeam.pushToPhysics", msg)
        msg = "duplicated beam details are:\n beam1=" .. dumps(dedup[key]) .. "\n"
        msg = msg .. "beam2=" .. dumps(beam)
        --log('D', "jbeam.pushToPhysics", msg)
      else
        dedup[key] = beam
      end
    end

    addBeamByData(vehicle, beam)
  end
end

local function processWheels(vehicle)
  if vehicle.wheels == nil then return end
  for wheelKey = 0, tableSizeC(vehicle.wheels) - 1 do
    local wheel = vehicle.wheels[wheelKey]
    if wheel.nodes ~= nil and next(wheel.nodes) ~= nil then
      local torqueArm
      if type(wheel.torqueArm) == 'number' then
        torqueArm = wheel.torqueArm
      else
        if type(wheel.torqueArm) ~= 'nil' then
          log('W', "jbeam.pushToPhysics","*** wheel: "..wheel.name..' could not bind torqueArm for wheel')
        end
      end
      local nodeCouple = wheel.nodeCouple or wheel.nodeCoupling
      if type(nodeCouple) == 'string' then
        log('W', "jbeam.pushToPhysics","*** wheel: "..wheel.name..' nodeCouple needs a ":" at the end')
        nodeCouple = nil
      end
      local torqueCouple = wheel.torqueCouple or wheel.torqueCoupling
      if type(torqueCouple) == 'string' then
        log('W', "jbeam.pushToPhysics","*** wheel: "..wheel.name..' torqueCouple needs a ":" at the end')
        torqueCouple = nil
      end
      local wid = obj:setWheel(wheel.cid, wheel.node1, wheel.node2, wheel.nodeArm or -1,
        torqueArm or -1, torqueCouple or -1, checkNum(wheel.torqueArm2, -1),
        checkNum(wheel.torqueJointNode1, -1), checkNum(wheel.torqueJointNode2, -1),
        math.max(checkNum(wheel.brakeTorque), checkNum(wheel.parkingTorque), 1) * checkNum(wheel.brakeSpring, 10))

      for _, v in ipairs(wheel.nodes) do
        obj:addWheelNode(wid, v)
      end

      local wobj = obj:getWheel(wid)
      if wobj then
        wobj:setThermal(
          checkNum(wheel.heatCoefNodeToEnv), checkNum(wheel.heatCoefEnvMultStationary, 0.4),
          checkNum(wheel.heatCoefEnvTerminalSpeed, 20), checkNum(wheel.heatCoefNodeToCore),
          checkNum(wheel.heatCoefCoreToNodes), checkNum(wheel.heatCoefNodeToSurface),
          checkNum(wheel.heatCoefFriction), checkNum(wheel.heatCoefFlashFriction),
          checkNum(wheel.heatCoefStrain), checkNum(wheel.smokingTemp, 1e18), checkNum(wheel.meltingTemp, 1e19),
          type(wheel.heatAffectsPressure) == 'boolean' and wheel.heatAffectsPressure or false
        )

        wobj:setFrictionThermalSensitivity(
          checkNum(wheel.frictionLowTemp, -300), checkNum(wheel.frictionHighTemp, 1e7),
          checkNum(wheel.frictionLowSlope, 1e-10), checkNum(wheel.frictionHighSlope, 1e-10),
          checkNum(wheel.frictionSlopeSmoothCoef, 10), checkNum(wheel.frictionCoefLow, 1),
          checkNum(wheel.frictionCoefMiddle, 1), checkNum(wheel.frictionCoefHigh, 1)
        )
      end
    end
  end
end

local function processRails(vehicle)
  if vehicle.rails == nil then return end
  local cids = {}
  for _, rail in pairs(vehicle.rails) do
    if rail["links:"] ~= nil then
      local looped = 0
      if rail.looped == 1 or rail.looped == true then
        looped = 1
      end
      if rail.capped == 0 then
        rail.capped = false
      end

      rail.cid = obj:addRail(looped)
      cids[rail.cid] = rail

      -- add links
      local brokenmap = {}
      if rail["broken:"] ~= nil then
        for _, nid in pairs(rail["broken:"]) do
          brokenmap[nid] = 1
        end
      end

      local rLinks = rail["links:"]
      local linkSize = #rLinks
      if looped == 1 then rail.capped = false end

      -- guard for mistaken last == 1st link
      if looped == 1 and rLinks[1] == rLinks[linkSize] then
        table.remove(rLinks) -- remove last link
      end

      for i, nid in ipairs(rLinks) do
        local lcapped = 0
        if rail.capped and (i == 1 or i == linkSize) then lcapped = 1 end
        obj:addRailLink(rail.cid, nid, lcapped, brokenmap[nid] or 0)
      end
    end
  end
  vehicle.rails.cids = cids
end

local function processSlidenodes(vehicle)
  if vehicle.slidenodes == nil then return end
  for _, snode in pairs(vehicle.slidenodes) do
    local attached = 1
    if snode.attached == 0 or snode.attached == false then
      attached = 0
    end
    local fixtorail = 1
    if snode.fixToRail == 0 or snode.fixToRail == false then
      fixtorail = 0
    end
    local railId = -1
    if snode.railName ~= nil and vehicle.rails[snode.railName] ~= nil then
      railId = vehicle.rails[snode.railName].cid or -1
    end

    local spring = snode.spring or vehicle.options.beamSpring
    local strength = snode.strength or math.huge

    snode.cid = obj:addSlidenode(snode.id, railId, attached, fixtorail, snode.tolerance or 0, spring, strength, snode.capStrength or strength)
  end
end

local function processTorsionhydros(vehicle)
  if vehicle.torsionHydros == nil then return end
  vehicle.torsionbars = vehicle.torsionbars or {}
  local tbi = tableEndC(vehicle.torsionbars)
  for i, hydro in pairs(vehicle.torsionHydros) do
    vehicle.torsionbars[tbi] = hydro; tbi = tbi + 1
    hydro.inRate = hydro.inRate or 2
    hydro.outRate = hydro.outRate or hydro.inRate
    hydro.inLimit = checkNum(hydro.inExtent, hydro.inLimit or -1)
    hydro.outLimit = checkNum(hydro.outExtent, hydro.outLimit or 1)
    hydro.inputSource = hydro.inputSource or "steering"
    hydro.inputCenter = hydro.inputCenter or 0
    hydro.inputInLimit = hydro.inputInLimit or -1
    hydro.inputOutLimit = hydro.inputOutLimit or 1
    hydro.inputFactor = hydro.inputFactor or 1

    if type(hydro.extentFactor) == 'number' then
      hydro.factor = hydro.extentFactor
    end

    if type(hydro.factor) == 'number' then
      hydro.inLimit = -math.abs(hydro.factor)
      hydro.outLimit = math.abs(hydro.factor)
      hydro.inputFactor = sign2(hydro.factor)
    end
  end
end

local function processTorsionbars(vehicle)
  if vehicle.torsionbars == nil then return end
  for _, tb in pairs(vehicle.torsionbars) do
    local spring = tb.spring
    local damp = checkNum(tb.damp)
    local id1, id2, id3, id4 = tb.id1, tb.id2, tb.id3, tb.id4
    if type(id1) ~= 'number' then
      id1, spring, damp = 0, 0, 0
    end
    if type(id2) ~= 'number' then
      id2, spring, damp = 0, 0, 0
    end
    if type(id3) ~= 'number' then
      id3, spring, damp = 0, 0, 0
    end
    if type(id4) ~= 'number' then
      id4, spring, damp = 0, 0, 0
    end

    tb.precompressionAngle = checkNum(tb.precompressionAngle)
    local precompressionAngle = tb.precompressionAngle
    if type(tb.precompressionTime) == 'number' and tb.precompressionTime > 0 then
      if precompressionAngle == 0 then
        tb.precompressionTime = nil
      else
        precompressionAngle = 0
      end
    end

    tb.cid = obj:setTorsionbar(-1, id1, id2, id3, id4, spring, spring, damp, damp,
      checkNum(tb.strength, math.huge), checkNum(tb.deform, math.huge), precompressionAngle)
  end
end

local function processTriangles(vehicle)
  if vehicle.triangles == nil then return end
  vehicle.pressureGroups = {}
  local pressureGroupCount = 0
  local n = vehicle.nodes
  for _, triangle in pairs(vehicle.triangles) do
    if triangle.breakGroup == '' then triangle.breakGroup = nil end
    if triangle.triangleType ~= nil and type(triangle.triangleType) == 'string' then
      triangle.triangleType = triTypeMap[triangle.triangleType]
    end
    triangle.triangleType = triangle.triangleType or NORMALTYPE

    local pressureGroup = -1
    local pressure = -1
    if triangle.pressureGroup ~= nil and triangle.pressureGroup ~= '' then
      if vehicle.pressureGroups[triangle.pressureGroup] ~= nil then
        pressureGroup = vehicle.pressureGroups[triangle.pressureGroup]
      else
        vehicle.pressureGroups[triangle.pressureGroup] = pressureGroupCount
        pressureGroup = pressureGroupCount
        pressureGroupCount = pressureGroupCount + 1
      end

      if triangle.pressure ~= nil or triangle.pressurePSI ~= nil then
        if triangle.pressure == false or triangle.pressurePSI == false then
          triangle.pressure = false
          triangle.pressurePSI = false
          pressure = -1
        else
          triangle.pressure = triangle.pressure or PSItoPascal(triangle.pressurePSI) -- From PSI to Pa
          triangle.pressurePSI = (triangle.pressure - 101325) / 6894.757
          pressure = triangle.pressure
        end
      end
    end

    local dragCoef = triangle.dragCoef or 100
    local liftCoef = triangle.liftCoef or dragCoef
    local externalCollision = 1 -- full collisions
    if triangle.externalCollisionBias == 'out' then externalCollision = 2 end
    if triangle.externalCollisionBias == 'in' then externalCollision = 3 end
    if triangle.id1 == triangle.id2 or triangle.id1 == triangle.id3 or triangle.id2 == triangle.id3 then
      local t1, t2, t3 = n[triangle.id1].name, n[triangle.id2].name, n[triangle.id3].name
      log('E', "jbeam.pushToPhysics", "Found degenerate collision triangle with nodes: "..t1..', '..t2..', '..t3)
    end

    triangle.cid = obj:setTriangle(-1, triangle.id1, triangle.id2, triangle.id3, dragCoef * 0.01, liftCoef * 0.01,
      (triangle.skinDragCoef or 0) * 0.01, type(triangle.stallAngle) == 'number' and triangle.stallAngle or 0.58,
      pressure, pressureGroup, externalCollision, triangle.triangleType, triangle.groundModel or "asphalt")
  end
end

local function processRefNodes(vehicle)
  if vehicle.refNodes == nil then
    vehicle.refNodes = {}
  end
  local refNode0 = vehicle.refNodes[0]
  if refNode0 ~= nil then
    obj:setReferenceNodes(refNode0.ref, refNode0.back, refNode0.left, refNode0.up,
      refNode0.leftCorner or refNode0.ref, refNode0.rightCorner or refNode0.ref
    )
  else
    log('E', "jbeam.pushToPhysics", "Reference nodes missing. Please add them")
    vehicle.refNodes[0] = {ref = 0, back = 1, left = 2, up = 0}
  end
end

local function pushToPhysics(vehicle)
  if type(vehicle) ~= 'table' then return end
  --log('D', "jbeam.pushToPhysics"," ** pushing vehicle to physics")
  obj:requestReset(RESET_PHYSICS)
  processNodes(vehicle)
  processBeams(vehicle)
  processWheels(vehicle)
  processRails(vehicle)
  processSlidenodes(vehicle)
  processTorsionhydros(vehicle)
  processTorsionbars(vehicle)
  processTriangles(vehicle)
  processRefNodes(vehicle)
  obj:finishLoading()
  return true
end


local function loadVehicleStage2(vdataStage1)
  --if not vehicle then return end
  local t = HighPerfTimer()

  profilerPushEvent('jbeam/loadVehicleStage2')

  if not pushToPhysics(vdataStage1.vdata) then
    --log('W', "jbeam.compile", "*** push error")
    return nil
  end
  vdataStage1.vdata.format = "parsed"

  M.data   = vdataStage1.vdata
  M.config = vdataStage1.config

  -- backward compatibility
  M.vehicleDirectory = M.data.vehicleDirectory

  profilerPopEvent() -- jbeam/loadVehicleStage2

  log('D', 'loader', 'Vehicle loading took: ' .. tostring(t:stop()) .. ' ms')
  return vdataStage1.vdata
end


M.loadVehicleStage2 = loadVehicleStage2

return M