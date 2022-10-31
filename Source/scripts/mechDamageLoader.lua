-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local extensions = require("extensions")

local wheelName = { "wheel_FR", "wheel_FL", "wheel_RR", "wheel_RL"} -- For regular cars, not pigeon or trucks
local wheelPosName = {"FR", "FL", "RR" , "RL"}
local wheelID = {FR = 0, FL = 1, RR = 2, RL = 3}


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
local dt = loadTableFromFile(f, false)
local ve = be:getObjectByID(vid)
local cat = ""
local dev = ""
local split = {}
local valsplt = {}
local nval = 0

for k,v in pairs(dt) do
if not string.match(v,"false") then 
split = extensions.blrutils.ssplit(k, ".")
cat = split[1]
dev = split[2]

if cat == "powertrain" then
ve:queueLuaCommand("powertrain.breakDevice(powertrain.getDevice('" .. dev .. "'))")
elseif cat == "wheels" then
ve:queueLuaCommand("beamstate.breakBreakGroup('" .. wheelName[wheelID[dev]+1] .. "')")
elseif cat == "tire" then
ve:queueLuaCommand("beamstate.deflateTire(" .. wheelID[dev] .. ")")
elseif cat == "brake" then
ve:queueLuaCommand("wheels.wheels[" .. wheelID[dev] .. "].isBrakeMolten=true")
ve:queueLuaCommand("damageTracker.setDamage('wheels', 'brake" .. wheelPosName[wheelID[dev]] .. "', true)")
elseif cat == "brakeOverHeat" then
ve:queueLuaCommand("wheels.wheels[" .. wheelID[dev] .. "].padGlazingFactor=" .. tonumber(v))
ve:queueLuaCommand("damageTracker.setDamage('wheels', 'brakeOverHeat" .. wheelPosName[wheelID[dev]+1] .. "'," .. tonumber(v) .. ")")
elseif cat == "engine" then
valsplt = extensions.blrutils.ssplit(v, ",") -- true,0.5,etc..											-- Engine Damage Subcategories
if dev == "engineReducedTorque" then 																			
ve:queueLuaCommand("powertrain.getDevice('mainEngine').outputTorqueState = " .. tonumber(valsplt[2])) 	-- Set output torque state
ve:queueLuaCommand("damageTracker.setDamage('engine', 'engineReducedTorque', true)") 					-- Alert damage tracker
elseif dev == "engineDisabled" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine'):disable()")
elseif dev == "engineLockedUp" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine'):lockUp()")
elseif dev == "engineHydrolocked" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine'):lockUp()")
ve:queueLuaCommand("damageTracker.setDamage('engine', 'engineHydrolocked', true)")
elseif dev == "catastrophicOverrevDamage" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine').overRevDamage = 1")
ve:queueLuaCommand("powertrain.getDevice('mainEngine'):lockUp()")
ve:queueLuaCommand("damageTracker.setDamage('engine', 'catastrophicOverrevDamage', true)")
elseif dev == "mildOverrevDamage" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine').overRevDamage =" .. tonumber(valsplt[2])) 		-- Apply overrev damage value
ve:queueLuaCommand("powertrain.getDevice('mainEngine'):scaleOutputTorque(0.98, 0.2)")					-- Reduce torque
ve:queueLuaCommand("damageTracker.setDamage('engine', 'mildOverrevDamage', true)")						
elseif dev == "catastrophicOverTorqueDamage" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine').overTorqueDamage =" .. tonumber(valsplt[2]))
ve:queueLuaCommand("powertrain.getDevice('mainEngine'):lockUp()")
ve:queueLuaCommand("damageTracker.setDamage('engine', 'catastrophicOverTorqueDamage', true)")
elseif dev == "oilpanLeak" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine').thermals.applyDeformGroupDamageOilpan(1)")
elseif dev == "oilRadiatorLeak" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine').thermals.applyDeformGroupDamageOilRadiator(10)")
elseif dev == "headGasketDamaged" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine').thermals.headGasketBlown = true")
ve:queueLuaCommand("powertrain.getDevice('mainEngine'):scaleOutputTorque(0.8)")							-- Might need to process this before output torque state value
ve:queueLuaCommand("damageTracker.setDamage('engine', 'headGasketDamaged', true)")
elseif dev == "pistonRingsDamaged" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine').thermals.pistonRingsDamaged = true")
ve:queueLuaCommand("powertrain.getDevice('mainEngine'):scaleOutputTorque(0.8)")							-- Might need to process this before output torque state value
ve:queueLuaCommand("damageTracker.setDamage('engine', 'pistonRingsDamaged', true)")
elseif dev == "rodBearingsDamaged" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine').thermals.connectingRodBearingsDamaged = true")
ve:queueLuaCommand("damageTracker.setDamage('engine', 'rodBearingsDamaged', true)")
elseif dev == "blockMelted" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine'):scaleFriction(10000)")	
ve:queueLuaCommand("powertrain.getDevice('mainEngine').thermals.engineBlockMelted = true")
ve:queueLuaCommand("damageTracker.setDamage('engine', 'blockMelted', true)")
elseif dev == "cylinderWallsMelted" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine'):scaleFriction(10000)")	
ve:queueLuaCommand("powertrain.getDevice('mainEngine').thermals.cylinderWallsMelted = true")
ve:queueLuaCommand("damageTracker.setDamage('engine', 'cylinderWallsMelted', true)")
elseif dev == "superchargerDamaged" then
ve:queueLuaCommand("powertrain.getDevice('mainEngine').supercharger.applyDeformGroupDamage(1)")	
elseif dev == "turbochargerDamaged " then
ve:queueLuaCommand("powertrain.getDevice('mainEngine').turbocharger.applyDeformGroupDamage(1)")	
elseif dev == "impactDamage" then
-- A bunch of variables need to be fetched for this one, with minimal impact maybe not worth it for now
-- Big enough impacts will break the engine anyway 
ve:queueLuaCommand("damageTracker.setDamage('engine', 'impactDamage', true, true)")
elseif dev == "exhaustBroken" then
-- Gotta find a way to break off the exhaust if possible
else
-- Should not happen unless some sub-devices are forgotten
end

end
end
end
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
ve:queueLuaCommand("partCondition.initConditions(nil," .. odometer .. ", 1)")
ve:queueLuaCommand("controller.getAllControllers()['analogOdometer'].updateGFX(1)")

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
ve:queueLuaCommand("powertrain.getDevice('" .. mdev .. "'):setPartCondition('" .. sdev .. "'," .. odoval .. ",1)")
else
ve:queueLuaCommand("powertrain.getDevice('" .. mdev .. "'):setPartCondition(nil," .. odoval .. ",1)")
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
ve:queueLuaCommand("partCondition.initConditions(nil," .. odometer .. ", 1)")
ve:queueLuaCommand("controller.getAllControllers()['analogOdometer'].updateGFX(1)")
end

M.forceSetOdometer = forceSetOdometer
M.saveIntegrityToFile = saveIntegrityToFile
M.loadIntegrityFromFile = loadIntegrityFromFile
M.getIntegrityDevices = getIntegrityDevices
M.getNewCarMechData = getNewCarMechData
M.saveDamageToFile = saveDamageToFile
M.loadDamageFromFile = loadDamageFromFile

return M



