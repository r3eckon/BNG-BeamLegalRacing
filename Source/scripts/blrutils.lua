-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local json = require("json")
local extensions = require("extensions")

local dailySeedOffset = 1000	-- Seed offset for daily seed should be bigger value than total amount of needed rolls in flowgraph.
local startSeed = 1234			-- in order to avoid repeating random values. Without this value the paint colors in shop
local day = 0					-- are still showing up the next day, just offset by one vehicle. Increase as needed.

local markers = {}

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
pos = v:getPosition()
pos = pos + (vec3(0,0, math.sin(os.clock()) * 0.0015))
v:setPosition(pos)
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
toRet["driftpts"] = lerp(rval,tonumber(driftpts[1]), tonumber(driftpts[2]), false)
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
dtable["sseed"] = dtable["nseed"]
updateDataTable("beamLR/options", dtable)
end

local function setNextCareerSeed(seed)
local dtable = {}
dtable["nseed"] = seed
updateDataTable("beamLR/options", dtable)
end


local function resetCareer() 

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
cycleCareerSeed()

copyFile("beamLR/init/mainData",  "beamLR/mainData")
copyFile("beamLR/init/partInv",  "beamLR/partInv")
copyFile("beamLR/init/garage/car0" , "beamLR/garage/car0")
copyFile("beamLR/init/garage/config/car0" , "beamLR/garage/config/car0")
copyFile("beamLR/init/beamstate/car0.save.json" , "beamLR/beamstate/car0.save.json")
copyFile("beamLR/init/beamstate/mech/car0" , "beamLR/beamstate/mech/car0")
copyFile("beamLR/init/beamstate/integrity/car0" , "beamLR/beamstate/integrity/car0")
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



