local M = {}

local function testPrint(toPrint)
print(toPrint)
end

-- Adds fuel in available tanks
local function addFuel(val)
local storageData = energyStorage.getStorages()
local remainToAdd = val
local currentVal = 0
local currentCap = 0
local currentAdd = 0

--Start by filling mainTank if it exists on vehicle
if storageData["mainTank"] then
currentVal = storageData["mainTank"].remainingVolume
currentCap = storageData["mainTank"].capacity
currentAdd = math.min(currentCap - currentVal, remainToAdd)
energyStorage.getStorage("mainTank"):setRemainingVolume(currentVal + currentAdd)
remainToAdd = math.max(remainToAdd - currentAdd, 0)
end

--Now filling auxTank if it exists
if storageData["auxTank"] then
currentVal = storageData["auxTank"].remainingVolume
currentCap = storageData["auxTank"].capacity
currentAdd = math.min(currentCap - currentVal, remainToAdd)
energyStorage.getStorage("auxTank"):setRemainingVolume(currentVal + currentAdd)
remainToAdd = math.max(remainToAdd - currentAdd, 0)
end

--Return remaining value
return remainToAdd
end

-- Force set fuel total value
local function setFuel(val)
local storageData = energyStorage.getStorages()
local remainToAdd = val
local currentCap = 0
local currentAdd = 0

--Start by filling mainTank if it exists on vehicle
if storageData["mainTank"] then
currentCap = storageData["mainTank"].capacity
currentAdd = math.min(currentCap, remainToAdd)
energyStorage.getStorage("mainTank"):setRemainingVolume(currentAdd)
remainToAdd = math.max(remainToAdd - currentAdd, 0)
end

--Now filling auxTank if it exists
if storageData["auxTank"] then
currentCap = storageData["auxTank"].capacity
currentAdd = math.min(currentCap, remainToAdd)
energyStorage.getStorage("auxTank"):setRemainingVolume(currentAdd)
remainToAdd = math.max(remainToAdd - currentAdd, 0)
end

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

if storageData["mainTank"] then
toRet = toRet + storageData["mainTank"].remainingVolume
end

if storageData["auxTank"] then
toRet = toRet + storageData["auxTank"].remainingVolume
end

return toRet
end

local function getFuelCapacityTotal()
local storageData = energyStorage.getStorages()
local toRet = 0

if storageData["mainTank"] then
toRet = toRet + storageData["mainTank"].capacity
end

if storageData["auxTank"] then
toRet = toRet + storageData["auxTank"].capacity
end

return toRet
end

local function getPowertrainLayoutName(layout)
local toRet = ""
if layout[poweredWheelsFront] == 0 and layout[poweredWheelsRear] == 0 then
toRet = "ERROR"
elseif layout[poweredWheelsFront] == 0 then
toRet = "RWD"
elseif layout[poweredWheelsRear] == 0 then
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

M.getPowertrainLayoutName = getPowertrainLayoutName
M.getRawPerformanceValue = getRawPerformanceValue
M.getPerformanceClass = getPerformanceClass
M.getFuelCapacityTotal = getFuelCapacityTotal
M.getFuelTotal = getFuelTotal
M.setFuel = setFuel
M.addFuel = addFuel
M.getEnergyStorageData = getEnergyStorageData
M.testPrint = testPrint

return M