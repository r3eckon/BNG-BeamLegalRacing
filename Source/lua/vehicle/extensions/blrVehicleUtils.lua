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

M.getFuelCapacityTotal = getFuelCapacityTotal
M.getFuelTotal = getFuelTotal
M.setFuel = setFuel
M.addFuel = addFuel
M.getEnergyStorageData = getEnergyStorageData
M.testPrint = testPrint

return M