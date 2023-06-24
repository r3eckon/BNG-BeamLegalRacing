local M = {}

-- Adds fuel in available tanks
local function addFuel(val)
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

--Start by filling mainTank if it exists on vehicle
--if storageData["mainTank"] then
--currentVal = storageData["mainTank"].remainingVolume
--currentCap = storageData["mainTank"].capacity
--currentAdd = math.min(currentCap - currentVal, remainToAdd)
--energyStorage.getStorage("mainTank"):setRemainingVolume(currentVal + currentAdd)
--remainToAdd = math.max(remainToAdd - currentAdd, 0)
--end

--Now filling auxTank if it exists
--if storageData["auxTank"] then
--currentVal = storageData["auxTank"].remainingVolume
--currentCap = storageData["auxTank"].capacity
--currentAdd = math.min(currentCap - currentVal, remainToAdd)
--energyStorage.getStorage("auxTank"):setRemainingVolume(currentVal + currentAdd)
--remainToAdd = math.max(remainToAdd - currentAdd, 0)
--end

--Return remaining value
return remainToAdd
end

-- Force set fuel total value
local function setFuel(val)
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

--Start by filling mainTank if it exists on vehicle
--if storageData["mainTank"] then
--currentCap = storageData["mainTank"].capacity
--currentAdd = math.min(currentCap, remainToAdd)
--energyStorage.getStorage("mainTank"):setRemainingVolume(currentAdd)
--remainToAdd = math.max(remainToAdd - currentAdd, 0)
--end

--Now filling auxTank if it exists
--if storageData["auxTank"] then
--currentCap = storageData["auxTank"].capacity
--currentAdd = math.min(currentCap, remainToAdd)
--energyStorage.getStorage("auxTank"):setRemainingVolume(currentAdd)
--remainToAdd = math.max(remainToAdd - currentAdd, 0)
--end

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

local function updateGFX(dtSim)
velocityLast = velocity
velocity = obj:getVelocity()
if dtSim == 0 then
force = 0
else
forcevector = vec3({ (velocity["x"] - velocityLast["x"]) / dtSim, (velocity["y"] - velocityLast["y"]) / dtSim, (velocity["z"] - velocityLast["z"]) / dtSim })
force = forcevector:length()
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

return M