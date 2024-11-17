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

----------------------------
-- Clearing and unloading --
----------------------------

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

-----------------------------
-- Loading data from files --
-----------------------------

local function loadTransform(t)
  for key, data in pairs(t) do
    if key == "rot" then
      t[key] = quat(data.x, data.y, data.z, data.w)
    else
      t[key] = vec3(data.x, data.y, data.z)
    end
  end

  -- TODO: deduplicate
  local rot = t.rot
  local scl = t.scl
  -- compute local unit vectors
  local x, y, z = rot * vec3(scl.x,0,0), rot * vec3(0,scl.y,0), rot * vec3(0,0,scl.z)
  t.x = x
  t.y = y
  t.z = z
end

local function loadDragStripData(filepath)
  if not filepath then
    log("E", logTag, "No filepath given for loading drag strip")
    return
  end
  local data = jsonReadFile(filepath)
  --Comprobe that the data is valid and has all the necessary fields
  if not data or not data.context or not data.strip or not data.phases or not next(data.strip.lanes)  then
    log("E", logTag, "Failed to read file: " .. filepath)
    return
  end

  for k,lane in ipairs(data.strip.lanes) do
    -- load all waypoint transforms
    for _, waypoint in pairs(lane.waypoints) do
      loadTransform(waypoint.transform)
    end
    -- boundary
    loadTransform(lane.boundary.transform)

    --
    local stageToEnd = lane.waypoints.endLine.transform.pos - lane.waypoints.stage.transform.pos
    lane.stageToEnd = stageToEnd
    lane.stageToEndNormalized = stageToEnd:normalized()
  end

  --Convert the endCamera transform to vec3 and quat if there is any camera.
  if data.strip.endCamera then
    for key, data in pairs(data.strip.endCamera.transform) do
      if key == "rot" then
        data.strip.endCamera.transform[key] = quat(data.x, data.y, data.z, data.w)
      else
        data.strip.endCamera.transform[key] = vec3(data.x, data.y, data.z)
      end
    end
  end

  data.isCompleted = false
  data.isStarted = false

  data.racers = {}
  log('I', logTag, 'Loaded drag strip from: '.. filepath)

  return data
end

local function loadPrefabs(data)
  if not data then return end

  log("I", logTag, 'Loading Waypoints...')
  for laneNum, lane in ipairs(data.strip.lanes) do
    for key, waypoint in pairs(lane.waypoints) do
      if waypoint.waypoint  ~= nil then
        local wp = scenetree.findObject(waypoint.name)
        if not wp then
          log("I", logTag, 'Creating waypoint named "'..waypoint.name..'"')
          wp = createObject('BeamNGWaypoint')
          wp:setPosition(waypoint.transform.pos)
          local scl = waypoint.transform.scl or {x = 3, y = 3, z = 3}
          wp:setField('scale', 0, scl.x .. ' ' ..scl.y..' '..scl.z)
          wp:setField('rotation', 0, waypoint.transform.rot.x .. ' ' ..waypoint.transform.rot.y..' '..waypoint.transform.rot.z..' '..waypoint.transform.rot.w)
          wp:registerObject(waypoint.name)
          scenetree.MissionGroup:addObject(wp)
          needsMapReload = true
        else
          log("W", logTag, "Waypoint already exists in the scene: " .. waypoint.name)
        end
      end
    end
  end

  --Spawn all prefabs aviable in the file
  log("I", logTag, 'Loading Prefabs...')
  for prefabName, prefabData in pairs(data.prefabs) do
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
    for prefabName, prefabData in pairs(dragData.prefabs) do
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


  local details = core_vehicles.getVehicleDetails(vehId)
  if details then
    racer.niceName = details.model.Brand .. " " .. details.configs.Name
  end
  local status, ret = xpcall(function() return type(deserialize(veh.partConfig)) end, nop)
  if not ret then
    racer.stock = true
  else
    racer.stock = false
  end
  racer.licenseText = core_vehicles.getVehicleLicenseText(veh)

  --DEBUG
  if debugMenu then
    M.selectElement(vehId) --select the vehicle in the editor
  end

  log('I', logTag, "Loaded vehicle " .. vehId .. " at lane: " .. lane)
  dragData.racers[vehId] = racer
end
M.setupRacer = setupRacer

-----------------------------
-- Mission Setup Interface --
-----------------------------

M.loadDragDataForMission = function (filepath)
  clear()
  local data = loadDragStripData(filepath)

  --Load the prefabs and waypoints
  loadPrefabs(data)
  gameplayContext = data.context
  extensions.load('gameplay_drag_dragTypes_headsUpDrag')
  ext = gameplay_drag_dragTypes_headsUpDrag
  dragData = data
  log('I', logTag, 'Loaded data from file: ' .. filepath)
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


------------------------------
-- Freeroam Setup Interface --
------------------------------

local function init()
  return loadDragStripData(levelDir .. "/dragstrips/dragStripData.dragData.json")
end

local tempLanePos = vec3()
local function getLaneDependingOnDistanceToStage(vehPos)
  local distance = math.huge
  local selectedLaneIndex = 1
  for i, lane in ipairs(dragData.strip.lanes) do
    tempLanePos:set(lane.waypoints.stage.transform.pos.x,lane.waypoints.stage.transform.pos.y, lane.waypoints.stage.transform.pos.z)
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
  --drawDebugMenu()
end
M.onUpdate = onUpdate



M.resetDragRace = function ()
  ext.resetDragRace()
end

M.clearRacers = function ()
  dragData.racers = {}
end

M.unloadRace = function ()
  clear()
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
    -- load the racer (player vehicle)
    dragData.racers = {}
    if lane == 1 then
      dragData.prefabs.christmasTree.treeType = ".500"
    else
      dragData.prefabs.christmasTree.treeType = ".400"
    end
    M.setupRacer(be:getPlayerVehicleID(0), lane)

    -- load the practice extension and
    extensions.load('gameplay_drag_dragTypes_' .. dragData.dragType)
    ext = gameplay_drag_dragTypes_dragPracticeRace
    gameplayContext = dragData.context or 'freeroam'

    log("I",logTag,"Starting Freeroam Dragrace on lane " .. lane)
  end
  ext.startActivity()
end



M.getData = function ()
  return dragData
end



-------------------------
-- Exit/Breakout hooks --
-------------------------

local function onVehicleResetted(vid)
  if be:getPlayerVehicleID(0) == vid then
    M.clearTimeslip()
  end
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


--TIMESLIP interface

local timerKeys = {"reactionTime", "time_60", "time_330", "time_1_8",  "time_1000", "time_1_4", }
local velocityKeys = {"velAt_1_4", "velAt_1_8"}
local rowsInfo = {
  { key = "laneName", label = "Lane" },
  --{ key = "tree", label = "Tree" },
  { key = nil, label = "" },  -- Fixed empty key
  { key = "reactionTime", label = "R/T" },
  { key = "time_60", label = "60'" },
  { key = "time_330", label = "330'" },
  { key = "time_1_8", label = "660'" },
  { key = "velAt_1_8_kmh", label = "km/h" },
  { key = "velAt_1_8_mph", label = "mph" },
  { key = "time_1000", label = "1000'" },
  { key = "time_1_4", label = "1/4 mile" },
  { key = "velAt_1_4_kmh", label = "km/h" },
  { key = "velAt_1_4_mph", label = "mph" },
}
local racerRowsInfo = {
  { key = "lane", label = "Lane" },
  { key = "licenseText", label = "License" },
  { key = "name", label = "Vehicle" },
  { key = "stock", label = "" },
}

local longestRowLabel = -math.huge
for _, r in ipairs(rowsInfo) do
  longestRowLabel = math.max(longestRowLabel, #r.label+2)
end
for _, r in ipairs(racerRowsInfo) do
  longestRowLabel = math.max(longestRowLabel, #r.label+2)
end
for _, r in ipairs(rowsInfo) do
  r.label = r.label .. string.rep(".", longestRowLabel - #r.label)
end
  for _, r in ipairs(racerRowsInfo) do
  r.label = r.label .. string.rep(".", longestRowLabel - #r.label)
end

local treeNames = {[".400"] = "Pro Tree", [".500"] = "Sportsman Tree"}
M.clearTimeslip = function()
  guihooks.trigger("onDragRaceTimeslipData", nil)
end
M.sendTimeslipDataToUi = function()
  log("I","","Requesting Timeslip Data...")
  if not dragData or not next(dragData) then
    guihooks.trigger("onDragRaceTimeslipData", nil)
    return
  end
  -- main data
  local slipData = {}

  -- info about the strip itself
  local stripInfo = {}
  table.insert(stripInfo, dragData.stripInfo and dragData.stripInfo.stripName or "Drag Strip")
  table.insert(stripInfo, core_levels.getLevelByName(getCurrentLevelIdentifier()).title)
  table.insert(stripInfo, os.date(dragData.stripInfo and dragData.stripInfo.dateFormat or "%a %m/%d/%Y %I:%M:%S %p"))
  slipData.stripInfo = stripInfo
  slipData.tree = treeNames[dragData.prefabs.christmasTree.treeType]
  slipData.env = {
    tempK = core_environment.getTemperatureK(),
    tempC = core_environment.getTemperatureK() - 273.15,
    tempF = (core_environment.getTemperatureK() - 273.15) * (9/5) + 32,
    customGrav = math.abs(core_environment.getGravity() - 9.81) > 0.01,
    gravity = string.format("%0.2f m/s²", 100*core_environment.getGravity() / 9.81),
  }

  -- initialize every lane as empty
  local dataByLane = {}
  local laneNumsOrdered = {}
  for laneNum, lane in ipairs(dragData.strip.lanes) do
    dataByLane[laneNum] = {laneName = lane.shortName}
    table.insert(laneNumsOrdered, laneNum)
  end
  table.sort(laneNumsOrdered, function(a,b) return ((dragData.strip.lanes[a].laneOrder) or a) > ((dragData.strip.lanes[b].laneOrder) or b) end)



  local racerInfos = {}
  for vehId, racer in pairs(dragData.racers) do
    for _, key in ipairs(timerKeys) do
      dataByLane[racer.lane][key] = string.format("%0.3f",racer.timers[key].value)
    end
    for _, key in ipairs(velocityKeys) do
      dataByLane[racer.lane][key..'_kmh'] = string.format("%0.3f",racer.timers[key].value * 3.6)
      dataByLane[racer.lane][key..'_mph'] = string.format("%0.3f",racer.timers[key].value * 2.23694)
    end

    local racerInfo = {
      name = racer.niceName,
      stock = racer.stock and "Stock" or "Modified",
      licenseText = racer.licenseText,
      lane = dragData.strip.lanes[racer.lane].longName,
      laneOrder = dragData.strip.lanes[racer.lane].laneOrder,
      laneNum = racer.lane,
      finalTime = racer.timers.time_1_4.value,
    }
    table.insert(racerInfos, racerInfo)
  end
  table.sort(racerInfos, function(a,b) return a.laneOrder < b.laneOrder end)
  slipData.racerInfos = racerInfos


  -- build final table for UI
  local tab = {}
  for _, r in ipairs(rowsInfo) do
    local row = {}
    table.insert(row, r.label)
    for _, laneNum in ipairs(laneNumsOrdered) do
      if r.key then
        local col = dataByLane[laneNum]
        if col then
          table.insert(row, col[r.key] or " - ")
        else
          table.insert(row, '-')
        end
      else
        table.insert(row, ' ')
      end
    end
    table.insert(tab, row)
  end

  if #racerInfos > 1 then
    if racerInfos[1].finalTime < racerInfos[2].finalTime then
      table.insert(tab, {'',string.format("+%0.3f",racerInfos[2].finalTime - racerInfos[1].finalTime),'WINNER'})
    else
      table.insert(tab, {'','WINNER',string.format("+%0.3f",racerInfos[1].finalTime - racerInfos[2].finalTime)})
    end

  end

  slipData.timesTable = tab


  guihooks.trigger("onDragRaceTimeslipData", slipData)

end

M.screenshotTimeslip = function()
  local dir = "screenshots/timeslips/"..getScreenShotDateTimeString()
  screenshot.doScreenshot(nil, nil, dir,'jpg')
  ui_message("Timeslip saved: " .. dir .. ".jpg", nil, nil, "save")
end


-- DEBUG FUNCTIONALITY


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
      --[[
      if not editor_fileDialog then im.BeginDisabled() end
      if im.Button("Load Save Data ##loadDataFromFile") then
        editor_fileDialog.openFile(function(data) loadDataFromFile(data.filepath) end, {{"dragData Files",".dragData.json"}}, false, currentFileDir)
      end
      if not editor_fileDialog then im.EndDisabled() end
      ]]
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

        for nameType, p in pairs(dragData.prefabs) do
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
            selectElement(vehId)
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


return M