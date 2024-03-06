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

M.forceSetOdometer = forceSetOdometer
M.saveIntegrityToFile = saveIntegrityToFile
M.loadIntegrityFromFile = loadIntegrityFromFile
M.getIntegrityDevices = getIntegrityDevices
M.getNewCarMechData = getNewCarMechData
M.saveDamageToFile = saveDamageToFile
M.loadDamageFromFile = loadDamageFromFile

return M



