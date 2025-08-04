-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local jbeamIO = require('jbeam/io')
local vehManager = extensions.core_vehicle_manager
local partInventory = {}
local partPrice = {}
local categoryData = {}
local currentFilter = ""

local jbeamFileMap = {}
local fullSlotNameLibrary = {}
local fullPartNameLibrary = {}



local function copytable(input)
local output = {}
for k,v in pairs(input) do
output[k] = v
end
return output
end

local function getVehicleData(veid, ignoreShopMode)
local toRet = {}
local shopmode = extensions.blrglobals.blrFlagGet("shopmode")
local shopmodeid = extensions.blrutils.blrvarGet("playervehid")
if not veid then
if shopmode and (not ignoreShopMode) then
toRet = vehManager.getVehicleData(shopmodeid)
else
toRet = vehManager.getPlayerVehicleData()
end
else
toRet = vehManager.getVehicleData(veid)
end
return toRet
end




local function ioCtx()
return getVehicleData().ioCtx
end

local function getPartJbeam(partName)
return jbeamIO.getPart(ioCtx(), partName)
end

local function getSlotMap(customIO)
local slotMap = {}
if customIO then
slotMap = jbeamIO.getAvailableSlotNameMap(customIO)
else
local playerVehicle = getVehicleData()
slotMap = jbeamIO.getAvailableSlotNameMap(playerVehicle.ioCtx)
end
return slotMap
end

-- returns table of child slot names for specified part
local function getPartChildSlotNames(part)
local jbeam = getPartJbeam(part)
local slots = {}
local toRet = {}
local fmt2 = false
if jbeam["slots2"] then
slots = jbeam["slots2"]
fmt2=true
elseif jbeam["slots"] then
slots = jbeam["slots"]
fmt2=false
else -- no slots or slots2 table, part has no child slots
return toRet
end
for k,v in pairs(slots) do
if fmt2 then
table.insert(toRet, v.name)
else
table.insert(toRet, v.type)
end
end
return toRet
end


-- updated in 1.18 for 0.36 update to work with slotPartMap which uses slot paths but
-- doesn't include empty child slots so have to add them manually
-- ACTUALLY just edited jbeam/optimization script, this is probably a bug caued by optimization
-- script removing empty parts from slotPartMap, should probably get fixed in a coming update
local function getVehicleParts(veid)
return getVehicleData(veid).vdata.slotPartMap
end

local function getSlotIDFromPath(path)
local csplit = extensions.blrutils.ssplit(path,"/")
return csplit[#csplit-1]
end

-- Changed for 0.36 update, used to be called getActualSlots
-- key = slot path, val = internal slot name
local function getPathKeyedSlots()
local toRet = {}
local parts = getVehicleParts()
for k,v in pairs(parts) do
toRet[k] = getSlotIDFromPath(k)
end
return toRet
end


-- Added in 1.18, KEY = SLOTID, VALUE = TRUE
-- Returns a list of slot IDs present on vehicle, used for part buying menu to show currently 
-- compatible part indicator (the little warning symbol with yellow text)
-- Doesn't need paths because the parts will fit for the same slot IDs, duplicates don't matter, only that
-- the slot ID is present in this table to show in part buying menu that part will immediately fit on vehicle
local function getVehicleSlotIDsList()
local toRet = {}
local slots = getPathKeyedSlots()
for k,v in pairs(slots) do
toRet[v] = true
end
return toRet
end

-- Added in 1.18, KEY = PART, VALUE = TRUE
-- Returns a list of installed parts on vehicle, used for part buying menu to show currently installed part
-- needed because part buying menu doesn't use slot paths, only slot IDs and old "usedParts" list passed to
-- UI now uses slot paths. This instead only sends a list of parts currently used regardless of the slot it's on
local function getVehicleInstalledPartsList()
local toRet = {}
local parts = getVehicleParts()
for k,v in pairs(parts) do
if v ~= "" then
toRet[v] = true
end
end
return toRet 
end


-- Added for 0.36 update (BLR 1.18)
-- key = slot id, val = table of slot paths
local function getIDKeyedSlots()
local toRet = {}
local parts = getVehicleParts()
local csplit = {}
local ckey = ""
for slotPath,part in pairs(parts) do
csplit = extensions.blrutils.ssplit(slotPath, "/")
ckey = csplit[#csplit-1]
if toRet[ckey] == nil then
toRet[ckey] = {}
end
table.insert(toRet[ckey],slotPath)
end
return toRet
end


local function getMainPartName(raw, vehid)
local data = getVehicleData(vehid, raw)
if data then
return jbeamIO.getMainPartName(data.ioCtx)
end
end

local function getAvailablePartList()
local toRet = {}
local playerVehicle = getVehicleData()
local availParts = getSlotMap()
local slots = getVehicleParts()
for k,v in pairs(slots) do		-- Loops over current vehicle slots to show parts available for current build
if k~="main" then				-- Avoid adding "main" part to list
toRet[k] = availParts[k]
end		
end 
return toRet
end

local function getAllAvailableParts(vehSpecific)
local toRet = {}
if vehSpecific then
local ioCtx = {preloadedDirs = {ioCtx()["preloadedDirs"][1]}}
toRet = jbeamIO.getAvailableParts(ioCtx)
else
toRet = jbeamIO.getAvailableParts(ioCtx())
end
return toRet
end


local function getAvailablePartData(k)
local playerVehicle = getVehicleData()
local availParts = jbeamIO.getAvailableParts(playerVehicle.ioCtx)
return availParts[k]
end

local function getGarageUIData()
local toRet = {}
local current = getVehicleParts()	-- Current parts
local slots = getPathKeyedSlots() 		-- Gets actual slots from current car
local avail = getSlotMap()	   		-- Gets all available parts for all available slots of this car

for slotPath,slotID in pairs(slots) do -- Looping over vehicle current slots 

if avail[slotID] ~= nil then		-- Filter slots that have no avail parts, apparently this happens.

if toRet[slotPath] == nil then			-- Init return table slots
toRet[slotPath] = {}
end

for _,part in pairs(avail[slotID]) do -- Looping over all available parts for the current slot
if partInventory[part] ~= nil then 	-- Finding the part in player inventory
if partInventory[part] >= 1 then
table.insert(toRet[slotPath], part) -- Populate return table
end
end

end 

end

end

for slot,part in pairs(current) do	-- Fix for search function not finding current used parts
if part ~= "" and slots[slot] ~= "main" then
table.insert(toRet[slot], part)
end
end

return toRet
end

local function getPartInventory()
return partInventory
end

local function addToInventory(p)
if partInventory[p] == nil then
partInventory[p] = 1
else
partInventory[p] = partInventory[p] + 1
end
end

local function removeFromInventory(p)
if partInventory[p] ~= nil and partInventory[p] > 0 then
partInventory[p] = partInventory[p] - 1
end
end

local function saveConfig(file, vehid)
-- 1.16 need to save then restore ilinks & odometer since vanilla config saving removes them
local current = jsonReadFile(file)
local ilinks = current["ilinks"]
local odometer = current["odometer"]
extensions.core_vehicle_partmgmt.save(file) 
local ctable = jsonReadFile(file)
ctable["paints"] = nil
ctable["mainPartName"] = getMainPartName(false, vehid)
ctable["model"] = getMainPartName(false, vehid)
-- need this for advanced vehicle building, adds missing slots relying on defaults
-- with actual part used so bought cars aren't missing parts after being avbready
ctable["parts"] = getVehicleParts(vehid)
ctable["ilinks"] = ilinks -- restore ilinks
ctable["odometer"] = odometer -- restore odometer

-- 1.16 dynamic mirrors
local mdata = extensions.core_vehicle_mirror.getAnglesOffset()
ctable["mirrors"] = {}
for k,v in pairs(mdata) do
ctable["mirrors"][k] = {}
ctable["mirrors"][k]["x"] = v["angleOffset"]["x"]
ctable["mirrors"][k]["z"] = v["angleOffset"]["z"]
end

jsonWriteFile(file,ctable,true)
end


local function loadConfig(file)
extensions.core_vehicle_partmgmt.loadLocal(file)

-- 1.16 dynamic mirrors
local mdata = extensions.core_vehicle_mirror.getAnglesOffset()
local cdata = jsonReadFile(file)
if cdata["mirrors"] then
for k,v in pairs(cdata["mirrors"]) do
if mdata[k] then
extensions.core_vehicle_mirror.setAngleOffset(k, v["x"], v["z"], nil, false)
end
end
extensions.customGuiStream.sendMirrorsData()
end

end


local function loadTableFromFile(file, numVals)
local filedata = readFile(file)
local dtable = {}
for k,v in string.gmatch(filedata, "([^%c]+)=([^%c]+)") do
if numVals then 
dtable[k] = tonumber(v)
else
dtable[k] = v
end
end
return dtable
end

local function loadInventoryFromFile(file)
partInventory = loadTableFromFile(file, true)
end

local function saveInventoryToFile(file)
local filedata = ""
for k,v in pairs(partInventory) do
filedata = filedata .. k .. "=" .. v .. "\n"
end
writeFile(file, filedata)
end

local function loadPartPriceLibrary(file) -- Loading prices from file allows future features like
partPrice = loadTableFromFile(file, true) -- different prices depending on shop, map, etc...
end										  -- Could load all lib files on flowgraph start, send needed one to UI

local function getPartPriceLibrary()
return partPrice
end

-- 1.17.5 slot favorites
local favoritesData = {}
local function loadFavorites()
favoritesData = loadTableFromFile("beamLR/slotFavorites", false)
print("loaded favorites dump")
dump(favoritesData)
end


local function loadCategories(file)
categoryData = loadTableFromFile(file, false)
loadFavorites() -- 1.17.5 slot favorites
currentFilter = "all"
end

local function getCategories()
return caregoryData
end


local function categoryFilter(source, keyMode)
local toRet = {}
local part = ""
local cm = false
-- 1.17.5 slot favorites
if currentFilter=="favorites" then
for k,v in pairs(source) do
if keyMode then part = k else part = v end
if favoritesData[part] and favoritesData[part] == "true" then
if not toRet[k] then toRet[k] = {} end
for i,p in pairs(v) do
toRet[k][p] = true
end
end
end

else

for k,v in pairs(source) do
cm = false													-- Reset current match flag
if keyMode then part = k else part = v end
for f,t in pairs(categoryData) do							-- To have universal filters, loop over universal part names to see if they match												-- with the current part in the list. Only add if matching the selected filter.
if currentFilter=="all" or (string.match(part, f) and t == currentFilter) then	-- Matching filter detected, adding to return table
if not toRet[k] then toRet[k] = {} end
for i,p in pairs(v) do
toRet[k][p] = true
end
cm = true
end
if cm then break end									-- Stop looping over filters once match has been found
end
end

end



return toRet
end




local function setFilter(filter)
currentFilter = filter
end

local function getFilter()
return currentFilter
end

local function tableCopy(t) -- Wont be actual copy if values are tables
local t2 = {}
for k,v in pairs(t) do
t2[k] = v
end
return t2
end


local trackModeTuningAvoid = {"$revLimiterRPM", "$n2o_power", "$n2o_rpm", "$wastegateStart"}

local function strMatchTable(toMatch, toSearch)
local toRet = false
for k,v in pairs(toSearch) do
if toMatch:match(v) then 
toRet = true
break
end
end
return toRet
end

local function getTuningUIData(trackMode)
local dtable = getVehicleData().vdata.variables
local toRet = {}
local cname = ""
local ckey = ""
for k,v in pairs(dtable) do
if (not k:match("$fuel") and not trackMode) or (not strMatchTable(k,trackModeTuningAvoid) and trackMode) and v~= nil then			
-- Don't show slider to tune fuel since it's overriden by saved fuel value -- 1.10 TRACK EVENTS can show fuel slider
ckey = v["name"]
ckey = string.sub(ckey, 2, #ckey)
ckey = "ui_" .. ckey
toRet[ckey] = tableCopy(v) 					-- Using name with removed dollar sign as key so that UI doesn't fuck up
toRet[ckey]["uiname"] = ckey				-- Give that formatted name to UI so it can use it as key to lookup vals

if not string.match(v["name"], "_FR") and v["subCategory"] ~= nil then -- Append subcategory for tuning items that have it
cname = v["title"] .. " " ..  v["subCategory"]
toRet[ckey]["title"] = cname
end

end
end
return toRet
end


local function getTuningUIValues()
local dtable = getVehicleData().vdata.variables
local toRet = {}
local ckey = ""
local cval = 0
local relVal = 0
local disRange = 0
local disVal = 0

for k,v in pairs(dtable) do
ckey = v["name"]
ckey = string.sub(ckey, 2, #ckey)
ckey = "ui_" .. ckey

cval = v["val"]
relVal = (cval - v["min"]) / (v["max"] - v["min"])
disRange = v["maxDis"] - v["minDis"]
disVal = (relVal * disRange) + v["minDis"] 


toRet[ckey] = disVal
end
return toRet
end


local function tuningTableFromUIData(uidata, defaults)
local dtable = getVehicleData().vdata.variables
local toRet = {}
local ckey = ""

local cval = 0
local relDisVal = 0
local valRange = 0
local tval = 0

for k,v in pairs(dtable) do
toRet[k] = {}

if defaults then					-- If default mode is on, load default values
toRet[k] = v["default"]
else
ckey = v["name"]					-- Create the CKEY val to index the uidata table with and fetch vals
ckey = string.sub(ckey, 2, #ckey)
ckey = "ui_" .. ckey

if uidata[ckey] ~= nil then
cval = uidata[ckey]
relDisVal = (cval - v["minDis"]) / (v["maxDis"] - v["minDis"])
valRange = v["max"] - v["min"]
tval = (relDisVal * valRange) + v["min"]
toRet[k] = tval
else
toRet[k] = v["val"]
end

end
end

return toRet
end

local function applyTuningData(dtable)
extensions.core_vehicle_partmgmt.setConfigVars(dtable,true)
end

local function resetTuningData()
local dtable = tuningTableFromUIData(nil, true)
applyTuningData(dtable)
end

local function getVehiclePaintData()
local toRet = {}
local paintA = getVehicleColor()
local paintB = getVehicleColorPalette(0)
local paintC = getVehicleColorPalette(1)
toRet["paintA"] = paintA
toRet["paintB"] = paintB
toRet["paintC"] = paintC
return toRet
end


local function getPartPreviewImageTable()
local toRet = {}
local model = getMainPartName()

--detect format
local fmt = "png"
if FS:fileExists("ui/modules/apps/beamlrui/partimg/alder_hubcap_01a_F.jpg") then
fmt = "jpg"
end

local images = FS:findFiles("ui/modules/apps/beamlrui/partimg/", "*." .. fmt, 0)
local cpart = ""
for k,v in pairs(images) do
cpart = string.gsub(v, "/ui/modules/apps/beamlrui/partimg/", "")
cpart = cpart:gsub("." .. fmt, "")
toRet[cpart] = v
end
if FS:directoryExists("ui/modules/apps/beamlrui/partimg_override/" .. model) then
local overrides = FS:findFiles("ui/modules/apps/beamlrui/partimg_override/" .. model, "*." .. fmt, 0)
for k,v in pairs(overrides) do
cpart = string.gsub(v, "/ui/modules/apps/beamlrui/partimg_override/" .. model .. "/", "")
cpart = cpart:gsub("." .. fmt, "")
toRet[cpart] = v
end
end
return toRet
end

local function getPartPrice(part)				-- UPDATED TO WORK WITH OFFICIAL PART PRICES
if partPrice[part] == nil then
return getPartJbeam(part)["information"]["value"]
else
return partPrice[part]
end
end

local function getPartName(part)
return getPartJbeam(part)["information"]["name"]
end


local function getFullSlotMap()
local allParts = getAllAvailableParts(true)
local toRet = {}
local cpart = {}
local ctype = ""
for k,v in pairs(allParts) do
cpart = getPartJbeam(k)
ctype = cpart["slotType"]

-- 0.32.2 fix for table format in slotType (found in BX series bx_bashbar_R.jbeam)
-- parts with multiple compatible slots, add to slot map for each one
if type(ctype) == "table" then
for _,t in pairs(ctype) do
if not string.match(t, "simple_traffic") then
if t ~= "main" then
if not string.match(k, "simple_traffic") then
if toRet[t] == nil then toRet[t] = {} end
table.insert(toRet[t], k)
end
end
end
end
else
if not string.match(ctype, "simple_traffic") then
if ctype ~= "main" then
if not string.match(k, "simple_traffic") then
if toRet[ctype] ~= nil then
table.insert(toRet[ctype], k)
else
toRet[ctype] = {k}
end
end
end
end
end

end
return toRet
end


-- 1.18 fix for some universal parts no longer showing up in shops, like GPS
local function getMergedSlotMaps() -- Should give player access to all vehicle parts except wheels which are too numerous to give good UX
local slotMap = getAvailablePartList()
local fullMap = getFullSlotMap()
local allParts = getAllAvailableParts() -- will contain non veh specific parts
local vehSlots = getVehicleSlotIDsList() 
local cjbeam = {}
local ctype = ""
local pairings = {}

local toRet = {}

for k,v in pairs(slotMap) do
if not string.match(k, "simple_traffic") then -- Remove simple traffic from this part list
toRet[k] = v
for _,p in pairs(v) do				
pairings[k .. ">" .. p] = true -- to avoid adding same part twice to same slots
end
end
end							

for k,v in pairs(fullMap) do
toRet[k] = v
for _,p in pairs(v) do				
pairings[k .. ">" .. p] = true -- to avoid adding same part twice to same slots
end
end

-- this is the part added in 1.18, take all parts including common parts and add them to slot map
-- if the slot they fit in exists on the vehicle
for part,pdata in pairs(allParts) do
cjbeam = getPartJbeam(part)
ctype = cjbeam["slotType"]
if type(ctype) == "table" then
for k,v in pairs(cjbeam["slotType"]) do
if vehSlots[v] then
if not toRet[v] then toRet[v]={} end
if not pairings[v .. ">" .. part] then
table.insert(toRet[v], part) 
pairings[v .. ">" .. part] = true -- to avoid adding same part twice to same slots
end
end
end
else
if vehSlots[ctype] then
if not toRet[ctype] then toRet[ctype]={} end
if not pairings[ctype .. ">" .. part] then
table.insert(toRet[ctype], part)
pairings[ctype .. ">" .. part] = true -- to avoid adding same part twice to same slots
end
end
end
end

return toRet
end

local function getFullPartPrices() -- This is the new function to send part prices to UI
local avail = getMergedSlotMaps()
local customprices = partPrice
local toRet = {}

-- Loading official prices
for k,v in pairs(avail) do
for _,part in pairs(v) do
toRet[part] = getPartPrice(part)
end
end

-- Merging custom prices
for k,v in pairs(customprices) do
toRet[k] = v
end

return toRet
end

local function getPartNameLibrary()
-- 1.17.5 simplified, using the jbeam cache full part name library
-- instead of generating it on the fly
return fullPartNameLibrary
end

local function getSlotNameLibrary()
-- 1.17.5 simplified, using the jbeam cache full slot name library
-- instead of generating it on the fly, should also include some
-- slots that were missing using previous version
return fullSlotNameLibrary
end

local function searchFilter(source, keyMode, deepSearch)	-- Directly matches filter with part list for simple search function
local toRet = {}
local part = ""
local cname = ""
local snameLib = getSlotNameLibrary()
local pnameLib = getPartNameLibrary()

for k,v in pairs(source) do
if keyMode then part = k else part = v end
cname = snameLib[part] or ""
if string.match(part:upper(), currentFilter:upper()) or string.match(cname:upper(),currentFilter:upper()) then -- Updated to match proper slot name not just internal slot name
for i,p in pairs(v) do
if not toRet[k] then toRet[k] = {} end
toRet[k][p]=true
end
elseif deepSearch then
for i,p in pairs(v) do
cname = pnameLib[p]
if string.match(p:upper(), currentFilter:upper()) or string.match(cname:upper(),currentFilter:upper()) then
if not toRet[k] then toRet[k] = {} end
toRet[k][p]=true
end
end
end
end



return toRet
end


local function getCustomIOCTX(model)  -- Returns IOCTX based on model to use for car that hasn't spawned
return {preloadedDirs = {"/vehicles/" .. model .. "/", "/vehicles/common/"}}
end

-- Returns slot map containing data only for specific slots
-- 1.15.3 added param: avoid, list of terms to avoid when looking for parts 
-- (ex: cargo boxes cause issues with rollcage, avoid when randomizing shop parts)
local function getFilteredSlotMap(fullmap, filters, avoid) 
local toRet = {}
local skip = false
for k,v in pairs(filters) do
	if avoid then
		toRet[v] = {}
		if fullmap[v] then
		for _,p in pairs(fullmap[v]) do
			skip = false
				for _,a in pairs(avoid) do
					if string.match(p, a) then skip=true break end
				end
			if not skip then table.insert(toRet[v], p) end
		end
		else
		-- Issue fixed for 1.15.4, bx has "bx_underglow" in actualSlotDebug output but
		-- slot doesn't actually exist (missing in part editor and slotMap) this should
		-- prevent issue without having to remove item from random slots which means
		-- if devs add underglow slot to bx it should be allowed to spawn on used cars
		print("getFilteredSlotMap missing item (" .. v .. ") from filters. Check slotMap for missing random slot.")
		end
	else
		toRet[v] = fullmap[v]
	end
end
return toRet
end


local function generateConfigVariant(baseFile, fmap, seed)
math.randomseed(seed)
local toRet = {}
local pathToIdMap = {}
local csplit = {}
local cid = ""
local baseConfig = jsonReadFile(baseFile)
local originalParts = jsonReadFile(baseFile)["parts"] or jsonReadFile(baseFile)

if not baseConfig["parts"] then -- Detected old config format, build format 2 config
toRet["format"] = 2
toRet["parts"] = baseConfig
toRet["vars"] = {}
else
toRet = baseConfig	-- format 2 config, can use base config table
end

-- 1.18 fix, handle configs that have paths as slots instead of IDs
-- happens in vanilla if two slots had the same ID, it will turn them into paths
for k,v in pairs(toRet["parts"]) do
csplit = extensions.blrutils.ssplit(k, "/")
if #csplit > 1 then
cid = csplit[#csplit-1]
else
cid = csplit[1]
end
pathToIdMap[k] = cid
end

local cpick = 0		
for k,v in pairs(originalParts) do
cid = pathToIdMap[k]
if fmap[cid] then
cpick = math.random(0,#fmap[cid])	-- If random picks 0 the slot will be empty to allow removed part
if cpick == 0 then 
toRet["parts"][k] = ""
else
toRet["parts"][k] = fmap[cid][cpick]
end
end
end
return toRet
end



local function getTuningFuelLoad()
local toRet = 0
local tunedata = getTuningUIData(true)
for k,v in pairs(tunedata) do
if v["name"]:match("$fuel") then
toRet = toRet + v["val"]
end
end
return toRet
end

local function getSortedTuningCategories(trackMode)
local tdata = getTuningUIData(trackMode)
local toRet = {}
local added = {}
local ccat = ""
for k,v in pairs(tdata) do
ccat = v['category']
if not added[ccat] then
table.insert(toRet, ccat)
added[ccat] = true
end
end
table.sort(toRet)
return toRet
end


local function getSortedTuningFields(trackMode)
local tdata = getTuningUIData(trackMode)
local cats = getSortedTuningCategories(trackMode)
local sortedFields = {}
local fieldMap = {}
local toRet = {}
local ccat = ""
local cfield = ""

for k,v in pairs(tdata) do
fieldMap[v["title"]] = k
table.insert(sortedFields, v["title"])
end
table.sort(sortedFields)

for k,v in ipairs(sortedFields) do
cfield = fieldMap[v]
ccat = tdata[cfield]["category"]
if not toRet[ccat] then toRet[ccat] = {} end
table.insert(toRet[ccat], cfield)
end

return toRet
end

local function getSortedShopSlots()
local sdata = getMergedSlotMaps()
local snames = getSlotNameLibrary()

local sortedSlots = {} -- KEY=POSITION,VAL=SLOT
local smap = {}
local toRet = {}
local cname = ""

for k,v in pairs(sdata) do
if snames[k] then
cname = snames[k] .. " " .. k
else -- 1.10.1 fix for missing paint_design part, default to using internal slot name in case no name is found
cname = k
end
smap[cname] = k -- Adding internal slot name to proper name to avoid duplicates in mapping
table.insert(sortedSlots, cname) -- Sort by name
end
table.sort(sortedSlots)

for k,v in ipairs(sortedSlots) do
table.insert(toRet, smap[v])
end

return toRet
end

local function getSortedShopParts()
local sdata = getMergedSlotMaps()
local pnames = getPartNameLibrary()

local toRet = {} -- KEY=SLOT,VAL=TABLE:KEY=POSITION,VAL=PART
local csort = {} 
local cmap = {}
local cname = ""

for k,v in pairs(sdata) do
toRet[k] = {}
cmap = {}
csort = {}
for _,p in pairs(sdata[k]) do
cname = pnames[p] or p -- 1.10.1 fix
cmap[cname] = p
table.insert(csort, cname)
end
table.sort(csort)
for _,p in ipairs(csort) do
table.insert(toRet[k], cmap[p])
end
end

return toRet
end

-- fixed in 1.17 to handle slots with the same proper name
local function getSortedGarageSlots()
local sdata = getGarageUIData()
local snames = getSlotNameLibrary()

local sortedSlots = {} -- KEY=POSITION,VAL=SLOT NAME
local smap = {}
local toRet = {} -- KEY=POSITION,VAL=SLOT
local cname = ""

for k,v in pairs(sdata) do
cname = snames[k] or k -- 1.10.1 fix

if not smap[cname] then 
smap[cname] = {} -- 1.17 fix for slots using exact same name
table.insert(sortedSlots, cname)
end

table.insert(smap[cname], k)
end
table.sort(sortedSlots)

local index = 1

for k,v in ipairs(sortedSlots) do
for _,n in pairs(smap[v]) do
toRet[index] = n
index = index + 1
end
end

return toRet
end

local function getSortedGarageParts()
local sdata = getGarageUIData()
local pnames = getPartNameLibrary()

local toRet = {} -- KEY=SLOT,VAL=TABLE:KEY=POSITION,VAL=PART
local csort = {} 
local cmap = {}
local cname = ""

for k,v in pairs(sdata) do
toRet[k] = {}
cmap = {}
csort = {}
for _,p in pairs(sdata[k]) do
cname = pnames[p] or p -- 1.10.1 fix
cmap[cname] = p
table.insert(csort, cname)
end
table.sort(csort)
for _,p in ipairs(csort) do
table.insert(toRet[k], cmap[p])
end
end

return toRet
end

-- Removes vehicle model name from slots for easier finding of universal parts
local function getPartsCommonSlots()
local model = getMainPartName()
local parts = getVehicleParts()
local toRet = {}
local ckey = ""

for k,v in pairs(parts) do
ckey = string.gsub(k, model .. "_", "")
toRet[ckey] = v
end

return toRet
end

local configDataCache = {}
local configPathCache = {}
local ilinksCache = {}

-- parse ilinks strings and cache parsed table to optimize repair cost calc flowgraph
local parsedInventoryLinksCache = {}

local function parseInventoryLinks()
parsedInventoryLinksCache = {}
local ilinks = configDataCache["ilinks"]

if not ilinks then return end -- no ilinks detected, probably a new vehicle

local csplit = {}
for k,v in pairs(ilinks) do
csplit = extensions.blrutils.ssplit(v, ",")
parsedInventoryLinksCache[k] = {tonumber(csplit[1]), tonumber(csplit[2])}
end

end

local function getScaledPartPrice(value, odometer)
local toRet = 1.0

if odometer >= 30000000 then
toRet = 0.9 - (0.8 * (math.min(1.0, odometer / 250000000)))
end

return toRet * value
end


local function getPartPricesCommonSlots()
local model = getMainPartName()
local parts = getVehicleParts()
local toRet = {}
local ckey = ""
local codo = 0

for k,v in pairs(parts) do
ckey = string.gsub(k, model .. "_", "")
if v and v ~= "" then
if not parsedInventoryLinksCache[v] then
codo = 0
else
codo = extensions.blrPartInventory.getPart(parsedInventoryLinksCache[v][1])[2]
end
toRet[ckey] = getScaledPartPrice(getPartPrice(v) or getPartPrice("default"), codo)
else
toRet[ckey] = 0
end
end

return toRet
end

local generatedDamageCostTable = {}

local function generateDamageCostTable()
local fdata = extensions.blrutils.loadDataTable("beamLR/dmgPrices") -- KEY: damage element, VAL: cost OR comma sep list of common slots
local cprices = getPartPricesCommonSlots() -- KEY: common slot, VAL: cost
generatedDamageCostTable = {} -- KEY: damage element, VAL: cost

local csplit = ""
local ccost = 0

for k,v in pairs(fdata) do

if tonumber(v) then -- If dmgPrices file has number value, directly use it
generatedDamageCostTable[k] = tonumber(v)
else -- Otherwise its comma separated common slot names
csplit = extensions.blrutils.ssplit(v, ",")
ccost = 0

for _,toMatch in pairs(csplit) do -- Looping over common slots linked to damage element
for slot,value in pairs(cprices) do -- Looping over common slot keyed part prices table to find match
if string.find(slot, toMatch) then
ccost = ccost + value
end
end
end 

generatedDamageCostTable[k] = ccost

end -- if tonumber(v) then

end -- for k,v in pairs(fdata) do

end

local function getGeneratedDamageCost()
return generatedDamageCostTable
end

local function getChildSlots(parent, veid)
local activeParts = {} -- Contains child links but has to be indexed using part, not slot
local chosenParts = {} -- Contains part linked to slots
local vehicleData = getVehicleData(veid)
local lookupkey = ""
local toRet = {}

activeParts = vehicleData.vdata.activePartsData
chosenParts = vehicleData.vdata.slotPartMap
lookupkey = chosenParts[parent]

if activeParts[lookupkey] then
toRet = activeParts[lookupkey].slots
end

return toRet
end


local csl_activeParts = {}
local csl_chosenParts = {}
local csl_vehicleData = {}
local csl_result = {}
local csl_defaults = {} -- for non avb part edits to add removed child slots to inv except defaults


local function childSlotLookupStep(slot)
local csl_ctype = ""
local csl_lookupkey = csl_chosenParts[slot]
if csl_activeParts[csl_lookupkey] then
csl_result[slot] = slot .. csl_chosenParts[slot]
if csl_activeParts[csl_lookupkey]["slots2"] then
for k,v in pairs(csl_activeParts[csl_lookupkey]["slots2"]) do
csl_ctype= slot .. v["name"] .. "/"
csl_defaults[csl_ctype]=v["default"]
childSlotLookupStep(csl_ctype)
end
elseif csl_activeParts[csl_lookupkey].slots then
for k,v in pairs(csl_activeParts[csl_lookupkey].slots) do
csl_ctype= slot .. v["type"] .. "/"
csl_defaults[csl_ctype]=v["default"]
childSlotLookupStep(csl_ctype)
end
end
else
csl_result[slot] = ""
end
end


local function getAllChildSlots(parent, veid)
-- Reset tables for new lookup
csl_activeParts = {}
csl_chosenParts = {}
csl_vehicleData = {}
csl_result = {}
csl_defaults = {}

-- Fill tables with reusable data
if not veid then 
csl_vehicleData = getVehicleData()
else
csl_vehicleData = vehManager.getVehicleData(veid)
end
csl_activeParts = csl_vehicleData.vdata.activePartsData
csl_chosenParts = csl_vehicleData.vdata.slotPartMap

childSlotLookupStep(parent)

csl_result[parent] = nil

return csl_result
end

local function getCSLDefaults()
return csl_defaults
end


-- Used to scale repair costs on VLUA side to avoid having to parse
-- advanced repair string on gelua every frame to update repair cost
local function sendInventoryDataToVLUA()
local vehid = extensions.blrutils.blrvarGet("playervehid") -- actual veh id, avoids unicycle
local veh = scenetree.findObjectById(vehid)
veh:queueLuaCommand("extensions.blrVehicleUtils.resetInventoryData()")

local pid = 0
local inv_type = "" -- also used as link_key
local inv_odo = 0
local inv_int = 0
local inv_use = 0
local link_odo = 0

local cinvdata = {}

-- (pid, inv_type, inv_odo, inv_int, inv_use, link_odo)
for k,v in pairs(parsedInventoryLinksCache) do
inv_type = k
pid = v[1]
link_odo = v[2]
cinvdata = extensions.blrPartInventory.getPart(pid)
inv_odo = cinvdata[2]
inv_int = cinvdata[3]
inv_use = cinvdata[4]
veh:queueLuaCommand(string.format("extensions.blrVehicleUtils.receiveInventoryData(%d, %q, %f, %f, %d, %f)", pid, inv_type, inv_odo, inv_int, inv_use, link_odo))
end

end


local function loadConfigFileData(gid)
configPathCache = "beamLR/garage/config/car" .. gid
configDataCache = jsonReadFile(configPathCache)
-- 1.17.5 odo scaled part repair cost
parseInventoryLinks() -- parse updated inventory links
sendInventoryDataToVLUA() -- send updated data to vlua
generateDamageCostTable() -- regenerate damage costs
-- 1.17.5 ^
return configDataCache
end

local delayedSlotSet = {}
local function setSlotDelayed(slot, part, partID)
local currentParts = getVehicleParts()

print("SET SLOT DELAYED CALLED WITH PARAMS: " .. (slot or "null") .. "," .. (part or "null") .. "," .. (partID or 0))

-- 1.16 additions for part specific odometer
loadConfigFileData(extensions.blrutils.blrvarGet("playerCurrentCarGarageID"))
local vehicleCurrentOdometer = extensions.blrglobals.gmGetVal("codo")
local csplit = {}
local removedID = -1
local removedILODO = -1 -- ilinks odometer (odometer of vehicle when part was added)
local removedINVODO = -1 -- inventory odometer (actual part odometer value)

local removedPart = nil
local addedPart = nil
local removedPartPath = ""
local addedPartPath = ""
-- 1.16 ^

if part == "" then					-- part is null, part is being removed
	if currentParts[slot] ~= nil and currentParts[slot] ~= "" then   -- Check if slot has part
		delayedSlotSet[slot] = part
		removedPart = currentParts[slot]
	end
else								-- part isn't null, part is being added to vehicle
	if currentParts[slot] ~= nil and currentParts[slot] ~= "" then   -- Check if there's a part in that slot already
		removedPart = currentParts[slot]
	end
	delayedSlotSet[slot] = part
	addedPart = part
end

-- 1.16 update for part specific odometer
-- for removed part calculate actual odometer, set part used flag to false and remove from ilinks
if removedPart then 
-- First init some values
removedPartPath = slot .. removedPart
csplit = extensions.blrutils.ssplit(ilinksCache[removedPartPath], ",")
removedID = tonumber(csplit[1])
removedILODO = tonumber(csplit[2])
removedINVODO = extensions.blrPartInventory.getPart(removedID)[2]
-- Update inventory part data
extensions.blrPartInventory.setPartOdometer(removedID, removedINVODO + (vehicleCurrentOdometer - removedILODO))
extensions.blrPartInventory.setPartUsed(removedID, false)
-- Remove from ilinks
ilinksCache[removedPartPath] = nil
print("SHOULD HAVE UPDATED PART ID " .. removedID .. " ODOMETER VALUE TO " .. (removedINVODO + (vehicleCurrentOdometer - removedILODO)))
print("SHOULD HAVE REMOVED PART ID " .. removedID .. " FROM ilinks")
end

if addedPart then -- for added part just set part used flag in inventory and add to ilinks
addedPartPath = slot .. addedPart
extensions.blrPartInventory.setPartUsed(partID, true)
ilinksCache[addedPartPath] = partID .. "," .. vehicleCurrentOdometer
print("SHOULD HAVE ADDED PART ID " .. partID .. " TO ILINKS WITH DATA [" .. partID .. "," .. vehicleCurrentOdometer .. "]")
end

-- 1.16



end


-- Added in 0.36 to interface between old config data and 
-- new tree structure part setting function 
local function setPartsConfig(data)
local tree = getVehicleData().config.partsTree
local csplit = {}
local cnode = {}

for path,part in pairs(data) do
cnode = tree
csplit = extensions.blrutils.ssplit(path, "/")
for _,slot in pairs(csplit) do
if slot ~= "" then
cnode = cnode["children"][slot]
end
end
if part == "" then
cnode["partPath"] = nil
else
cnode["partPath"] = path .. part
end
cnode["chosenPartName"] = part
print("Should have set part for slot " .. cnode.id .. " to: " .. part)
end

extensions.core_vehicle_partmgmt.setPartsTreeConfig(tree)
end


-- ilinks passed as parameters in selective repair because that removes and deletes some parts
local function executeDelayedSlotSet(ilinks)
-- 1.16 addition
configDataCache["ilinks"] = ilinks or ilinksCache
jsonWriteFile(configPathCache, configDataCache)
extensions.blrPartInventory.save()
-- 1.16 ^
setPartsConfig(delayedSlotSet)
-- 1.17.5 odo scaled part repair cost
parseInventoryLinks() -- parse updated inventory links
sendInventoryDataToVLUA() -- send updated data to vlua
generateDamageCostTable() -- regenerate damage costs
-- 1.17.5 ^
end

local function setSlotWithChildren(slot, val, pid)
delayedSlotSet = copytable(getVehicleParts()) -- load table with current parts
-- 1.16 addition, load config file ilinks to perform part specific odometer offsets
ilinksCache = loadConfigFileData(extensions.blrutils.blrvarGet("playerCurrentCarGarageID"))["ilinks"]
local setList = getAllChildSlots(slot)
setSlotDelayed(slot,val, pid) -- start with parent slot
for k,v in pairs(setList) do -- then loop over child slots, always set to empty
setSlotDelayed(k,"")
end
executeDelayedSlotSet()
end


-- Non AVB slot setting, updated in 1.14 to fix issue with subparts not added to inventory
-- tried dealing with defaults but there's nothing I can do so default parts can be exploited
local function setSlot(slot, val)
local toSet = getVehicleParts()
local currentParts = getVehicleParts()
local childslots = getAllChildSlots(slot)

if val == "" then					-- Val is null, part is being removed
if currentParts[slot] ~= nil and currentParts[slot] ~= "" then   -- Check if slot has part
addToInventory(currentParts[slot])	-- Add removed part to inventory
toSet[slot] = val
setPartsConfig(toSet)
end

else								-- Val isn't null, part is being added to vehicle

if partInventory[val] ~= nil then	-- Check that inventory contains part being added
if partInventory[val] >= 1 then	
if currentParts[slot] ~= nil and currentParts[slot] ~= "" then   -- Check if there's a part in that slot already
addToInventory(currentParts[slot])	-- If so add removed part to inventory
end
removeFromInventory(val)			-- Remove added part from inventory
toSet[slot] = val
setPartsConfig(toSet)
end
end

end

-- loop over child slots, add parts to inventory (even defaults, nothing I can do about this without AVB)
for k,v in pairs(childslots) do
if (v~= nil and v ~= "") then
addToInventory(v)
end
end

end

-- updated for 1.16 advanced part inventory
local function templateLoadInventorySwap(currentConfig, targetConfig, vehOdo)
local clinks = currentConfig["ilinks"]
local tlinks = targetConfig["ilinks"]
local inventory = extensions.blrPartInventory.getInventory()

local csplit = {}
local cid = 0
local clinkodo = 0 -- ilinks odo value, when part was attached to vehicle

-- for current config need to set part as unused and calculate new odometer 
for k,v in pairs(clinks) do
csplit = extensions.blrutils.ssplit(v, ",")
cid = tonumber(csplit[1])
clinkodo = tonumber(csplit[2])
extensions.blrPartInventory.setPartUsed(cid, false)
extensions.blrPartInventory.setPartOdometer(cid, vehOdo - clinkodo, true) -- using increment mode
end

-- for target config just set part as used
for k,v in pairs(tlinks) do
csplit = extensions.blrutils.ssplit(v, ",")
cid = tonumber(csplit[1])
extensions.blrPartInventory.setPartUsed(cid, true)
end

end




local function getMainPartChild(veid)
local vehicleData = {}
local activeParts = {}
local chosenParts = {}
local toRet = ""
local mainPart = getMainPartName()
local jbeamdata = jsonReadFile(string.format("vehicles/%s/%s.jbeam", mainPart,mainPart))[mainPart]
local newfmt = jbeamdata["slots2"]
local slotdata = {}
if newfmt then
slotdata = jbeamdata["slots2"]
else
slotdata = jbeamdata["slots"]
end


if not veid then 
vehicleData = getVehicleData()
else
vehicleData = vehManager.getVehicleData(veid)
end
activeParts = vehicleData.vdata.activePartsData
chosenParts = vehicleData.vdata.slotPartMap

for k,v in pairs(slotdata) do
if newfmt then
if v[6] and v[6]["coreSlot"] then
toRet = "/" .. v[1] .. "/" .. chosenParts["/" .. v[1] .. "/"]
end
else
if v[4] and v[4]["coreSlot"] then
toRet = "/" .. v[1] .. "/" .. chosenParts["/" .. v[1] .. "/"]
end
end
end

return toRet
end

-- 1.18 updated to work with slot/part paths
local function getParentMap(veid)
local toRet = {}
local vehicleData = {}
local chosenParts = {}

if not veid then 
vehicleData = getVehicleData()
else
vehicleData = vehManager.getVehicleData(veid)
end
chosenParts = vehicleData.vdata.slotPartMap

local cchilds = {}

for k,v in pairs(chosenParts) do
cchilds = getAllChildSlots(k)
for slot,part in pairs(cchilds) do
if part ~= "" then
if not toRet[part] then toRet[part] = {} end
table.insert(toRet[part], k .. v)
end
end
end

return toRet
end

-- 1.18 updated to work with slot/part paths
local function getChildMap()
local toRet = {}
local vehicleData = {}
local chosenParts = {}

if not veid then 
vehicleData = getVehicleData()
else
vehicleData = vehManager.getVehicleData(veid)
end
chosenParts = vehicleData.vdata.slotPartMap

for k,v in pairs(chosenParts) do
if v ~= "" then
toRet[k .. v] = getAllChildSlots(k)
end
end

return toRet
end

-- manual init for non inventory slot set used in advanced repair ui
local function initDelayedSlotTable()
delayedSlotSet = copytable(getVehicleParts())
end

local function setSlotDelayedNoInventory(slot, val)
delayedSlotSet[slot] = val
end

-- updated in 1.18 to use part path system since non unique part ids would cause missing slots
local function getPartKeyedSlots()
local parts = getVehicleParts()
local toRet = {}
local cpath = ""
for k,v in pairs(parts) do
cpath = k .. v
if v and v ~= "" then
toRet[cpath] = k
end
end
return toRet
end


-- KEY=part name, VAL=list of inventory IDs
local function getAdvancedInventoryPartMap()
local toRet = {}
local cpart = ""
local cid = -1
for k,v in pairs(extensions.blrPartInventory.getInventory()) do
cid = k
cpart = v[1]
if not toRet[cpart] then toRet[cpart] = {} end
table.insert(toRet[cpart], cid)
end
return toRet
end

local function getPartKeyedSlotMap()
local slots = getIDKeyedSlots(true)
local map = getSlotMap()
local toRet = {}
local stemp = ""
for slot,avail in pairs(map) do
if slots[slot] ~= nil then
for _,part in pairs(avail) do
-- 1.16.4 fix for missing slots in part edit, handle case where part fits in multiple slots
-- 1.18 update, since slot ids can have multiple paths, might as well only use tables in here
-- also now inserting the slot paths, not the slot ID
if toRet[part] == nil then
toRet[part] = {}
end
for _,slotPath in pairs(slots[slot]) do
table.insert(toRet[part], slotPath)
end
end
end
end
return toRet
end


-- 1.16 for advanced inventory sorting 
local function getValueSortedKeys(t)
    local keymap = {}
    local sorted = {}
    local toRet = {}
    
    for k,v in pairs(t) do
        if not keymap[v] then keymap[v] = {} end
        table.insert(keymap[v], k)
        table.insert(sorted, v)
    end
    
    table.sort(sorted)
    local used = {}
    for _,k in pairs(sorted) do
        for _,v in pairs(keymap[k]) do
            if not used[v] then
                table.insert(toRet, v)
                used[v] = true
            end
        end
    end

    return toRet
end


-- get name then odometer sorted table (sorts by name, then by odometer)
local function getNOST(name, odo)
local sortedNames = getValueSortedKeys(name)
local sortedOdos = getValueSortedKeys(odo)
local nkso = {}
local final = {}

--dump(name)
--dump(odo)

local cname = ""
for _,id in ipairs(sortedOdos) do
    cname = name[id]
    if not nkso[cname] then nkso[cname] = {} end
    table.insert(nkso[cname],id)
end

local usedname = {}

for _,nameid in ipairs(sortedNames) do
    cname = name[nameid]
    if not usedname[cname] then
    for _,odoid in ipairs(nkso[cname]) do
        table.insert(final, odoid)
    end
    usedname[cname] = true
    end
end

return final
end


local function getAdvancedInventoryUIParts()
local toRet = {}
local unsorted = {}
local current = getVehicleParts()	-- Current parts
local slots = getPathKeyedSlots()		-- Gets actual slots from current car
local avail = getSlotMap()	   		-- Gets all available parts for all available slots of this car
local invmap = getAdvancedInventoryPartMap() -- Inventory map KEY=part name, VAL=table of inventory IDs
local pksmap = getPartKeyedSlotMap() -- part keyed slot map KEY=part name, VAL=slot in which it fits
local names = getPartNameLibrary()
local inventory = extensions.blrPartInventory.getInventory()
local sorted = {}

local cslot = ""

-- build initially unsorted table
for slotPath,slotID in pairs(slots) do -- loop over slots
if avail[slotID] then
	for _,part in pairs(avail[slotID]) do -- loop over parts that fit in this slot
		if invmap[part] then -- check if inventory contains current part
			-- 1.16.4 fix for missing slots due to part fitting in multiple slots
			if type(pksmap[part]) == "table" then
			
				for _,cs in pairs(pksmap[part]) do
					if not unsorted[cs] then unsorted[cs] = {} end
					if not sorted[cs] then sorted[cs] = {} end
					for _,id in pairs(invmap[part]) do -- loop over inventory IDs for current part
						table.insert(unsorted[cs], id) -- add them to unsorted table
					end
				end
				
				else
				
				cslot = pksmap[part] -- get current slot from part keyed slot map
				if not unsorted[cslot] then unsorted[cslot] = {} end
				if not sorted[cslot] then sorted[cslot] = {} end
				for _,id in pairs(invmap[part]) do -- loop over inventory IDs for current part
					table.insert(unsorted[cslot], id) -- add them to unsorted table
				end
				
			end
		end
	end
end
end

local cnames = {}
local codos = {}

-- build sorted table
for slot,tab in pairs(unsorted) do
	cnames = {}
	codos = {}
	for _,id in pairs(tab) do
		if inventory[id][4] ~= 1 then -- skip used parts for sorted lists, will be manually added to top of list
		cnames[id] = names[inventory[id][1]] or inventory[id][1]
		codos[id] = inventory[id][2]
		end
	end
	--dump(cnames)
	--dump(codos)
	sorted[slot] = getNOST(cnames, codos)
end

return sorted
end


local function getUsedPartInventoryIDs()
local toRet = {}
local csplit = {}
local cid = -1
local pksmap = getPartKeyedSlotMap()
local main = getMainPartName()
local gid = extensions.blrutils.blrvarGet("playerCurrentCarGarageID")
local ckey = ""
loadConfigFileData(gid)

if configDataCache["ilinks"] then

for k,v in pairs(configDataCache["ilinks"]) do
if k ~= getMainPartName() then
csplit = extensions.blrutils.ssplit(v, ",")

-- 1.18 edit, since ilinks now use paths to define parts but pksmap only uses part name
-- need to grab the actual part name from the full path EX: /legran_body/legran_hood/[ legran_hood ]
ckey = extensions.blrutils.ssplit(k, "/")
ckey = ckey[#ckey]

cid = tonumber(csplit[1])
-- 1.16.4 fix for missing slots caused by parts that can work in many slots
if type(pksmap[ckey]) == "table" then
	for _,s in pairs(pksmap[ckey]) do
		toRet[s] = cid
	end
else
	toRet[pksmap[ckey]] = cid
end

end
end

else

print("getUsedPartInventoryIDs failed due to missing ilinks for vehicle with GID " .. gid)

end

return toRet
end

-- EDITED IN 1.18 TO WORK WITH BEAMNG 0.36 SLOT/PART PATH SYSTEM
local function initVehicleInventoryLinks()
local chosenParts = getVehicleParts()
local gid = extensions.blrutils.blrvarGet("playerCurrentCarGarageID")
local configFile = loadConfigFileData(gid)
local odometer = configFile["odometer"]
local cpath = ""
local mainPartChild = getMainPartChild()
if not configFile["ilinks"] then
print("Detected new vehicle with GID" .. gid .. ", creating inventory links!")
local cid = -1

configFile["ilinks"] = {}
for k,v in pairs(chosenParts) do
--if v and v~="" and k~=mainPartChild then -- before 1.17, changed to allow pickup frame swaps
if v and v~="" then
cpath = k .. v -- build path using slot path and appending part, to disambiguate same parts and slot IDs in use
cid = extensions.blrPartInventory.add(v, odometer, 1.0, true)
configFile["ilinks"][cpath] = cid .. "," .. odometer
end
end

jsonWriteFile(configPathCache, configFile, true)
end

loadConfigFileData(gid) -- reload config file data to get ilinks into cache
end

-- For used parts, value represents vehicle odometer when part was added
-- to calculate actual odometer value of part currently attached to vehicle
local function getInventoryLinkOdometers(forui)
local gid = extensions.blrutils.blrvarGet("playerCurrentCarGarageID")
local ilinks = loadConfigFileData(gid)["ilinks"]

-- to avoid ui init request bugging out for brand new vehicles before ilinks are created
if not ilinks then return nil end

local toRet = {}

local csplit = {}
local cid = -1
local cilinkodo = -1 -- Vehicle odometer when part was added

for k,v in pairs(ilinks) do
csplit = extensions.blrutils.ssplit(v, ",")
cid = tonumber(csplit[1])
cilinkodo = tonumber(csplit[2])
toRet[cid] = cilinkodo
end

-- Force data at index 0 so JS indices are same as lua
if forui and not toRet[0] then toRet[0] = -1 end

return toRet
end

-- source table format: slot={1,2,3,10,20,69,...}
local function advancedInventorySearch(source)
local sname = getSlotNameLibrary()
local pname = getPartNameLibrary()
local invdata = extensions.blrPartInventory.getInventory()
local toRet = {}
local filter = currentFilter

local cslotname = ""
local cpart = ""
local cpartname = ""


for slot, list in pairs(source) do
cslotname = sname[slot] or slot

-- slot itself matches search filter
if (string.match(cslotname:upper(), filter:upper())) or (string.match(slot:upper(), filter:upper())) then
toRet[slot] = true
end

-- didnt find match in slot name, look for matching parts
if not toRet[slot] then
for _,id in ipairs(list) do
cpart = invdata[id][1]
cpartname = pname[cpart] or cpart

if (string.match(cpartname:upper(), filter:upper())) or (string.match(cpart:upper(), filter:upper())) then
toRet[slot] = true
break
end
end

end
end


return toRet
end

-- source table format: slot={1,2,3,10,20,69,...}
local function advancedInventoryCategory(source)
local sname = getSlotNameLibrary()
local invdata = extensions.blrPartInventory.getInventory()
local toRet = {}
local filter = currentFilter

local cname = ""

for slot,_ in pairs(source) do

-- 1.17.5 slot favorites
if filter == "favorites" then
if favoritesData[slot] and favoritesData[slot] == "true" then
toRet[slot] = true
end
else
cname = sname[slot] or slot
for stype,category in pairs(categoryData) do
if (filter == "all") or (category == filter) then
if (string.match(cname:upper(), stype:upper())) or (string.match(slot:upper(), stype:upper())) then
toRet[slot] = true
break
end
end
end
end
end

return toRet
end

-- 1.18 fix for part path
-- 1.16 updated for part specific odometer values
local function getVehiclePartCost(odoscale)
local ilinks = jsonReadFile(configPathCache)["ilinks"]
local inventory = extensions.blrPartInventory.getInventory()
local codo = extensions.blrglobals.gmGetVal("codo")
local total = 0

local part_name = ""
local part_id = -1
local part_odo = -1
local part_val = 0

local csplit = {}
local psplit = {}

for k,v in pairs(ilinks) do
csplit = extensions.blrutils.ssplit(v, ",")
psplit = extensions.blrutils.ssplit(k, "/")
part_name = psplit[#psplit]

part_id = tonumber(csplit[1])
part_odo = inventory[part_id][2] + (codo - tonumber(csplit[2])) -- calculate actual part odometer
part_val = getPartPrice(part_name) or getPartPrice("default")

if odoscale then
part_val = part_val * (0.95 - math.min(0.9, part_odo / 200000000.0))
end

total = total + part_val
end


return total
end

local function getVehicleSalePrice(reputation, repairCost, scrapVal)
local partcost = getVehiclePartCost(true)
local repratio = 1.0 - math.min(1.0, reputation / 50000.0) -- 100% sell price at 50k rep
local repscl = 1.0 - (0.8 * repratio) -- at 0 rep sell price is 20% of total part value
return math.max((partcost * repscl) - repairCost , scrapVal)
end


local function getDynamicMirrorsData()
local mirrors = extensions.core_vehicle_mirror.getAnglesOffset()
local avail = getAllAvailableParts(true)
local toRet = {}

local defaultIcons = {}
defaultIcons["left"] = "mirrorLeftDefault"
defaultIcons["right"] = "mirrorRightDefault"
defaultIcons["center"] = "mirrorInteriorMiddle"

for k,v in pairs(mirrors) do
toRet[k] = {}

toRet[k]["part"] = v["name"]
if avail[v["name"]] then
toRet[k]["name"] = getPartName(v["name"])
else
if string.find(v["name"], "_L") then
toRet[k]["name"] = "Left Mirror"
elseif string.find(v["name"], "_R") then
toRet[k]["name"] = "Right Mirror"
else
toRet[k]["name"] = "Rear View Mirror"
end
end
toRet[k]["id"] = v["id"]
toRet[k]["angle"] = v["angleOffset"]
toRet[k]["icon"] = v["icon"]
toRet[k]["clampX"] = v["clampX"]
toRet[k]["clampY"] = v["clampY"]

if string.find(toRet[k]["name"]:upper(), "LEFT") then
toRet[k]["position"] = "left"
elseif string.find(toRet[k]["name"]:upper(), "RIGHT") then
toRet[k]["position"] = "right"
else
toRet[k]["position"] = "center"
end

if not v["icon"] then
toRet[k]["icon"] = defaultIcons[toRet[k]["position"]]
end

end
return toRet
end

-- get mirrors sorted in position based tables with lower ID priority
local function getSortedMirrors()
local mdata = getDynamicMirrorsData()
local idsorted = {}
local psorted = {}
local toRet = {}
local depth = 0

psorted["left"] = {}
psorted["right"] = {}
psorted["center"] = {}

for k,v in pairs(mdata) do
idsorted[v["id"]+1] = k
end

for i=1,#idsorted do
table.insert(psorted[mdata[idsorted[i]].position], idsorted[i])
if #psorted[mdata[idsorted[i]].position] > depth then depth = #psorted[mdata[idsorted[i]].position] end
end 

for i=1,depth do 
toRet[i] = {}
table.insert(toRet[i], psorted["left"][i] or "none") 
table.insert(toRet[i], psorted["center"][i] or "none") 
table.insert(toRet[i], psorted["right"][i] or "none") 
end

return toRet
end

-- updates ilink values after template loading
local function templateLoadedUpdateIlinks(cpath,tpath, odo)
local tdata = jsonReadFile(tpath)
local csplit = {}
local cid = 0
local clink = ""
local newlinks = {}

for k,v in pairs(tdata["ilinks"]) do
csplit = extensions.blrutils.ssplit(v,",")
cid = tonumber(csplit[1])
clink = cid .. "," .. odo
newlinks[k] = clink
end

tdata["ilinks"] = newlinks
tdata["odometer"] = odo

jsonWriteFile(cpath, tdata, true)
end

-- to avoid issues with 1.16 advanced inventory ilinks just copy
-- current config into a template file 
local function createTemplateFile(currentConfig,templatePath)
extensions.blrutils.copyFile(currentConfig, templatePath)
end


local function getValueRangedPartList(minval, maxval)
local toRet = {}
local cprice = 0

for k,v in pairs(getAllAvailableParts(true)) do
cprice = getPartPrice(k) or 0 -- 	 avoid liveries to skip old paint and dynamic texture skin
if cprice >= minval and cprice <= maxval and not string.find(k, "skin") then
table.insert(toRet, k)
end
end

return toRet
end


local gciteration = 0
local gcintercount = 1000

local function gcinterval(interval)
gciteration = gciteration + 1
if (gciteration % interval) == 0 then 
print("GC RUNNING, CURRENT MEM USAGE " .. collectgarbage("count") .. " KB")
collectgarbage()
end
end



local cacheReady = false -- used to avoid trying to use cache in UI init before its loaded

-- returns false when json file cannot be read 
local function jsonReadFileSafe(path)
local result, returned = pcall(jsonReadFile, path)
local toRet

if result then 
toRet = returned
else
toRet = result 
end

return toRet 
end


-- creates a jbeam file map for ALL JBEAM FILES including mods 
local function createFullJbeamMap()
local files = FS:findFiles("vehicles", "*.jbeam", 100)
local cdata = {}
jbeamFileMap = {}

for k,v in pairs(files) do
cdata = jsonReadFileSafe(v)

if cdata then
for p,pdata in pairs(cdata) do
jbeamFileMap[p] = v
end
else
print("BEAMLR JBEAM CACHING AVOIDED BROKEN JBEAM FILE: " .. v)
end

gcinterval(gcintercount)
end

end

local function getJbeamFromFullMap(p)
return jsonReadFile(jbeamFileMap[p])[p]
end

local function createFullPartNameLibrary()
local cjbeam = {}
local inventory = extensions.blrPartInventory.getInventory()
local cpart = ""

fullPartNameLibrary = {}
for k,v in pairs(jbeamFileMap) do
cjbeam = getJbeamFromFullMap(k)
fullPartNameLibrary[k] = cjbeam["information"]["name"] or k
gcinterval(gcintercount)
end
end

local function parseJbeamSlotsTable(data)
local toRet = {}
local header = data[1]
local sid = 1


for i=2,#data do
if not toRet[sid] then toRet[sid] = {} end
for j=1,#header do
toRet[sid][header[j]] = data[i][j]
end
sid = sid + 1
end


return toRet
end

-- can't optimize this one, part jbeam doesn't contain parent slot UI name so no way around
-- looping over every single jbeam file to build a list of slot names
local function createFullSlotNameLibrary()
local cjbeam = {}
fullSlotNameLibrary = {}
local cslotdata = {}
local newfmt = false

for k,v in pairs(jbeamFileMap) do
cjbeam = getJbeamFromFullMap(k)
cslotdata = nil -- reset to nil to avoid parts that have no child slots
if cjbeam["slots2"] then
newfmt = true
cslotdata = parseJbeamSlotsTable(cjbeam["slots2"])
elseif cjbeam["slots"] then
newfmt = false
cslotdata = parseJbeamSlotsTable(cjbeam["slots"])
end

if cslotdata then
for _,slot in pairs(cslotdata) do
if newfmt then
fullSlotNameLibrary[slot["name"]] = slot["description"] or slot["name"]
else
fullSlotNameLibrary[slot["type"]] = slot["description"] or slot["type"]
end
end
end

gcinterval(gcintercount)
end

end



local cacheValidBypass = false

local function isJbeamCacheValid()

if cacheValidBypass then return false end


if not FS:fileExists("beamLR/cache/cachedMods") then 
return false
end

local mods = core_modmanager.getMods()
local cached = extensions.blrutils.loadDataTable("beamLR/cache/cachedMods")
local version = cached["cached_game_version"]

-- 1.17.4 fix for potentially uncached jbeam file changes in new game versions
if version ~= beamng_versiond then return false end

for k,v in pairs(mods) do
if v.active and not cached[k] then return false end
end



return true
end


local function generateJbeamLibraries()
local cvalid = isJbeamCacheValid()
local cachedMods = {}

gciteration = 0

if cvalid then
jbeamFileMap = extensions.blrutils.loadDataTable("beamLR/cache/jbeamFileMap")
fullSlotNameLibrary = extensions.blrutils.loadDataTable("beamLR/cache/fullSlotNameLibrary")
fullPartNameLibrary = extensions.blrutils.loadDataTable("beamLR/cache/fullPartNameLibrary")
else
createFullJbeamMap()
gcinterval(1)
createFullPartNameLibrary()
gcinterval(1)
createFullSlotNameLibrary()
gcinterval(1)
extensions.blrutils.saveDataTableOptimized("beamLR/cache/jbeamFileMap", jbeamFileMap, gcintercount)
extensions.blrutils.saveDataTableOptimized("beamLR/cache/fullSlotNameLibrary", fullSlotNameLibrary, gcintercount)
extensions.blrutils.saveDataTableOptimized("beamLR/cache/fullPartNameLibrary", fullPartNameLibrary, gcintercount)

for k,v in pairs(core_modmanager.getMods()) do
if v.active then -- skip deactivated mods
cachedMods[k] = "true"
end
end

cachedMods["cached_game_version"] = beamng_versiond

extensions.blrutils.saveDataTableOptimized("beamLR/cache/cachedMods", cachedMods, gcintercount)

end

cacheValidBypass = false
cacheReady = true

extensions.blrglobals.blrFlagSet("uiInitRequest", true) -- force UI init after cache is ready to refresh UI 
end





local function getSlotKeyedFullInventory()
local inventory = extensions.blrPartInventory.getInventory()
local toRet = {}

local cpart = ""
local cjbeam = {}
local cslot = ""

-- parent slot key in jbeam table= "slotType"
-- can be table for parts that can fit in multiple slots

for pid,pdata in pairs(inventory) do

cpart = pdata[1]
cjbeam = getJbeamFromFullMap(cpart)
cslot = cjbeam["slotType"]

-- insert part inventory id into slot specific table 
if type(cslot) == "table" then
for _,s in pairs(cslot) do
if s ~= "main" and pdata[4] ~= 1 then
if not toRet[s] then toRet[s] = {} end
table.insert(toRet[s], pid)
end
end
else
if cslot ~= "main" and pdata[4] ~= 1 then
if not toRet[cslot] then toRet[cslot] = {} end
table.insert(toRet[cslot], pid)
end
end
end


return toRet
end



local function getSortedFullInventorySlots()
local inventory = getSlotKeyedFullInventory()
local slots = {}
local toRet = {}

for k,v in pairs(inventory) do
slots[k] = fullSlotNameLibrary[k] or k
end


for k,v in valueSortedPairs(slots) do
table.insert(toRet, k)
end

return toRet
end


local function getFullSlotNameLibrary()
return fullSlotNameLibrary
end

local function getFullPartNameLibrary()
return fullPartNameLibrary
end


local function setCacheValidBypass(bypass)
cacheValidBypass = bypass
end


local function jbeamCacheReady()
return cacheReady
end

local jbcsmap = {}
local jbcsconfig = {}

local function buildJbeamChildSlotMap(part, start, config)
if start then 
jbcsmap = {} 
jbcsconfig = config
end

--print("part=" .. part)

local cfile = jbeamFileMap[part]

if not cfile or not FS:fileExists(cfile) then
print("JBEAM FILE WAS MISSING FOR PART " .. part)
if cfile then print("RETURNED FILE PATH WAS " .. cfile) else print("RETURNED FILE PATH WAS NIL") end
return
end

local cjbeam = jsonReadFile(cfile)[part]
local cstype = cjbeam["slotType"]

-- insert part's own slot into map
if cstype then -- 1.18 fix, handling for some parts fitting into multiple slots
if type(cstype) == "table" then
for k,v in pairs(cstype) do
table.insert(jbcsmap, v)
end
else
table.insert(jbcsmap, cstype) 
end
end

local cslots = cjbeam["slots"] or cjbeam["slots2"]

if not cslots then return end -- no child slots, return 

cslots = parseJbeamSlotsTable(cslots) 

local cpart = ""

for k,v in pairs(cslots) do

cpart = jbcsconfig["parts"][v["type"]]

--print(v["type"])

if cpart and cpart ~= "" and cpart ~= "none" then
--print("cpart=" .. cpart)
buildJbeamChildSlotMap(cpart)
end

end

--dump("DUMPING JBEAM CHILD SLOT MAP FOR PART: " .. part)
--dump(jbcsmap)

end

local function getJbeamChildSlotMap(part, config)
buildJbeamChildSlotMap(part, true, config)
return jbcsmap
end

-- randomly picks from a set of item with set thresholds from 0.0 to 1.0
-- set should be in increasing order of rarity, first threshold must be 1.0
-- picks item if roll is below its threshold
-- % chance calculated by item threshold - next item threshold (or 0 for last item)
-- example
-- items = {"A", "B", "C", "D"}
-- thresholds = {1.0, 0.5, 0.25, 0.1 }
-- "A" has a chance of 50% (1.0 - 0.5)
-- "B" has a chance of 25% (0.5 - 0.25)
-- "C" has a chance of 15% (0.25 - 0.1)
-- "D" has a chance of 10% (0.1 - 0.0)
-- if chances don't add up to 100% they will not be accurate representation of output
local function getRandomItemSetThresholds(items, thresholds)
local roll = math.random()
local pick = -1

for i=#items,1,-1 do
    if roll <= thresholds[i] then pick = i break end
end

return items[pick]
end


-- 1.18 fix for slot paths
-- 1.17.4 defective (missing important parts) config generator
local function generateDefectiveConfigVariant(baseFile, fmap, seed)
math.randomseed(seed)
local toRet = generateConfigVariant(baseFile, fmap, seed) -- start by generating a randslots config
local csplit = {}
local cid = ""


-- now remove an important part like engine, wheels, tires, etc.
-- 40% chance engine gets removed, 10% chance for every other item 
local items = {"engine", "tire_F", "tire_R", "wheel_F", "wheel_R", "suspension_F", "suspension_R"}
local thresholds = {1.0, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1}
local pick = getRandomItemSetThresholds(items, thresholds)
local parent = ""
local children = {}
local toremove = {}
local slotIDPathMap = {}

-- 1.18 fix, build map of slot IDs to list of paths with this slot ID
-- otherwise configs with slot paths don't work with defective config gen
-- This fix means slots with same IDs will have their part removed if picked
-- but this (hopefully) isn't a problem considering the "defective" part set isn't
-- the kind to be in slots ids that are in multiple spots on a car 
for slot,_ in pairs(toRet["parts"]) do
csplit = extensions.blrutils.ssplit(slot, "/")
if #csplit > 1 then 
cid = csplit[#csplit-1]
else
cid = csplit[1]
end
if not slotIDPathMap[cid] then slotIDPathMap[cid] = {} end
table.insert(slotIDPathMap[cid], slot)
end



dump("Spawning defective vehicle, removed part: " .. pick)

for k,v in pairs(toRet["parts"]) do

-- 1.18 fix, remove path from slot ID to avoid string.find matching with parent in path
csplit = extensions.blrutils.ssplit(k, "/")
if #csplit > 1 then 
cid = csplit[#csplit-1]
else
cid = csplit[1]
end

-- checking v to skip empty slots, if no part is installed any child slots it could have are already empty
if string.find(cid, pick) and v and v ~= "" and v ~= "none" then 
children = getJbeamChildSlotMap(v, toRet)
for _,slot in pairs(children) do
table.insert(toremove, slot)
end
end
end

for k,v in pairs(toremove) do
if slotIDPathMap[v] then
for _,slot in pairs(slotIDPathMap[v]) do
if toRet["parts"][slot] then toRet["parts"][slot] = "" end
end
end
end

return toRet
end

-- 1.18 update for BeamNG 0.36, converts into slot path by inserting parent path
local function getSortedJbeamSlotsTable(slots, ppath)
local sknv = {}
local toRet = {}


-- build internal slot name key, ui slot name value table
for k,v in pairs(slots) do
sknv[v.type] = fullSlotNameLibrary[v.type]
end

for k,v in valueSortedPairs(sknv) do
table.insert(toRet, ppath .. k .. "/")
end

return toRet
end


local function getParsedInventoryLinks()
return parsedInventoryLinksCache
end



-- mostly used for repair ui to be able to find part name from part name library
-- without having to parse part name out of the path
local function getPartPathToPartIDMap()
local toRet = {}
local parts = getVehicleParts()
local cpath = ""
for slot,part in pairs(parts) do
cpath = slot .. "/" .. part
toRet[cpath] = part
end
return toRet
end


-- KEY = SLOT ID, VAL = LIST OF PARTS ATTACHED TO SLOTS WITH THIS ID
local function getSlotIDPartMap()
local parts = getVehicleParts()
local csplit = {}
local cid = ""
local toRet = {}

for k,v in pairs(parts) do
csplit = extensions.blrutils.ssplit(k, "/")
cid = csplit[#csplit-1]
if not toRet[cid] then toRet[cid] = {} end
if v ~= "" then table.insert(toRet[cid], v) end
end

return toRet
end

M.getSlotIDPartMap = getSlotIDPartMap
M.getPartPathToPartIDMap = getPartPathToPartIDMap
M.getVehicleInstalledPartsList = getVehicleInstalledPartsList
M.getVehicleSlotIDsList = getVehicleSlotIDsList
M.getSlotIDFromPath = getSlotIDFromPath
M.getPartChildSlotNames = getPartChildSlotNames
M.getIDKeyedSlots = getIDKeyedSlots
M.getParsedInventoryLinks = getParsedInventoryLinks
M.loadFavorites = loadFavorites
M.getSortedJbeamSlotsTable = getSortedJbeamSlotsTable
M.getRandomItemSetThresholds = getRandomItemSetThresholds
M.getJbeamChildSlotMap = getJbeamChildSlotMap
M.buildJbeamChildSlotMap = buildJbeamChildSlotMap
M.jbeamCacheReady = jbeamCacheReady
M.setCacheValidBypass = setCacheValidBypass
M.generateJbeamLibraries = generateJbeamLibraries
M.isJbeamCacheValid = isJbeamCacheValid
M.getFullPartNameLibrary = getFullPartNameLibrary
M.getFullSlotNameLibrary = getFullSlotNameLibrary
M.getSortedFullInventorySlots = getSortedFullInventorySlots
M.createFullSlotNameLibrary = createFullSlotNameLibrary
M.parseJbeamSlotsTable = parseJbeamSlotsTable
M.createFullPartNameLibrary = createFullPartNameLibrary
M.getSlotKeyedFullInventory = getSlotKeyedFullInventory
M.getJbeamFromFullMap = getJbeamFromFullMap
M.createFullJbeamMap = createFullJbeamMap
M.getValueRangedPartList = getValueRangedPartList
M.createTemplateFile = createTemplateFile
M.templateLoadedUpdateIlinks = templateLoadedUpdateIlinks
M.getSortedMirrors = getSortedMirrors
M.getDynamicMirrorsData = getDynamicMirrorsData
M.advancedInventoryCategory = advancedInventoryCategory
M.advancedInventorySearch = advancedInventorySearch
M.getInventoryLinkOdometers = getInventoryLinkOdometers
M.initVehicleInventoryLinks = initVehicleInventoryLinks
M.getUsedPartInventoryIDs = getUsedPartInventoryIDs
M.getPartKeyedSlotMap = getPartKeyedSlotMap
M.getAdvancedInventoryUIParts = getAdvancedInventoryUIParts
M.initDelayedSlotTable = initDelayedSlotTable
M.getPartKeyedSlots = getPartKeyedSlots
M.setSlotDelayedNoInventory = setSlotDelayedNoInventory
M.getChildMap = getChildMap
M.getParentMap = getParentMap
M.getMainPartChild = getMainPartChild
M.templateLoadInventorySwap = templateLoadInventorySwap
M.getCSLDefaults = getCSLDefaults
M.setSlotDelayed = setSlotDelayed
M.setSlotWithChildren = setSlotWithChildren
M.executeDelayedSlotSet = executeDelayedSlotSet
M.getAllChildSlots = getAllChildSlots
M.childSlotLookupStep = childSlotLookupStep
M.getChildSlots = getChildSlots
M.getGeneratedDamageCost = getGeneratedDamageCost
M.generateDamageCostTable = generateDamageCostTable
M.getPartPricesCommonSlots = getPartPricesCommonSlots
M.getPartsCommonSlots = getPartsCommonSlots
M.getSortedGarageParts = getSortedGarageParts
M.getSortedGarageSlots = getSortedGarageSlots
M.getSortedShopParts = getSortedShopParts
M.getSortedShopSlots = getSortedShopSlots
M.getSortedTuningFields = getSortedTuningFields
M.getSortedTuningCategories = getSortedTuningCategories
M.getTuningFuelLoad = getTuningFuelLoad
M.getFilteredSlotMap = getFilteredSlotMap
M.generateConfigVariant = generateConfigVariant
M.generateDefectiveConfigVariant = generateDefectiveConfigVariant
M.getCustomIOCTX = getCustomIOCTX
M.getSlotNameLibrary = getSlotNameLibrary
M.getVehicleSalePrice = getVehicleSalePrice
M.getVehiclePartCost = getVehiclePartCost
M.getPartShopList = getMergedSlotMaps
M.getMergedSlotMaps = getMergedSlotMaps
M.getFullSlotMap = getFullSlotMap
M.getAllAvailableParts = getAllAvailableParts
M.getPartNameLibrary = getPartNameLibrary
M.getFullPartPrices = getFullPartPrices
M.ioCtx = ioCtx
M.getPartJbeam = getPartJbeam
M.getMainPartName = getMainPartName
M.getPartPreviewImageTable = getPartPreviewImageTable
M.getVehiclePaintData = getVehiclePaintData
M.resetTuningData = resetTuningData
M.searchFilter = searchFilter
M.getTuningUIValues = getTuningUIValues
M.applyTuningData = applyTuningData
M.tuningTableFromUIData = tuningTableFromUIData
M.getTuningUIData = getTuningUIData
M.getFilter = getFilter
M.setFilter = setFilter
M.categoryFilter = categoryFilter
M.loadCategories = loadCategories
M.getPartPriceLibrary = getPartPriceLibrary
M.loadPartPriceLibrary = loadPartPriceLibrary
M.getPartPrice = getPartPrice
M.getVehicleParts = getVehicleParts
M.saveInventoryToFile = saveInventoryToFile
M.loadInventoryFromFile = loadInventoryFromFile
M.removeFromInventory = removeFromInventory
M.addToInventory = addToInventory
M.getPartInventory = getPartInventory
M.getGarageUIData = getGarageUIData
M.setSlot = setSlot
M.getPathKeyedSlots = getPathKeyedSlots
M.getAvailablePartList = getAvailablePartList
M.getSlotMap = getSlotMap
M.getVehicleData = getVehicleData
M.saveConfig = saveConfig
M.loadConfig = loadConfig

return M
