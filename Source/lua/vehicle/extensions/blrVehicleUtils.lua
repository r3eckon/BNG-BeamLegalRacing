local M = {}

local engineFuelType = "none"
local jbeamIO = require("jbeam/io")


local function ioCtx()
return {preloadedDirs = v.data.directoriesLoaded}
end

local function getPartJbeam(partName)
return jbeamIO.getPart(ioCtx(), partName)
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
local function getVehicleParts()
return v.data.slotPartMap
end


-- Total fuel in all tanks
local function getFuelTotal()
local storageData = energyStorage.getStorages()
local toRet = 0

for k,v in pairs(storageData) do
if v["type"] == "fuelTank" then
toRet = toRet + v["remainingVolume"]
end
end


--if storageData["mainTank"] then
--toRet = toRet + storageData["mainTank"].remainingVolume
--end

--if storageData["auxTank"] then
--toRet = toRet + storageData["auxTank"].remainingVolume
--end

return toRet
end

local function getFuelCapacityTotal()
local storageData = energyStorage.getStorages()
local toRet = 0

for k,v in pairs(storageData) do
if v["type"] == "fuelTank" then
toRet = toRet + v["capacity"]
end
end

--if storageData["mainTank"] then
--toRet = toRet + storageData["mainTank"].capacity
--end

--if storageData["auxTank"] then
--toRet = toRet + storageData["auxTank"].capacity
--end

return toRet
end

local function getEngineFuelType()
if not powertrain.getDevices()["mainEngine"] then return "none" end
return powertrain.getDevices()["mainEngine"].requiredEnergyType or "gasoline"
end

-- Need to call this on vehicle loaded and post edits so it handles engine swap
-- Called from "Force Set Fuel" function in flowgraph, not using unique node
local function loadFuelType()
engineFuelType = getEngineFuelType()
end

local wrongFuel = false

-- Disables/enables engine if incorrect fuel type detected
-- wont enable engine when tank is drained to prevent infinite fuel exploit
-- doesn't allow re-enabling engine if wrong fuel is in tank until drained
local function fuelTypeCheck(toCheck, drained)
local engine = powertrain.getDevices()["mainEngine"]
if engineFuelType == "none" then return end

--1.15 fix for removing tank not disabling engine
--properly checks for fuel tank energy type in fuel type check
local storage = energyStorage.getStorages()
local foundTank = false
for k,v in pairs(storage) do 
foundTank = v.energyType == toCheck
if foundTank then break end
end
if not foundTank then 
obj:queueGameEngineLua("guihooks.trigger('Message', {ttl = 10, msg = 'Wrong fuel used! Drain the tank to fix the engine.', icon = 'directions_car'})")
engine:disable()
return
end

if toCheck == engineFuelType and engine.isDisabled then
if not drained and not wrongFuel then
engine:enable()
end
elseif toCheck ~= engineFuelType and not engine.isDisabled then
engine:disable()
wrongFuel = true
obj:queueGameEngineLua("guihooks.trigger('Message', {ttl = 10, msg = 'Wrong fuel used! Drain the tank to fix the engine.', icon = 'directions_car'})")
end
if drained then
wrongFuel = false
end
end

local fuelTypes = {}
local fuelQuality = 1.0
local ratio_regular = 1.0
local ratio_midgrade = 0.0
local ratio_premium = 0.0

local function getFuelTypesString()
local toRet = ""
for k,v in pairs(fuelTypes) do
if v then toRet = toRet .. k .. "," end
end
if toRet == "" then toRet = "none," end
return string.sub(toRet, 1,-2)
end

-- to save fuel ratio in gelua
local function getFuelRatioString()
return "" .. ratio_regular .. "," .. ratio_midgrade .. "," .. ratio_premium
end

local function resetFuelRatio()
ratio_regular = 1.0
ratio_midgrade = 0.0
ratio_premium = 0.0
end

local function updateFuelRatio(added, tier)
local total = getFuelTotal()
local ptotal = total - added
local quant_regular = ptotal * ratio_regular
local quant_midgrade = ptotal * ratio_midgrade
local quant_premium = ptotal * ratio_premium
if tier == "regular" then
quant_regular = quant_regular + added
elseif tier == "midgrade" then
quant_midgrade = quant_midgrade + added
elseif tier == "premium" then
quant_premium = quant_premium + added
end
if total > 0 then
ratio_regular = quant_regular / total
ratio_midgrade = quant_midgrade / total
ratio_premium = quant_premium / total
end
end


local function updateFuelQuality()
fuelQuality = math.min(1.0 + 0.025 * ratio_midgrade + 0.05 * ratio_premium, 1.05)
if powertrain.getDevices()["mainEngine"] then
if not powertrain.getDevices()["mainEngine"].isDisabled then
powertrain.getDevices()["mainEngine"].outputTorqueState = fuelQuality
end
end
end

-- Adds fuel in available tanks
local function addFuel(val, fueltype, tier)
local storageData = energyStorage.getStorages()
local remainToAdd = val
local currentVal = 0
local currentCap = 0
local currentAdd = 0

for k,v in pairs(storageData) do
if v["type"] == "fuelTank" then
currentVal = v["remainingVolume"]
currentCap = v["capacity"]
currentAdd = math.min(currentCap - currentVal, remainToAdd)
v:setRemainingVolume(currentVal + currentAdd)
remainToAdd = math.max(remainToAdd - currentAdd, 0)
end
end

--Check fuel type, if wrong type is used engine will be disabled
if fueltype then 
fuelTypeCheck(fueltype, false)
fuelTypes[fueltype] = true
end

--Update fuel quality ratio
updateFuelRatio(currentAdd, tier)
updateFuelQuality()


--Return remaining value
return remainToAdd
end

-- Force set fuel total value
local function setFuel(val, fueltype, rratio, mratio, pratio, forceDisable)
local storageData = energyStorage.getStorages()
local remainToAdd = val
local currentCap = 0
local currentAdd = 0

-- This should work for all vehicles
for k,v in pairs(storageData) do
if v["type"] == "fuelTank" then
currentCap = v["capacity"]
currentAdd = math.min(currentCap, remainToAdd)
v:setRemainingVolume(currentAdd)
remainToAdd = math.max(remainToAdd - currentAdd, 0)
end
end

--Check fuel type, if wrong type is used engine will be disabled
if fueltype then 
fuelTypeCheck(fueltype, val <= 0) 
fuelTypes = {} -- Set used fuel types to a single type since this is setFuel
fuelTypes[fueltype] = true
else
fuelTypes = {} -- for loading legacy garage files, assume correct fuel type was stored
fuelTypes[engineFuelType] = true
end

--Set fuel ratio, if not specified defaults to 100% regular
ratio_regular = rratio or 1.0
ratio_midgrade = mratio or 0.0
ratio_premium = pratio or 0.0

--Tank drained, force set fuel ratios to 0
if val <= 0 then 
resetFuelRatio()
fuelTypes = {} -- reset fuel types
end

-- Has to be used when loading vehicle with mixed fuels otherwise
-- using addFuel bugs the tank volume to max capacity
if forceDisable then
fuelTypes = {gasoline = true, diesel = true}
powertrain.getDevices()["mainEngine"]:disable()
wrongFuel = true
end

updateFuelQuality()

--Return remaining value
return remainToAdd
end


local function getEnergyStorageData(storage)
local toRet = ""
local storageData = energyStorage.getStorages()[storage]
if storageData then
toRet = "true," .. storageData.capacity .. "," .. storageData.remainingVolume
else
toRet = "false"
end
return toRet
end



local smoothFuel = false
local smoothFuelLast = 0
local smoothFuelTotal = 0
local smoothFuelAllowed = 0
local smoothFuelStart = 0
local smoothFuelTier = "regular"
local smoothFuelType = "gasoline"
local function smoothRefuelToggle(toggle, allowed, fueltype, tier)
smoothFuel = toggle
if toggle then 
smoothFuelTotal = 0
smoothFuelAllowed = allowed or 999999
smoothFuelStart = getFuelTotal()
smoothFuelTier = tier or "regular"
smoothFuelType = fueltype or "gasoline"
--print("Smooth fuel start: " .. smoothFuelStart)
else 
--print("Refuel Stopped! Total added: " .. smoothFuelTotal .. "L") 
obj:queueGameEngineLua("extensions.blrutils.smoothFuelCharge(" .. smoothFuelTotal .. ")")
end
end

local function smoothRefuel(addval,delay, ct)
local capacity = getFuelCapacityTotal()
local current = getFuelTotal()
if current >= capacity - addval then
addFuel(addval * 2,smoothFuelType, smoothFuelTier) -- makes sure to top off tank in final tick
smoothFuelTotal = capacity - smoothFuelStart
smoothRefuelToggle(false)
--print("Finish car fuel: " .. smoothFuelStart + smoothFuelTotal)
elseif smoothFuelTotal >= smoothFuelAllowed then
setFuel(smoothFuelStart + smoothFuelAllowed,smoothFuelType, ratio_regular, ratio_midgrade, ratio_premium)
smoothFuelTotal = smoothFuelAllowed
smoothRefuelToggle(false)
--print("Finish car fuel: " .. smoothFuelStart + smoothFuelAllowed)
elseif ct - smoothFuelLast >= delay then
smoothFuelTotal = smoothFuelTotal + (addval - addFuel(addval,smoothFuelType, smoothFuelTier))
smoothFuelLast = ct
--print(getFuelTotal())
end
end

local function getSmoothFuelTotal()
return smoothFuelTotal
end

-- 0.36 update removed vehicleCertifications, replaced with vehiclePerformanceData.lua
-- but that script doesn't have "static" performance data anymore, using this legacy code
-- here to get these values back. script says "we can't use in the future" about this code
-- so might not work for future versions of the game at some point.
local function getPowerValues()
   local toRet = {}
   local engines = powertrain.getDevicesByCategory("engine")
   if not engines or #engines <= 0 then
     log("I", "vehicleCertifications", "Can't find any engine, not getting static performance data")
     return 0, 0
   end

   local maxRPM = 0
   local maxTorque = -1
   local maxPower = -1
   if #engines > 1 then
     local torqueData = {}
     for _, v in pairs(engines) do
       local tData = v:getTorqueData()
       maxRPM = max(maxRPM, tData.maxRPM)
       table.insert(torqueData, tData)
     end

     local torqueCurve = {}
     local powerCurve = {}
     for _, td in ipairs(torqueData) do
       local engineCurves = td.curves[td.finalCurveName]
       for rpm, torque in pairs(engineCurves.torque) do
         torqueCurve[rpm] = (torqueCurve[rpm] or 0) + torque
       end
       for rpm, power in pairs(engineCurves.power) do
         powerCurve[rpm] = (powerCurve[rpm] or 0) + power
       end
     end
     for _, torque in pairs(torqueCurve) do
       maxTorque = max(maxTorque, torque)
     end
     for _, power in pairs(powerCurve) do
       maxPower = max(maxPower, power)
     end
   else
     local torqueData = engines[1]:getTorqueData()
     maxRPM = torqueData.maxRPM
     maxTorque = torqueData.maxTorque
     maxPower = torqueData.maxPower
   end

	toRet["power"] = maxPower
	toRet["torque"] = maxTorque
	toRet["rpm"] = maxRPM
   return toRet
end


local function getLegacyCertifications()
local toRet = {}
local staticData = extensions.vehiclePerformanceData.getStaticData()
local powerValues = getPowerValues()

for k,v in pairs(staticData) do
toRet[k] = v
end

for k,v in pairs(powerValues) do
toRet[k] = v
end

return toRet
end


local function getPowertrainLayoutName()
local layout = getLegacyCertifications()["powertrainLayout"]
local toRet = ""
if layout["poweredWheelsFront"] == 0 and layout["poweredWheelsRear"] == 0 then
toRet = "ERROR"
elseif layout["poweredWheelsFront"] == 0 then
toRet = "RWD"
elseif layout["poweredWheelsRear"] == 0 then
toRet = "FWD"
else
toRet = "AWD"
end
return toRet
end

local function getRawPerformanceValue()
local cdata = getLegacyCertifications()
local horsepower = cdata["power"]
local torque = cdata["torque"]
local weight = cdata["weight"]
return ((torque / 3.0) + horsepower) / (weight / 2.0)
end


local function getPerformanceClass()
local pvalue = getRawPerformanceValue()
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

local function advancedCouplersFix()
local couplers = controller.getControllersByType("advancedCouplerControl")
local lastid = -1 -- To properly fix hood couplers
for k,v in pairs(couplers) do
if v.name ~= "hoodLatchCoupler" then
v:reset()
v:tryAttachGroupImpulse()
else
lastid = k
end
end
if lastid ~= -1 then
couplers[lastid]:reset()
couplers[lastid]:tryAttachGroupImpulse()
end
end

local function getInductionType()
local induction = getLegacyCertifications()["inductionType"]
local natural = induction["naturalAspiration"]
local nitrous = induction["N2O"]
local supercharged = induction["supercharger"]
local turbocharged = induction["turbocharger"]
local toRet = ""
if natural and not (supercharged or turbocharged) then
toRet = "NA"
elseif supercharged then
toRet = "SC"
elseif turbocharged then
toRet = "Turbo"
end
if nitrous then
toRet = toRet .. "+N2O"
end
return toRet
end

local function getForceVectorLength()
local gx, gy, gz = sensors.gx, sensors.gy, sensors.gz
local length = math.sqrt((gx*gx) + (gy*gy) + (gz*gz))
return length
end

local function getPerformanceData()
local cdata = getLegacyCertifications()
local horsepower = cdata["power"]
local torque = cdata["torque"]
local weight = cdata["weight"]
local class = getPerformanceClass()
local value = getRawPerformanceValue()
return "" .. horsepower .. "," .. torque .. "," .. weight .. "," .. class .. "," .. value
end

local force = 0
local velocity = vec3({0,0,0})
local velocityLast = vec3({0,0,0})
local forcevector = vec3({0,0,0})
local ctime = 0


local function updateGFX(dtSim)
ctime = ctime + dtSim
velocityLast = velocity
velocity = obj:getVelocity()
if dtSim == 0 then
force = 0
else
forcevector = vec3({ (velocity["x"] - velocityLast["x"]) / dtSim, (velocity["y"] - velocityLast["y"]) / dtSim, (velocity["z"] - velocityLast["z"]) / dtSim - 9.81 })
force = forcevector:length()
end
if smoothFuel then
smoothRefuel(0.1, 0.05, ctime)
end
end

local function getAcceleration()
return force
end

local function toggleNitrous()
for k,v in pairs(controller.getControllersByType("nitrousOxideInjection")) do v:toggleActive() end
end

local function getNitrousRemainingVolume(bottle)
if not bottle then bottle = "mainBottle" end
local toRet = 0
if energyStorage then
if energyStorage.getStorage(bottle) then
toRet =  energyStorage.getStorage(bottle).remainingMass
end
end
return toRet
end

local function getNitrousCapacity(bottle)
if not bottle then bottle = "mainBottle" end
local toRet = 0
if energyStorage then
if energyStorage.getStorage(bottle) then
toRet =  energyStorage.getStorage(bottle).capacity
end
end
return toRet
end

-- 1.18 breakable beam issue: for some reason legran (that i know of) now (used to work fine afaik) has 2 nodes 
-- that are on the door but has the mirror itself as part origin, where mirror connects to door, 
-- connecting to another node on the door so two beams never get broken even if mirror is completely pulled off
-- keeping things as is for now, should only result in slightly less repair cost for some parts that have this
-- problem, only solution would be to keep a % of breakable beams but then it makes it so ex: bumper that isn't
-- fully ripped off has the full repair cost
local function getBreakableBeamCount(part)
local beams = v.data.beams
local nodes = v.data.nodes
local partBeams = {}
local cid1, cid2
local count = 0

for k,v in pairs(beams) do
if v["partOrigin"] == part then
table.insert(partBeams, v)
end
end

for k,v in pairs(partBeams) do
cid1 = v["id1"]
cid2 = v["id2"]
if v["beamType"] ~= 7 then
if nodes[cid1].partOrigin ~= part or nodes[cid2].partOrigin ~= part then
count = count+1
end
end
end

return count
end

local function getDeformableBeamCount(part)
local beams = v.data.beams
local nodes = v.data.nodes
local partBeams = {}
local cid1, cid2
local count = 0

for k,v in pairs(beams) do
if v["partOrigin"] == part then
table.insert(partBeams, v)
end
end

for k,v in pairs(partBeams) do
count = count+1
end

return count
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

local breakBeamCount = {}
local deformBeamCount = {}
local partPrices = {}

-- 1.18 fix, using part paths, need to grab last part of path to find part name 
-- for deformable and breakable beam lookup
local function buildAdvancedDamageTables()
local beamData = beamstate.getPartDamageTable()
local customPrices = loadTableFromFile("beamLR/partprices", true)
local cpart = ""
breakBeamCount = {}
deformBeamCount = {}
partPrices = {}

for k,v in pairs(beamData) do
csplit = ssplit(k, "/")
cpart = csplit[#csplit]
breakBeamCount[k] = getBreakableBeamCount(cpart)
deformBeamCount[k] = getDeformableBeamCount(cpart)
partPrices[k] = customPrices[cpart] or beamData[k].value 

--print("BEAM COUNT DEBUG FOR PART: " .. k .. "," .. breakBeamCount[k] .. "," .. deformBeamCount[k] .. "," .. partPrices[k])

end

--dump(breakBeamCount)
--dump(deformBeamCount)
--dump(partPrices)

end

-- 1.17.5 part odometer scaled repair cost
local inventoryLinksData = {}
local inventoryData = {}

local function getScaledPartPrice(value, odometer)
local toRet = 1.0

if odometer >= 30000000 then
toRet = 0.9 - (0.8 * (math.min(1.0, odometer / 250000000)))
end

return toRet * value
end

local function getPartOdometer(link_key)
if not (inventoryData and inventoryLinksData[link_key]) then return 0 end
return inventoryData[inventoryLinksData[link_key][1]][2]
end


local function getAdvancedRepairCost(dbg)
local beamData = beamstate.getPartDamageTable()
local toRet = 0
local cbdmg = 0 -- deform damage percent
local cddmg = 0 -- break damage percent
local ctdmg = 0 -- total damage percent
local cbroken = 0 -- broken count
local cdeformed = 0 -- deformed count
local cdcount = 0 -- deformable count
local cbcount = 0 -- breakable count

local codo = 0 -- 1.17.5 part odometer value scaling

if dbg then print("ADVANCED DAMAGE DEBUG") end

for k,v in pairs(beamData) do
cbroken = v["beamsBroken"] or 0
cdeformed = v["beamsDeformed"] or 0
cdcount = deformBeamCount[k] or 0
cbcount = breakBeamCount[k] or 0
cbdmg = 0
cddmg = 0
ctdmg = 0

codo = getPartOdometer(k) or 0

if cbcount > 0 then
cbdmg = math.min(1.0, cbroken / cbcount)
else
cbdmg = 0
end
if cdcount > 0 then
cddmg = math.min(1.0, cdeformed / cdcount )
else
cddmg = 0
end
if cbdmg + cddmg > 0 then
ctdmg = math.min(1.0, math.max(cbdmg, cddmg))
else
ctdmg = 0
end
if ctdmg > 0 then
toRet = toRet + getScaledPartPrice(partPrices[k],codo) * (ctdmg*ctdmg*ctdmg)
if dbg then print(k .. "\tCBCOUNT=" .. cbcount .. "\tCBROKEN=" .. cbroken  .. "\tCDCOUNT=" .. cdcount  .. "\tCDEFORMED=" .. cdeformed  .. "\tCTDMG=" .. ctdmg  .. "\tVALUE=" .. partPrices[k]  .. "\tTOTAL=" .. toRet) end
end
end

return toRet
end

local function getAdvancedRepairString()
local beamData = beamstate.getPartDamageTable()
local toRet = ""
local cbdmg = 0 -- deform damage percent
local cddmg = 0 -- break damage percent
local ctdmg = 0 -- total damage percent
local cbroken = 0 -- broken count
local cdeformed = 0 -- deformed count
local cdcount = 0 -- deformable count
local cbcount = 0 -- breakable count
local ccost = 0

local codo = 0 -- 1.17.5 odo scaling for part repair cost

for k,v in pairs(beamData) do
cbroken = v["beamsBroken"] or 0
cdeformed = v["beamsDeformed"] or 0
cdcount = deformBeamCount[k] or 0
cbcount = breakBeamCount[k] or 0
cbdmg = 0
cddmg = 0
ctdmg = 0

codo = getPartOdometer(k) or 0

if cbcount > 0 then
cbdmg = math.min(1.0, cbroken / cbcount)
else
cbdmg = 0
end
if cdcount > 0 then
cddmg = math.min(1.0, cdeformed / cdcount )
else
cddmg = 0
end
if cbdmg + cddmg > 0 then
ctdmg = math.min(1.0, math.max(cbdmg, cddmg))
else
ctdmg = 0
end
if ctdmg > 0 then
ccost = getScaledPartPrice(partPrices[k],codo) * (ctdmg*ctdmg*ctdmg)
toRet = toRet .. k .. ":" .. string.format("%.2f",ccost) .. ","
end
end

toRet = string.sub(toRet, 1,-2)

return toRet
end

-- below code is useless, found a better way to do it, keeping in case it is needed later

-- for quick traffic toggle, to remove light glow, must be used before setHidden
--local function toggleAllProps(toggle)
--for k,prop in pairs(v.data.props) do 
--if prop then 
--prop.disabled = not toggle
--obj:propUpdate(k, 0, 0, 0, 0, 0, 0, false, 0, 0) 
--end 
--end
--end

-- Advanced ghost mode disables sounds, props and collisions
-- for quicker traffic toggle
--local function toggleAdvancedGhostMode(toggle)
--local ttext = (toggle and "true") or "false"
--toggleAllProps(not toggle)
--sounds.setEnabled(not toggle)
--obj:setGhostEnabled(toggle)
--obj:queueGameEngineLua(string.format("scenetree.findObjectById(%d):setHidden(%s)", obj:getId(), ttext))
--end

--M.toggleAdvancedGhostMode = toggleAdvancedGhostMode
--M.toggleAllProps = toggleAllProps


--1.14.3 fixes to avoid errors with nil fields
local function loadOdometer()
if controller.getAllControllers()['analogOdometer'] then
controller.getAllControllers()['analogOdometer'].updateGFX(1)
end
end


local function setPartCondition(mainDevice, subDevice, odometer, integrity)
if powertrain.getDevice(mainDevice) then
powertrain.getDevice(mainDevice):setPartCondition(subDevice,odometer,integrity)
end
end

local wheelName = { "wheel_FR", "wheel_FL", "wheel_RR", "wheel_RL"} -- Breakgroups
local wheelPosName = {"FR", "FL", "RR" , "RL"}
local wheelID = {FR = 0, FL = 1, RR = 2, RL = 3}

local function buildWheelTables()
wheelName = {}
wheelPosName = {}
wheelID = {}
for k,v in pairs(wheels.wheels) do
wheelName = "wheel_" .. v.name
wheelPosName = v.name
wheelID[wheelPosName] = v.id
end
end

-- 1.17.4 manual gearbox synchro wear
local function setGearboxSynchroWear(wear)
local gearbox = powertrain.getDevice("gearbox")
local gtype = gearbox.type
local cindex = gearbox.gearIndex

-- no synchros on other types of gearboxes
if gtype ~= "manualGearbox" then return end

local gcount = gearbox.gearCount

-- force update all gear synchros to use new damage values
for i=-1,gcount-1 do -- start at -1 for reverse gear
if i ~= 0 then -- must skip neutral to avoid errors
gearbox.synchroWear[i] = wear[i]
gearbox.isGrindingShift=true
gearbox:setGearGrinding(true,i,0)
gearbox:updateGrinding(0)
end
end

-- restore last gear index because it got changed
gearbox:setGearIndex(cindex) 
end


-- 1.14.3 fix for nil devices when some parts are removed
local function loadMechanicalDamage(file)
local dt = loadTableFromFile(file, false)
local cat = ""
local dev = ""
local split = {}
local valsplt = {}
local nval = 0
local synchroWear = {0,0,0,0,0,0,0,[-1]=0}

-- 1.13.4 now fetching wheel data to build tables
buildWheelTables()

for k,v in pairs(dt) do
	if not string.match(v,"false") then 
		split = ssplit(k, ".")
		cat = split[1]
		dev = split[2]

		if cat == "powertrain" then
			if powertrain.getDevice(dev) then
				powertrain.breakDevice(powertrain.getDevice(dev))
			end
		elseif cat == "wheels" then
			if wheels.wheels[wheelID[dev]] then
				beamstate.breakBreakGroup(wheelName[wheelID[dev]+1])
			end
		elseif cat == "tire" then
			if wheels.wheels[wheelID[dev]] then
				beamstate.deflateTire(wheelID[dev])
			end
		elseif cat == "brake" then
			if wheels.wheels[wheelID[dev]] then
				wheels.wheels[wheelID[dev]].isBrakeMolten=true
				damageTracker.setDamage('wheels', 'brake' .. wheelPosName[wheelID[dev]], true)
			end
		elseif cat == "brakeOverHeat" then
			if wheels.wheels[wheelID[dev]] then
				wheels.wheels[wheelID[dev]].padGlazingFactor= tonumber(v)
				damageTracker.setDamage('wheels', 'brakeOverHeat' .. wheelPosName[wheelID[dev]+1],tonumber(v))
			end
		elseif cat == "engine" and powertrain.getDevice('mainEngine') then
			valsplt = ssplit(v, ",") -- true,0.5,etc..											-- Engine Damage Subcategories
			if dev == "engineReducedTorque" then 																		
				powertrain.getDevice('mainEngine').outputTorqueState = tonumber(valsplt[2]) 	-- Set output torque state
				damageTracker.setDamage('engine', 'engineReducedTorque', true)-- Alert damage tracker 					
			elseif dev == "engineDisabled" then
				powertrain.getDevice('mainEngine'):disable()
			elseif dev == "engineLockedUp" then
				powertrain.getDevice('mainEngine'):lockUp()
			elseif dev == "engineHydrolocked" then
				powertrain.getDevice('mainEngine'):lockUp()
				damageTracker.setDamage('engine', 'engineHydrolocked', true)
			elseif dev == "catastrophicOverrevDamage" then
				powertrain.getDevice('mainEngine').overRevDamage = 1
				powertrain.getDevice('mainEngine'):lockUp()
				damageTracker.setDamage('engine', 'catastrophicOverrevDamage', true)
			elseif dev == "mildOverrevDamage" then
				powertrain.getDevice('mainEngine').overRevDamage = tonumber(valsplt[2]) 		-- Apply overrev damage value
				powertrain.getDevice('mainEngine'):scaleOutputTorque(0.98, 0.2)					-- Reduce torque
				damageTracker.setDamage('engine', 'mildOverrevDamage', true)						
			elseif dev == "catastrophicOverTorqueDamage" then
				powertrain.getDevice('mainEngine').overTorqueDamage = tonumber(valsplt[2])
				powertrain.getDevice('mainEngine'):lockUp()
				damageTracker.setDamage('engine', 'catastrophicOverTorqueDamage', true)
			elseif dev == "oilpanLeak" then
				powertrain.getDevice('mainEngine').thermals.applyDeformGroupDamageOilpan(1)
			elseif dev == "oilRadiatorLeak" then
				powertrain.getDevice('mainEngine').thermals.applyDeformGroupDamageOilRadiator(1)
			elseif dev == "radiatorLeak" then
				powertrain.getDevice('mainEngine').thermals.applyDeformGroupDamageRadiator(1)	
			elseif dev == "headGasketDamaged" then
				powertrain.getDevice('mainEngine').thermals.headGasketBlown = true
				powertrain.getDevice('mainEngine'):scaleOutputTorque(0.8)						-- Might need to process this before output torque state value
				damageTracker.setDamage('engine', 'headGasketDamaged', true)
			elseif dev == "pistonRingsDamaged" then
				powertrain.getDevice('mainEngine').thermals.pistonRingsDamaged = true
				powertrain.getDevice('mainEngine'):scaleOutputTorque(0.8)						-- Might need to process this before output torque state value
				damageTracker.setDamage('engine', 'pistonRingsDamaged', true)
			elseif dev == "rodBearingsDamaged" then
				powertrain.getDevice('mainEngine').thermals.connectingRodBearingsDamaged = true
				damageTracker.setDamage('engine', 'rodBearingsDamaged', true)
			elseif dev == "blockMelted" then
				powertrain.getDevice('mainEngine'):scaleFriction(10000)	
				powertrain.getDevice('mainEngine').thermals.engineBlockMelted = true
				damageTracker.setDamage('engine', 'blockMelted', true)
			elseif dev == "cylinderWallsMelted" then
				powertrain.getDevice('mainEngine'):scaleFriction(10000)	
				powertrain.getDevice('mainEngine').thermals.cylinderWallsMelted = true
				damageTracker.setDamage('engine', 'cylinderWallsMelted', true)
			elseif dev == "superchargerDamaged" then
				powertrain.getDevice('mainEngine').supercharger.applyDeformGroupDamage(1)
			elseif dev == "turbochargerDamaged " then
				powertrain.getDevice('mainEngine').turbocharger.applyDeformGroupDamage(1)
			elseif dev == "impactDamage" then
				-- A bunch of variables need to be fetched for this one, with minimal impact maybe not worth it for now
				-- Big enough impacts will break the engine anyway 
				damageTracker.setDamage('engine', 'impactDamage', true, true)
			elseif dev == "exhaustBroken" then
			-- Gotta find a way to break off the exhaust if possible
			else
			-- Should not happen unless some sub-devices are forgotten
			end
		-- 1.17.4 manual gearbox synchro wear	
		elseif cat == "gearbox" and powertrain.getDevice('gearbox') and powertrain.getDevice('gearbox').type == "manualGearbox" then
			local gindex = string.gsub(dev, "synchro_", "")
			gindex = tonumber(gindex)
			if gindex < powertrain.getDevice('gearbox').gearCount then
				synchroWear[gindex] = tonumber(v or "0") -- default to 0% wear 
			end
		end
	end
end
-- 1.17.4 gearbox synchro wear loading
setGearboxSynchroWear(synchroWear)
end

--Not sure why this is needed but disassembled vehicles aren't registered
--on map.objects list and return nil position/rotation causing vehicles that
--spawn from garage after using this one to spawn at 0,0,0 and fall forever
local function forceMapInit()
mapmgr.enableTracking("clone")
mapmgr.sendTracking()
end

-- Called from item use flowgraph, calls back to GE to update item after usage
local function useFuelCanister(itemkey, ftype, ftier, quantity)
local remain = addFuel(quantity, ftype, ftier)
local used = quantity-remain
local engine = powertrain.getDevices()["mainEngine"]
local disabled = "false"
if engine.isDisabled then disabled = "true" end
obj:queueGameEngineLua("extensions.blrVehicleCallbacks.usedFuelcan('" .. itemkey .. "'," .. used .. "," .. disabled .. ")")
end

local function setOilLeak(rate)
if powertrain and powertrain.getDevice("mainEngine") then
local current = powertrain.getDevice("mainEngine").thermals.fluidLeakRates.oil.oilpan --math.max so if oilpan is damaged odometer leak doesn't reset it
powertrain.getDevice("mainEngine").thermals.fluidLeakRates.oil.oilpan = math.max(rate, current)
else
print("setOilLeak didn't find mainEngine device, skipping.\nThis is normal if vehicle has no engine.")
end
end

local function getOilLeak()
if powertrain and powertrain.getDevice("mainEngine") then
return powertrain.getDevice("mainEngine").thermals.fluidLeakRates.oil.oilpan
else
print("getOilLeak didn't find mainEngine device, using 0 as fallback.\nThis is normal if vehicle has no engine.")
return 0
end
end

-- used to avoid spamming console with warnings about missing mainEngine device
local oilCurrentWarn = false
local oilInitialWarn = false

-- 1kg = ~1.1L
local function getOilVolumeCurrent()
if powertrain and powertrain.getDevice("mainEngine") then
return powertrain.getDevice("mainEngine").thermals.fluidReservoirs.oil.currentMass * 1.1
else
if not oilCurrentWarn then
print("getOilVolumeCurrent didn't find mainEngine device, using 0 as fallback.\nThis is normal if vehicle has no engine.")
oilCurrentWarn = true
end
return 0
end
end

-- This is the quantity used when refilling oil
local function getOilVolumeInitial()
if powertrain and powertrain.getDevice("mainEngine") then
return powertrain.getDevice("mainEngine").thermals.fluidReservoirs.oil.initialMass * 1.1
else
if not oilInitialWarn then
print("getOilVolumeInitial didn't find mainEngine device, using 0 as fallback.\nThis is normal if vehicle has no engine.")
oilInitialWarn = true
end
return 0
end
end

local function setOilVolume(liters)
if liters < 0 then -- for compatibility with old saves, -1 val to use initial value
liters = getOilVolumeInitial()
end
if powertrain and powertrain.getDevice("mainEngine") then
powertrain.getDevice("mainEngine").thermals.fluidReservoirs.oil.currentMass = (liters / 1.1)
else
print("setOilVolume didn't find mainEngine device, skipping.\nThis is normal if vehicle has no engine.")
end
end

local function refillOil(toadd)
local target = getOilVolumeInitial()
local current = getOilVolumeCurrent()
local needed = target - current
local added = math.min(toadd, needed)
setOilVolume(current + added)
return toadd - added -- return quantity remaining in bottle
end


local function useOilBottle(itemkey, brand, grade, quantity)
if powertrain and powertrain.getDevice("mainEngine") then
local remain = refillOil(quantity)
local used = quantity-remain
obj:queueGameEngineLua("extensions.blrVehicleCallbacks.usedOilBottle('" .. itemkey .. "'," .. used .. ")")
else
print("Couldn't use oil bottle, unable find mainEngine powertrain device!")
end
end

local function getIntegrityOffset(odometer)
local offset = 0
local minimum = 200000000
local maximum = 450000000
if odometer >= minimum then
offset = 0.15 * math.min(1.0, (odometer-minimum) / (maximum-minimum))
end
return offset
end

local advancedPartConditions = {}

local function setAdvancedPartCondition(part, odometer, integrity)
advancedPartConditions[part] = {}
advancedPartConditions[part].odometer = odometer
if string.find(part, "radiator") then -- avoid causing radiator leak due to odometer
advancedPartConditions[part].integrityValue = integrity
else
advancedPartConditions[part].integrityValue = integrity - getIntegrityOffset(odometer) -- decrease integrity for high odometer parts
end
advancedPartConditions[part].visualValue = "a" -- if visual value is a number paint bug happens, using string to disable paint integrity
print("Set part condition for " .. part .. " to " .. odometer .. " odometer and " .. integrity .. " integrity")
end

local function applyAdvancedPartConditions()
partCondition.reset()
partCondition.initConditions(advancedPartConditions, 0.0, 1.0, "a", nil)
advancedPartConditions = {}
print("Should have applied part conditions!")
end



local integrityUpdateQueue = {}

local function queueIntegrityUpdate(id, part)
integrityUpdateQueue[id] = part
print("QUEUED INTEGRITY UPDATE FOR ID " .. id .. " PART NAME " .. part)
end


local function executeIntegrityUpdate()
local conditions = partCondition.getConditions()
local integrity = 0

if (not conditions) or (type(conditions) ~= "table") then
partCondition.initConditions(nil, 0.0, 1.0, "a", nil)
print("PART CONDITIONS TABLE WAS MISSING OR RETURNED false! Calling initConditions with 0 odo, 1 integrity.\nThis shouldn't happen, likely caused by broken save files.")
end

-- key is is inventory id, value is part name
for k,v in pairs(integrityUpdateQueue) do
	if conditions[v] then
		-- math.min to avoid cases where increased odometer would restore more integrity than was removed
		integrity = math.min(1.0, conditions[v].integrityValue + getIntegrityOffset(conditions[v].odometer))
		print("PART CONDITION FOR " .. v .. "=" .. integrity)
	else
		integrity = 1
		print("MISSING PART CONDITION FOR " .. v)
	end
obj:queueGameEngineLua("extensions.blrPartInventory.setPartIntegrity(" .. k .. "," .. integrity .. ")")
end

integrityUpdateQueue = {}
end



-- now that mod has part specific odometer values we can calculate oil leak rate
-- for both engine and oilpan separately so replacing oilpan will slow the leak
local function getOilLeakRatio()
local clues = extensions.blrPowertrainClues.getClues()
local conditions = partCondition.getConditions()
local oilpanPart = clues["oilpan"]
local enginePart = clues["engine"]
local oilpanOdo = 0
local engineOdo = 0
local engineRatio = 0
local oilpanRatio = 0

if enginePart and conditions[enginePart] then
engineOdo = conditions[enginePart].odometer
else
engineOdo = 0
print("getOilLeakRatio had no condition or clue data for the engine, odo set to 0 as fallback.\nThis is normal if vehicle has no engine.")
end


-- oilpan is not separate from engine
if oilpanPart == enginePart then
	
	engineRatio = math.min(engineOdo / 200000000.0, 2.0) * 1.0  -- 100% of leak from engine
	oilpanRatio = 0

	if engineOdo < 100000000.0 then engineRatio = 0 end

else -- oilpan is separate from engine

	if oilpanPart then 
	
		if conditions[oilpanPart] then
			oilpanOdo = conditions[oilpanPart].odometer
		else
			oilpanOdo = 0
			print("getOilLeakRatio had no condition data for the oilpan, odo set to 0 as fallback.\n This shouldn't happen.")
		end

		engineRatio = math.min(engineOdo / 200000000.0, 2.0) * 0.3 -- 30% of oil leak from engine
		oilpanRatio = math.min(oilpanOdo / 200000000.0, 2.0) * 0.7 -- 70% of oil leak from oilpan

		if oilpanOdo < 100000000.0 then oilpanRatio = 0 end
		if engineOdo < 100000000.0 then engineRatio = 0 end

	else -- if vehicle has no oilpan, leak all oil very fast
		oilpanRatio = 1000.0
		engineRatio = 0.0
	end

end

return engineRatio, oilpanRatio
end

local function updateOilLeakRate()
local engineRatio, oilpanRatio = getOilLeakRatio()
local ratio = engineRatio + oilpanRatio
local baserate = getOilVolumeInitial() / 3600.0 -- calculate a base leak rate for engine which leaks all oil in 1 hour
local leak = ratio * baserate
setOilLeak(leak)
obj:queueGameEngineLua("extensions.mechDamageLoader.oilLeakMessage(" .. engineRatio .. "," .. oilpanRatio .. ")")
end



-- calculate "coolness" rating based on performance and looks
local function getCarMeetRatingData()
local final = 0
local ratingData = {}
ratingData["details"] = {}


-- deal with raw performance scoring
local pval = getRawPerformanceValue()
local prel = math.min(1.0, pval / 5.0) -- 100% performance rating if val >= 5.0, a maxed out, stripped down drag scintilla can hit 6.0
local pscore = 10000 * prel -- score up to 10000 for max performance
final = final + pscore
ratingData["details"]["performance"] = pscore


-- deal with powertrain clues scoring, +100 points for each device
local clues = extensions.blrPowertrainClues.getClues()
if clues["turbocharger"] 
then final = final + 100 
ratingData["details"]["turbocharger"] = 100
end
if clues["supercharger"] then 
final = final + 100 
ratingData["details"]["supercharger"] = 100
end
if clues["nitrous"] then 
ratingData["details"]["nitrous"] = 100
final = final + 100 
end


-- deal with specific parts
local parts = v.config.parts
for k,v in pairs(parts) do


if string.find(v, "spoiler") or string.find(v, "wing") then -- spoiler
ratingData["details"]["spoiler"] = (ratingData["details"]["spoiler"] or 0) + 50
final = final + 50 
end
if string.find(v, "underglow") then -- neons
ratingData["details"]["underglow"] = (ratingData["details"]["underglow"] or 0) + 50
final = final + 50 
end
if string.find(v, "splitter") or string.find(v, "_lip") then -- splitter or lip
ratingData["details"]["lip"] = (ratingData["details"]["lip"] or 0) + 50
final = final + 50 
end
if string.find(v, "race_seat") or string.find(v,"seat_race") or string.find(v, "seat_FL_race") or string.find(v,"seat_FR_race") then -- race seats
ratingData["details"]["race_seat"] = (ratingData["details"]["race_seat"] or 0) + 50
final = final + 50 
end
if string.find(v, "strut_bar") then -- strut bar
ratingData["details"]["strut_bar"] = (ratingData["details"]["strut_bar"] or 0) + 50
final = final + 50 
end
if string.find(v, "rollcage") then -- rollcage
ratingData["details"]["rollcage"] = (ratingData["details"]["rollcage"] or 0) + 50
final = final + 50 
end
if string.find(k, "paint_design") and v~="none" and v ~= "" and not string.find(v, "_old") then -- paint design (avoid old paint skin)
ratingData["details"]["paint"] = 50
final = final + 50 
end
-- could add more of these later if I think of other cool/race/ricer parts

-- now checking for carbon fiber parts and adding score for each part
if string.find(v, "CF") or string.find(v, "carbon") then
ratingData["details"]["carbon"] = (ratingData["details"]["carbon"] or 0) + 50
final = final + 50 
end

end


ratingData["model"] = v.vehicleDirectory:gsub("/vehicles/", ""):gsub("/", "")
ratingData["total"] = final
return ratingData
end




-- opens hood for showoff during car meet, works even for rear/mid engine cars
local function openCarMeetLatches()
local controllers = controller.getAllControllers()
local model = v.vehicleDirectory:gsub("/vehicles/", ""):gsub("/", "")
local parts = v.config.parts

-- build table of potential latches and catches for all vehicle types
local latch_rear = {}
table.insert(latch_rear, controllers.tailgateLatchCoupler)
table.insert(latch_rear, controllers.tailgateLatch)
table.insert(latch_rear, controllers.tailgateCoupler)
table.insert(latch_rear, controllers.decklidCoupler)

local catch_rear = {}
table.insert(catch_rear, controllers.tailgateCatchCoupler)
table.insert(catch_rear, controllers.tailgateCatch)

local latch_front = {}
table.insert(latch_front, controllers.hoodLatchCoupler)
table.insert(latch_front, controllers.hoodLatch)
table.insert(latch_front, controllers.hoodCoupler)

local catch_front = {}
table.insert(catch_front, controllers.hoodCatchCoupler)
table.insert(catch_front, controllers.hoodCatch)


-- first open up hood to show engine
if model == "bolide" or model == "scintilla" or model=="sbr" or model == "autobello" then
for k,v in pairs(latch_rear) do v.detachGroup() end
for k,v in pairs(catch_rear) do v.detachGroup() end
elseif model == "covet" then
if parts["covet_body"] == "covet_body_mid" then
for k,v in pairs(latch_rear) do v.detachGroup() end
for k,v in pairs(catch_rear) do v.detachGroup() end
else
for k,v in pairs(latch_front) do v.detachGroup() end
for k,v in pairs(catch_front) do v.detachGroup() end
end
else
for k,v in pairs(latch_front) do v.detachGroup() end
for k,v in pairs(catch_front) do v.detachGroup() end
end


end


local function sendMeetScoreData(index)
local scoredata = jsonEncode(getCarMeetRatingData())
obj:queueGameEngineLua("extensions.blrCarMeet.onCarMeetScoreReceived(" .. index ..",'" .. scoredata .. "')")
end


local function getGearboxSynchroTotalWear()
local gearbox = powertrain.getDevice("gearbox")
if not gearbox then return 0 end
local gtype = gearbox.type
local toRet = 0

local wear = 0


if gtype == "manualGearbox" then
local gcount = gearbox.gearCount

for i=-1,gcount-1 do 
if i ~= 0 then
wear = wear + gearbox.synchroWear[i]
end
end

toRet = wear / gcount
end


return toRet
end






local function resetInventoryData()
inventoryLinksData = {}
inventoryData = {}
end

local function receiveInventoryData(pid, inv_type, inv_odo, inv_int, inv_use, link_odo)
inventoryData[pid] = {inv_type,inv_odo,inv_int,inv_use}
inventoryLinksData[inv_type] = {pid, link_odo}
end

local function dumpInventoryData()
dump(inventoryData)
dump(inventoryLinksData)
end




M.getVehicleParts = getVehicleParts
M.getLegacyCertifications = getLegacyCertifications
M.getScaledPartPrice = getScaledPartPrice
M.dumpInventoryData = dumpInventoryData
M.resetInventoryData = resetInventoryData
M.receiveInventoryData = receiveInventoryData
M.getIntegrityOffset = getIntegrityOffset
M.getGearboxSynchroTotalWear = getGearboxSynchroTotalWear
M.setGearboxSynchroWear = setGearboxSynchroWear
M.sendMeetScoreData = sendMeetScoreData
M.openCarMeetLatches = openCarMeetLatches
M.getCarMeetRatingData = getCarMeetRatingData
M.getOilLeakRatio = getOilLeakRatio
M.cachePartConditions = cachePartConditions
M.cachePowertrainClues = cachePowertrainClues
M.executeIntegrityUpdate = executeIntegrityUpdate
M.queueIntegrityUpdate = queueIntegrityUpdate
M.setAdvancedPartCondition = setAdvancedPartCondition
M.applyAdvancedPartConditions = applyAdvancedPartConditions
M.useOilBottle = useOilBottle
M.updateOilLeakRate = updateOilLeakRate
M.refillOil = refillOil
M.getOilVolumeInitial = getOilVolumeInitial
M.getOilVolumeCurrent = getOilVolumeCurrent
M.setOilVolume = setOilVolume
M.setOilLeak = setOilLeak
M.useFuelCanister = useFuelCanister
M.forceMapInit = forceMapInit
M.loadMechanicalDamage = loadMechanicalDamage
M.setPartCondition = setPartCondition
M.loadOdometer = loadOdometer
M.getFuelTypesString = getFuelTypesString
M.resetFuelRatio = resetFuelRatio
M.getFuelRatioString = getFuelRatioString
M.loadFuelType = loadFuelType
M.getEngineFuelType = getEngineFuelType
M.smoothRefuelToggle = smoothRefuelToggle
M.getAdvancedRepairString = getAdvancedRepairString
M.buildAdvancedDamageTables = buildAdvancedDamageTables
M.getAdvancedRepairCost = getAdvancedRepairCost
M.loadTableFromFile = loadTableFromFile
M.getDeformableBeamCount = getDeformableBeamCount
M.getBreakableBeamCount = getBreakableBeamCount
M.getNitrousCapacity = getNitrousCapacity
M.getNitrousRemainingVolume = getNitrousRemainingVolume
M.toggleNitrous = toggleNitrous
M.getAcceleration = getAcceleration
M.updateGFX = updateGFX
M.getPerformanceData = getPerformanceData
M.getForceVectorLength = getForceVectorLength
M.getInductionType = getInductionType
M.advancedCouplersFix = advancedCouplersFix
M.getPowertrainLayoutName = getPowertrainLayoutName
M.getRawPerformanceValue = getRawPerformanceValue
M.getPerformanceClass = getPerformanceClass
M.getFuelCapacityTotal = getFuelCapacityTotal
M.getFuelTotal = getFuelTotal
M.setFuel = setFuel
M.addFuel = addFuel
M.getEnergyStorageData = getEnergyStorageData
M.getSmoothFuelTotal = getSmoothFuelTotal

return M