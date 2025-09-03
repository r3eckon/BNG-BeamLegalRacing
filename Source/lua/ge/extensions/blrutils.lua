-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

--Locals table for variable storage, lua has a hard limit of 200 locals
local locals = {}

local json = require("json")
local extensions = require("extensions")
local uiapps = require("ui/apps")

local dailySeedOffset = 1000	-- Seed offset for daily seed should be bigger value than total amount of needed rolls in flowgraph.
local startSeed = 1234			-- in order to avoid repeating random values. Without this value the paint colors in shop
local day = 0					-- are still showing up the next day, just offset by one vehicle. Increase as needed.

local pwager = 10000				-- Player wager, start scenario with max wager but could add proper option val 
local lastProcessedRace = {}	

local markers = {}
local markersOriginPos = {}      -- To fix markers moving downwards, likely due to floating point error when using pos = pos + sin(os.clock())

local blrtime = 0				-- Not time of day, used for race timers

-- Iterator for sorted linked tables
function linkedpairs(keys, values)
local current = 0    
return function()
    current = current + 1
    if not keys[current] then return nil end
    return current,keys[current],values[current]
end
end

-- global linked sort function, returns sorted key/value pairs in static order tables
function linkedsort(t, keymode)
local added = {}
local keys = {}
local values = {}
local sortedValues = {}
local sortedKeys = {}

-- Fill up arrays for sorting
for k,v in pairs(t) do
table.insert(values, v)
table.insert(keys, k)
end

-- Sort array based on mode
if keymode then
table.sort(keys)
for index,item in ipairs(keys) do
for key,val in pairs(t) do
    if not added[key] and item == key then
        sortedKeys[index] = key
        sortedValues[index] = val
        added[key] = true
        break
    end
end
end
else 
table.sort(values)
for index,item in ipairs(values) do
for key,val in pairs(t) do
    if not added[key] and item == val then
        sortedKeys[index] = key
        sortedValues[index] = val
        added[key] = true
        break
    end
end
end
end

--for k,v in ipairs(sortedKeys) do print(k .. "=" .. v) end
--for k,v in ipairs(sortedValues) do print(k .. "=" .. v) end

return sortedKeys, sortedValues
end

--global key sorted table iterator
function keySortedPairs(tab)
    local ordered = {}
    local ckey = 0
    for k,v in pairs(tab) do
       table.insert(ordered, k)
    end
    table.sort(ordered)
    return function()
        if ckey > #ordered then return nil end
        ckey = ckey+1
        return ordered[ckey],tab[ordered[ckey]]
    end
end

--global value sorted table iterator
function valueSortedPairs(t)
local values = {}
local keys = {}
local added = {}

for k,v in pairs(t) do
    table.insert(values, v)
end
table.sort(values)

for index,item in ipairs(values) do
for k,v in pairs(t) do
    if not added[k] and v==item then
        keys[index] = k
        added[k] = true
        break
    end
end
end


local ckey = 0

return function()
    ckey = ckey+1
    if ckey > #keys then return nil end
    return keys[ckey], t[keys[ckey]]
    end
end


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
local markerType = {}

-- 0.36 added different marker object types, could use them for different areas
markerType["default"] = "/art/shapes/collectible/s_collect_BNG.dae"
markerType["bomb"] = "/art/shapes/collectible/s_collect_bomb.dae"
markerType["gas"] = "/art/shapes/collectible/s_collect_gas_canister.dae"
markerType["gear"] = "/art/shapes/collectible/s_collect_gear.dae"
markerType["part"] = "/art/shapes/collectible/s_collect_machine_part.dae"
markerType["medkit"] = "/art/shapes/collectible/s_collect_medikit.dae"
markerType["money"] = "/art/shapes/collectible/s_collect_money_sack.dae"
markerType["trash"] = "/art/shapes/collectible/s_collect_trashbin.dae"
markerType["crate"] = "/art/shapes/collectible/s_collect_wooden_crate.dae"
markerType["repair"] = "/art/shapes/collectible/s_collect_wrenchkit.dae"

-- could also use dynamic colors when player is within range of interactive area
-- but gonna use static colors for now
local colorLogo = "1.0 0.4 0.0 1.0"
local colorBackground = "0.364 0.619 1.0 1.0"

local mid = 1
local marker = {}
local csplit = {}
local ctype = ""
local cname = ""
local cpos = {}
for k,v in pairs(mtable) do
csplit = ssplit(v, ",")

ctype = csplit[2] or "default" -- replace with type based markers
cname = csplit[1]

-- offset spawn position down bit to account for new shape being taller
cpos = getObjectPosName(cname):toTable()
cpos[3] = cpos[3] - 0.8
cpos = vec3(cpos)

if not markerType[ctype] then
print("Invalid marker object type for " .. k .. ", using default!")
ctype = "default"
end

marker = createObject('TSStatic')
marker:setField('shapeName', 0, markerType[ctype])
marker:setPosition(cpos)
marker:setField("instanceColor", 0, colorBackground)
marker:setField("instanceColor2", 0, colorLogo)
marker.scale = vec3(2, 2, 2)
marker:registerObject("BLRMarker" .. mid)
markers[k] = marker
markersOriginPos[k] = cpos -- Store spawn position to use as center point of animation
mid = mid+1
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

-- 1.17.5 numkey, to load as array, allows appending to table without looping over keys
local function loadDataTable(file, numkey)
local filedata = readFile(file)
local dtable = {}
if numkey then
for k,v in string.gmatch(filedata, "([^%c]+)=([^%c]+)") do
    dtable[tonumber(k)] = v
end
else
for k,v in string.gmatch(filedata, "([^%c]+)=([^%c]+)") do
    dtable[k] = v
end
end
return dtable
end

local function loadDataString(filedata)
local dtable = {}
for k,v in string.gmatch(filedata, "([^%c]+)=([^%c]+)") do
    dtable[k] = v
end
return dtable
end

-- 1.18.2 addition for car shop util ui, fmt specifies orders and which lines are added to saved file
local function saveDataTable(file, data, fmt)
local filedata = ""
if fmt then
for _,k in ipairs(fmt) do
if data[k] then
filedata = filedata .. k .. "=" .. data[k] .. "\n"
end
end
else
for k,v in pairs(data) do
filedata = filedata .. k .. "=" .. v .. "\n"
end
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

locals["shautoindex"] = 0

local function slotHelper(params)
local filedata = ""
local veh = be:getPlayerVehicle(0)
local vehicleData = map.objects[veh:getId()]
local pos = vehicleData.pos:toTable()
local rot = quatFromDir(vehicleData.dirVec, vehicleData.dirVecUp):toTable()
if not params then params = {} end
local spprefix = params["spprefix"] or "slotp" -- slot position prefix
local srprefix = params["srprefix"] or "slotr" -- slot rotation prefix
local cpprefix = params["cpprefix"] or "camp" -- cam position prefix
local crprefix = params["crprefix"] or "camr" -- cam rotation prefix
local append = params["append"] -- append mode, adds to file instead of overwriting
local cam = params["cam"] -- also add camera position and rotation
local index = params["index"] or "" -- add index to the end of prefix
local autoindex = params["autoindex"] -- automatically incremented index

if append then filedata = readFile("beamLR/slotHelper") end

if autoindex then index = locals["shautoindex"] end

filedata = filedata .. (spprefix) .. index .. "=" .. pos[1] .. "," .. pos[2] .. "," .. pos[3] .. "\n"
filedata = filedata .. (srprefix) .. index .. "=" .. rot[1] .. "," .. rot[2] .. "," .. rot[3] .. "," .. rot[4] .. "\n"

if cam then 
pos = core_camera.getPosition():toTable()
rot = core_camera.getQuat():toTable()
filedata = filedata .. (cpprefix) .. index .. "=" .. pos[1] .. "," .. pos[2] .. "," .. pos[3] .. "\n"
filedata = filedata .. (crprefix) .. index .. "=" .. rot[1] .. "," .. rot[2] .. "," .. rot[3] .. "," .. rot[4] .. "\n"
end
writeFile("beamLR/slotHelper", filedata)
if autoindex then locals["shautoindex"] = locals["shautoindex"]+1 end
end

local function slotHelperAutoIndexReset()
locals["shautoindex"] = 0
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
local paint = convertUIPaintToVehiclePaint(getGarageCarPaint(gid))
local mc = convertUIPaintToMeshColors(getGarageCarPaint(gid))
livePaintUpdate(vid, paint)
--repaintFullMesh(vid, mc.car,mc.cag, mc.cab, mc.caa, mc.cbr,mc.cbg,mc.cbb, mc.cba, mc.ccr,mc.ccg,mc.ccb, mc.cca)
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
veh = scenetree.findObjectById(vid)
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

local function processCarShopRandoms(dtable, seed, defective)
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

if defective then -- 1.17.4 make defective cars a bit cheaper and lower odometer
toRet["baseprice"] = toRet["baseprice"] * 0.8
toRet["odometer"] = toRet["odometer"] * 0.8
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

locals["getDailySeedOffset"] = function()
return dailySeedOffset
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

toRet["cost_midgrade"] = math.floor(toRet["cost"] * 1.25 * 100.0) / 100.0
toRet["cost_premium"] =  math.floor(toRet["cost"] * 1.5 * 100.0) / 100.0
toRet["cost_diesel"] =  math.floor(toRet["cost"] * 1.15 * 100.0) / 100.0

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
local autoseed = (tonumber(dtable["autoseed"]) == 1) or (dtable["autoseed"] == "true")--check text param for old version compatibility
if autoseed then -- New automatic seed increment feature
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

-- test function, returns a list of starter car models and seeds that spawn them
locals["getStarterCarSeedList"] = function(dbg)
local count = #FS:findFiles("beamLR/init/garage/", "*", 0)
local found = 0
local cseed = 1
local cid = 0
local ccarfile = {}
local cmodel = ""
local toRet = {}

while found < count do
cid = getStarterCarID(cseed, count)
ccarfile = loadDataTable("beamLR/init/garage/car" .. cid)
cmodel = ccarfile["type"]

if not toRet[cmodel] then
toRet[cmodel] = cseed
found = found + 1
if dbg then print(cseed .. "=" .. cmodel) end
end

cseed = cseed + 1
end

return toRet
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
local event = loadDataTable("beamLR/currentTrackEvent")
local ctemplates = {}

deleteFile("beamLR/partInv") -- keeping this in for 1.16 so defunct inventory files are deleted
deleteFile("beamLR/partInventory") -- 1.16 advanced part inventory
deleteFile("beamLR/itemInventory") -- 1.15 item inventory needs deletion
deleteFile("beamLR/usedPartDayData") -- 1.16 used part day data
deleteFile("beamLR/carMeetDayData") -- 1.17 car meet day data
deleteFile("beamLR/ownedProperties") -- 1.17 properties
deleteFile("beamLR/trackEventResults") -- 1.17.5 past event data
extensions.blrItemInventory.resetInventory() -- need to do this to avoit items staying after reset
extensions.blrPartInventory.reset() -- same thing with part inventory
extensions.blrPartInventory.resetUsedPartShopDayData() -- same thing with used part day data
extensions.blrCarMeet.resetDayData()

local count = #FS:findFiles("beamLR/garage/", "*", 0)

for i=0,count-1 do -- Clear out garage 
deleteFile("beamLR/garage/car" .. i)
deleteFile("beamLR/garage/config/car" .. i)
deleteFile("beamLR/beamstate/car" .. i .. ".save.json")
deleteFile("beamLR/beamstate/mech/car" .. i)
deleteFile("beamLR/beamstate/integrity/car" .. i)
-- Removing template folder
FS:directoryRemove("beamLR/garage/config/template/car" .. i)
end

for _,v in pairs(FS:directoryList("beamLR/races")) do	-- Loop over all available race clubs to reset progress files
if v ~= "/beamLR/races/integrity" then					-- this should automatically detect all folders except integrity store
if FS:fileExists(v .. "/progress") then -- 1.17.4 shared progress, some club folders have no progress file
deleteFile(v .. "/progress")
copyFile("beamLR/init/emptyRaceProgress", v .. "/progress")
end
end
end

resetShopDailyData()


-- Difficulty setting based
copyFile("beamLR/init/mainData_" .. difficulty ,  "beamLR/mainData")
-- Just copy empty starter inventory no matter difficulty level
--copyFile("beamLR/init/partInv",  "beamLR/partInv") -- no longer needed as of 1.16
copyFile("beamLR/init/partInventory",  "beamLR/partInventory") -- 1.16 advanced part inventory
copyFile("beamLR/init/itemInventory",  "beamLR/itemInventory")
copyFile("beamLR/init/usedPartDayData",  "beamLR/usedPartDayData") -- 1.16 part shop day data
copyFile("beamLR/init/carMeetDayData",  "beamLR/carMeetDayData") -- 1.17 car meet day data
copyFile("beamLR/init/ownedProperties",  "beamLR/ownedProperties") -- 1.17 properties
copyFile("beamLR/init/trackEventResults",  "beamLR/trackEventResults") -- 1.17.5 track event results
-- Uses seed based random starter car ID out of available setups, not based on difficulty
copyFile("beamLR/init/garage/car" .. carid , "beamLR/garage/car0")
copyFile("beamLR/init/garage/config/car" .. carid , "beamLR/garage/config/car0")
copyFile("beamLR/init/beamstate/car" .. carid .. ".save.json" , "beamLR/beamstate/car0.save.json")
copyFile("beamLR/init/beamstate/mech/car" .. carid , "beamLR/beamstate/mech/car0")
copyFile("beamLR/init/beamstate/integrity/car" .. carid , "beamLR/beamstate/integrity/car0")
-- Create new template folder for car0
FS:directoryCreate("beamLR/garage/config/template/car0")

-- Reset current track event
event["status"] = "over"
event["carid"] = 0
event["eventid"] = 0
updateDataTable("beamLR/currentTrackEvent", event)


end

local function backupCareer()
-- Delete existing backup
deleteDir("beamLR/backup")

-- Root folder data
copyFile("beamLR/mainData", "beamLR/backup/mainData")
-- copyFile("beamLR/partInv", "beamLR/backup/partInv") -- no longer needed as of 1.16
extensions.blrPartInventory.save() -- need to save before copying file otherwise last changes arent in file
copyFile("beamLR/partInventory", "beamLR/backup/partInventory") -- 1.16 advanced part inventory
copyFile("beamLR/options", "beamLR/backup/options")
copyFile("beamLR/currentTrackEvent", "beamLR/backup/currentTrackEvent")
extensions.blrItemInventory.saveInventory()
copyFile("beamLR/itemInventory", "beamLR/backup/itemInventory")
extensions.blrPartInventory.saveUsedPartShopDayData()
copyFile("beamLR/usedPartDayData", "beamLR/backup/usedPartDayData") -- 1.16 used part day data
extensions.blrCarMeet.updateDayData()
copyFile("beamLR/carMeetDayData", "beamLR/backup/carMeetDayData") -- 1.17 car meet
copyFile("beamLR/ownedProperties", "beamLR/backup/ownedProperties") -- 1.17 properties
copyFile("beamLR/trackEventResults", "beamLR/backup/trackEventResults") -- 1.17.5 track event results


-- Garage data
local count = #FS:findFiles("beamLR/garage/", "*", 0)
local ctemplates = {}
for i=0,count-1 do 
copyFile("beamLR/garage/car" .. i, "beamLR/backup/garage/car" .. i)
copyFile("beamLR/garage/config/car" .. i,"beamLR/backup/garage/config/car" .. i)
copyFile("beamLR/beamstate/car" .. i .. ".save.json","beamLR/backup/beamstate/car" .. i .. ".save.json")
copyFile("beamLR/beamstate/mech/car" .. i,"beamLR/backup/beamstate/mech/car" .. i)
copyFile("beamLR/beamstate/integrity/car" .. i,"beamLR/backup/beamstate/integrity/car" .. i)

-- Backup templates
ctemplates = FS:findFiles("beamLR/garage/config/template/car" .. i, "*", 0)
for _,file in pairs(ctemplates) do
copyFile(file, file:gsub("beamLR/garage/", "beamLR/backup/garage/"))
end


end

-- Race progress data
local dest = ""
for _,v in pairs(FS:directoryList("beamLR/races")) do
if v ~= "/beamLR/races/integrity" then
dest = v:gsub("beamLR", "beamLR/backup")
if FS:fileExists(v .. "/progress") then -- 1.17.4 shared progress, some club folders have no progress file
copyFile(v .. "/progress", dest .. "/progress")
end
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
--copyFile("beamLR/backup/partInv","beamLR/partInv") -- no longer needed as of 1.16
copyFile("beamLR/backup/partInventory", "beamLR/partInventory") -- 1.16 advanced part inventory
copyFile("beamLR/backup/options","beamLR/options")
copyFile("beamLR/backup/currentTrackEvent","beamLR/currentTrackEvent")
copyFile("beamLR/backup/itemInventory", "beamLR/itemInventory")
copyFile("beamLR/backup/usedPartDayData", "beamLR/usedPartDayData") -- 1.16 used part day data
copyFile("beamLR/backup/carMeetDayData", "beamLR/carMeetDayData") -- 1.17 car meet
copyFile("beamLR/backup/ownedProperties", "beamLR/ownedProperties") -- 1.17 properties
copyFile("beamLR/backup/trackEventResults", "beamLR/trackEventResults") -- 1.17.5 track event results

extensions.blrItemInventory.loadInventory() -- need to load inventory right now otherwise empty inventory table will overwrite restored backup
extensions.blrPartInventory.load() -- probably should do the same for new part inventory system
extensions.blrPartInventory.loadUsedPartShopDayData() -- and used part day data
extensions.blrCarMeet.loadDayData()

-- Garage data
local count = #FS:findFiles("beamLR/backup/garage/", "*", 0)
local ctemplates = {}
for i=0,count-1 do 
copyFile("beamLR/backup/garage/car" .. i,"beamLR/garage/car" .. i)
copyFile("beamLR/backup/garage/config/car" .. i,"beamLR/garage/config/car" .. i)
copyFile("beamLR/backup/beamstate/car" .. i .. ".save.json", "beamLR/beamstate/car" .. i .. ".save.json")
copyFile("beamLR/backup/beamstate/mech/car" .. i,"beamLR/beamstate/mech/car" .. i)
copyFile("beamLR/backup/beamstate/integrity/car" .. i,"beamLR/beamstate/integrity/car" .. i)

-- Restore template files
ctemplates = FS:findFiles("beamLR/backup/garage/config/template/car" .. i, "*", 0)
for _,file in pairs(ctemplates) do
copyFile(file, file:gsub("beamLR/backup/garage/","beamLR/garage/"))
end

end

-- Race progress data
local dest = ""
for _,v in pairs(FS:directoryList("beamLR/backup/races")) do	
if v ~= "/beamLR/backup/races/integrity" then
dest = v:gsub("beamLR/backup", "beamLR")		
if FS:fileExists(v .. "/progress") then -- 1.17.4 shared progress, some club folders have no progress file
copyFile(v .. "/progress", dest .. "/progress")
end
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
local parts = extensions.blrpartmgmt.getVehicleParts(veid)
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

-- location can be home, gas or garage
local function getMapTowSpot(location)
local toRet = {}
local path = "beamLR/mapdata/" .. getLevelName() .. "/towing"
local dtable = loadDataTable(path)
toRet["pos"] = ssplitnum(dtable[location .. "_pos"], ",")
toRet["rot"] = ssplitnum(dtable[location .. "_rot"], ",")
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
local ioctx = extensions.blrpartmgmt.getCustomIOCTX(model)
local slotMap = extensions.blrpartmgmt.getSlotMap(ioctx)
local filteredMap = extensions.blrpartmgmt.getFilteredSlotMap(slotMap, randSlots)
local randomConfig = extensions.blrpartmgmt.generateConfigVariant(baseFile, filteredMap, seed)
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
local slots = extensions.blrpartmgmt.getPathKeyedSlots()
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

locals["driftTotal"]  = 0
locals["driftCurrent"]  = 0
locals["driftCombo"] = 0

local function setDriftTotal(score)
locals["driftTotal"]  = score
end

local function setDriftCurrent(score)
locals["driftCurrent"]  = score
end

locals["setDriftCombo"] = function(score)
locals["driftCombo"] = score
end

local function getDriftTotal()
return locals["driftTotal"] 
end

local function getDriftCurrent()
return locals["driftCurrent"] 
end

locals["getDriftCombo"] = function()
return locals["driftCombo"]
end

local function getDriftCombined()
return math.floor(locals["driftTotal"]  + math.floor(locals["driftCurrent"] * locals["driftCombo"]) )
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


-- bronze: E,D
-- silver: C,B,A
-- gold: S
-- hero: S,X

local function createPerformanceFiles(officialModels, officialConfigs, ignored, overwrite)
local data = {}
data["X"] = ""
data["S"] = ""
data["A"] = ""
data["B"] = ""
data["C"] = ""
data["D"] = ""
data["E"] = ""
data["NA"] = "" -- When custom configs / models are allowed if unable to calculate class

data["/club/street_bronze"] = ""
data["/club/street_silver"] = ""
data["/club/street_gold"] = ""
data["/club/street_hero"] = ""
data["/club/street_gold_drag"] = ""
data["/club/street_hero_drag"] = ""
data["/club/dirt_bronze"] = ""
data["/club/dirt_silver"] = ""
data["/club/dirt_gold"] = ""
data["/club/dirt_hero"] = ""

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
local induction = ""
local tier = ""
local drivetrain = ""
local brand = ""
local ccpath = ""
local ckey = ""

local tiers = {A = "tier_high", S = "tier_high", X = "tier_high", C = "tier_mid", B = "tier_mid"}

local clubLeague = ""
local clubType = ""
local clubPath = ""


local ignoreModels = {us_semi = true, atv=true, utv=true, racetruck=true, md_series=true, citybus=true, midtruck=true, rockbouncer=true}
for k,v in pairs(ignored) do
ignoreModels[v] = true
end


-- Filter models
for k,v in pairs(models) do
ctype = v["Type"]
if ctype == "Car" or ctype == "Truck" then
cauthor = v["Author"]
if not officialModels and not ignoreModels[k] then
table.insert(filteredModels, k)
elseif cauthor == "BeamNG" and not ignoreModels[k] then
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

brand = models[v]["Brand"] or "NOBRAND"
induction = (cdata["Induction Type"] or "NOINDUCTION"):gsub("%s%+%s", "_") -- Replaces + N2O with _N2O for folder structure
drivetrain = (cdata["Drivetrain"] or "NODRIVETRAIN"):gsub("4WD", "AWD"):gsub("4x4", "AWD"):gsub("4x2", "AWD")
tier = tiers[cclass] or "NONE"

ccpath = "/vehicles/" .. v .. "/" .. cname .. ".pc" -- Current config path to add to files

data[cclass] = data[cclass] .. ccpath .. "\n" -- Add to generic performance class

-- 1.18 addition, generating race club class files automatically
if cclass == "D" then
clubLeague = "bronze"
elseif cclass == "C" or cclass == "B" or cclass == "A" then
clubLeague = "silver"
elseif cclass == "S" then
clubLeague = "gold"
elseif cclass == "X" then
clubLeague = "hero"
else
clubLeague = "NONE"
end

if clubLeague ~= "NONE" then
if not string.find(string.upper(ccpath), "ASPHALT") and (string.find(string.upper(ccpath), "RALLY") or string.find(string.upper(ccpath), "GRAVEL") or string.find(string.upper(ccpath), "OFFROAD")) then
clubType = "dirt"
clubPath = "/club/dirt_" .. clubLeague
elseif string.find(string.upper(ccpath), "DRAG") then
clubType = "drag"
clubPath = "/club/street_" .. clubLeague .. "_drag"
else
clubType = "street"
clubPath = "/club/street_" .. clubLeague
end

data[clubPath] = data[clubPath] .. ccpath .. "\n"

if cclass == "S" then -- also add S class to hero leagues
if clubType == "dirt" then data["/club/dirt_hero"] = data["/club/dirt_hero"] .. ccpath .. "\n" end
if clubType == "drag" then data["/club/street_hero_drag"] = data["/club/street_hero_drag"] .. ccpath .. "\n" end
if clubType == "street" then data["/club/street_hero"] = data["/club/street_hero"] .. ccpath .. "\n" end
end
end


ckey = "brand/" .. brand .. "/" .. cclass
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n" -- Add to brand specific classes

ckey = "induction/" .. induction .. "/" .. cclass
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n" -- Add to induction specific classes

ckey = "drivetrain/" .. drivetrain .. "/" .. cclass
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n" -- Add to drivetrain specific classes

if tier ~= "NONE" then

ckey = "brand/" .. brand .. "/" .. tier -- Add to brand tier 
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n"

ckey = "induction/" .. induction .. "_" .. tier -- Add to induction tier 
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n"

ckey = "drivetrain/" .. drivetrain .. "_" .. tier -- Add to drivetrain tier 
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n"

end


else
data["NA"] = data["NA"] .. "/vehicles/" .. v .. "/" .. cname .. ".pc" .. "\n"
end

elseif csource == "BeamNG - Official" then
if ccancalc then
cpower = cdata["Power"]
ctorque = cdata["Torque"]
cweight = cdata["Weight"]
cclass = getPerformanceClass(cpower,ctorque,cweight)

brand = models[v]["Brand"] or "NOBRAND" -- Turbo + N2O
induction = (cdata["Induction Type"] or "NOINDUCTION"):gsub("%s%+%s", "_") -- Replaces +N2O with _N2O for folder structure
drivetrain = (cdata["Drivetrain"] or "NODRIVETRAIN"):gsub("4WD", "AWD"):gsub("4x4", "AWD"):gsub("4x2", "AWD")
tier = tiers[cclass] or "NONE"

ccpath = "/vehicles/" .. v .. "/" .. cname .. ".pc" -- Current config path to add to files

data[cclass] = data[cclass] .. ccpath .. "\n" -- Add to generic performance class


-- 1.18 addition, generating race club class files automatically
if cclass == "D" then
clubLeague = "bronze"
elseif cclass == "C" or cclass == "B" or cclass == "A" then
clubLeague = "silver"
elseif cclass == "S" then
clubLeague = "gold"
elseif cclass == "X" then
clubLeague = "hero"
else
clubLeague = "NONE"
end

if clubLeague ~= "NONE" then
if not string.find(string.upper(ccpath), "ASPHALT") and (string.find(string.upper(ccpath), "RALLY") or string.find(string.upper(ccpath), "GRAVEL") or string.find(string.upper(ccpath), "OFFROAD")) then
clubType = "dirt"
clubPath = "/club/dirt_" .. clubLeague
elseif string.find(string.upper(ccpath), "DRAG") then
clubType = "drag"
clubPath = "/club/street_" .. clubLeague .. "_drag"
else
clubType = "street"
clubPath = "/club/street_" .. clubLeague
end

data[clubPath] = data[clubPath] .. ccpath .. "\n"

if cclass == "S" then -- also add S class to hero leagues
if clubType == "dirt" then data["/club/dirt_hero"] = data["/club/dirt_hero"] .. ccpath .. "\n" end
if clubType == "drag" then data["/club/street_hero_drag"] = data["/club/street_hero_drag"] .. ccpath .. "\n" end
if clubType == "street" then data["/club/street_hero"] = data["/club/street_hero"] .. ccpath .. "\n" end
end
end


ckey = "brand/" .. brand .. "/" .. cclass
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n" -- Add to brand specific classes

ckey = "induction/" .. induction .. "/" .. cclass
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n" -- Add to induction specific classes

ckey = "drivetrain/" .. drivetrain .. "/" .. cclass
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n" -- Add to drivetrain specific classes

if tier ~= "NONE" then

ckey = "brand/" .. brand .. "/" .. tier -- Add to brand tier 
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n"

ckey = "induction/" .. induction .. "_" .. tier -- Add to induction tier 
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n"

ckey = "drivetrain/" .. drivetrain .. "_" .. tier -- Add to drivetrain tier 
if not data[ckey] then data[ckey] = "" end
data[ckey] = data[ckey] .. ccpath .. "\n"

end

else
data["NA"] = data["NA"] .. "/vehicles/" .. v .. "/" .. cname .. ".pc" .. "\n"
end
end
end
end
end
-- Write performance files
for k,v in pairs(data) do
if not FS:fileExists("beamLR/performanceClass/" .. k) or overwrite then
writeFile("beamLR/performanceClass/" .. k, v)
end
end
end

local function modelFromConfig(path)
local offset = 0
if string.sub(path, 1,1) == "/" then offset = 1 end -- Detects path starting with slash
local split = ssplit(path, "/")
local model = split[2+offset]
return model
end

local function loadDataFile(path, asKeys) -- For files not in table format, load each line as a table element
local filedata = readFile(path)
if string.sub(filedata, #filedata, #filedata) == "\n" then -- Remove last newline if it exists to prevent empty last element
filedata = string.sub(filedata, 1, #filedata-1) 
end
filedata = filedata:gsub("\r", "") -- Clear \r character leaving only \n 
local filesplit = ssplit(filedata, "\n")
local toRet = {}
for k,v in pairs(filesplit) do
if asKeys then
toRet[v] = true
else
toRet[k] = v
end
end
return toRet
end

local function saveDataFile(path, data, useKeys)
local filedata = ""
for k,v in pairs(data) do
if useKeys then
filedata = filedata .. k .. "\n"
else
filedata = filedata .. v .. "\n"
end
end
writeFile(path, filedata:sub(1,-2))--sub removes last newline, wouldn't be a problem because loadDataFile ignores it but still makes cleaner files
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
local copTable = {}				-- Vehid KEY, true val, non cop ids will return nil when checked
local copfixReceived = {}		-- Vehid KEY, SENT as boolean val
locals["copCount"] = 0		    -- Fixes to send before stopping
locals["copfixSent"] = 0			-- Sent fixes so far

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
locals["copCount"] = 0
for k,v in pairs(lastTrafficData) do
if v["autoRole"] == "police" then
copTable[k] = true
locals["copCount"] = locals["copCount"] + 1
end
end
end

local function copfixReset() -- Should be called before init pass
copfixReceived = {}
locals["copfixSent"] = 0
end

local function copfixInit()	-- Initial copfix pass, sends fixes to all cops active when fix is triggered
local cdata = {}
updateTrafficData()

for k,v in pairs(copTable) do
cdata = lastTrafficData[k]

if cdata["state"] == "active" then -- Found active cop
forceSetAIMode(k, "traffic") -- Send fix
copfixReceived[k] = true	-- Set fix received to true for vehid 
locals["copfixSent"] = locals["copfixSent"] + 1 -- Increment sent copfix amount
print("Should have fixed cop: " .. k)

if locals["copfixSent"] == locals["copCount"] then -- Finished sending copfixes in init pass
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
locals["copfixSent"] = locals["copfixSent"] + 1 -- Increment sent copfix amount
print("Should have fixed cop: " .. veid)

if locals["copfixSent"] == locals["copCount"] then -- Finished sending copfixes in init pass
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

local function addShopCarToGarage(sfile, count, seed) -- Force add car to garage using a shop file, added for track events
local ctable = loadDataTable("beamLR/shop/car/" .. sfile) 
local config = ctable["config"]
local baseprice = ssplitnum(ctable["baseprice"], ",")[1]
local paintdata = vehiclePaintToGaragePaint(createRandomPaint(seed))
local filedata = ""
local filename = "beamLR/garage/car" .. (count)
filedata = "name=" .. ctable["name"] .. "\n"
filedata = filedata .. "type=" .. ctable["type"] .. "\n"
filedata = filedata .. "gas=2" .. "\n"
filedata = filedata .. "baseprice=" .. ctable["baseprice"] .. "\n"
filedata = filedata .. "partprice=" .. ctable["partprice"] .. "\n"
filedata = filedata .. "scrapval=" .. ctable["scrapval"] .. "\n"
filedata = filedata .. "paintA=" .. paintdata .. "\n"
filedata = filedata .. "paintB=" .. paintdata .. "\n"
filedata = filedata .. "paintC=" .. paintdata .. "\n"
filedata = filedata .. "damage=0\n"
filedata = filedata .. "impoundval=0\n"
filedata = filedata .. "nos=0\n"
writeFile(filename, filedata)

extensions.blrutils.copyFile(config, "beamLR/garage/config/car" .. (count))

local ifile = "odometer=0"
writeFile("beamLR/beamstate/integrity/car" .. (count), ifile)

local mechdata = extensions.mechDamageLoader.getNewCarMechData()
writeFile("beamLR/beamstate/mech/car" .. (count), mechdata)

FS:directoryCreate("beamLR/garage/config/template/car" .. (count))

end

local function getLevelInfo(level)
return jsonReadFile("/levels/" .. level .. "/info.json")
end

local function getInstalledLevels() -- As key map for quick lookup
local levels = core_levels.getLevelNames()
local toRet = {}
for k,v in pairs(levels) do -- Look for terrain file to ensure lvl is actually installed
if FS:findFiles("levels/" .. v, "*.ter", 0, false)[1] ~= nil then
toRet[v] = true
end
end
return toRet
end

local function getLevelUITitle(level)
local installed = getInstalledLevels()
if installed[level] then
local info = getLevelInfo(level)
return translateLanguage(info["title"], info["title"])
else
return "MISSING_LEVEL"
end
end

locals["clubCompletionStatus"] = function()
local complete = true
local list = FS:directoryList("beamLR/races")
local current = {}
for k,v in pairs(list) do
if v ~= "/beamLR/races/integrity" then
if FS:fileExists(v .. "/progress") then -- 1.17.4 shared progress, some club folders have no progress file
current = loadDataTable(v .. "/progress" )["current"]
complete = current == "hero"
if not complete then break end
end
end
end
return complete
end


local function eventBrowserGetList() -- Returns event list for browser UI
local toRet = {}
local sortedRep = {}
local sortedName = {}
local sortedRepKeys = {}
local sortedNameKeys = {}
local packedRep = {}
local toRetSorted = {}
local files = FS:findFiles("beamLR/trackEvents/", "*", 0)
local pdata = loadDataTable("beamLR/mainData")
local currentEvent = loadDataTable("beamLR/currentTrackEvent")
local installedLevels = getInstalledLevels()
local cdata = {}
local i = 1
for k,v in pairs(files) do
cdata = loadDataTable(v)
if installedLevels[cdata["map"]] then -- do not offer events on maps that aren't installed
toRet[i] = {}
toRet[i]["title"] = cdata["title"]
toRet[i]["joincost"] = cdata["joincost"]
toRet[i]["map"] = getLevelUITitle(cdata["map"]) -- Using UI level name
toRet[i]["joined"] = (v:sub(21) == currentEvent["efile"] and currentEvent["status"] ~= "over")
toRet[i]["unlocked"] = extensions.blrglobals.gmGetVal("playerRep") >= tonumber(cdata["reputation"])
toRet[i]["bossevent"] = cdata["bossevent"]
toRet[i]["bossunlocked"] = locals["clubCompletionStatus"]()
if(cdata["bossevent"] == "true") then
toRet[i]["unlocked"] = toRet[i]["unlocked"] and locals["clubCompletionStatus"]()
end
toRet[i]["repunlock"] = tonumber(cdata["reputation"])
toRet[i]["file"] = v:sub(21)
i = i+1
end
end

--Event sorting, first by rep then by name
--Step 1, build sorted tables
for k,v in pairs(toRet) do
table.insert(sortedRep, v["repunlock"])
table.insert(sortedName, v["title"])
end
local sortedRepKeys, sortedRepValues = linkedsort(sortedRep)
local sortedNameKeys, sortedNameValues = linkedsort(sortedName)

--Step 2, pack events keys with same amount of rep into rep amount keyed tables
for i,k,v in linkedpairs(sortedRepKeys, sortedRepValues) do
if not packedRep["" .. v] then packedRep["" .. v] = {} end
table.insert(packedRep["" .. v], k)
end

local cpack = {}
local cdone = {}

--Step 3, build final table
for rep_i,rep_k,rep_v in linkedpairs(sortedRepKeys, sortedRepValues) do
if not cdone["" .. rep_v] then
cpack = packedRep["" .. rep_v]
for name_i,name_k,name_v in linkedpairs(sortedNameKeys, sortedNameValues) do
for pack_k,pack_v in pairs(cpack) do
if name_k == pack_v then
table.insert(toRetSorted, toRet[pack_v])
end
end
end
cdone["" .. rep_v] = true
end
end


return toRetSorted
end

local function eventBrowserGetPlayerData() -- Returns player data for browser UI
local toRet = {}
local lgslots = extensions.blrglobals.blrFlagGet("limitedGarageSlots")
local pdata = loadDataTable("beamLR/mainData")
toRet["money"] = extensions.blrglobals.gmGetVal("playerMoney")
toRet["rep"] = extensions.blrglobals.gmGetVal("playerRep")
toRet["bossunlock"] = locals["clubCompletionStatus"]()
if lgslots then
toRet["availslots"] = extensions.blrglobals.getProjectVariable("playerGarageSlots") - extensions.blrglobals.getProjectVariable("playerCarCount")
else
toRet["availslots"] = 999999999
end
--dump(toRet)
return toRet
end

local function getVehicleInfoFile(model) -- info.json containing UI name and brand, dont specify model to use current veh model
if not model then model = getVehicleMainPartName() end
local data = jsonReadFile("/vehicles/" .. model .. "/info.json")
return data
end

local inspectionDataEvent = {} -- Stores last loaded inspection related fields for comparison with vehicle


local function loadEventWithRandoms(event, seed)
local edata = loadDataTable("beamLR/trackEvents/" .. event)
math.randomseed(seed)
local lapssplit = ssplitnum(edata["laps"], ",")
local roundssplit = ssplitnum(edata["rounds"], ",")
local opcountsplit = ssplitnum(edata["opcount"], ",")
local timesplit = ssplitnum(edata["timeofday"], ",")
local carsplit = ssplit(edata["carreward"], ",")

local partsplit = {}
local partrange = {}
local partchance = 0
local partdata = ""
if edata["partreward"] ~= "none" then
partsplit = ssplit(edata["partreward"], ",")
partrange = ssplitnum(partsplit[2], ":")
partchance = tonumber(partsplit[1])
end


local moneysplit = extensions.blrutils.ssplit(edata["moneyreward"], ",")
local moneyrange = {}
local moneydata = ""
moneyrange[1] = ssplitnum(moneysplit[1], ":")
moneyrange[2] = ssplitnum(moneysplit[2], ":")
moneyrange[3] = ssplitnum(moneysplit[3], ":")

local repsplit = extensions.blrutils.ssplit(edata["repreward"], ",")
local reprange = {}
local repdata = ""
reprange[1] = ssplitnum(repsplit[1], ":")
reprange[2] = ssplitnum(repsplit[2], ":")
reprange[3] = ssplitnum(repsplit[3], ":")


-- Event params are individually seeded except for reward which is linked to total duration of event
local laproll = math.random()
local roundroll =  math.random()
local opcountroll = math.random()
local timeroll =  math.random()
local partroll = math.random()
local carroll = 0
local rewardfloat = (laproll + timeroll) / 2.0 -- Max laps + max rounds = max reward

if #lapssplit > 1 then
edata["laps"] = math.floor(lerp(laproll, lapssplit[1], lapssplit[2], false))
end

if #roundssplit > 1 then
edata["rounds"] = math.floor(lerp(roundroll, roundssplit[1], roundssplit[2], false))
end

if #opcountsplit > 1 then
edata["opcount"] = math.floor(lerp(opcountroll, opcountsplit[1], opcountsplit[2], false))
end

if #timesplit > 1 then
edata["timeofday"] = lerp(timeroll, timesplit[1], timesplit[2], false)
end

if #moneyrange[1] > 1 then
moneydata = (math.floor(lerp(rewardfloat, moneyrange[1][1], moneyrange[1][2], false) / 100.0) * 100.0) .. ","
else
moneydata = moneyrange[1][1] .. ","
end
if #moneyrange[2] > 1 then
moneydata = moneydata .. (math.floor(lerp(rewardfloat, moneyrange[2][1], moneyrange[2][2], false) / 100.0) * 100.0) .. ","
else
moneydata = moneydata .. moneyrange[2][1] .. ","
end
if #moneyrange[3] > 1 then
moneydata = moneydata .. (math.floor(lerp(rewardfloat, moneyrange[3][1], moneyrange[3][2], false) / 100.0) * 100.0)
else
moneydata = moneydata .. moneyrange[3][1]
end

if #reprange[1] > 1 then
repdata = (math.floor(lerp(rewardfloat, reprange[1][1], reprange[1][2], false) / 10.0) * 10.0) .. ","
else
repdata = reprange[1][1] .. ","
end
if #reprange[2] > 1 then
repdata = repdata .. (math.floor(lerp(rewardfloat, reprange[2][1], reprange[2][2], false) / 10.0) * 10.0) .. ","
else
repdata = repdata .. reprange[2][1] .. ","
end
if #reprange[3] > 1 then
repdata = repdata .. (math.floor(lerp(rewardfloat, reprange[3][1], reprange[3][2], false) / 10.0) * 10.0)
else
repdata = repdata .. reprange[3][1]
end

edata["moneyreward"] = moneydata
edata["repreward"] = repdata

if #carsplit > 1 then
carroll = math.random(1, #carsplit)
edata["carreward"] = carsplit[carroll]
end

if partroll <= partchance then
local partlist = extensions.blrpartmgmt.getValueRangedPartList(partrange[1], partrange[2])
if #partlist > 0 then
local partpick = math.random(1, #partlist)
edata["partreward"] = partlist[partpick]
else
edata["partreward"] = "none"
end
else
edata["partreward"] = "none"
end

return edata
end


local function eventBrowserGetData(event, seed) -- Returns selected event data for browser UI
local toRet = {}
local edata = loadEventWithRandoms(event, seed)
local cdata = {}
toRet["title"] = edata["title"]
toRet["map"] = getLevelUITitle(edata["map"]) -- Using UI level name
toRet["layout"] = edata["layout"]
local timedata = formatTimeOfDay(tonumber(edata["timeofday"]))
local timestring = string.format("%.2d:%.2d", timedata["hours"], timedata["minutes"])
toRet["timeofday"] = timestring 
toRet["perfclass"] = edata["perfclass"]
toRet["powertrain"] = edata["powertrain"]
if edata["allowedmodel"] ~= "any" then
toRet["allowedmodel"] = getVehicleInfoFile(edata["allowedmodel"])["Name"]
else
toRet["allowedmodel"] = "any"
end
toRet["allowedbrand"] = edata["allowedbrand"]
toRet["induction"] = edata["induction"]
toRet["reputation"] = tonumber(edata["reputation"])
toRet["bossevent"] = edata["bossevent"] -- for 1.15 race of heroes event
toRet["joincost"] = tonumber(edata["joincost"])
toRet["laps"] = edata["laps"]
toRet["rounds"] = edata["rounds"]
toRet["opcount"] = edata["opcount"]
toRet["moneyreward"] = edata["moneyreward"]
toRet["repreward"] = edata["repreward"]

if edata["partreward"] ~= "none" then
toRet["partreward"] = extensions.blrpartmgmt.getPartNameLibrary()[edata["partreward"]] or edata["partreward"]
else
toRet["partreward"] = "none"
end


if edata["carreward"] ~= "none" then -- Use proper car name instead of file name
local cars = ssplit(edata["carreward"], ",")
local cfirst = true
toRet["carreward"] = ""
for k,v in pairs(cars) do
cdata = loadDataTable("beamLR/shop/car/" .. v)
if not cfirst then
toRet["carreward"] = toRet["carreward"] .. ", "
end
toRet["carreward"] = toRet["carreward"] .. cdata["name"]
cfirst=false
end
else
toRet["carreward"] = "none"
end
toRet["pitlane"] = edata["pitlane"]
toRet["efile"] = event -- Passing efile parameter to use when joining

-- set inspection fields
inspectionDataEvent = {}
inspectionDataEvent["perfclass"] = toRet["perfclass"]
inspectionDataEvent["powertrain"] = toRet["powertrain"]
inspectionDataEvent["model"] = edata["allowedmodel"] -- Use event data internal model instead of UI brand, no need to load veh info file 
inspectionDataEvent["brand"] = toRet["allowedbrand"]
inspectionDataEvent["induction"] = toRet["induction"]

return toRet
end

local function fetchVehicleUtilsData(vehid)-- Use this to update vehutils values when player changes vehicles
local ptid = "vehinfo_powertrain"
local inid = "vehinfo_induction"
local pcid = "vehinfo_perfclass"
local pdid = "vehinfo_perfdata"
local ptfetch = "extensions.blrVehicleUtils.getPowertrainLayoutName()"
local infetch = "extensions.blrVehicleUtils.getInductionType()"
local pcfetch = "extensions.blrVehicleUtils.getPerformanceClass()"
local pdfetch = "extensions.blrVehicleUtils.getPerformanceData()"
if not vehid then vehid = be:getPlayerVehicle(0):getId() end
extensions.vluaFetchModule.exec(vehid, ptfetch, ptid, true)
extensions.vluaFetchModule.exec(vehid, infetch, inid, true)
extensions.vluaFetchModule.exec(vehid, pcfetch, pcid, true)
extensions.vluaFetchModule.exec(vehid, pdfetch, pdid, true)
end

local function getFetchedVehicleUtilsData() 
local toRet = {}
local ptid = "vehinfo_powertrain"
local inid = "vehinfo_induction"
local pcid = "vehinfo_perfclass"
local pdid = "vehinfo_perfdata"
toRet["powertrain"] = extensions.vluaFetchModule.getVal(ptid)
toRet["induction"] = extensions.vluaFetchModule.getVal(inid)
toRet["perfclass"] = extensions.vluaFetchModule.getVal(pcid)
toRet["perfdata"] = extensions.vluaFetchModule.getVal(pdid)
return toRet
end

local inspectionDataCar = {} -- For inspection process

local function eventBrowserGetCarData(carid)
local toRet = {}
local walking = getVehicleMainPartName() == "unicycle"
toRet["walking"] = walking

if not walking then
local vudata = getFetchedVehicleUtilsData()
local info = getVehicleInfoFile()
local cdata = loadDataTable("beamLR/garage/car" .. carid)
toRet["garagename"] = cdata["name"]
toRet["impounded"] = tonumber(cdata["impoundval"]) > 0
toRet["model"] = cdata["type"]
toRet["uiname"] = info["Name"]
--toRet["damage"] = cdata["damage"] -- Damage sent through FG at regular interval to get current damage
toRet["brand"] = info["Brand"]
toRet["powertrain"] = vudata["powertrain"]
toRet["induction"] = vudata["induction"]
toRet["perfclass"] = vudata["perfclass"]
end

-- Set inspection data
inspectionDataCar = {}
inspectionDataCar["model"] = toRet["model"]
inspectionDataCar["brand"] = toRet["brand"] 
inspectionDataCar["powertrain"] = toRet["powertrain"] 
inspectionDataCar["induction"] = toRet["induction"]
inspectionDataCar["perfclass"] = toRet["perfclass"]

return toRet
end

local function performanceUIData()
local perfdata = getFetchedVehicleUtilsData()["perfdata"]
local perfsplit = extensions.blrutils.ssplit(perfdata, ",")
local perftable = {}
perftable["power"] = perfsplit[1]
perftable["torque"] = perfsplit[2]
perftable["weight"] = perfsplit[3]
perftable["class"] = perfsplit[4]
perftable["value"] = perfsplit[5]
return perftable
end


local function getCurrentEventData()
local toRet = {}
local cdata = loadDataTable("beamLR/currentTrackEvent")
local edata = loadEventWithRandoms(cdata["efile"], tonumber(cdata["seed"]))
local vdata = loadDataTable("beamLR/garage/car" .. cdata["carid"])

toRet["title"] = edata["title"]
toRet["map"] = getLevelUITitle(edata["map"]) -- Using UI level name
toRet["status"] = cdata["status"]
toRet["cround"] = cdata["cround"]
toRet["tround"] = edata["rounds"]
toRet["carname"] = vdata["name"]
toRet["efile"] = cdata["efile"]

return toRet
end

local function getEventInspectionStatus()
local failed = false -- Final inspection result
local cpass = false -- Current item
local csplit = {}
local ccarval = ""

 -- Check first field to know if table has been loaded
if inspectionDataCar["brand"] and inspectionDataEvent["brand"] then

if inspectionDataEvent["brand"] ~= "any" then
cpass = false
csplit = ssplit(inspectionDataEvent["brand"], ",")
ccarval = inspectionDataCar["brand"]
for k,v in pairs(csplit) do
cpass = ccarval == v 
if cpass then break end
end
failed = failed or not cpass
end

if inspectionDataEvent["model"] ~= "any" then
cpass = false
csplit = ssplit(inspectionDataEvent["model"], ",")
ccarval = inspectionDataCar["model"]
for k,v in pairs(csplit) do
cpass = ccarval == v 
if cpass then break end
end
failed = failed or not cpass
end

if inspectionDataEvent["powertrain"] ~= "any" then
cpass = false
csplit = ssplit(inspectionDataEvent["powertrain"], ",")
ccarval = inspectionDataCar["powertrain"]
for k,v in pairs(csplit) do
cpass = ccarval == v 
if cpass then break end
end
failed = failed or not cpass
end

if inspectionDataEvent["perfclass"] ~= "any" then
cpass = false
csplit = ssplit(inspectionDataEvent["perfclass"], ",")
ccarval = inspectionDataCar["perfclass"]
for k,v in pairs(csplit) do
cpass = ccarval == v 
if cpass then break end
end
failed = failed or not cpass
end

-- Induction uses string matching, nitrous is optional since "NA" still matches "SC,Turbo,NA+N2O"
if inspectionDataEvent["induction"] ~= "any" then
cpass = string.find(inspectionDataEvent["induction"], inspectionDataCar["induction"], 1, true)
failed = failed or not cpass
end

else
failed=true--Set inspection failed to be safe in event where no data was loaded (ui init request after loading?)
end

return not failed
end

local function getEventSeed(uid) -- Generates unique seeds for event, no collision until > 100 event files
local currentData = loadDataTable("beamLR/currentTrackEvent")
local currentID = tonumber(currentData["eventid"])
local seed = getDailySeed() + ((currentID+1) * 100) + uid
return seed
end

local function joinEvent(event, carid, uid)
local currentData = loadDataTable("beamLR/currentTrackEvent")
local currentID = tonumber(currentData["eventid"])
local seed = getEventSeed(uid)
local edata = loadEventWithRandoms(event, seed)
local filedata = "status=joined\n"
filedata = filedata .. "seed=" .. seed .. "\n" 
filedata = filedata .. "efile=" .. event .. "\n"
filedata = filedata .. "cround=0\ncarid=" .. carid .. "\n"

filedata = filedata .. "ctimes=player:0"
for i=1,tonumber(edata["opcount"]) do
filedata = filedata .. ",op" .. i .. ":0"
end
filedata = filedata .. "\n"

filedata = filedata .. "eventid=" .. (currentID+1) -- Increment eventid for new event
writeFile("beamLR/currentTrackEvent", filedata)

-- Refresh current event data for both UIs
local cdata = getCurrentEventData()
extensions.customGuiStream.sendDataToUI("currentTrackEvent", cdata)
extensions.customGuiStream.sendEventBrowserCurrentEventData(cdata)
-- Refresh event list to get updated join state
local elist = extensions.blrutils.eventBrowserGetList()
extensions.customGuiStream.sendEventBrowserList(elist)

-- Charge player for event joining
local cmoney = extensions.blrglobals.gmGetVal("playerMoney")
local nmoney = cmoney - tonumber(edata["joincost"])
extensions.blrglobals.gmSetVal("playerMoney", nmoney)
local dtable = {}
dtable["money"] = nmoney
updateDataTable("beamLR/mainData", dtable)

extensions.blrglobals.blrFlagSet("eventRestrictUpdate", true) -- Request update for vehicle restriction state
end

local function checkVehicleEventRestricted(gid)
local dtable = loadDataTable("beamLR/currentTrackEvent")
local restrict = tonumber(dtable["carid"]) == gid and dtable["status"] ~= "over"
extensions.blrglobals.blrFlagSet("vehicleEventRestricted", restrict)
extensions.customGuiStream.sendDataToUI("vehicleRestricted", restrict)
end


local function towPlayerNoReset(location)
local playerVehicle = be:getPlayerVehicle(0)
local spot = getMapTowSpot(location)
if not playerVehicle then return end
local vehRot = quat(playerVehicle:getClusterRotationSlow(playerVehicle:getRefNodeId()))
local pos = vec3(spot["pos"][1], spot["pos"][2], spot["pos"][3])
local rot = quat(spot["rot"][1],spot["rot"][2],spot["rot"][3],spot["rot"][4] )
local diffRot = vehRot:inversed() * rot
playerVehicle:setClusterPosRelRot(playerVehicle:getRefNodeId(), pos.x, pos.y, pos.z, diffRot.x, diffRot.y, diffRot.z, diffRot.w)
playerVehicle:applyClusterVelocityScaleAdd(playerVehicle:getRefNodeId(), 0, 0, 0, 0)
playerVehicle:setOriginalTransform(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)
end

local function getOrderedCarTemplateList(gid)
local templates = FS:findFiles("beamLR/garage/config/template/car" .. gid, "*", 0)
local toRet = {}
for k,v in pairs(templates) do
toRet[k] = templates[k]:gsub("/beamLR/garage/config/template/car" .. gid .. "/", "")
end
table.sort(toRet)
return toRet
end

local function getCarTemplateFolder(gid)
return "beamLR/garage/config/template/car" .. gid .. "/"
end

local function uiRefreshTemplates()
local cvgid = extensions.blrglobals.gmGetVal("cvgid")
local templates = getOrderedCarTemplateList(cvgid)
local tempfolder = getCarTemplateFolder(cvgid)
extensions.customGuiStream.sendDataToUI("vehicleTemplateList", templates)
extensions.customGuiStream.sendDataToUI("vehicleTemplateFolder", tempfolder)
end

-- updated for 1.18 to work with part paths in config
-- updated for 1.16 advanced part inventory
-- set detailed to true to get list of missing parts
local function templateLoadCheck(current, target, detailed)
local toRet = true
local toRetDetailed = {}
local clinks = current["ilinks"]
local tlinks = target["ilinks"]
local inventory = extensions.blrPartInventory.getInventory()

local psplit = {}
local csplit = {}
local tsplit = {}

local pname = ""
local cid = 0
local tid = 0

for k,v in pairs(tlinks) do
tsplit = ssplit(v, ",")
tid = tonumber(tsplit[1])

psplit = ssplit(k, "/")-- 1.18 fix, parse part name from path
pname = psplit[#psplit]

if clinks[k] then -- current config contains target part 
	csplit = ssplit(v, ",")
	cid = tonumber(csplit[1])
	if tid ~= cid then -- not same part ID, check inventory if target part is in use
		if not inventory[tid] then toRet = false break end -- part ID doesn't exist in inventory, can't load
		if inventory[tid][1] ~= pname then toRet = false break end -- part at target inventory ID changed, can't load
		if inventory[tid][4] == 1 then toRet = false break end -- target part in use, can't load
	end
else -- current config doesn't contain target part, check inventory
	if not inventory[tid] then toRet = false break end -- part ID doesn't exist in inventory, can't load
	if inventory[tid][1] ~= pname then toRet = false break end -- part at target inventory ID changed, can't load
	if inventory[tid][4] == 1 then toRet = false break end -- target part in use, can't load
end

end

-- detailed mode builds list of inventory IDs for missing parts in template
if detailed then
for k,v in pairs(tlinks) do
psplit = ssplit(k, "/")
pname = psplit[#psplit]

tsplit = ssplit(v, ",")
tid = tonumber(tsplit[1])
	if clinks[k] then -- current config contains target part 
	csplit = ssplit(v, ",")
	cid = tonumber(csplit[1])
	if tid ~= cid then -- not same part ID, check inventory if target part is in use
		if (not inventory[tid]) or (inventory[tid][1] ~= pname) or (inventory[tid][4] == 1) then
			table.insert(toRetDetailed, k)
		end
	end
	else -- current config doesn't contain target part, check inventory
		if (not inventory[tid]) or (inventory[tid][1] ~= pname) or (inventory[tid][4] == 1) then
			table.insert(toRetDetailed, k)
		end
	end
end
end

if not detailed then
return toRet
else
return toRet, toRetDetailed
end

end


local function processMissionRandoms(mdata, mtype)
local toRet = {}
local items = loadDataFile("beamLR/missions/items/" .. mtype .. "/" .. mdata["items"]) -- Now uses list files
local ipick = ""
local idata = {}
local difficulty = 0
local basereward = tonumber(mdata["reward"])
local weightscale = 0
math.randomseed(os.clock()*1000) -- No complex seeding for mission system


if #items > 1 then
ipick = items[math.random(1, #items)]
else
ipick = items[1]
end

idata = loadDataTable("beamLR/missions/items/" .. mtype .. "/" .. ipick)
difficulty = 1.0 - math.max(0, math.min(1.0, tonumber(idata["failg"]) / 100.0))
local weightscale = tonumber(idata["wrscl"] or "1.0") -- Difficulty increase from item weight, items without the param default to 1.0
difficulty = difficulty + (weightscale - 1.0) -- which means since 1.0 is removed here it won't add any difficulty

toRet["reward"] = basereward + (basereward * difficulty)
toRet["itemname"] = idata["name"]
toRet["failg"] = tonumber(idata["failg"])
toRet["desc"] = mdata["desc"]:gsub("$item", idata["name"]) .. "\n"
toRet["desc"] = toRet["desc"] .. "Reward: $" .. toRet["reward"] .. "\n"
toRet["desc"] = toRet["desc"] .. "Max Force: " .. toRet["failg"] .. " Gs\n"

if mtype == "trailer" or mtype == "gooseneck" then
toRet["desc"] = toRet["desc"] .. "Task: Unhook trailer inside markers\nNote: Damaging the trailer will fail the mission!"
else
toRet["desc"] = toRet["desc"] .. "Task: Drive to marked location"
end

toRet["tconfig"] = idata["trailer"]

return toRet
end


local function timeDetector(tstart, tend) -- Expects 24h format time (ex: 12.5 for 12h30 PM)
if tstart == tend then return true end -- Always return true if start time is same as end time
local ctime = core_environment.getTimeOfDay().time
local rtime = ((ctime - 0.5) % 1) * 24.0
local inside = false
if tstart < tend then
inside = (rtime >= tstart and rtime <= tend)
else
inside = not (rtime >= tend and rtime <= tstart)
end
return inside
end

local function hoursTimeString(hours) -- 12.5 to 12:30
local h,m = math.modf(hours)
return string.format("%02d:%02d", h, m * 60.0)
end


local savedGameOptions = {} -- To reset game options after scenario stops
local function setGameOption(setting, value)
savedGameOptions[setting] = settings.getValue(setting)
settings.setValue(setting, value, true)
end

local function getSavedGameOption(setting, value)
return savedGameOptions[setting]
end

local function resetGameOptions()
for k,v in pairs(savedGameOptions) do
settings.setValue(k, v, true)
end
end


locals["dsBackOpacity"]  = 0
locals["dsTextOpacity"]  = 0

local function setDeathScreenBackOpacity(dx, mx, mn)
locals["dsBackOpacity"]  = math.max(math.min(locals["dsBackOpacity"]  + dx, mx), mn)
extensions.customGuiStream.sendGameOverUIBackOpacity(locals["dsBackOpacity"] )
return locals["dsBackOpacity"] 
end

local function setDeathScreenTextOpacity(dx, mx, mn)
locals["dsTextOpacity"]  = math.max(math.min(locals["dsTextOpacity"]  + dx, mx), mn)
extensions.customGuiStream.sendGameOverUITextOpacity(locals["dsTextOpacity"] )
return locals["dsTextOpacity"] 
end

local function playSFX(effect)
blrvarSet("SFXFile", effect)
extensions.blrglobals.blrFlagSet("SFXQueued", true)
end

-- Race path helper function: finds editor selection and dumps to file
-- To create or edit race paths without having to input each trigger individually
local function racePathHelper(separator)
local data = ""
local cobj = {}
local cname = ""
for k,v in ipairs(editor.selection.object) do
cobj = scenetree.findObjectById(v)
cname = cobj:getName()
data = data .. cname
if separator then
data = data .. separator
else
data = data .. "\n"
end
end
data = data:sub(1,-2)
writeFile("beamLR/racePathHelper", data)
end

local function createRandomFactoryPaint(seed, model)
math.randomseed(seed)
local paints = getVehicleInfoFile(model)["paints"]
local pkeys = {}
local pid = 1
for k,v in pairs(paints) do
pkeys[pid] = k
pid = pid+1
end
local pick = pkeys[math.random(1, #pkeys)]
print("Picked random factory paint key: " .. pick)
local paint = paints[pick]
return createVehiclePaint({x=paint.baseColor[1], y=paint.baseColor[2], z=paint.baseColor[3], w=paint.baseColor[4]}, paint.metallic, paint.roughness, paint.clearcoat, paint.clearcoatRoughness)
end

local function processRaceRandoms(raceData, seed)
local toRet = {}
local crand = 0
local wager= ssplit(raceData["wager"], ",")
local parts= ssplit(raceData["parts"], ",")
local partsRand = tonumber(raceData["partsRand"]) == 1
local reputation = ssplit(raceData["rep"], ",")
local enemyModels = raceData["enemyModel"] -- Now receiving perfclass loader table, no need for ssplit
local enemyConfigs = raceData["enemyConfig"] -- Now receiving perfclass loader table, no need for ssplit
local enemyRisk = ssplit(raceData["enemyRisk"], ",")
local laps = ssplit(raceData["laps"], ",")
local slipsChance = tonumber(raceData["slips"])
local pmodel = extensions.blrpartmgmt.getMainPartName()
local slipsBlacklist = loadDataFile("beamLR/pinkslipsBlacklist", true)-- Loaded as keys for fast lookup
local wagertmp = 0
local lstrig = tonumber(raceData["lstrig"] or "0")
local lswp = tonumber(raceData["lswp"] or "0")
local wpsplit = ssplit(raceData["waypoints"], ",")
local wploop = "" -- looping subsection
local wptoret = "" -- final waypoint list
local wrand = 0 -- to link lap count with rewards 
local traffic = tonumber(raceData["traffic"])--traffic param now interpreted as chance to use traffic

-- 1.16.9 seeded race RNG
math.randomseed(seed)

if #wager > 1 then 
wrand = math.random()
toRet["wager"] = math.floor(lerp(wrand, tonumber(wager[1]), tonumber(wager[2]), false)*100.0) / 100.0;
else 
toRet["wager"] = tonumber(wager[1])
end
wagertmp = toRet["wager"]

crand = math.random()
if crand <= slipsChance then -- RNG based pink slips 
toRet["slips"] = 1
-- 1.12 now uses chance for slips to also have a bonus wager
if crand > slipsChance / 2.0 then toRet["wager"] = 0 end
else -- No pink slips, randomly generate wager
toRet["slips"] = 0
end

if partsRand then
crand = math.random(#parts)
toRet["parts"] = parts[crand]
else
toRet["parts"] = raceData["parts"]
end

if #reputation > 1 then
toRet["rep"] = math.floor(lerp(wrand, tonumber(reputation[1]), tonumber(reputation[2]), false))
else 
toRet["rep"] = tonumber(reputation[1])
end

if #enemyModels > 1 then
-- dev mode attempt to load specific model
if blrvarGet("devRaceModel") then
for i=1,100 do 
crand = math.random(#enemyModels)
toRet["enemyModel"] = enemyModels[crand]
toRet["enemyConfig"] = enemyConfigs[crand]
if toRet["enemyModel"] == blrvarGet("devRaceModel") then break end
end
else
crand = math.random(#enemyModels)
toRet["enemyModel"] = enemyModels[crand]
toRet["enemyConfig"] = enemyConfigs[crand]
end

else 
toRet["enemyModel"] = raceData["enemyModel"][1]
toRet["enemyConfig"] = raceData["enemyConfig"][1]
end

-- enemy model is on slips blacklist, only offer slips if player also has
-- a blacklisted (aka fancy) vehicle model otherwise force disable slips
if slipsBlacklist[toRet["enemyModel"]] and not slipsBlacklist[pmodel] then
toRet["slips"] = 0
toRet["wager"] = wagertmp -- Restores wager in event it was set to 0 by slips
end


if #enemyRisk > 1 then
toRet["enemyRisk"] = math.random(tonumber(enemyRisk[1])*100.0, tonumber(enemyRisk[2])*100.0) / 100.0
else
toRet["enemyRisk"] = tonumber(enemyRisk[1])
end

-- upper bound + 1 because floor would mean only 1.0 roll has max lap count, cap with math.min in case the 1.0 roll happens
if #laps > 1 then 
toRet["laps"] = math.min(tonumber(laps[2]), math.floor(lerp(wrand, tonumber(laps[1]), tonumber(laps[2])+1, false)))
else
toRet["laps"] = tonumber(laps[1])
end

--1.14 looping race subsection
blrvarSet("racelstrig", lstrig)
if lswp > 0 then
-- build looping waypoint subsection
wploop = wpsplit[lswp]
for i=lswp+1,#wpsplit do
wploop = wploop .. "," .. wpsplit[i]
end
-- build final waypoint list
wptoret = raceData["waypoints"]
for i=2,toRet["laps"] do
wptoret = wptoret .. "," .. wploop
end
toRet["waypoints"] = wptoret
else
toRet["waypoints"] = raceData["waypoints"]
end

local raceTrafficMode = blrvarGet("raceTrafficMode")
if raceTrafficMode == 0 then
if (math.random() < traffic) then
toRet["traffic"] = 1
else
toRet["traffic"] = 0
end
else
toRet["traffic"] = raceTrafficMode-1
end

lastProcessedRace = toRet

return toRet
end

local function wpspdHelper(scale,minimum,original)
local split = ssplit(original, ",")
local vsplit = {}
local cval = 0
local toRet = "wpspd="
for k,v in pairs(split) do
vsplit = ssplit(v, ":")
cval = tonumber(vsplit[2])
if cval >= minimum then
toRet = toRet .. vsplit[1] .. ":" .. (cval * scale) .. ","
else
toRet = toRet .. vsplit[1] .. ":" .. (cval) .. ","
end
end
return writeFile("beamLR/wpspdHelper",toRet:sub(1,-2))
end

-- 1.12 added system for better day change detection 
-- should work with most reasonable time scale vals
local dayChangeReady = {}
local dayChangeDone = {}

local function getDayChangeDone(day)
return dayChangeDone[day]
end
local function getDayChangeReady(day)
return dayChangeReady[day]
end
local function setDayChangeDone(day)
dayChangeDone[day] = true
end
local function setDayChangeReady(day)
dayChangeReady[day] = true
end
local function initDayChangeSystem()
dayChangeReady = {}
dayChangeDone = {}
end


local function getRouteDistance(from, to)
local route = require('/lua/ge/extensions/gameplay/route/route')()
local fromPos = {}
local toPos = scenetree.findObject(to):getPosition()
if type(from) == "string" then
fromPos = scenetree.findObject(from):getPosition()
else
fromPos = from
end
if type(to) == "string" then
toPos = scenetree.findObject(to):getPosition()
else
toPos = to
end
route:setRouteParams(0,nil,0,0)
route:setupPath(fromPos,toPos)
local distance = -1 -- if this stays at -1 then path was invalid
if route.path[1] then distance = route.path[1].distToTarget end
return distance
end

local function getRouteDistanceFromPlayer(to)
local veh = be:getPlayerVehicle(0)
local vehicleData = map.objects[veh:getId()]
return getRouteDistance(vehicleData.pos, to)
end

local function getDistanceFromPlayer(to)
local veh = be:getPlayerVehicle(0)
local vehicleData = map.objects[veh:getId()]
local toPos = to
if type(to) == "string" then
toPos = scenetree.findObject(to):getPosition()
end
return vehicleData.pos:distance(toPos)
end

local function getGPSDestinationUIList()
local gtable = loadDataTable("beamLR/mapdata/" .. getLevelName() .. "/gps")
local toRet = {}
toRet["names"] = {}
toRet["keys"] = {}
local tmap = {}
local names = {}
local csplit = {}
local cname = ""
local i = 1
for k,v in pairs(gtable) do
if k ~= "PlayerGarage" then
csplit = ssplit(v, ",")
cname = csplit[3]
if tmap[cname] then 
cname = cname .. "+" .. i
i = i+1
end
tmap[cname] = k
table.insert(names, cname)
end
end
table.sort(names)
toRet["names"][1] = "Player Garage"
toRet["keys"][1] = "PlayerGarage"
for k,v in ipairs(names) do
toRet["names"][k+1] = ssplit(v, "+")[1]
toRet["keys"][k+1] = tmap[v]
end
return toRet
end

local function gpsGetUnit()
local units = getSettingValue("uiUnits")
local toRet = ""
if units == "imperial" then
toRet ="mi"
else
toRet ="km"
end
return toRet
end

local function setGPSDestination(dest)--nil dest will turn off gps
if dest then
local gtable = loadDataTable("beamLR/mapdata/" .. getLevelName() .. "/gps")
local selected = gtable[dest]
local csplit = ssplit(selected, ",")
local targetwp = csplit[2]
blrvarSet("gpswaypoint", targetwp) -- used by flowgraph to set project var for gmwp system
extensions.customGuiStream.sendGPSCurrentDestination(csplit[3])
extensions.customGuiStream.sendGPSDistanceUnit(gpsGetUnit()) -- sends correct unit (km/mi)
extensions.blrglobals.blrFlagSet("gpsActive", true) -- flowgraph detects this flag to turn on gmwp system
else
extensions.blrglobals.blrFlagSet("gpsActive", false)
extensions.blrglobals.blrFlagSet("gmstate", false)
end
end

local function getGPSDistance()
local dest = blrvarGet("gpswaypoint")
local units = extensions.blrutils.getSettingValue("uiUnits")
-- not using GPS route distance, groundmarkers distance is more accurate & stable
local dist = 0
if core_groundMarkers.routePlanner.path and core_groundMarkers.routePlanner.path[1] then
dist = core_groundMarkers.routePlanner.path[1].distToTarget
end
dist = dist/1000.0
if units == "imperial" then
dist = dist / 1.609344
end
return dist
end

local function gpsFindNearest(dtype)
local gtable = loadDataTable("beamLR/mapdata/" .. getLevelName() .. "/gps")
local ttable = {}
local csplit = {}
local ctype = ""
local cwp = ""
local cdist = 0
local cbestdist = 999999999
local cbestkey = ""
for k,v in pairs(gtable) do
csplit = ssplit(v, ",")
ctype = csplit[1]
cwp = csplit[2]
if ctype == dtype then
--cdist = getRouteDistanceFromPlayer(cwp)
--using vec3 distance from player to wp seems more accurate than route distance to find nearest
cdist = getDistanceFromPlayer(cwp)
if cdist < cbestdist then
cbestdist = cdist
cbestkey = k
end
end
end
setGPSDestination(cbestkey)
end

-- 1.18 fix for gps detection not working due to slot path
locals["gpsCheck"] = function()
local parts = extensions.blrpartmgmt.getSlotIDPartMap()
return (parts["gps"] and parts["gps"][1]) or (parts["gps_alt"] and parts["gps_alt"][1]) or (parts["gps_altb"] and parts["gps_altb"][1])
end

local function gpsToggleStateUpdate()
local playerWalking = extensions.blrpartmgmt.getMainPartName() == "unicycle" -- force off when walking
local forcedOff = extensions.blrglobals.blrFlagGet("gpsForceOff") -- Used in missions, races, shops, etc
local mode = blrvarGet("gpsmode")
if not (forcedOff or playerWalking) then
if mode == 0 then --default mode, checks vehicle to make sure gps is installed
local hasGPS = locals["gpsCheck"]() ~= nil
extensions.customGuiStream.sendGPSToggleState(hasGPS)
if not hasGPS then 
setGPSDestination() -- to remove groundmarkers if part edit done with gps active
extensions.customGuiStream.sendGPSPage(0)
end 
elseif mode == 1 then -- always on mode
extensions.customGuiStream.sendGPSToggleState(true)
elseif mode == 2 then -- always off mode
extensions.customGuiStream.sendGPSToggleState(false)
setGPSDestination()
extensions.customGuiStream.sendGPSPage(0)
else
end
else
extensions.customGuiStream.sendGPSToggleState(false)
setGPSDestination()
extensions.customGuiStream.sendGPSPage(0)
end
end

local function loadCustomIMGUILayout()
if FS:fileExists("settings/beamlr_imgui.ini") then
extensions.ui_imgui.loadIniSettingsFromDisk("settings/beamlr_imgui.ini")
end
end

local iminit = {}
local function IMGUILayoutInit(wid)
if not iminit[wid] then
extensions.blrdelay.setParam("wid", wid)
extensions.blrdelay.queue("iminit", "wid",1)
iminit[wid]=true
end
end

local function IMGUIResetInitStates()
iminit = {}
end

local function advancedDamageStringToTable(str)
local toRet = {}
local stable = ssplit(str, ",")
local csplit = {}
for k,v in pairs(stable) do
csplit = ssplit(v, ":")
toRet[csplit[1]] = tonumber(csplit[2])
end
return toRet
end

local function getGasStationByID(id)
local stations = extensions.freeroam_facilities.getFacilities(extensions.blrutils.getLevelName()).gasStations
local toRet = {}
for k,v in pairs(stations) do
if v.id==id then toRet = v end
end
return toRet
end

local function setGasStationDisplayValue(id, fueltype, value, enabled, ustax)
local station = getGasStationByID(id)
station.prices[fueltype].priceBaseline = value
station.prices[fueltype].priceRandomnessBias = nil
station.prices[fueltype].priceRandomnessGain = nil
station.prices[fueltype].disabled = not enabled
station.prices[fueltype].us_9_10_tax = ustax
if ustax then station.prices[fueltype].priceBaseline = value - 0.01 end --remove 1 cent from actual value for display in US maps
end

local function applyGasStationsDisplays()
extensions.freeroam_facilities_fuelPrice.setDisplayPrices()
end

local function smoothFuelCharge(added)
blrvarSet("smoothFuelAdded", math.floor(added * 100.0) / 100.0)
extensions.blrglobals.blrFlagSet("smoothFuelCharge", true)
extensions.blrglobals.blrFlagSet("smoothFueling", false)
end

-- For now only "gasoline" type and force enabled US tax since only west coast has displays
locals["lastGasUnit"] = ""
local function blrStationDisplays()
local level = getLevelName()
local unit = getSettingValue("uiUnits")
locals["lastGasUnit"] = unit
if not FS:directoryExists("beamLR/mapdata/" .. level) then
print("Missing mapdata for level, skipping gas station display init")
return
end
local triggers = loadDataTable("beamLR/mapdata/" .. level .. "/triggers")
local csplit = {}
local ctrig = {}
local cdata = {}
local cval = {}
for k,v in pairs(triggers) do
csplit = ssplit(v, ",")
if csplit[1] == "station" then
ctrig = loadDataTable("beamLR/mapdata/" .. level .. "/triggerData/" .. csplit[2])
cdata = processGasStationRandoms(ctrig, getDailySeed() + tonumber(ctrig["id"]))
if ctrig["display"] then
cval[1] = tonumber(cdata["cost"])
cval[2] = tonumber(cdata["cost_midgrade"])
cval[3] = tonumber(cdata["cost_premium"])
cval[4] = tonumber(cdata["cost_diesel"])
if unit == "imperial" then 
cval[1] = cval[1] * 3.785
cval[2] = cval[2] * 3.785
cval[3] = cval[3] * 3.785
cval[4] = cval[4] * 3.785
end
setGasStationDisplayValue(ctrig["display"], "gasoline", cval[1], true, true)
setGasStationDisplayValue(ctrig["display"], "gasoline2", cval[2], true, true)
setGasStationDisplayValue(ctrig["display"], "gasoline3", cval[3], true, true)
setGasStationDisplayValue(ctrig["display"], "diesel", cval[4], true, true)
end
end
end
applyGasStationsDisplays()
end

-- Force refresh gas station displays if uiUnit setting changed
-- 1.16 send unit to UI for part odometer display
local function onSettingsChanged()
local nunit = getSettingValue("uiUnits")
if locals["lastGasUnit"] ~= nunit then
blrStationDisplays()
extensions.customGuiStream.sendDataToUI("advinvUnits", nunit)
end
end

-- Moves the trigger up and down to trigger the onEnter event which
-- sometimes doesn't happen after towing
locals["refreshOldPos"] = {}
locals["towingTriggerRefresh"] = function(step, trig)
local obj = scenetree.findObject(trig)
if obj then
if step == 1 then
locals["refreshOldPos"] = obj:getPosition():toTable()
obj:setPosition(vec3(locals["refreshOldPos"][1], locals["refreshOldPos"][2], locals["refreshOldPos"][3] + 10))
elseif step == 2 then
obj:setPosition(vec3(locals["refreshOldPos"][1], locals["refreshOldPos"][2], locals["refreshOldPos"][3]))
end
end
end

-- Util function to check for missing or unreachable waypoints
locals["validateWaypoints"] = function(club, league, ignore)
local dtable = {}
local waypoints = {}
local cwp = ""
local pwp = ""
local nwp = ""
local basepath = "/beamLR/races/" .. club .. "/" .. league .. "/"
if not FS:directoryExists(basepath) then
print("Waypoint validation error, invalid base path. Check club and league.")
return
end
local rfiles = FS:findFiles(basepath, "*", 0)
local toskip = {}
if ignore then
for k,v in pairs(ignore) do
toskip[v] = true
end
end
for k,v in pairs(rfiles) do
if not toskip[v:gsub(basepath, "")] then
dtable = loadDataTable(v)
waypoints = ssplit(dtable["waypoints"], ",")
for i=1,#waypoints do
cwp = waypoints[i]
if i > 1 then pwp = waypoints[i-1] else pwp = "START" end
if i < #waypoints then nwp = waypoints[i+1] else nwp = "FINISH" end
if not scenetree.findObject(cwp) then -- Found waypoint missing from map entirely (removed by game update)
print("MISSING " .. cwp .. " (BETWEEN " .. pwp .. " & " .. nwp .. ") IN FILE " .. v:gsub(basepath, ""))
elseif pwp ~= "START" then 
if #map.getPath(pwp, cwp) < 1 then -- Found existing waypoint with no path between itself and previous waypoint
print("NO PATH BETWEEN " .. pwp .. " AND " .. cwp .. " IN FILE " .. v:gsub(basepath, ""))
end
end
end
end
end
end

-- Util function to check for missing or unreachable waypoints, this one for track events
locals["validateEventWaypoints"] = function(efile)
local dtable = {}
local waypoints = {}
local cwp = ""
local pwp = ""
local nwp = ""
local epath = "/beamLR/trackEvents/" .. efile


dtable = loadDataTable(epath)
waypoints = ssplit(dtable["waypoints"], ",")
for i=1,#waypoints do
cwp = waypoints[i]
if i > 1 then pwp = waypoints[i-1] else pwp = "START" end
if i < #waypoints then nwp = waypoints[i+1] else nwp = "FINISH" end
if not scenetree.findObject(cwp) then -- Found waypoint missing from map entirely (removed by game update)
print("MISSING " .. cwp .. " (BETWEEN " .. pwp .. " & " .. nwp .. ")")
elseif pwp ~= "START" then 
if #map.getPath(pwp, cwp) < 1 then -- Found existing waypoint with no path between itself and previous waypoint
print("NO PATH BETWEEN " .. pwp .. " AND " .. cwp)
end
end
end


end

locals["validateMatchingEventWaypoints"] = function(keyword)
local files = FS:findFiles("/beamLR/trackEvents/", "*", 1)
local csplit = {}
local cfile = ""
for k,v in pairs(files) do
if string.find(v, keyword) then
csplit = ssplit(v, "/")
cfile = csplit[#csplit]
print("Checking file " .. cfile)
locals["validateEventWaypoints"](cfile)
end
end
end


locals["rewardScaler"] = function(folder, filter, field, lowscale, highscale)
local files = {}
local cdata = {}
local cfield = ""
local csplit = {}
local clow = 0
local chigh = 0
local ccount = 0

if filter then 
files = FS:findFiles(folder, filter .. "*", 0)
else
files = FS:findFiles(folder, "*", 0)
end

for k,v in pairs(files) do
if FS:fileExists(v) then
	cdata = loadDataTable(v)
	cfield = cdata[field]
	if cfield and cfield ~= "" then
		csplit = ssplit(cfield, ",")
		ccount = #csplit
		if ccount > 1 then
			clow = tonumber(csplit[1])
			chigh = tonumber(csplit[2])
		else
			chigh = tonumber(csplit[1])
		end
		clow = clow * lowscale
		chigh = chigh * highscale
		
		if ccount > 1 then
			cdata[field] = clow .. "," .. chigh
		else
			cdata[field] = chigh
		end
		
		saveDataTable(v, cdata)
	end
end

end



end



locals["missingConfigFinder"] = function(folder, perfclassmode, field)
local files = FS:findFiles(folder, "*", 10)
local cdata = {}
local missing = {}

if perfclassmode then
for k,v in pairs(files) do
if FS:fileExists(v) then
cdata = loadDataFile(v)
for _,path in pairs(cdata) do
if not FS:fileExists(path) then
table.insert(missing, path .. " in file " .. v)
end
end
end
end

else
for k,v in pairs(files) do
if FS:fileExists(v) and (not string.find(v, "progress")) and (not string.find(v, "integrity")) and (not string.find(v, "list")) then
cdata = loadDataTable(v)
if not string.find(cdata[field], "class:") then
for sid,spath in pairs(ssplit(cdata[field], ",")) do
if not FS:fileExists(spath) then
table.insert(missing, spath .. " in file " .. v)
end
end
end
end
end
end

return missing
end


locals["checkMissingConfigs"] = function()
for k,v in pairs(extensions.blrutils.missingConfigFinder("beamLR/races", false, "enemyConfig")) do print(v) end
for k,v in pairs(extensions.blrutils.missingConfigFinder("beamLR/performanceClass", true, "enemyConfig")) do print(v) end
for k,v in pairs(extensions.blrutils.missingConfigFinder("beamLR/shop/car", false, "config")) do print(v) end
end

-- added for 0.33 to rebuild simple traffic spawngroups after cars got put under a same simple_traffic model
locals["spawngroupGenerator"] = function(output)
local data = {}
data.data = {}

local configs = FS:findFiles("vehicles/simple_traffic/", "*.pc", 1)
local toadd = ""

for k,v in pairs(configs) do
if not string.find(v, "parked") then
toadd = v
toadd = toadd:gsub("/vehicles/simple_traffic/", "")
toadd = toadd:gsub(".pc", "")
table.insert(data.data, {model="simple_traffic", config=toadd})
end
end

data.type = "custom"
data.name = "BeamLR Traffic"

jsonWriteFile(output, data, true)
end


locals["loadCarShopList"] = function(baselist)
local basepath = "beamLR/shop/car/list_" .. baselist
local toRet = loadDataFile(basepath)

if not toRet then return end

local addons = {}
local clist = {}

-- Detected addon folder for list, adding models
if FS:directoryExists("beamLR/shop/car/addon_" .. baselist) then
addons = FS:findFiles("beamLR/shop/car/addon_" .. baselist, "*", 1)

for _,addfile in pairs(addons) do
clist = loadDataFile(addfile)
for _,carfile in pairs(clist) do
table.insert(toRet, carfile)
end
end
end

return toRet
end

-- To avoid repetitive code & flowgraph when buttons are needed conditionally
locals["imButton"] = function(name, id, width, height, sameline, enabled, ignoreToggle)
local im = ui_imgui

local enable = enabled and (extensions.blrglobals.blrFlagGet("imToggle") or ignoreToggle)

local toRet = {}

if sameline then
im.SameLine()
end

im.Button(name .. "##" .. id, im.ImVec2(width, height))

if not enable then return toRet end

if im.IsItemHovered() then
local down = im.IsMouseClicked(0)
local hold = im.IsMouseDown(0)
local up = im.IsMouseReleased(0)
if (down or hold or up) then
if down then hold = false up = false end
if hold then down = false up = false end
if up then down = false hold = false end
end
toRet["down"] = down
toRet["hold"] = hold
toRet["up"] = up
else
toRet["down"] = false
toRet["hold"] = false
toRet["up"] = false
end

return toRet
end


locals["setPause"] = function(pause)
simTimeAuthority.pause(pause)
end

locals["saveDataTableOptimized"] = function(path, data, gcinterval)

deleteFile(path) -- start by clearing existing file data since we use append mode

local f = io.open(path, "a")
local iteration = 0

if not f then
print("saveDataTableOptimized could not open file at path: " .. path)
return false
end

for k,v in pairs(data) do
iteration = iteration + 1
f:write(k .. "=" .. v .. "\n")
if (iteration % gcinterval) == 0 then
collectgarbage()
end
end


collectgarbage()
f:flush()
f:close()
end

locals["sandboxExecute"] = function(path, params)
local s = readFile(path)
local f = loadstring(s)
return f(params)
end


-- generates a new config specific drag race file by copying existing file for a club & league
locals["generateDragRaceFile"] = function(clublistpath, league, config)
local clist = loadDataFile(clublistpath)
local cfolder = ""
local cfiles = {}
local cid = 0
local cdata = {}

for k,v in pairs(clist) do
cfolder = v .. "/" .. league .. "/"
cfiles = FS:findFiles(cfolder, "*", 1)
cid = #cfiles
cdata = loadDataTable(cfiles[1])
cdata["enemyConfig"] = config
saveDataTable(cfolder .. "race" .. cid, cdata)
end


end

-- forces buffered data to get flushed to log file by printing a ton of characters
locals["logflush"] = function()
print("                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ")
end


locals["raceSelector"] = function(club, league, race)
local pfile = "beamLR/races/" .. club .. "/progress"

if not FS:fileExists(pfile) then
print("Race selector error, invalid path to club progress. Check club and league.")
return
end

local pdata = loadDataTable(pfile)
local csplit = {}
local crace = ""

pdata["current"] = league
pdata[league] = ""

for k,v in pairs(FS:findFiles("beamLR/races/" .. club .. "/" .. league, "*", 1)) do
csplit = ssplit(v, "/")
crace = csplit[#csplit]
if crace ~= race then
pdata[league] = pdata[league] .. crace .. ","
end
end

saveDataTable(pfile, pdata)
end

locals["racePathDebugger"] = function(club, league, race)
local tool = require("editor/aiTests")
local rpath = "beamLR/races/" .. club .. "/" .. league .. "/" .. race
if not FS:fileExists(rpath) then
print("Invalid path to race file!")
return
end

local rdata = loadDataTable(rpath)
local waypoints = ssplit(rdata["waypoints"], ",")

for i,wp in ipairs(waypoints) do
if i == 1 then
tool.setStart(wp)
elseif i == #waypoints then
tool.setEnd(wp)
else
tool.addWaypoint(wp)
end
end


print("Note: must be in 'AI Path/Plan Tests' tab for path to show.")
end

locals["racePathDebuggerClear"] = function()
require("editor/aiTests").clear()
end

-- sets default values used for new releases
locals["loadReleaseValues"] = function()
-- starting with options
local dtable = loadDataTable("beamLR/options")
dtable["autoseed"] = "1"
dtable["advrepwarnack"] = "0"
dtable["traffic"] = "8"
dtable["trucks"] = "1"
dtable["police"] = "1"
dtable["edittreemode"] = "0"
dtable["targetwager"] = "10000"
dtable["sleeptime"] = "8"
dtable["dwtoggle"] = "1"
dtable["atcount"] = "10"
dtable["tsbias"] = "0.8"
dtable["trisk"] = "0.2"
dtable["tsrate"] = "0.1"
dtable["lrestrict"] = "1"
saveDataTable("beamLR/options", dtable)

-- next doing mainData
dtable = loadDataTable("beamLR/mainData")
dtable["time"] = "0.0"
saveDataTable("beamLR/mainData", dtable)

-- next doing car0 file
dtable = loadDataTable("beamLR/garage/car0")
dtable["oil"] = "3.83" -- works for starter legran, if another car is used need to adjust value
dtable["gas"] = "10.0"
saveDataTable("beamLR/garage/car0", dtable)
end


locals["blrlogid"] = 0

-- tail this file with powershell for instant logs during main thread locking loops
-- EX: Get-Content C:\Users\r3eck\AppData\Local\BeamNG.drive\0.36\beamLR\blrlog.txt  -Wait -Tail 1
locals["blrlog"] = function(txt, wid)
if wid then
print("BeamLR Log ID " .. locals["blrlogid"])
end
local toprint = txt
local prefix = "[" .. string.format("%.3f",os.clock()) .. "] "
if type(txt) == "table" then
toprint = dumps(txt)
end

if wid then
prefix = "[" .. locals["blrlogid"] .. "]" .. prefix
locals["blrlogid"] = locals["blrlogid"]+1
end

local f = io.open("beamLR/blrlog.txt", "a")
f:write(prefix .. toprint .. "\n")
f:flush()
f:close()
end



locals["isAppOnLayout"] = function(app, layout)
local layouts = uiapps.getAvailableLayouts()
for _,layoutData in pairs(layouts) do
if layoutData.type == layout then
for _,appData in pairs(layoutData.apps) do
if appData.appName == app then return true end
end
end
end
return false
end

locals["deleteFolder"] = function(path)
if FS:directoryExists(path) then
FS:remove(path)
end
end


M.deleteFolder = locals["deleteFolder"]
M.isAppOnLayout = locals["isAppOnLayout"]
M.blrlog = locals["blrlog"]
M.loadReleaseValues = locals["loadReleaseValues"]
M.getStarterCarSeedList = locals["getStarterCarSeedList"]
M.racePathDebuggerClear = locals["racePathDebuggerClear"]
M.racePathDebugger = locals["racePathDebugger"]
M.validateMatchingEventWaypoints = locals["validateMatchingEventWaypoints"]
M.raceSelector = locals["raceSelector"]
M.logflush = locals["logflush"]
M.generateDragRaceFile = locals["generateDragRaceFile"]
M.sandboxExecute = locals["sandboxExecute"]
M.saveDataTableOptimized = locals["saveDataTableOptimized"]
M.setPause = locals["setPause"]
M.imButton = locals["imButton"]
M.loadCarShopList = locals["loadCarShopList"]
M.validateEventWaypoints = locals["validateEventWaypoints"]
M.spawngroupGenerator = locals["spawngroupGenerator"]
M.setDriftCombo = locals["setDriftCombo"]
M.getDriftCombo = locals["getDriftCombo"]
M.checkMissingConfigs = locals["checkMissingConfigs"]
M.missingConfigFinder = locals["missingConfigFinder"]
M.rewardScaler = locals["rewardScaler"]
M.getDailySeedOffset = locals["getDailySeedOffset"]
M.validateWaypoints = locals["validateWaypoints"]
M.gpsCheck = locals["gpsCheck"]
M.clubCompletionStatus = locals["clubCompletionStatus"]
M.towingTriggerRefresh = locals["towingTriggerRefresh"]
M.saveDataFile = saveDataFile
M.onSettingsChanged = onSettingsChanged
M.blrStationDisplays = blrStationDisplays
M.smoothFuelCharge = smoothFuelCharge
M.setGasStationDisplayValue = setGasStationDisplayValue
M.applyGasStationsDisplays = applyGasStationsDisplays
M.getGasStationByID = getGasStationByID
M.advancedDamageStringToTable = advancedDamageStringToTable
M.IMGUIResetInitStates = IMGUIResetInitStates
M.IMGUILayoutInit = IMGUILayoutInit
M.loadCustomIMGUILayout = loadCustomIMGUILayout
M.slotHelperAutoIndexReset = slotHelperAutoIndexReset
M.getDistanceFromPlayer = getDistanceFromPlayer
M.gpsGetUnit = gpsGetUnit
M.gpsToggleStateUpdate = gpsToggleStateUpdate
M.gpsFindNearest = gpsFindNearest
M.getGPSDistance = getGPSDistance
M.setGPSDestination = setGPSDestination
M.getGPSDestinationUIList = getGPSDestinationUIList
M.getRouteDistanceFromPlayer = getRouteDistanceFromPlayer
M.getRouteDistance = getRouteDistance
M.getInstalledLevels = getInstalledLevels
M.initDayChangeSystem = initDayChangeSystem
M.setDayChangeReady = setDayChangeReady
M.setDayChangeDone = setDayChangeDone
M.getDayChangeReady = getDayChangeReady
M.getDayChangeDone = getDayChangeDone
M.wpspdHelper = wpspdHelper
M.createRandomFactoryPaint = createRandomFactoryPaint
M.racePathHelper = racePathHelper
M.playSFX = playSFX
M.setDeathScreenTextOpacity = setDeathScreenTextOpacity
M.setDeathScreenBackOpacity = setDeathScreenBackOpacity
M.resetGameOptions = resetGameOptions
M.getSavedGameOption = getSavedGameOption
M.setGameOption = setGameOption
M.hoursTimeString = hoursTimeString
M.timeDetector = timeDetector
M.templateLoadCheck = templateLoadCheck
M.lerp = lerp
M.loadEventWithRandoms = loadEventWithRandoms
M.getEventSeed = getEventSeed
M.uiRefreshTemplates = uiRefreshTemplates
M.getCarTemplateFolder = getCarTemplateFolder
M.getOrderedCarTemplateList = getOrderedCarTemplateList
M.towPlayerNoReset = towPlayerNoReset
M.performanceUIData = performanceUIData
M.getLevelUITitle = getLevelUITitle
M.getLevelInfo = getLevelInfo
M.checkVehicleEventRestricted = checkVehicleEventRestricted
M.joinEvent = joinEvent
M.getEventInspectionStatus = getEventInspectionStatus
M.getCurrentEventData = getCurrentEventData
M.fetchVehicleUtilsData = fetchVehicleUtilsData
M.getFetchedVehicleUtilsData = getFetchedVehicleUtilsData
M.getVehicleInfoFile = getVehicleInfoFile
M.eventBrowserGetCarData = eventBrowserGetCarData
M.eventBrowserGetPlayerData = eventBrowserGetPlayerData
M.eventBrowserGetData = eventBrowserGetData
M.eventBrowserGetList = eventBrowserGetList
M.addShopCarToGarage = addShopCarToGarage
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
M.getDriftTotal = getDriftTotal
M.getDriftCurrent = getDriftCurrent
M.getDriftCombined = getDriftCombined
M.setDriftCurrent = setDriftCurrent
M.setDriftTotal = setDriftTotal
M.setDriftCurrent = setDriftCurrent
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



