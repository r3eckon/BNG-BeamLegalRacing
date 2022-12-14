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

local function getVehicleParts()
local chosen = vehManager.getPlayerVehicleData().chosenParts
return chosen
end

local function ioCtx()
return vehManager.getPlayerVehicleData().ioCtx
end


local function getActualSlots()
local toRet = {}
local chosen = vehManager.getPlayerVehicleData().chosenParts
for k,v in pairs(chosen) do
table.insert(toRet, k)
end
return toRet
end

local function getSlotMap()
local playerVehicle = vehManager.getPlayerVehicleData()
local slotMap = jbeamIO.getAvailableSlotMap(playerVehicle.ioCtx)
return slotMap
end

local function getMainPartName()
return jbeamIO.getMainPartName(vehManager.getPlayerVehicleData().ioCtx)
end

local function getAvailablePartList()
local toRet = {}
local playerVehicle = vehManager.getPlayerVehicleData()
local availParts = getSlotMap()
local slots = vehManager.getPlayerVehicleData().chosenParts
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
local playerVehicle = vehManager.getPlayerVehicleData()
local availParts = jbeamIO.getAvailableParts(playerVehicle.ioCtx)
return availParts[k]
end

local function getPlayerVehicleData()
return vehManager.getPlayerVehicleData()
end

local function getGarageUIData()
local toRet = {}
local current = {}
local slots = getActualSlots() 		-- Gets actual slots from current car
local avail = getSlotMap()	   		-- Gets all available parts for all available slots of this car

for _,slot in pairs(slots) do		-- Looping over vehicle current slots 

if avail[slot] ~= nil then			-- Filter slots that have no avail parts, apparently this happens.

if toRet[slot] == nil then			-- Init return table slots
toRet[slot] = {}
end

for _,part in pairs(avail[slot]) do -- Looping over all available parts for the current slot

if partInventory[part] ~= nil then 	-- Finding the part in player inventory
if partInventory[part] >= 1 then
table.insert(toRet[slot], part) 	-- Populate return table
end
end

end 

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
if partInventory[p] ~= nil or 0 then
partInventory[p] = partInventory[p] - 1
end
end

local function setSlot(slot, val)
local toSet = vehManager.getPlayerVehicleData().config.parts
local currentParts = getVehicleParts()

if val == "" then					-- Val is null, part is being removed
if currentParts[slot] ~= nil and currentParts[slot] ~= "" then   -- Check if slot has part
addToInventory(currentParts[slot])	-- Add removed part to inventory
toSet[slot] = val
extensions.core_vehicle_partmgmt.setPartsConfig(toSet)
end

else								-- Val isn't null, part is being added to vehicle

if partInventory[val] ~= nil then	-- Check that inventory contains part being added
if partInventory[val] >= 1 then	
if currentParts[slot] ~= nil and currentParts[slot] ~= "" then   -- Check if there's a part in that slot already
addToInventory(currentParts[slot])	-- If so add removed part to inventory
end
removeFromInventory(val)			-- Remove added part from inventory
toSet[slot] = val
extensions.core_vehicle_partmgmt.setPartsConfig(toSet)
end
end

end

end


local function saveConfig(file)
extensions.core_vehicle_partmgmt.save(file)
end


local function loadConfig(file)
extensions.core_vehicle_partmgmt.load(file)
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

local function loadCategories(file)
categoryData = loadTableFromFile(file, false)
currentFilter = "all"
end

local function getCategories()
return caregoryData
end


local function categoryFilter(source, keyMode)
local toRet = {}
local part = ""
local cm = false

if currentFilter == "all" then
toRet = source
else

for k,v in pairs(source) do

cm = false													-- Reset current match flag
if keyMode then part = k else part = v end

for f,t in pairs(categoryData) do							-- To have universal filters, loop over universal part names to see if they match												-- with the current part in the list. Only add if matching the selected filter.
	if string.match(part, f) and t == currentFilter then	-- Matching filter detected, adding to return table
		toRet[k] = v
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

local function getTuningUIData()
local dtable = extensions.core_vehicle_manager.getPlayerVehicleData().vdata.variables
local toRet = {}
local cname = ""
local ckey = ""
for k,v in pairs(dtable) do
if k ~= "$fuel" and v~= nil then			-- Don't show slider to tune fuel since it's overriden by saved fuel value

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
local dtable = extensions.core_vehicle_manager.getPlayerVehicleData().vdata.variables
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
local dtable = extensions.core_vehicle_manager.getPlayerVehicleData().vdata.variables
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
local fullmap = getAvailablePartList()
local cslot = {}
for k,v in pairs(fullmap) do
for _,p in pairs(v) do
if FS:fileExists("ui/modules/apps/beamlrui/partimg/" .. p .. ".png") then
toRet[p] = p .. ".png"
end
end
end
return toRet
end

local function getPartJbeam(partName)
return jbeamIO.getPart(ioCtx(), partName)
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
for k,v in pairs(allParts) do
cpart = getPartJbeam(k)
if not string.match(cpart["slotType"], "simple_traffic") then
if cpart["slotType"] ~= "main" then
if not string.match(k, "simple_traffic") then
if toRet[cpart["slotType"]] ~= nil then
table.insert(toRet[cpart["slotType"]], k)
else
toRet[cpart["slotType"]] = {k}
end
end
end
end
end
return toRet
end

local function getMergedSlotMaps() -- Should give player access to all vehicle parts except wheels which are too numerous to give good UX
local slotMap = getAvailablePartList()
local fullMap = getFullSlotMap()
local toRet = {}

for k,v in pairs(slotMap) do
if not string.match(k, "simple_traffic") then -- Remove simple traffic from this part list
toRet[k] = v	
end								
end							

for k,v in pairs(fullMap) do
toRet[k] = v				
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
local avail = getMergedSlotMaps()
local toRet = {}
for k,v in pairs(avail) do
for _,part in pairs(v) do
toRet[part] = getPartName(part)
end
end
return toRet
end

local function getVehiclePartCost()
local parts = getVehicleParts()
local total = 0
local ccost = 0
for k,v in pairs(parts) do
if k ~= "main" then
if v ~= "" then
ccost = getPartPrice(v) or 0
total = total + ccost
end
end
end
return total
end

local function getVehicleSalePrice(odometer, reputation, repairCost, scrapVal)
local partcost = getVehiclePartCost()
local odoscl = 0.9 - math.min(((odometer / 200000000.0) * 0.8), 0.8)
local repscl = 0.1 + math.min(((reputation / 5000.0) * 0.8), 0.8)
return math.max(((partcost * repscl) * odoscl) - repairCost , scrapVal)
end


local function getSlotNameLibrary()
local toRet = {}
local avail = getMergedSlotMaps()
local cjbeam = {}
local cslots = {}
for k,v in pairs(avail) do
for _,part in pairs(v) do
cjbeam = getPartJbeam(part)
if cjbeam ~= nil then
cslots = cjbeam["slots"]
if cslots ~= nil then
for _,s in pairs(cslots) do
toRet[s["type"]] = s["description"]
end
end
end
end
end
return toRet
end

local function searchFilter(source, keyMode)				-- Directly matches filter with part list for simple search function
local toRet = {}
local part = ""
local cname = ""
local nameLib = getSlotNameLibrary()

for k,v in pairs(source) do
if keyMode then part = k else part = v end
cname = nameLib[part] or ""
if string.match(part:upper(), currentFilter:upper()) or string.match(cname:upper(),currentFilter:upper()) then -- Updated to match proper slot name not just internal slot name
toRet[k] = v
end
end

return toRet
end



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
M.getActualSlots = getActualSlots
M.getAvailablePartList = getAvailablePartList
M.getSlotMap = getSlotMap
M.getPlayerVehicleData = getPlayerVehicleData
M.saveConfig = saveConfig
M.loadConfig = loadConfig

return M
