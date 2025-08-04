-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local extensions = require("extensions")




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


local function saveDamageToFile(f, dt)
local filedata = ""
local fullcat = ""
local fulldev = ""
local s,e = 0,0

for cat,dmgdat in pairs(dt) do  -- Gotta detect some subcategories here for easier reloading (wheelBrake, wheelTire, etc..)
for dev,dmgval in pairs(dmgdat) do -- Subcategories are stored in the DEV part

if string.match(dev, "tire") then 
s,e = string.find(dev, "tire")
fullcat = "tire"
fulldev = string.sub(dev, e+1, #dev) -- Resulting format : tire.FR
elseif string.match(dev, "brakeOverHeat") then -- REMEMBER: NEED TO MATCH MORE COMPLEX SUBCATEGORIES FIRST (if "brake" checked first this device get matched there)
s,e = string.find(dev, "brakeOverHeat")
fullcat = "brakeOverHeat"
fulldev = string.sub(dev, e+1, #dev) -- Resulting format : brakeOverHeat.FR
elseif string.match(dev, "brake") then 
s,e = string.find(dev, "brake")
fullcat = "brake"
fulldev = string.sub(dev, e+1, #dev) -- Resulting format : brake.FR
else -- No subcategory just apply cat as fullcat
fullcat = cat
fulldev = dev
end

filedata = filedata .. fullcat .. "." .. fulldev .. "=" .. tostring(dmgval) .. "\n"
end
end

writeFile(f,filedata)


end

local function loadDamageFromFile(f, vid)
local ve = be:getObjectByID(vid)
ve:queueLuaCommand("extensions.blrVehicleUtils.loadMechanicalDamage('" .. f .. "')") -- 1.14.3 fix
end

local function getNewCarMechData()
local toRet = "powertrain.mainEngine=false" .. "\n"
toRet = toRet .. "powertrain.driveshaft=false"
return toRet
end


local function getIntegrityDevices()	-- Should eventually detect what's on the car 
local toRet = {"odometer", "integrity.mainEngine"}
return toRet
end


local function loadIntegrityFromFile(file, vid)
local itable = loadTableFromFile(file)
local splitres = {}
local vehcmd = ""
local ve = be:getObjectByID(vid)
local mdev = ""
local sdev = ""
local valsplt = {}
local intval = 0
local odoval = 0

-- Loading vehicle odometer first 
-- UPDATED FOR 0.26 ANALOG ODOMETER GAUGE SYSTEM
-- THAT SYSTEM FOLLOWS THE ODOMETER VALUE OF THE "MAIN PART"
local odometer = tonumber(itable["odometer"])
ve:queueLuaCommand("partCondition.reset()")
-- for initConditions last {'a'} param is to avoid paint condition using fallback value
-- passing a useless table causes the paint condition function to return without setting mesh colors
ve:queueLuaCommand("partCondition.initConditions(nil," .. odometer .. ", 1, {'a'})")
ve:queueLuaCommand("extensions.blrVehicleUtils.loadOdometer()") -- 1.14.3 fix

-- Now loading integrity values for different devices
for k,v in pairs(itable) do
if string.match(k, "integrity") then
splitres = extensions.blrutils.ssplit(k, ".") 	-- integrity.mainEngine.radiator=INTEGRITY_VALUE,ODOMETER_VALUE
mdev = splitres[2] 								-- mainEngine
sdev = splitres[3]								-- radiator
valsplt = extensions.blrutils.ssplit(v, ",")	-- INTEGRITY_VALUE,ODOMETER_VALUE
intval = tonumber(valsplt[1])					-- INTEGRITY_VALUE
odoval = tonumber(valsplt[2])					-- ODOMETER_VALUE

-- PROBLEM. CANT USE INTEGRITY VALUE WITH MECHANICAL DAMAGE LOADING. 
-- EX: RADIATOR REPAIR WILL BREAK AGAIN IF INTEGRITY BELOW .8 SO JUST USE ODOMETER FOR NOW
if sdev ~= nil then
ve:queueLuaCommand("extensions.blrVehicleUtils.setPartCondition(" .. mdev .. "," .. sdev .. "," .. odoval .. ",1)")
else
ve:queueLuaCommand("extensions.blrVehicleUtils.setPartCondition(" .. mdev .. ",nil," .. odoval .. ",1)")
end
end
end

end

local function saveIntegrityToFile(file, dt)
local itable = dt
local filedata = ""

local odometer = tonumber(dt["odometer"]) -- For now, apply car odometer to every part but system is rdy for part by part odometer vals

filedata = "odometer=" .. odometer .. "\n"

for k,v in pairs(dt) do
if string.match(k,"integrity") then
filedata = filedata .. k .. "=" .. v .. "," .. odometer .. "\n"
end
end

writeFile(file, filedata)

end

local function forceSetOdometer(vid, odometer)
local ve = be:getObjectByID(vid)
ve:queueLuaCommand("partCondition.reset()")
-- for initConditions last {'a'} param is to avoid paint condition using fallback value
-- passing a useless table causes the paint condition function to return without setting mesh colors
ve:queueLuaCommand("partCondition.initConditions(nil," .. odometer .. ", 1, {'a'})")
ve:queueLuaCommand("extensions.blrVehicleUtils.loadOdometer()") -- 1.14.3 fix
end

-- EDITED IN 1.18 TO WORK WITH BEAMNG 0.36 SLOT/PART PATH SYSTEM
local function loadAdvancedIntegrityData(vid, cfile, vehOdoOverride, fuelReload)
local ve = be:getObjectByID(vid)
local parts = extensions.blrpartmgmt.getVehicleParts(vid)
local cdata = jsonReadFile(cfile)

-- Queue integrity loading for later if vehicle config file doesn't have inventory links ready
if not cdata["ilinks"] then
local params = {}
params["vid"] = vid
params["cfile"] = cfile
params["vehOdoOverride"] = vehOdoOverride
extensions.blrglobals.blrFlagSet("integrityLoadingQueued", true)
extensions.blrutils.blrvarSet("integrityLoadingData", params)
print("Config at path (" .. cfile .. ") missing ilinks, skipping integrity loading!")
return
end

if extensions.blrglobals.blrFlagGet("integrityLoadingQueued") then
print("Executing delayed integrity loading.")
extensions.blrglobals.blrFlagSet("integrityLoadingQueued", false)
end

local mainPart = extensions.blrpartmgmt.getMainPartName()
local vehodo = vehOdoOverride or cdata["odometer"] -- override used in post part edit to reload actual odometer
local ilinks = cdata["ilinks"]
local inventory = extensions.blrPartInventory.getInventory()

local csplit = {}
local cilink = {}
local ilinkid = 0
local ilinkodo = 0
local invodo = 0
local invint = 0
local cpath = ""

local totalodo = 0

local cparams = ""

print("LOAD ADVANCED INTEGRITY DATA DEBUG BEGIN")


-- 1.18 edit, set integrity for main part first
cparams = string.format("%q,%f,%f", "/" .. mainPart, vehodo, 1.0)
ve:queueLuaCommand("extensions.blrVehicleUtils.setAdvancedPartCondition(".. cparams .. ")")


for k,v in pairs(parts) do
if v ~= "" then -- skip empty slots as they don't have ilinks 
cpath = k .. v
cilink = ilinks[cpath]
csplit = extensions.blrutils.ssplit(cilink, ",")
ilinkid = tonumber(csplit[1])
print("ILINK ID: " .. ilinkid)
ilinkodo = tonumber(csplit[2])
print("ILINK ODO: " .. ilinkodo)
invodo = inventory[ilinkid][2]
invint = inventory[ilinkid][3]

-- calculates actual odometer value of part
totalodo = invodo + (vehodo - ilinkodo)

cparams = string.format("%q,%f,%f", cpath, totalodo, invint)
ve:queueLuaCommand("extensions.blrVehicleUtils.setAdvancedPartCondition(".. cparams .. ")")
end
end

ve:queueLuaCommand("extensions.blrVehicleUtils.applyAdvancedPartConditions()")

-- For some reason loading integrity resets fuel so need to reload in case 
-- integrity loading was delayed to after fuel value was initially loaded
-- Should only happen for brand new cars so no need to check fuel type and tiers
if fuelReload then
csplit = extensions.blrutils.ssplit(cfile, "/") -- beamLR/garage/config/car
local gpath = "beamLR/garage/" .. csplit[4]
local gdata = extensions.blrutils.loadDataTable(gpath)
local fuelval = tonumber(gdata["gas"])
ve:queueLuaCommand("extensions.blrVehicleUtils.loadFuelType()")
ve:queueLuaCommand(string.format("extensions.blrVehicleUtils.setFuel(%.12f)", fuelval))
end


end

local function saveAdvancedIntegrityData(vid, cfile)
local cdata = jsonReadFile(cfile)
cdata["odometer"] = extensions.blrglobals.gmGetVal("codo")

local ilinks = cdata["ilinks"]
local csplit = {}
local cid = 0
local ve = be:getObjectByID(vid)

for k,v in pairs(ilinks) do
csplit = extensions.blrutils.ssplit(v, ",")
cid = tonumber(csplit[1])
ve:queueLuaCommand("extensions.blrVehicleUtils.queueIntegrityUpdate(" .. cid .. ",'" .. k .. "')")
end

ve:queueLuaCommand("extensions.blrVehicleUtils.executeIntegrityUpdate()")

jsonWriteFile(cfile, cdata, true)
end

-- called from vehicle lua if engine leaks oil, could probably give more precise info
-- by receiving params like which part causes leak, player unit setting based info on
-- what mileage prevents leak, leak rate, etc.
local function oilLeakMessage(engine, oilpan)
if oilpan >= 1000.0 then 
guihooks.trigger('Message', {ttl = 10, category="oilleak", msg = 'No oilpan installed! Vehicle can\'t hold oil!', icon = 'format_color_reset'})
return
end


if engine > 0 and oilpan > 0 then
guihooks.trigger('Message', {ttl = 10, category="oilleak", msg = 'Vehicle leaks oil! Use lower mileage engine and oil pan to fix it.', icon = 'format_color_reset'})
elseif engine > 0 then
guihooks.trigger('Message', {ttl = 10, category="oilleak", msg = 'Vehicle leaks oil! Use lower mileage engine to fix it.', icon = 'format_color_reset'})
elseif oilpan > 0 then
guihooks.trigger('Message', {ttl = 10, category="oilleak", msg = 'Vehicle leaks oil! Use lower mileage oil pan to fix it.', icon = 'format_color_reset'})
end
end


local ptclues = {}

local function resetPowertrainClues()
ptclues = {}
end

local function receivePowertrainClues(k,v)
if not ptclues["part"] then ptclues["part"] = {} end
if not ptclues["slot"] then ptclues["slot"] = {} end
ptclues["part"][k] = v
end

local function processPowertrainClues()
local chosenParts = extensions.blrpartmgmt.getVehicleParts()
local pkslots = {}

for k,v in pairs(chosenParts) do
if v and v ~= "" then
pkslots[v] = k
end
end


if ptclues["part"] then
for k,v in pairs(ptclues["part"]) do
ptclues["slot"][k] = pkslots[v]
end
else
print("Can't load powertrain clues due to missing data.\nThis is normal if vehicle has no powertrain parts.")
end

end

local function getPowertrainClues()
return ptclues
end







M.resetPowertrainClues = resetPowertrainClues
M.getPowertrainClues = getPowertrainClues
M.processPowertrainClues = processPowertrainClues
M.receivePowertrainClues = receivePowertrainClues
M.oilLeakMessage = oilLeakMessage
M.saveAdvancedIntegrityData = saveAdvancedIntegrityData
M.loadAdvancedIntegrityData = loadAdvancedIntegrityData
M.forceSetOdometer = forceSetOdometer
M.saveIntegrityToFile = saveIntegrityToFile
M.loadIntegrityFromFile = loadIntegrityFromFile
M.getIntegrityDevices = getIntegrityDevices
M.getNewCarMechData = getNewCarMechData
M.saveDamageToFile = saveDamageToFile
M.loadDamageFromFile = loadDamageFromFile

return M



