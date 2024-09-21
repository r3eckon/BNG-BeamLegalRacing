-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- BEAMLR EDIT START
local extensions = require("extensions")
-- BEAMLR EDIT END

local M = {}
local im = ui_imgui
local ffi = require('ffi')
local logTag = ""
--M.dependencies = {"gameplay_drag_dragRace", "gameplay_drag_times", "gameplay_drag_display"}
local currentFileDir = "/gameplay/temp/"
local debugMenu = false
local dragData
local gameplayContext = "freeroam"
local ext

local levelDir = ""

local selectedVehicle = -1
local search = require('/lua/ge/extensions/editor/util/searchUtil')()
local aviableLanes = {}

local needsMapReload = false
local needsCollisionRebuild = false
local currentLevel = ""
local initFlagCounter = 0

local function unloadPrefabs()
  if not dragData or gameplayContext == "freeroam" then return end
  if needsMapReload then
    for laneNum, lane in ipairs(dragData.strip.lanes) do
      for pointType, point in pairs(lane) do
        point.waypoint.wp:delete()
      end
    end
    map.reset()
  end
  if needsCollisionRebuild then
    for prefabName, prefabData in pairs(dragData.strip.prefabs) do
      if prefabData.path and prefabData.isUsed then
        local obj = scenetree.findObjectById(prefabData.prefabId)
        if obj then
          if editor and editor.onRemoveSceneTreeObjects then
            editor.onRemoveSceneTreeObjects({prefabData.prefabId})
          end
          obj:delete()
        end
      end
    end
    be:reloadCollision()
  end
end

local function unloadAllExtensions()
  extensions.unload('gameplay_drag_display')
  extensions.unload('gameplay_drag_times')
  extensions.unload('gameplay_drag_dragTypes_headsUpDrag')
  extensions.unload('gameplay_drag_dragTypes_dragPracticeRace')
end

local function clear()
  dragData = nil
  selectedVehicle = -1
  aviableLanes = {}
  needsMapReload = false
  needsCollisionRebuild = false
  ext = nil
  unloadAllExtensions()
  gameplayContext = "freeroam"
  initFlagCounter = 0
end

local function init()
  local data = jsonReadFile(levelDir .. "/dragstrips/dragStripData.dragData.json")
  if not data then
    log('I', logTag, 'No data found in this level, no freeroam drag will be loaded.')
    initFlagCounter = 11
    return
  end
  if #data.strip.lanes <= 0 then
    log('I', logTag, 'No lanes found in this drag data.')
    return
  else
    for k,lane in ipairs(data.strip.lanes) do
      for _, laneStage in pairs(lane) do
        for transformKey, transformData in pairs(laneStage.transform) do
          if transformKey == "rot" then
            laneStage.transform[transformKey] = quat(transformData.x, transformData.y, transformData.z, transformData.w)
          else
            laneStage.transform[transformKey] = vec3(transformData.x, transformData.y, transformData.z)
          end
        end

        -- TODO: deduplicate
        local rot = laneStage.transform.rot
        local scl = laneStage.transform.scl
        -- compute local unit vectors
        local x, y, z = rot * vec3(scl.x,0,0), rot * vec3(0,scl.y,0), rot * vec3(0,0,scl.z)
        laneStage.transform.x = x
        laneStage.transform.y = y
        laneStage.transform.z = z
        
        -- also compute vector from start to end
      end
      local startToEnd = lane.endLine.transform.pos - lane.stage.transform.pos
      lane.stage.toEnd = startToEnd
      lane.stage.toEndNormalized = startToEnd:normalized()
    end
  end
  data.racers = {}
  log('I', logTag, 'Loaded drag strip from: '.. tostring(levelDir .. "/dragstrips/dragStripData.dragData.json"))
  return data
end
local function setupRacers()
  -- Setup racers
  dragData.racers = {}
  M.setupRacer(be:getPlayerVehicleID(0), 1)
  if not dragData.racers[be:getPlayerVehicleID(0)] then
    return
  end
end

local function loadPracticeExtension()
  -- Load the dragRace extension
  extensions.load('gameplay_drag_dragTypes_' .. dragData.context)
  ext = gameplay_drag_dragTypes_dragPracticeRace
  gameplayContext = "freeroam"
end

local function onVehicleResetted(vid)
  if gameplayContext == "freeroam" and dragData and dragData.isStarted then
    if dragData.racers[vid] then
      clear()
    end
  end
end
M.onVehicleResetted = onVehicleResetted

local function onVehicleSwitched(oldId, newId)
  if gameplayContext == "freeroam" and dragData and dragData.isStarted then
    if dragData.racers[oldId] or dragData.racers[newId] then
      clear()
    end
  end
end
M.onVehicleSwitched = onVehicleSwitched

local function onVehicleDestroyed(vid)
  if gameplayContext == "freeroam" and dragData and dragData.isStarted then
    if dragData.racers[vid] then
      clear()
    end
  end
end
M.onVehicleDestroyed = onVehicleDestroyed

local function onExtensionLoaded()
  clear()
end
M.onExtensionLoaded = onExtensionLoaded

local function onAnyMissionChanged(status, id)
  clear()
  --check if its stopped to load the freeroam data again
  if status == "stopped" then
    dragData = init()
  end
end
M.onAnyMissionChanged = onAnyMissionChanged

local function loadPrefabs(data)

  if not data then return end

  log("I", logTag, 'Loading Waypoints...')
  for laneNum, lane in ipairs(data.strip.lanes) do
    for pointType, point in pairs(lane) do
      if point.waypoint  ~= nil then
        point.waypoint.name = 'drag_'..laneNum..'_'..pointType
        local wp = scenetree.findObject(point.waypoint.name)
        if not wp then
          log("I", logTag, 'Creating waypoint named "'..point.waypoint.name..'"')
          wp = createObject('BeamNGWaypoint')
          wp:setPosition(point.transform.pos)
          local scl = point.transform.scl or {x = 3, y = 3, z = 3}
          wp:setField('scale', 0, scl.x .. ' ' ..scl.y..' '..scl.z)
          wp:setField('rotation', 0, point.transform.rot.x .. ' ' ..point.transform.rot.y..' '..point.transform.rot.z..' '..point.transform.rot.w)
          wp:registerObject(point.waypoint.name)
          scenetree.MissionGroup:addObject(wp)
          needsMapReload = true
        else
          log("W", logTag, "Waypoint already exists in the scene: " .. point.waypoint.name)
        end
      end
    end
  end

  --Spawn all prefabs aviable in the file
  log("I", logTag, 'Loading Prefabs...')
  for prefabName, prefabData in pairs(data.strip.prefabs) do
    if prefabData.path and prefabData.isUsed then
      local existingPrefab = scenetree.findObject(prefabName)
      if not existingPrefab then
        log("I", logTag, 'Spawning Prefab: '..prefabData.path)
        local scenetreeObject = spawnPrefab(Sim.getUniqueName(prefabName) , prefabData.path, 0 .. " " .. 0 .. " " .. 0, "0 0 1 0", "1 1 1", false)
        scenetreeObject.canSave = false
        if scenetree.MissionGroup then
          scenetree.MissionGroup:add(scenetreeObject)
          prefabData.prefabId = scenetreeObject:getID()
          needsCollisionRebuild = true
          log("I", logTag, "Prefab ".. prefabName .." added to MissionGroup")
        else
          log("E","","No missiongroup found! MissionGroup = " .. scenetree.MissionGroup)
        end
      else
        log("W",logTag, 'Prefab already spawned: '..prefabName)
      end
    end
  end
  --Resets the collision to avoid issues with old data
  if needsCollisionRebuild then
    be:reloadCollision()
  end
  --Resets the Navgrapgh to avoid issues with old data, this has a callback
  if needsMapReload then
    map.reset()
  end
end

local function loadDataFromFile(filepath)
  clear()
  local data = jsonReadFile(filepath)

  --Comprobe that the data is valid and has all the necessary fields
  if not data then
    log("E", logTag, "Failed to read file: " .. filepath)
    return
  end
  if not data.context then
    log("E", logTag, "Failed to read context from file: " .. filepath)
    return
  end
  if not data.strip then
    log("E", logTag, "Failed to read strip from file: " .. filepath)
    return
  end
  if not data.phases then
    log("E", logTag, "Failed to read phases from file: " .. filepath)
    return
  end
  if #data.strip.lanes <= 0 then
    log("E", logTag, "Failed to read lanes from file: " .. filepath)
    return
  else
    --Create the lookuptable of aviable lanes.
    for k,lane in ipairs(data.strip.lanes) do
      aviableLanes[k] = true
      --Convert all the tables to vec3 and quat.
      for _, laneStage in pairs(lane) do
        -- first read the transform (pos, rot, scl)
        for transformKey, transformData in pairs(laneStage.transform) do
          if transformKey == "rot" then
            laneStage.transform[transformKey] = quat(transformData.x, transformData.y, transformData.z, transformData.w)
          else
            laneStage.transform[transformKey] = vec3(transformData.x, transformData.y, transformData.z)
          end
        end
        local rot = laneStage.transform.rot
        local scl = laneStage.transform.scl
        -- compute local unit vectors
        local x, y, z = rot * vec3(scl.x,0,0), rot * vec3(0,scl.y,0), rot * vec3(0,0,scl.z)
        laneStage.transform.x = x
        laneStage.transform.y = y
        laneStage.transform.z = z
      end

      local startToEnd = lane.endLine.transform.pos - lane.stage.transform.pos
      lane.stage.toEnd = startToEnd
      lane.stage.toEndNormalized = startToEnd:normalized()
    end
  end
  --Convert the endCamera transform to vec3 and quat if there is any camera.
  if data.strip.endCamera then
    for transformKey, transformData in pairs(data.strip.endCamera.transform) do
      if transformKey == "rot" then
        data.strip.endCamera.transform[transformKey] = quat(transformData.x, transformData.y, transformData.z, transformData.w)
      else
        data.strip.endCamera.transform[transformKey] = vec3(transformData.x, transformData.y, transformData.z)
      end
    end
  end
  --Create the base table for the vehicles.
  data.racers = {}

  --Load the prefabs and waypoints
  loadPrefabs(data)
  gameplayContext = "activity"
  extensions.load('gameplay_drag_dragTypes_headsUpDrag')
  ext = gameplay_drag_dragTypes_headsUpDrag
  return data
end

local function getSelection(classNames)
  local id
  if editor.selection and editor.selection.object and editor.selection.object[1] then
    local currId = editor.selection.object[1]
    if not classNames or arrayFindValueIndex(classNames, scenetree.findObjectById(currId).className) then
      id = currId
    end
  end
  return id
end

local function setupRacer(vehId, lane)
  if not dragData then return end

  if not vehId then
    log('E', logtag, 'Vehicle with ID: ' .. vehId .. ' not found at the sceneTree')
    return
  end

  local veh = scenetree.findObjectById(vehId)
  if not veh or veh.className ~= "BeamNGVehicle" then
    log('E', logtag, 'Object with ID: ' .. vehId .. ' is not a vehicle')
    return
  end

  --Create a table for this vehicle and add to racers
  local racer = {
    vehId = vehId,
    phases = {}, --list of phases that are active
    currentPhase = 1, --current phase that is active
    isPlayable = true, --determine if it's controlled by the AI or the player
    lane = lane, --lane number of this vehicle in the race
    isDesqualified = false, --if the vehicle is desqualified
    desqualifiedReason = "None", --reason for desqualification if applicable
    isFinished = false, --if the vehicle has finished the race
    wheelsOffsets = {}, --table for the wheels offsets
    currentCorners = {}, --table for the current corners offsets (For now this is not used)
    canBeTeleported = dragData.canBeTeleported, --if the vehicle can be teleported
    canBeReseted = dragData.canBeReseted, --if the vehicle can be reseted when teleported, if not, if the player breaks the vehicle it will not be reseted and the player will have to restart the race or keep with a broken vehicle
    timers = {
      -- TODO: this is duplicted in times.lua!
      dial = {type = "dialTimer", value = 0},
      timer = {type = "timer", value = 0},
      reactionTime = {type = "reactionTimer", value = 0, distance = 0.2, isSet = false, label = "Reaction Time"},
      time_60 = {type = "distanceTimer", value = 0, distance = 18.288, isSet = false, label = "Distance: 60ft / 18.28m"},
      time_330 = {type = "distanceTimer", value = 0, distance = 100.584, isSet = false, label = "Distance: 330ft / 100.58m"},
      time_1_8 = {type = "distanceTimer", value = 0, distance = 201.168, isSet = false, label = "Distance: 1/8th mile / 201.16m"},
      time_1000 = {type = "distanceTimer", value = 0, distance = 304.8, isSet = false, label = "Distance: 1000ft / 304.8m"},
      time_1_4 = {type = "distanceTimer", value = 0, distance = 402.336, isSet = false, label = "Distance: 1/4th mile / 402.34m"},
      velAt_1_8 = {type = "velocity", value = 0, distance = 201.168, isSet = false, label = "Distance: 1/8th mile / 201.16m"},
      velAt_1_4 = {type = "velocity", value = 0, distance = 402.336, isSet = false, label = "Distance: 1/4th mile / 402.34m"}
    }
  }

  -- add working vector3 fields
  racer.vehPos = vec3()
  racer.vehDirectionVector = vec3()
  racer.vehDirectionVectorUp = vec3()
  racer.vehRot = quat()
  racer.vehVelocity = vec3()
  racer.prevSpeed = 0
  racer.vehSpeed = 0
  racer.vehObj = {}

  --Save the wheels offsets in local transform, this way we can update it and calculate distances only with the vehicle position and rotation.
  local wCount = veh:getWheelCount()-1
  local wheelsByFrontness = {}
  local maxFrontness = -math.huge
  if wCount > 0 then
    local vehPos = veh:getPosition()
    local forward = veh:getDirectionVector()
    local up = veh:getDirectionVectorUp()
    local vRot = quatFromDir(forward, up)
    local x,y,z = vRot * vec3(1,0,0),vRot * vec3(0,1,0),vRot * vec3(0,0,1)
    local center = veh:getSpawnWorldOOBB():getCenter()
    for i=0,wCount do
      local axisNodes = veh:getWheelAxisNodes(i)
      local nodePos = vec3(veh:getNodePosition(axisNodes[1]))
      local wheelNodePos = vehPos + nodePos

      local frontness = forward:dot(wheelNodePos - center)

      -- check if theres already a frontness thats less than 0.2m away
      for key, _ in pairs(wheelsByFrontness) do
        if math.abs(tonumber(key) - frontness) < 0.2 then
          frontness = key
        end
      end

      local pos = vec3(nodePos:dot(x), nodePos:dot(y), nodePos:dot(z))
      wheelsByFrontness[frontness] = wheelsByFrontness[frontness] or {}
      table.insert(wheelsByFrontness[frontness], pos)
      
      maxFrontness = math.max(frontness, maxFrontness)

    end
  end



  if not next(wheelsByFrontness) then
    log('E', logTag, 'Couldnt find front wheels for ' .. vehId .. '! will use OOBB as wheel offsets')

    local vehPos = veh:getPosition()
    local forward = veh:getDirectionVector()
    local up = veh:getDirectionVectorUp()
    local vRot = quatFromDir(forward, up)
    local x,y,z = vRot * vec3(1,0,0),vRot * vec3(0,1,0),vRot * vec3(0,0,1)
    local frontLeft, frontRight = veh:getSpawnWorldOOBB():getPoint(0) - vehPos, veh:getSpawnWorldOOBB():getPoint(3) - vehPos

    local posL = vec3(frontLeft:dot(x),  frontLeft:dot(y),  frontLeft:dot(z))
    local posR = vec3(frontRight:dot(x), frontRight:dot(y), frontRight:dot(z))
    maxFrontness = "oobb"
    wheelsByFrontness[maxFrontness] = {posL, posR}

  end
  racer.wheelsOffsets = wheelsByFrontness[maxFrontness]

  racer.frontWheelCenter = vec3()
  racer.wheelCountInv = 1 / #racer.wheelsOffsets

  --Initialize phases for this vehicle
  for _, p in ipairs(dragData.phases) do
    table.insert(racer.phases, {
      name = p.name,
      started = false, --true if the phase has been started
      completed = false, --true if the phase is completed
      dependency = p.dependency, --true if this phase depends on another to be completed or started
      timerOffset = 0, --seconds
      startedOffset = p.startedOffset, --seconds constant
    })
  end

  --DEBUG
  if debugMenu then
    M.selectElement(vehId) --select the vehicle in the editor
  end

  log('I', logTag, "Loaded vehicle " .. vehId .. " at lane: " .. lane)
  dragData.racers[vehId] = racer
end
M.setupRacer = setupRacer

local function selectElement(index)
  selectedVehicle = index
end

local function getLastElement()
  for vehId,_ in pairs(dragData.racers) do
    selectedVehicle = vehId
  end
end

local red, yellow, green = im.ImVec4(1,0.5,0.5,0.75), im.ImVec4(1,1,0.5,0.75), im.ImVec4(0.5,1,0.5,0.75)
local function drawDebugMenu()
  if debugMenu then
    if im.Begin("Drag Race General Debug") then
      if not editor_fileDialog then im.BeginDisabled() end
      if im.Button("Load Save Data ##loadDataFromFile") then
        editor_fileDialog.openFile(function(data) loadDataFromFile(data.filepath) end, {{"dragData Files",".dragData.json"}}, false, currentFileDir)
      end
      if not editor_fileDialog then im.EndDisabled() end
      im.SameLine()
      if im.Button("Clear Save Data ##clearData") then
        dragData = nil
      end
      if dragData then
        im.Columns(2,'mainDrag')
        im.Text("Drag Data")
        im.Text("Context: ")
        im.SameLine()
        im.Text(dragData.context)

        im.Text("dragtype extension: ")
        im.SameLine()
        im.TextColored(ext and green or red, ext and ext.__extensionName__ or "No Extension")

        im.Text("Is Started:")
        im.SameLine()
        im.TextColored(dragData.isStarted and green or red, dragData.isStarted and "Started" or "Stopped")

        im.NewLine()
        im.Text("Phases: ")
        for index, value in ipairs(dragData.phases or {}) do
          im.SameLine()
          if im.Button("Play " .. value.name) then
            ext.startDebugPhase(index, dragData)
          end
        end
        im.NewLine()

        if im.Button("Start Drag Race") then
          M.startDragRaceActivity()
        end

        if im.Button("Reset Drag Race") then
          ext.resetDragRace()
        end


        im.NextColumn()
        im.Text("Strip Data")
        im.NewLine()
        if dragData.strip.endCamera then
          im.Text("End Camera: ")
          im.SameLine()
          im.Text("Position: {" .. dragData.strip.endCamera.transform.pos.x .. ", " .. dragData.strip.endCamera.transform.pos.y .. ", " .. dragData.strip.endCamera.transform.pos.z .. "}")
          im.SameLine()
          im.Text("Rotation: {" .. dragData.strip.endCamera.transform.rot.x .. ", " .. dragData.strip.endCamera.transform.rot.y .. ", " .. dragData.strip.endCamera.transform.rot.z .. ", " .. dragData.strip.endCamera.transform.rot.w .. "}")
          im.SameLine()
          im.Text("Scale: {" .. dragData.strip.endCamera.transform.scl.x .. ", " .. dragData.strip.endCamera.transform.scl.y .. ", " .. dragData.strip.endCamera.transform.scl.z .. "}")
        end

        for nameType, p in pairs(dragData.strip.prefabs) do
          im.Text("Prefab: " .. nameType)
          im.SameLine()
          im.Text(" | Is Used: " .. tostring(p.isUsed))
          if p.isUsed then
            im.SameLine()
            im.Text(" |  " .. (p.path or "No path founded"))
          end
        end
        im.NextColumn()

        im.Columns(2, 'vehicles')

        im.BeginChild1("vehicle select", im.GetContentRegionAvail(), 1)
        im.Text("Vehicle Settings")
        for k,v in ipairs(aviableLanes) do
          if v then
            if im.Selectable1("Empty Lane - " ..k.. "##" .. k) then
              local vehId = getSelection()

              setupRacer(vehId, k)
              if not dragData.racers[vehId] then
                aviableLanes[k] = true
              else
                aviableLanes[k] = false
              end
            end
            if im.IsItemHovered() then
              im.tooltip("Add selected vehicle from scenetree to Lane: " ..k)
            end
          end
        end
        for vehId, _ in pairs(dragData.racers or {}) do
          if im.Selectable1(string.format("Racer ID: %d Lane: %d", vehId, dragData.racers[vehId].lane), vehId == selectedVehicle) then
            M.selectElement(vehId)
          end
        end
        im.EndChild()
        im.NextColumn()

        im.BeginChild1("vehicle detail", im.GetContentRegionAvail(), 1)
        if selectedVehicle and dragData.racers[selectedVehicle] then
          if im.Button("Remove Vehicle" .. "##"..selectedVehicle) then
            aviableLanes[dragData.racers[selectedVehicle].lane] = true
            dragData.racers[selectedVehicle] = nil
            selectedVehicle = -1
            getLastElement()
          end

          im.NewLine()
          im.Text("Lane ".. dragData.racers[selectedVehicle].lane .. " Data :")
          if selectedVehicle ~= -1 then
            im.Text("(Click to dump, hover to preview)")
            for key, laneData in pairs(dragData.strip.lanes[dragData.racers[selectedVehicle].lane]) do
              if im.Button("Lanedata: " .. key) then
                dump(laneData.transform)
              end
              if im.IsItemHovered() and editor_dragRaceEditor then
                local rot = quat(laneData.transform.rot)
                local x, y, z = laneData.transform.x, laneData.transform.y, laneData.transform.z
                local scl = (x+y+z)/2
                editor_dragRaceEditor.drawAxisBox(((-scl*2)+vec3(laneData.transform.pos)),x*2,y*2,z*2,color(255,255,255,0.2*255))
                local pos = vec3(laneData.transform.pos)
                debugDrawer:drawLine(pos, pos + x, ColorF(1,0,0,0.8))
                debugDrawer:drawLine(pos, pos + y, ColorF(0,1,0,0.8))
                debugDrawer:drawLine(pos, pos + z, ColorF(0,0,1,0.8))
              end
              --[[
              im.Text("-" .. key .. ": ")
              im.Text("Position: {" .. laneData.transform.pos.x .. ", " .. laneData.transform.pos.y .. ", " .. laneData.transform.pos.z .. "}")
              im.SameLine()
              im.Text("Rotation: {" .. laneData.transform.rot.x .. ", " .. laneData.transform.rot.y .. ", " .. laneData.transform.rot.z .. "," .. laneData.transform.rot.w .. "}")
              im.SameLine()
              im.Text("Scale: {" .. laneData.transform.scl.x .. ", " .. laneData.transform.scl.y .. ", " .. laneData.transform.scl.z .. "}")
              ]]
            end
          end
          im.Text("Vehicle Data: ")
          local vehicleData = dragData.racers[selectedVehicle]
          if not vehicleData then
            im.Text("No vehicle data yet")
          else
            if im.Button("Dump Vehicle data") then
              dump(dragData.racers[selectedVehicle])
            end
            local isP = im.BoolPtr(vehicleData.isPlayable)
            im.Checkbox("Is Playable", isP)
            vehicleData.isPlayable = isP[0]
            im.SameLine()
            im.Text(vehicleData.isPlayable and "Is Playable" or "Not playable")
            im.Text("Lane: " .. vehicleData.lane)
            im.Text(vehicleData.isDesqualified and "Desqualified" or "Not desqualified")
            im.Text("Desqualification Reason: " ..vehicleData.desqualifiedReason)
            im.Separator()
            im.Text("Phases")

            for _, phase in ipairs(vehicleData.phases) do
              im.Text(phase.name .. " - ")
              im.SameLine()
              im.TextColored(phase.started and green or red, "Started")
              im.SameLine()
              im.TextColored(phase.completed and green or red, "Completed")
              im.Text(dumps(phase))
              im.Separator()
            end
          end
        end
        im.EndChild()
        im.NextColumn()
      end
      im.Columns(0)
    end
  end
end


--FREEROAM DRAG UPDATE FUNCTIONS--

local tempLanePos = vec3()
local function getLaneDependingOnDistanceToStage(vehPos)
  local distance = math.huge
  local selectedLaneIndex = 1
  for i, lane in ipairs(dragData.strip.lanes) do
    tempLanePos:set(lane.stage.transform.pos.x,lane.stage.transform.pos.y, lane.stage.transform.pos.z)
    local dist =  tempLanePos:squaredDistance(vehPos)
    if dist < distance then
      distance = dist
      selectedLaneIndex = i
    end
  end
  return selectedLaneIndex, distance
end

local posXYZ =  vec3()
local elapsedTime = 0
local inZone = false
local dist = 1000
local function onUpdate(dtReal, dtSim, dtRaw)

  -- BEAMLR EDIT START
  if extensions.blrglobals.blrFlagGet("disableFreeroamDragPractice") then return end
  -- BEAMLR EDIT END

  if not levelLoaded then return end
  if gameplay_missions_missionManager.getForegroundMissionId() then return end
  if gameplayContext == "freeroam" then
    initFlagCounter = initFlagCounter + 1
    if initFlagCounter == 10 then
      clear()
      levelDir = core_levels.getLevelByName(getCurrentLevelIdentifier()).dir
      dragData = init()
      initFlagCounter = 11
    end
    if initFlagCounter >= 10 and dragData and not dragData.isStarted then
      if elapsedTime > 0.5 then
        elapsedTime = 0
        local vehObj = be:getObjectByID(be:getPlayerVehicleID(0))
        if vehObj then
          posXYZ:set(vehObj:getPositionXYZ())
          local lane, squaredDistance = getLaneDependingOnDistanceToStage(posXYZ)
          if squaredDistance < 100 then
            M.startDragRaceActivity(lane)
          end
        end
        --dump(squaredDistance)
      end
      elapsedTime = elapsedTime + dtSim
    end
  end
  drawDebugMenu()
end

M.onUpdate = onUpdate
M.selectElement = selectElement
M.loadPrefabs = loadPrefabs

M.setFilepath = function (filepath)
  dragData = loadDataFromFile(filepath)
  log('I', logTag, 'Loaded data from file: ' .. filepath)
end

M.resetDragRace = function ()
  ext.resetDragRace()
end

M.clearRacers = function ()
  dragData.racers = {}
end

M.unloadRace = function ()
  clear()
end

M.setVehicles = function (vehIds)
  for i, data in ipairs(vehIds) do
    setupRacer(data.id, i)
    if not dragData.racers[data.id] then
      log("E", logTag, "There is a problem with the vehicle setting, vehicle has not been set correctly.")
      return
    end
    dragData.racers[data.id].isPlayable = data.isPlayable
  end
end

M.setPlayableVehicle = function (vehId)
  if not vehId then return end
  dragData.racers[vehId].isPlayable = true
end

M.getTimers = function (vehId)
  if not dragData then return end
  return dragData.racers[vehId].timers or {}
end

M.getRacerData = function (vehId)
  if not dragData or not dragData.racers[vehId] then return end
  return dragData.racers[vehId] or {}
end

M.startDragRaceActivity = function (lane)
  if not dragData or not dragData.racers then
    log("E", logTag, "Data not found to start the Drag Race")
    return
  end
  if lane ~= nil and gameplayContext == "freeroam" then
    setupRacers()
    dragData.racers[be:getPlayerVehicleID(0)].lane = lane
    loadPracticeExtension()
    log("I",logTag,"Starting Freeroam Dragrace on lane " .. lane)
  else
    ext.startActivity()
  end
end

M.getData = function ()
  return dragData
end

return M