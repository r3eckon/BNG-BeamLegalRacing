local M = {}

local engineFuelType = "none"

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
fuelQuality = math.min(1.0 + 0.1 * ratio_midgrade + 0.2 * ratio_premium, 1.2)
if not powertrain.getDevices()["mainEngine"].isDisabled then
powertrain.getDevices()["mainEngine"].outputTorqueState = fuelQuality
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


local function getPowertrainLayoutName()
local layout = extensions.vehicleCertifications.getCertifications()["powertrainLayout"]
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
local cdata = extensions.vehicleCertifications.getCertifications()
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
local induction = extensions.vehicleCertifications.getCertifications()["inductionTypes"]
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
local cdata = extensions.vehicleCertifications.getCertifications()
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

local function buildAdvancedDamageTables()
local beamData = beamstate.getPartDamageTable()
local customPrices = loadTableFromFile("beamLR/partprices", true)
breakBeamCount = {}
deformBeamCount = {}
partPrices = {}
for k,v in pairs(beamData) do
breakBeamCount[k] = getBreakableBeamCount(k)
deformBeamCount[k] = getDeformableBeamCount(k)
partPrices[k] = customPrices[k] or beamData[k].value 
end
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

if dbg then print("ADVANCED DAMAGE DEBUG") end

for k,v in pairs(beamData) do
cbroken = v["beamsBroken"] or 0
cdeformed = v["beamsDeformed"] or 0
cdcount = deformBeamCount[k] or 0
cbcount = breakBeamCount[k] or 0
cbdmg = 0
cddmg = 0
ctdmg = 0
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
toRet = toRet + partPrices[k] * (ctdmg*ctdmg*ctdmg)
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

for k,v in pairs(beamData) do
cbroken = v["beamsBroken"] or 0
cdeformed = v["beamsDeformed"] or 0
cdcount = deformBeamCount[k] or 0
cbcount = breakBeamCount[k] or 0
cbdmg = 0
cddmg = 0
ctdmg = 0
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
ccost = partPrices[k] * (ctdmg*ctdmg*ctdmg)
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