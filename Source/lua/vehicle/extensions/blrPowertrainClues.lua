local M = {}

local function lookForOilpan(partData, nmode)
local found = false
if partData["mainEngine"] then
found = partData["mainEngine"]["deformGroups_oilPan"]
found = found or partData["mainEngine"]["oilpanMaximumSafeG"]
found = found or partData["mainEngine"]["oilpanNodes:"]
end
return found
end

local function lookForEngine(partData)
local found = false
if partData["powertrain"] and partData["powertrain"][2] then
found = partData["powertrain"][2][1] == "combustionEngine"
found = found or partData["powertrain"][2][2] == "mainEngine"
end
if partData["mainEngine"] then
found = found or partData["mainEngine"]["engineBlockMaterial"]
end
return found
end

local function lookForLongBlock(partData)
local found = false
if string.find(partData["partName"], "internals") then found = true end
return found
end

local function lookForRadiator(partData)
local found = false
if partData["mainEngine"] then
found = partData["mainEngine"]["coolantVolume"]
found = found or partData["mainEngine"]["deformGroups_radiator"]
found = found or partData["mainEngine"]["radiatorArea"]
end
return found
end

local function lookForIntake(partData)
local found = false
if partData["powertrainDamage"] and partData["powertrainDamage"][2] then
found = partData["powertrainDamage"][2][2] == "intake"
end
if not found and partData["beams"] then
for k,v in pairs(partData["beams"]) do
if v["deformGroup"] == "mainEngine_intake" then
found = true
break
end
end
end
return found
end

-- need to look for intake to avoid ECU turbocharger data, make sure we actually grab the turbo itself
local function lookForTurbocharger(partData)
return lookForIntake(partData) and partData["turbocharger"]
end
-- same as above for supercharger
local function lookForSupercharger(partData)
return lookForIntake(partData) and partData["supercharger"]
end

local function lookForTransmission(partData)
return partData["gearbox"]
end

local function lookForExhaust(partData)
local found = false
if not string.find(partData["partName"], "exhausttips") and string.find(partData["partName"], "exhaust") then
found = partData["soundConfigExhaust"]
found = found or (partData["mainEngine"] and partData["mainEngine"]["torqueModExhaust"])
end
return found
end

local function lookForNitrous(partData)
return partData["partName"] == "n2o_system"
end



-- not fully accurate but for my use only need engine and oilpan which works 
-- some vehicles (like bastion) have seemingly no individual oilpan part, so
-- oilpan part is the engine, weird but easy enough to detect, just gotta use
-- engine odometer alone for oil leak in this situation
local function getClues()
local toRet = {}

-- Start with oilpan, trying to find using string matching first since some vehicles
-- have oilpan deform groups attached to engine so first try finding actual oilpan part
local foundSlot = false -- if found slot but not found part it means oilpan is separate
local foundPart = false -- part but not currently installed on vehicle
for k,v in pairs(v.config.parts) do
if string.find(k, "oilpan") then
foundSlot = true
foundPart = (v ~= "")
if foundPart then toRet["oilpan"] = v end
break
end
end

-- Now dealing with other powertrain parts
for k,v in pairs(v.data.activeParts) do

if (not toRet["engine"]) and lookForEngine(v) then
toRet["engine"] = k 
end

-- this will likely set engine as oilpan part, happens if vehicle has no separate oilpan part
if (not toRet["oilpan"]) and (not foundSlot) and lookForOilpan(v) then
toRet["oilpan"] = k 
end

if (not toRet["longblock"]) and lookForLongBlock(v) then
toRet["longblock"] = k 
end

if (not toRet["radiator"]) and lookForRadiator(v) then
toRet["radiator"] = k 
end

if (not toRet["intake"]) and lookForIntake(v) then
toRet["intake"] = k 
end

if (not toRet["turbocharger"]) and lookForTurbocharger(v) then
toRet["turbocharger"] = k 
end

if (not toRet["supercharger"]) and lookForSupercharger(v) then
toRet["supercharger"] = k 
end

if (not toRet["transmission"]) and lookForTransmission(v) then
toRet["transmission"] = k 
end

if (not toRet["exhaust"]) and lookForExhaust(v) then
toRet["exhaust"] = k 
end

if (not toRet["nitrous"]) and lookForNitrous(v) then
toRet["nitrous"] = k 
end


end

return toRet
end

local function sendClues()
local clues = getClues()
for k,v in pairs(clues) do
obj:queueGameEngineLua("extensions.mechDamageLoader.receivePowertrainClues('" .. k .. "','".. v .."')")
end
obj:queueGameEngineLua("extensions.mechDamageLoader.processPowertrainClues()")
end



M.sendClues = sendClues
M.getClues = getClues


return M