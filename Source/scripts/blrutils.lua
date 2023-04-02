-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local json = require("json")
local extensions = require("extensions")

local dailySeedOffset = 1000	-- Seed offset for daily seed should be bigger value than total amount of needed rolls in flowgraph.
local startSeed = 1234			-- in order to avoid repeating random values. Without this value the paint colors in shop
local day = 0					-- are still showing up the next day, just offset by one vehicle. Increase as needed.

local pwager = 5000				-- Player wager, start scenario with max wager but could add proper option val 
local lastProcessedRace = {}	

local markers = {}
local markersOriginPos = {}      -- To fix markers moving downwards, likely due to floating point error when using pos = pos + sin(os.clock())

local blrtime = 0				-- Not time of day, used for race timers

local function deleteFile(filename)
if FS:fileExists(filename) then 
FS:removeFile(filename)
end
end

local function deleteDir(dir)
if FS:directoryExists(dir) then
FS:directoryRemove(dir)
end
end

local function moveFile(old, new)
if FS:fileExists(old) then 
FS:renameFile(old, new)
end
end

local function copyFile(src, dst)
if FS:fileExists(src) then
FS:copyFile(src,dst)
end
end


local function ssplit(s, delimiter) 
local result = {}
if delimiter == "." then
for match in (s..delimiter):gmatch("(.-)%"..delimiter) do
table.insert(result, match)
end
else
for match in (s..delimiter):gmatch("(.-)"..delimiter) do
table.insert(result, match)
end
end
return result
end

local function ssplitnum(s, delimiter) 
local result = {}
if delimiter == "." then
for match in (s..delimiter):gmatch("(.-)%"..delimiter) do
table.insert(result, tonumber(match))
end
else
for match in (s..delimiter):gmatch("(.-)"..delimiter) do
table.insert(result, tonumber(match))
end
end
return result
end

local function lerp(rel, minv, maxv, invert)
local toRet = 0
if invert then
toRet = maxv - (maxv-minv) * rel
else
toRet = minv + (maxv-minv) * rel
end
return toRet
end

local function createPaint(paint)
return createVehiclePaint({x = tonumber(paint[1]), y = tonumber(paint[2]), z = tonumber(paint[3]), w = tonumber(paint[4])}, {tonumber(paint[5]),tonumber(paint[6]),tonumber(paint[7]),tonumber(paint[8])})
end

local function createRandomPaint(seed)
math.randomseed(seed)
return createVehiclePaint({x = tonumber(math.random()), y = tonumber(math.random()), z = tonumber(math.random()), w = tonumber(math.random())}, {tonumber(math.random()),tonumber(math.random()),tonumber(math.random()),tonumber(math.random())})
end

local function boolToText(val, truetxt, falsetxt)
if val then return truetxt else return falsetxt end
end

local function cameraReset()
extensions.core_camera.resetCamera(0)
end

local function readJSONFile(filename)
  local content = readFile(filename)
  if content then
    local ok, data = pcall(json.decode, content)
    if ok == true then
		return data
    end
  end
end

local function blrSpawnPrefab(name,path,pos,rot,scl)
spawnPrefab(name,path,pos,rot,scl)
end

local function getLevelName()
return extensions.core_levels.getLevelName(getMissionFilename())
end


local function getObjectID(name)
return scenetree.findObject(name or "")
end

local function getObjectPosName(name)
return scenetree.findObject(name):getPosition()
end

local function getObjectPosID(id)
return scenetree.findObjectById(id):getPosition()
end

local function spawnMarkers(mtable)
local mid = 1
local marker = {}
for k,v in pairs(mtable) do
marker = createObject('TSStatic')
marker:setField('shapeName', 0, 'art/shapes/collectible/s_marker_BNG.dae')
marker:setPosition(getObjectPosName(v))
marker.scale = vec3(2, 2, 2)
marker:registerObject(mid .. "marker")
markers[k] = marker
markersOriginPos[k] = getObjectPosName(v) -- Store spawn position to use as center point of animation
end
end

local function deleteMarkers()
for k,v in pairs(markers) do
markers[k]:delete()
end
markers = {}
end

local function updateMarkers()
local pos = {}
local rot = {}

for k,v in pairs(markers) do
v:setPosition(markersOriginPos[k] + (vec3(0,0, math.sin(os.clock()) * 0.1)))
rot = quatFromEuler(0,0,(os.clock()*1.75)):toTorqueQuat()
v:setField('rotation', 0, rot.x .. ' ' .. rot.y .. ' ' .. rot.z .. ' ' .. rot.w)
end
end


local function getSettingValue(key)
return settings.getValue(key)
end

local function loadDataTable(file)
local filedata = readFile(file)
local dtable = {}
for k,v in string.gmatch(filedata, "([^%c]+)=([^%c]+)") do
    dtable[k] = v
end
return dtable
end

local function saveDataTable(file, data)
local filedata = ""
for k,v in pairs(data) do
filedata = filedata .. k .. "=" .. v .. "\n"
end
writeFile(file, filedata)
end

local function updateDataTable(file, mergeData)
local dtable = loadDataTable(file)
for k,v in pairs(mergeData) do
dtable[k] = v
end
saveDataTable(file, dtable)
end


local function slotHelper()
local filedata = ""
local veh = be:getPlayerVehicle(0)
local vehicleData = map.objects[veh:getId()]
local pos = vehicleData.pos:toTable()
local rot = quatFromDir(vehicleData.dirVec, vehicleData.dirVecUp):toTable()
filedata = "slotp=" .. pos[1] .. "," .. pos[2] .. "," .. pos[3] .. "\n"
filedata = filedata .. "slotr=" .. rot[1] .. "," .. rot[2] .. "," .. rot[3] .. "," .. rot[4] .. "\n"
pos = getCameraPosition():toTable()
rot = getCameraQuat():toTable()
filedata = filedata .. "camp=" .. pos[1] .. "," .. pos[2] .. "," .. pos[3] .. "\n"
filedata = filedata .. "camr=" .. rot[1] .. "," .. rot[2] .. "," .. rot[3] .. "," .. rot[4]
writeFile("beamLR/slotHelper", filedata)
end

local function saveUIPaintToGarageFile(gid, paintdata)
paintdata["paintA"] = string.gsub(paintdata["paintA"], " ", ",")
paintdata["paintB"] = string.gsub(paintdata["paintB"], " ", ",")
paintdata["paintC"] = string.gsub(paintdata["paintC"], " ", ",")
updateDataTable("beamLR/garage/car" .. gid, paintdata)
end

local function convertUIPaintToVehiclePaint(paintdata)
local toRet = {}
local cpaint = ssplit(string.gsub(paintdata["paintA"], " ", ","), ",")
toRet["paintA"] = createVehiclePaint({x=tonumber(cpaint[1]), y=tonumber(cpaint[2]), z=tonumber(cpaint[3]), w=tonumber(cpaint[4])}, {tonumber(cpaint[5]), tonumber(cpaint[6]), tonumber(cpaint[7]), tonumber(cpaint[8])})
cpaint = ssplit(string.gsub(paintdata["paintB"], " ", ","), ",")
toRet["paintB"] = createVehiclePaint({x=tonumber(cpaint[1]), y=tonumber(cpaint[2]), z=tonumber(cpaint[3]), w=tonumber(cpaint[4])}, {tonumber(cpaint[5]), tonumber(cpaint[6]), tonumber(cpaint[7]), tonumber(cpaint[8])})
cpaint = ssplit(string.gsub(paintdata["paintC"], " ", ","), ",")
toRet["paintC"] = createVehiclePaint({x=tonumber(cpaint[1]), y=tonumber(cpaint[2]), z=tonumber(cpaint[3]), w=tonumber(cpaint[4])}, {tonumber(cpaint[5]), tonumber(cpaint[6]), tonumber(cpaint[7]), tonumber(cpaint[8])})
return toRet
end

local function convertUIPaintToMeshColors(paintdata) -- Part of bug workaround
local toRet = {}
local cpaint = ssplit(string.gsub(paintdata["paintA"], " ", ","), ",")
toRet["car"] = cpaint[1]
toRet["cag"] = cpaint[2]
toRet["cab"] = cpaint[3]
toRet["caa"] = cpaint[4]
cpaint = ssplit(string.gsub(paintdata["paintB"], " ", ","), ",")
toRet["cbr"] = cpaint[1]
toRet["cbg"] = cpaint[2]
toRet["cbb"] = cpaint[3]
toRet["cba"] = cpaint[4]
cpaint = ssplit(string.gsub(paintdata["paintC"], " ", ","), ",")
toRet["ccr"] = cpaint[1]
toRet["ccg"] = cpaint[2]
toRet["ccb"] = cpaint[3]
toRet["cca"] = cpaint[4]
return toRet
end

local function livePaintUpdate(vid, paintdata)
extensions.core_vehicle_manager.liveUpdateVehicleColors(vid, nil, 1, paintdata["paintA"])
extensions.core_vehicle_manager.liveUpdateVehicleColors(vid, nil, 2, paintdata["paintB"])
extensions.core_vehicle_manager.liveUpdateVehicleColors(vid, nil, 3, paintdata["paintC"])
end

local function blrGetVehiclePaint() -- dont think I need this
local baseColor = getVehiclePaint().baseColor
local paintData =  createVehiclePaint(baseColor, be:getPlayerVehicle(0).metallicPaintData:toTable())
paintData.baseColor = baseColor
return paintData
end

local function blrSpawn(model, opt)
return extensions.core_vehicles.spawnNewVehicle(model, opt)
end

local function getVehicleMainPartName()
return extensions.core_vehicle_manager.getPlayerVehicleData().mainPartName
end

local function getGoodSlotList()	-- NEED THIS FOR REPAINT SYSTEM WHEN USING PART INTEGRITY, YOU KNOW THE BUG...
local toRet = {}
local allparts = extensions.core_vehicle_manager.getPlayerVehicleData().vdata.flexbodies
for _, flexbody in pairs(allparts) do
table.insert(toRet, flexbody.mesh)
end
local chosen = extensions.core_vehicle_manager.getPlayerVehicleData().chosenParts
for k,v in pairs(chosen) do
table.insert(toRet, v)
table.insert(toRet, k)
end
return toRet
end

local function repaintFullMesh(vid, r, g, b, a, r2, g2, b2, a2, r3, g3, b3, a3) -- For bug workaround, could be used on individual panels...?
local parts = getGoodSlotList()
local cstring = ""
for k,v in pairs(parts) do
cstring = string.format("partCondition.setPartMeshColor(%q, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d)",v,1+r*254,1+g*254,1+b*254,1+a*254,1+r2*254,1+g2*254,1+b2*254,1+a2*254,1+r3*254,1+g3*254,1+b3*254,1+a3*254)
be:getObjectByID(vid):queueLuaCommand(cstring)
end
end

local function getGarageCarPaint(gid)
local toRet = {}
local dtable = loadDataTable("beamLR/garage/car" .. gid)
toRet["paintA"] = string.gsub(dtable["paintA"], ",", " ")
toRet["paintB"] = string.gsub(dtable["paintB"], ",", " ")
toRet["paintC"] = string.gsub(dtable["paintC"], ",", " ")
return toRet
end

local function garagePaintReload(vid, gid)
local mc = convertUIPaintToMeshColors(getGarageCarPaint(gid))
repaintFullMesh(vid, mc.car,mc.cag, mc.cab, mc.caa, mc.cbr,mc.cbg,mc.cbb, mc.cba, mc.ccr,mc.ccg,mc.ccb, mc.cca)
end

local function processRaceRandoms(raceData)
local toRet = {}
local crand = 0
local wager= ssplit(raceData["wager"], ",")
local parts= ssplit(raceData["parts"], ",")
local partsRand = tonumber(raceData["partsRand"]) == 1
local reputation = ssplit(raceData["rep"], ",")
local enemyModels = ssplit(raceData["enemyModel"], ",")
local enemyConfigs = ssplit(raceData["enemyConfig"], ",")
local enemyRisk = ssplit(raceData["enemyRisk"], ",")
local laps = ssplit(raceData["laps"], ",")

if #wager > 1 then 
toRet["wager"] = math.random(tonumber(wager[1]), tonumber(wager[2]))
else 
toRet["wager"] = tonumber(wager[1])
end

if partsRand then
crand = math.random(#parts)
toRet["parts"] = parts[crand]
else
toRet["parts"] = raceData["parts"]
end

if #reputation > 1 then
toRet["rep"] = math.random(tonumber(reputation[1]), tonumber(reputation[2]))
else 
toRet["rep"] = tonumber(reputation[1])
end

if #enemyModels > 1 then
crand = math.random(#enemyModels)
toRet["enemyModel"] = enemyModels[crand]
toRet["enemyConfig"] = enemyConfigs[crand]
else 
toRet["enemyModel"] = raceData["enemyModel"]
toRet["enemyConfig"] = raceData["enemyConfig"]
end

if #enemyRisk > 1 then
toRet["enemyRisk"] = math.random(tonumber(enemyRisk[1])*100.0, tonumber(enemyRisk[2])*100.0) / 100.0
else
toRet["enemyRisk"] = tonumber(enemyRisk[1])
end

if #laps > 1 then
toRet["laps"] = math.random(tonumber(laps[1]), tonumber(laps[2]))
else
toRet["laps"] = tonumber(laps[1])
end

lastProcessedRace = toRet

return toRet
end

local function processChallengeRandoms(cdata)
local toRet = {}
local wager = ssplit(cdata["wager"], ",")
local targetspd = ssplit(cdata["targetspd"] or "", ",")
local targettime = ssplit(cdata["targettime"] or "", ",")
local driftpts = ssplit(cdata["driftpts"] or "", ",")
local reputation = ssplit(cdata["rep"] or "", ",")
local rval = math.random()
local cmin, cmax = 0,0


if #wager > 1 then 
toRet["wager"] = math.floor(lerp(rval, tonumber(wager[1]), tonumber(wager[2]), false))
else 
toRet["wager"] = tonumber(wager[1])
end

if #targetspd > 1 then 
toRet["targetspd"] = lerp(rval,tonumber(targetspd[1]), tonumber(targetspd[2]), false)
else 
toRet["targetspd"] = tonumber(targetspd[1])
end

if #targettime > 1 then 
toRet["targettime"] = lerp(rval,tonumber(targettime[1]), tonumber(targettime[2]), true)
else 
toRet["targettime"] = tonumber(targettime[1])
end

if #driftpts > 1 then 
toRet["driftpts"] = math.floor(lerp(rval,tonumber(driftpts[1]), tonumber(driftpts[2]), false))
else 
toRet["driftpts"] = tonumber(driftpts[1])
end

if #reputation > 1 then
toRet["rep"] = math.floor(lerp(rval,tonumber(reputation[1]), tonumber(reputation[2]), false))
else 
toRet["rep"] = tonumber(reputation[1])
end


return toRet
end



local function getVehicleData(vid)
local toRet = {}
local veh = {}
if vid ~= nil then
veh = scenetree.findObjectById(self.pinIn.vehId.value)
else
veh = be:getPlayerVehicle(0)
end
local vehicleData = map.objects[veh:getId()]
toRet["active"] = vehicleData.active
toRet["damage"] = vehicleData.damage
toRet["dirVec"] = vehicleData.dirVec:toTable()
toRet["dirVecUp"] = vehicleData.dirVecUp:toTable()
toRet["position"] = vehicleData.pos:toTable()
toRet["velocityVector"] = vehicleData.vel:toTable()
toRet["velocity"] = vehicleData.vel:length()
toRet["rotation"] = quatFromDir(vehicleData.dirVec, vehicleData.dirVecUp)
return toRet
end

local function processMissionRandoms(mdata)
local toRet = {}
local reward = ssplit(mdata["reward"] or "",",")

if #reward > 1 then 
toRet["reward"] = math.random(tonumber(reward[1]), tonumber(reward[2]))
else 
toRet["reward"] = tonumber(reward[1])
end

return toRet
end

local function vehiclePaintToGaragePaint(paintdata)
local toRet = ""
toRet = toRet .. paintdata.baseColor[1] .. ","
toRet = toRet .. paintdata.baseColor[2] .. ","
toRet = toRet .. paintdata.baseColor[3] .. ","
toRet = toRet .. paintdata.baseColor[4] .. ","
toRet = toRet .. paintdata.metallic .. ","
toRet = toRet .. paintdata.roughness .. ","
toRet = toRet .. paintdata.clearcoat .. ","
toRet = toRet .. paintdata.clearcoatRoughness
return toRet
end

local function processCarShopRandoms(dtable, seed)
local toRet = {}
local baseprice = ssplit(dtable["baseprice"], ",")
local odometer = ssplit(dtable["odometer"], ",")
math.randomseed(seed)	-- Load spawn seed
local roll = math.random()


if #baseprice > 1 then 
toRet["baseprice"] = tonumber(baseprice[1]) + roll * (tonumber(baseprice[2])-tonumber(baseprice[1]))
else 
toRet["baseprice"] = tonumber(baseprice[1])
end

if #odometer > 1 then 
toRet["odometer"] = tonumber(odometer[1]) + (1.0-roll) * (tonumber(odometer[2])-tonumber(odometer[1]))
else 
toRet["odometer"] = tonumber(odometer[1])
end
math.randomseed(os.time()) -- Return seed to pseudorandom value 
return toRet
end


local function getGameDay()
return day
end

local function setGameDay(d)
day = d
end

local function getDailySeed()
return startSeed + day * dailySeedOffset
end

local function initStartSeed(s)
startSeed = s
end

local function formatTimeOfDay(t)
local toRet = {}
local timeval = (t * 24.0 * 60.0) + (12.0 * 60.0)
local uitime = math.floor(timeval % (24.0*60.0))
local i,f = math.modf(timeval)

local seconds = math.floor((f * 60.0 / 100.0)*100.0)
local hours = math.floor(uitime / 60.0)
local minutes = math.floor(uitime - (hours*60.0))
toRet["hours"] = hours
toRet["minutes"] = minutes
toRet["seconds"] = seconds
return toRet
end

local function resetShopDailyData()
local allfiles = FS:findFiles("beamLR/shop/daydata", "*", 0)
for k,v in pairs(allfiles) do
deleteFile(v)
copyFile("beamLR/init/emptyShopDayData", v)
end
end

local function updateShopDailyData(shopFile, slot)
local dtable = loadDataTable("beamLR/shop/daydata/" .. shopFile)
if dtable["pslots"] == "none" then 
dtable["pslots"] = "" .. slot
else
dtable["pslots"] = dtable["pslots"] .. "," .. slot
end
updateDataTable("beamLR/shop/daydata/" .. shopFile, dtable)
end

local function processGasStationRandoms(data, seed)
local toRet = {}
local cost = ssplit(data["cost"], ",")

math.randomseed(seed)

if #cost > 1 then 
toRet["cost"] = math.random(tonumber(cost[1])*100.0, tonumber(cost[2])*100.0) / 100.0
else
toRet["cost"] = tonumber(cost[1])
end

return toRet
end


local function getCareerSeed()
local dtable = loadDataTable("beamLR/options")
return dtable["sseed"]
end

local function getNextCareerSeed()
local dtable = loadDataTable("beamLR/options")
return dtable["nseed"]
end

local function cycleCareerSeed()
local dtable = loadDataTable("beamLR/options")
local autoseed = dtable["autoseed"] or "false" -- Defaults to "false" for old versions
if autoseed == "true" then -- New automatic seed increment feature
if tonumber(dtable["sseed"]) > 0 and tonumber(dtable["sseed"]) < 9999999999 then
dtable["nseed"] = tonumber(dtable["sseed"]) + 1 -- Current seed within range, just increment
else
dtable["nseed"] = 1 -- Loop back to seed 1 if set seed was out of incrementable range
end
end
dtable["sseed"] = dtable["nseed"] -- Cycles the seed data
updateDataTable("beamLR/options", dtable)
end

local function setNextCareerSeed(seed)
local dtable = {}
dtable["nseed"] = seed
updateDataTable("beamLR/options", dtable)
end

local function getDifficultyLevel() 
local dtable = loadDataTable("beamLR/options")
return dtable["difficulty"]
end

local function getStarterCarID(seed, count)
math.randomseed(seed)
return math.random(0,count-1)
end

local function getOptionsTable()
return loadDataTable("beamLR/options")
end

local function resetCareer() 

cycleCareerSeed()

local options = getOptionsTable()
local seed = tonumber(options["sseed"]) -- Career seed cycled before this line so auto increment feature can work
local startCarCount = #FS:findFiles("beamLR/init/garage/", "*", 0) -- Automatically find amount of starter cars for easier modding
local carid = getStarterCarID(seed, startCarCount)
local difficulty = options["difficulty"] or "hard"	-- Default to hard difficulty if options file comes from older mod version

deleteFile("beamLR/mainData")
deleteFile("beamLR/partInv")

local count = #FS:findFiles("beamLR/garage/", "*", 0)

for i=0,count-1 do -- Clear out garage 
deleteFile("beamLR/garage/car" .. i)
deleteFile("beamLR/garage/config/car" .. i)
deleteFile("beamLR/beamstate/car" .. i .. ".save.json")
deleteFile("beamLR/beamstate/mech/car" .. i)
deleteFile("beamLR/beamstate/integrity/car" .. i)
end

for _,v in pairs(FS:directoryList("beamLR/races")) do	-- Loop over all available race clubs to reset progress files
if v ~= "/beamLR/races/integrity" then					-- this should automatically detect all folders except integrity store
deleteFile(v .. "/progress")
copyFile("beamLR/init/emptyRaceProgress", v .. "/progress")
end
end

resetShopDailyData()


-- Difficulty setting based
copyFile("beamLR/init/mainData_" .. difficulty ,  "beamLR/mainData")
-- Just copy empty starter inventory no matter difficulty level
copyFile("beamLR/init/partInv",  "beamLR/partInv")
-- Uses seed based random starter car ID out of available setups, not based on difficulty
copyFile("beamLR/init/garage/car" .. carid , "beamLR/garage/car0")
copyFile("beamLR/init/garage/config/car" .. carid , "beamLR/garage/config/car0")
copyFile("beamLR/init/beamstate/car" .. carid .. ".save.json" , "beamLR/beamstate/car0.save.json")
copyFile("beamLR/init/beamstate/mech/car" .. carid , "beamLR/beamstate/mech/car0")
copyFile("beamLR/init/beamstate/integrity/car" .. carid , "beamLR/beamstate/integrity/car0")
end

local function backupCareer()
-- Root folder data
copyFile("beamLR/mainData", "beamLR/backup/mainData")
copyFile("beamLR/partInv", "beamLR/backup/partInv")
copyFile("beamLR/options", "beamLR/backup/options")

-- Garage data
local count = #FS:findFiles("beamLR/garage/", "*", 0)
for i=0,count-1 do 
copyFile("beamLR/garage/car" .. i, "beamLR/backup/garage/car" .. i)
copyFile("beamLR/garage/config/car" .. i,"beamLR/backup/garage/config/car" .. i)
copyFile("beamLR/beamstate/car" .. i .. ".save.json","beamLR/backup/beamstate/car" .. i .. ".save.json")
copyFile("beamLR/beamstate/mech/car" .. i,"beamLR/backup/beamstate/mech/car" .. i)
copyFile("beamLR/beamstate/integrity/car" .. i,"beamLR/backup/beamstate/integrity/car" .. i)
end

-- Race progress data
local dest = ""
for _,v in pairs(FS:directoryList("beamLR/races")) do	
if v ~= "/beamLR/races/integrity" then
dest = v:gsub("beamLR", "beamLR/backup")				
copyFile(v .. "/progress", dest .. "/progress")
end
end

-- Daily data
local dayfiles = FS:findFiles("beamLR/shop/daydata", "*", 0)
local dest = ""
for _,v in pairs(dayfiles) do
dest = v:gsub("beamLR", "beamLR/backup")	
copyFile(v,dest)
end


end

local function restoreBackup()
if #FS:findFiles("beamLR/backup", "*", 0) > 0 then -- Check if a backup exists before loading

-- Clear out existing data with career reset
resetCareer()

-- Root folder data
copyFile("beamLR/backup/mainData","beamLR/mainData")
copyFile("beamLR/backup/partInv","beamLR/partInv")
copyFile("beamLR/backup/options","beamLR/options")

-- Garage data
local count = #FS:findFiles("beamLR/backup/garage/", "*", 0)
for i=0,count-1 do 
copyFile("beamLR/backup/garage/car" .. i,"beamLR/garage/car" .. i)
copyFile("beamLR/backup/garage/config/car" .. i,"beamLR/garage/config/car" .. i)
copyFile("beamLR/backup/beamstate/car" .. i .. ".save.json", "beamLR/beamstate/car" .. i .. ".save.json")
copyFile("beamLR/backup/beamstate/mech/car" .. i,"beamLR/beamstate/mech/car" .. i)
copyFile("beamLR/backup/beamstate/integrity/car" .. i,"beamLR/beamstate/integrity/car" .. i)
end

-- Race progress data
local dest = ""
for _,v in pairs(FS:directoryList("beamLR/backup/races")) do	
if v ~= "/beamLR/backup/races/integrity" then
dest = v:gsub("beamLR/backup", "beamLR")				
copyFile(v .. "/progress", dest .. "/progress")
end
end

-- Daily data
local dayfiles = FS:findFiles("beamLR/backup/shop/daydata", "*", 0)
local dest = ""
for _,v in pairs(dayfiles) do
dest = v:gsub("beamLR/backup", "beamLR")	
copyFile(v,dest)
end

extensions.blrglobals.blrFlagSet("restartQueued", true) -- Queue restart for flowgraph

end
end


local function msTimeFormat(time)
local toRet = {}
toRet["hours"] = math.floor(time / 3600000)
toRet["minutes"] = math.floor((time / 60000) - toRet["hours"] * 60)
toRet["seconds"] = math.floor((time / 1000) - ((toRet["hours"] * 3600) + toRet["minutes"] * 60))
toRet["milliseconds"] = time - (toRet["hours"] * 3600000 + toRet["minutes"] * 60000 + toRet["seconds"]*1000)
return toRet
end

local function raceTimeString(time)
return string.format("%02d:%02d.%03d", time["minutes"], time["seconds"], time["milliseconds"])
end


-- Used to keep track of race times with working pause function
local function onPreRender(dtReal,dtSim,dtRaw)
blrtime = blrtime + dtSim * 1000
end

local function getRaceTime()
return blrtime
end

local function nitrousCheck(veid) -- To quickly check if a vehicle has bottle before calling VLUA related to N2O
local parts = extensions.betterpartmgmt.getVehicleParts(veid)
return not (parts["n2o_bottle"] == nil or parts["n2o_bottle"] == "")
end

local function getMapSpawn()
local toRet = {}
local path = "beamLR/mapdata/" .. getLevelName() .. "/spawn"
local dtable = loadDataTable(path)
toRet["pos"] = ssplitnum(dtable["pos"], ",")
toRet["rot"] = ssplitnum(dtable["rot"], ",")
return toRet
end

local function getMapTowSpot()
local toRet = {}
local path = "beamLR/mapdata/" .. getLevelName() .. "/towing"
local dtable = loadDataTable(path)
toRet["pos"] = ssplitnum(dtable["pos"], ",")
return toRet
end

local function setWager(wager)
pwager = wager
end

local function getWager()
return pwager
end

local function cap(v,mn,mx)
return math.min(math.max(mn,  v), mx)
end

local function getLastProcessedRace()
return lastProcessedRace
end

local function testRandConfig(model, baseFile, randSlots, seed)
local ioctx = extensions.betterpartmgmt.getCustomIOCTX(model)
local slotMap = extensions.betterpartmgmt.getSlotMap(ioctx)
local filteredMap = extensions.betterpartmgmt.getFilteredSlotMap(slotMap, randSlots)
local randomConfig = extensions.betterpartmgmt.generateConfigVariant(baseFile, filteredMap, seed)
blrSpawn(model, { config = randomConfig } )
end

local function getActualRotationEuler(vehid)
local rot = quatFromDir(map.objects[vehid].dirVec, map.objects[vehid].dirVecUp)
local fix = quat(rot.y, -rot.x, -rot.w, rot.z)
local euler = fix:toEulerYXZ()
return vec3(euler.x * 180.0 / math.pi, euler.y * 180.0 / math.pi, euler.z * 180.0 / math.pi)
end

local blrvars = {}

local function blrvarSet(var, val)
blrvars[var] = val
end

local function blrvarGet(var)
return blrvars[var]
end

local function actualSlotDebug()
local filedata = ""
local slots = extensions.betterpartmgmt.getActualSlots()
for k,v in pairs(slots) do
filedata = filedata .. v .. "\n"
end
writeFile("beamLR/actualSlotsDebug", filedata)
end

local function getPartShopPriceScale(shopID, minVal, maxVal)
local seed = getDailySeed() + shopID
local range = maxVal - minVal
math.randomseed(seed)
local rand = math.random()
local scale = minVal + (rand * range)
return math.floor(scale * 100.0) / 100.0
end

local function resetTimeOfDay() -- For mission end cleanup
core_environment.setTimeOfDay({time = 0, play = false, dayScale = 1.0, nightScale = 2.0 })
end

local driftScore = 0

local function setDriftScore(score)
driftScore = score
end

local function getDriftScore()
return driftScore
end

local buttonConfirmState = {}

local function cycleButtonConfirm(id)
local cstate = buttonConfirmState[id] or false
buttonConfirmState[id] = not cstate
end

local function getButtonConfirm(id)
return buttonConfirmState[id] or false
end

local function resetButtonConfirm()
buttonConfirmState = {}
end

local function getButtonStates()
return buttonConfirmState
end

local function setButtonConfirm(id, state)
buttonConfirmState[id] = state
end

local function getPerformanceClass(horsepower, torque, weight)
local pvalue = ((torque / 3.0) + horsepower) / (weight / 2.0)
local toRet = "ERROR"
if pvalue < .3 then
toRet = "E"
elseif pvalue < .35 then
toRet = "D"
elseif pvalue < .5 then
toRet = "C"
elseif pvalue < .7 then
toRet = "B"
elseif pvalue < 0.85 then 
toRet = "A"
elseif pvalue <= 1.7 then 
toRet = "S"
elseif pvalue > 1.7 then 
toRet = "X"
end
return toRet
end

local function createPerformanceFiles(officialModels, officialConfigs)
local data = {}
data["X"] = ""
data["S"] = ""
data["A"] = ""
data["B"] = ""
data["C"] = ""
data["D"] = ""
data["E"] = ""
data["NA"] = "" -- When custom configs / models are allowed if unable to calculate class

local models = extensions.core_vehicles.getModelList()["models"]
local filteredModels = {}
local filteredConfigs = {}
local cconfigs = {}
local ctype = ""
local cauthor = ""
local cpower = 0
local ctorque = 0
local cweight = 0
local csource = ""
local ccancalc = false
local cclass = ""

-- Filter models
for k,v in pairs(models) do
ctype = v["Type"]
if ctype == "Car" or ctype == "Truck" then
cauthor = v["Author"]
if not officialModels then
table.insert(filteredModels, k)
elseif cauthor == "BeamNG" then
table.insert(filteredModels, k)
end
end
end

-- Filter configs
for k,v in pairs(filteredModels) do
cconfigs = extensions.core_vehicles.getModel(v)["configs"]
for cname,cdata in pairs(cconfigs) do
if not string.match(cname, "simple_traffic") then
csource = cdata["Source"]
ccancalc = cdata["Power"] and cdata["Torque"] and cdata["Weight"]

if not officialConfigs then
if ccancalc then
cpower = cdata["Power"]
ctorque = cdata["Torque"]
cweight = cdata["Weight"]
cclass = getPerformanceClass(cpower,ctorque,cweight)
data[cclass] = data[cclass] .. "/vehicles/" .. v .. "/" .. cname .. ".pc" .. "\n"
else
data["NA"] = data["NA"] .. "/vehicles/" .. v .. "/" .. cname .. ".pc" .. "\n"
end

elseif csource == "BeamNG - Official" then
if ccancalc then
cpower = cdata["Power"]
ctorque = cdata["Torque"]
cweight = cdata["Weight"]
cclass = getPerformanceClass(cpower,ctorque,cweight)
data[cclass] = data[cclass] .. "/vehicles/" .. v .. "/" .. cname .. ".pc" .. "\n"
else
data["NA"] = data["NA"] .. "/vehicles/" .. v .. "/" .. cname .. ".pc" .. "\n"
end
end
end
end
end
-- Write performance files
for k,v in pairs(data) do
writeFile("beamLR/performanceClass/" .. k, v)
end
end

local function modelFromConfig(path)
local offset = 0
if string.sub(path, 1,1) == "/" then offset = 1 end -- Detects path starting with slash
local split = ssplit(path, "/")
local model = split[2+offset]
return model
end

local function loadDataFile(path) -- For files not in table format, load each line as a table element
local filedata = readFile(path)
if string.sub(filedata, #filedata, #filedata) == "\n" then -- Remove last newline if it exists to prevent empty last element
filedata = string.sub(filedata, 1, #filedata-1) 
end
local filesplit = ssplit(filedata, "\n")
local toRet = {}
for k,v in pairs(filesplit) do
toRet[k] = v
end
return toRet
end

local function perfclassConfigLoader(configData) -- Creates config and model tables for race systems, works with class files and regular list
local toRet = {}
local csplit = {}
local cconfig = ""
local cmodel = ""
local class = ""
local classData = {}
toRet["models"] = {}
toRet["configs"] = {}
if configData:match("class:") then
csplit = extensions.blrutils.ssplit(configData, ":")
class = csplit[2]
classData = extensions.blrutils.loadDataFile("beamLR/performanceClass/" .. class)
for k,v in pairs(classData) do
cconfig = v
cmodel = extensions.blrutils.modelFromConfig(cconfig)
toRet["models"][k] = cmodel
toRet["configs"][k] = cconfig
end
else
csplit = extensions.blrutils.ssplit(configData, ",")
for k,v in pairs(csplit) do
cconfig = v
cmodel = extensions.blrutils.modelFromConfig(cconfig)
toRet["models"][k] = cmodel
toRet["configs"][k] = cconfig
end
end
return toRet
end


-- Cop Fix, after pursuit ended inactive police vehicles will stay on "follow" AI mode 
-- and has to be forced back to "traffic" after pursuit (hopefully will get fixed soon)
local lastTrafficData = {}
local copTable = {}				-- Vehid KEY, TRUE val, non cop ids will return nil when checked
local copfixReceived = {}		-- Vehid KEY, SENT as boolean val
local copCount = 0				-- Fixes to send before stopping
local copfixSent = 0			-- Sent fixes so far

local aimodes = {}
local rolestates = {}
local roleFixQueued = {}

local function updateTrafficData()
lastTrafficData = extensions.gameplay_traffic.getTraffic()
end

local function forceSetAIMode(veid, mode)
scenetree.findObjectById(veid):queueLuaCommand('ai.setMode("' .. mode .. '")')
end

local function updateCopTable()
updateTrafficData()
copTable = {}
aimodes = {}
rolestates = {}
roleFixQueued = {}
copCount = 0
for k,v in pairs(lastTrafficData) do
if v["autoRole"] == "police" then
copTable[k] = true
copCount = copCount + 1
end
end
end

local function copfixReset() -- Should be called before init pass
copfixReceived = {}
copfixSent = 0
end

local function copfixInit()	-- Initial copfix pass, sends fixes to all cops active when fix is triggered
local cdata = {}
updateTrafficData()

for k,v in pairs(copTable) do
cdata = lastTrafficData[k]

if cdata["state"] == "active" then -- Found active cop
forceSetAIMode(k, "traffic") -- Send fix
copfixReceived[k] = true	-- Set fix received to true for vehid 
copfixSent = copfixSent + 1 -- Increment sent copfix amount
print("Should have fixed cop: " .. k)

if copfixSent == copCount then -- Finished sending copfixes in init pass
extensions.blrglobals.blrFlagSet("policeResetRequest", false) -- Turn off request flag
print("Copfix finished in init pass, all cops were active to receive fix.")
end

else
print("Inactive cop detected: " .. k)
end

end

end

local function copfixHook(veid) -- Called by blrhook for onVehicleActiveChanged only when request flag is true and state active state is true
if copTable[veid] then -- Vehicle a cop
if not copfixReceived[veid] then -- Cop has not received fix yet

forceSetAIMode(veid, "traffic") -- Send fix
copfixReceived[veid] = true	-- Set fix received to true for vehid 
copfixSent = copfixSent + 1 -- Increment sent copfix amount
print("Should have fixed cop: " .. veid)

if copfixSent == copCount then -- Finished sending copfixes in init pass
extensions.blrglobals.blrFlagSet("policeResetRequest", false) -- Turn off request flag
print("Copfix finished on hook for last fix.")
end
end
end
end

local function copfixIteration() -- do not use, better fix added
updateTrafficData()
local cdata = {}
local complete = true
for k,v in pairs(copTable) do -- Only loops over cop veids
cdata = lastTrafficData[v]
if cdata["state"] == "active" then -- Found active cop to fix
forceSetAIMode(v, "traffic") -- Set AI mode to traffic to force cop to stop chasing player
table.insert(copfixReceived, v) -- Add cop veid to table tracking received copfix
print("Should have fixed cop: " .. v)
if #copfixReceived == #copTable then -- Detects when the fix is completed
extensions.blrglobals.blrFlagSet("policeResetRequest", false) -- Stops flowgraph from triggering iterations
print("Cop Fix Complete!")
end
else 
print("Inactive cop detected: " .. v)
end
end
end

local function getCopTable()
return copTable
end

local function forceSetPolice(mode)
gameplay_police.setPursuitMode(mode, nil, nil)
end


-- A different cop fix, problem caused by cops chasing random traffic getting
-- stuck in "follow" ai.mode defaulting to player when traffic cycles
local function fetchCopsAIModes() -- Execute this at regular interval for faster role fixing
local toFetch = "ai.mode"
for k,v in pairs(copTable) do
extensions.vluaFetchModule.exec(k, "ai.mode", "aimode" .. k, true)
aimodes[k] = extensions.vluaFetchModule.getVal("aimode" .. k)
end
end

local function updateCopRoleState(id) --
local cdata = {}
updateTrafficData()
cdata = lastTrafficData[id]
rolestates[id] = cdata.role.state
end

local function checkCopModeConflict(id)
if rolestates[id] == "none" then
if aimodes[id] == "follow" or aimodes[id] == "chase" then --Detected conflict
roleFixQueued[id] = true
print("Detected police role state conflict with AI mode, queuing fix for id " .. id)
end
end
end

local function roleStateFixHook(id, active)
if copTable[id] and not roleFixQueued[id] then
updateCopRoleState(id)
checkCopModeConflict(id)
end
if roleFixQueued[id] and active then
forceSetAIMode(id, "traffic") -- Send fix
roleFixQueued[id] = false
print("Sent role fix for id " .. id)
end
end

local function getAIModes()
return aimodes
end

local function disableQuickAccess()
if extensions.blrglobals.blrFlagGet("disableQuickAccess") and core_quickAccess.isEnabled() then
core_quickAccess.setEnabled(false)
end
end

local function getShopSeed(shopID)
return getDailySeed()+(shopID*10) -- As long as shops have < 10 slots no roll collision happens
end


M.getShopSeed = getShopSeed
M.disableQuickAccess = disableQuickAccess
M.getAIModes = getAIModes
M.roleStateFixHook = roleStateFixHook
M.checkCopModeConflict = checkCopModeConflict
M.updateCopRoleState = updateCopRoleState
M.fetchCopsAIModes = fetchCopsAIModes
M.perfclassConfigLoader = perfclassConfigLoader
M.loadDataFile = loadDataFile
M.modelFromConfig = modelFromConfig
M.createPerformanceFiles = createPerformanceFiles
M.copfixHook = copfixHook
M.copfixInit = copfixInit
M.copfixReset = copfixReset
M.copfixIteration = copfixIteration
M.getCopTable = getCopTable
M.updateCopTable = updateCopTable
M.updateTrafficData = updateTrafficData
M.forceSetPolice = forceSetPolice
M.forceSetAIMode = forceSetAIMode
M.setButtonConfirm = setButtonConfirm
M.getButtonStates = getButtonStates
M.resetButtonConfirm = resetButtonConfirm
M.getButtonConfirm = getButtonConfirm
M.cycleButtonConfirm = cycleButtonConfirm
M.getDriftScore = getDriftScore
M.setDriftScore = setDriftScore
M.resetTimeOfDay = resetTimeOfDay
M.getPartShopPriceScale = getPartShopPriceScale
M.getStarterCarID = getStarterCarID 
M.getOptionsTable = getOptionsTable
M.getDifficultyLevel = getDifficultyLevel
M.actualSlotDebug = actualSlotDebug
M.blrvarSet = blrvarSet
M.blrvarGet = blrvarGet
M.getActualRotationEuler = getActualRotationEuler
M.testRandConfig = testRandConfig
M.getLastProcessedRace = getLastProcessedRace
M.cap = cap
M.getWager = getWager
M.setWager = setWager
M.getMapTowSpot = getMapTowSpot
M.getMapSpawn = getMapSpawn
M.nitrousCheck = nitrousCheck
M.onPreRender = onPreRender
M.getRaceTime = getRaceTime
M.raceTimeString = raceTimeString
M.msTimeFormat = msTimeFormat
M.restoreBackup = restoreBackup
M.backupCareer = backupCareer
M.setNextCareerSeed = setNextCareerSeed
M.cycleCareerSeed = cycleCareerSeed
M.getNextCareerSeed = getNextCareerSeed
M.getCareerSeed = getCareerSeed
M.processGasStationRandoms = processGasStationRandoms
M.updateShopDailyData = updateShopDailyData
M.resetShopDailyData = resetShopDailyData
M.formatTimeOfDay = formatTimeOfDay
M.getDailySeed = getDailySeed
M.initStartSeed = initStartSeed
M.setGameDay = setGameDay
M.getGameDay = getGameDay
M.getGarageCarPaint = getGarageCarPaint
M.processCarShopRandoms = processCarShopRandoms
M.vehiclePaintToGaragePaint = vehiclePaintToGaragePaint
M.createRandomPaint = createRandomPaint
M.processMissionRandoms = processMissionRandoms
M.getVehicleData = getVehicleData
M.processChallengeRandoms = processChallengeRandoms
M.processRaceRandoms = processRaceRandoms
M.garagePaintReload = garagePaintReload
M.convertUIPaintToMeshColors = convertUIPaintToMeshColors
M.getGoodSlotList = getGoodSlotList
M.repaintFullMesh = repaintFullMesh
M.getVehicleMainPartName = getVehicleMainPartName
M.blrSpawn = blrSpawn
M.livePaintUpdate = livePaintUpdate
M.saveUIPaintToGarageFile = saveUIPaintToGarageFile
M.convertUIPaintToVehiclePaint = convertUIPaintToVehiclePaint
M.blrGetVehiclePaint = blrGetVehiclePaint
M.updateDataTable = updateDataTable
M.saveDataTable = saveDataTable
M.slotHelper = slotHelper
M.ssplitnum = ssplitnum
M.loadDataTable = loadDataTable
M.getSettingValue = getSettingValue
M.updateMarkers = updateMarkers
M.deleteMarkers = deleteMarkers
M.spawnMarkers = spawnMarkers
M.getObjectPosID = getObjectPosID
M.getObjectPosName = getObjectPosName
M.getObjectID = getObjectID
M.getLevelName = getLevelName
M.spawnPrefab = blrSpawnPrefab
M.readJSONFile = readJSONFile
M.cameraReset = cameraReset
M.boolToText = boolToText
M.createPaint = createPaint
M.ssplit = ssplit
M.resetCareer = resetCareer
M.copyFile = copyFile
M.deleteFile = deleteFile
M.deleteDir = deleteDir
M.moveFile = moveFile

return M



