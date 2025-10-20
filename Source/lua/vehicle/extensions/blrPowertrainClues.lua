local M = {}

local nodeRef = nil
local leakNodes = nil

local function getLeakNodes()
return leakNodes
end

local function generateNodeRef()
nodeRef = {}
for k,node in pairs(v.data.nodes) do
nodeRef[node.name or node.cid] = k
end
end

local function lookForLeakNodes(partData)
if leakNodes then return end
if not nodeRef then generateNodeRef() end

if nodeRef["oilpan"] then
leakNodes = {nodeRef["oilpan"]}
print("Found real oilpan node, using it as leak point")
return
end

leakNodes = {}
for k,v in pairs(partData["nodes"]) do
if v[1] and nodeRef[v[1]] then
table.insert(leakNodes, nodeRef[v[1]])
end
end

print("Found no real oilpan node, using engine nodes average pos as leak point")

end


local function getLeakPosition()
local cpos = nil
local count = #leakNodes

if count == 0 then
print("Leak node error: didn't find any leak nodes, can't spawn decals")
return
end

local ax = 0
local ay = 0
local az = 0

for k,v in pairs(leakNodes) do
cpos = vec3(obj:getNodePosition(v)) + vec3(obj:getPositionXYZ())
ax = ax + cpos.x
ay = ay + cpos.y
az = az + cpos.z
end

ax = ax / count
ay = ay / count
az = az / count

return vec3(ax,ay,az)
end



local function lookForOilpan(partData, nmode)
local found = false
if partData["mainEngine"] then
found = partData["mainEngine"]["deformGroups_oilPan"]
found = found or partData["mainEngine"]["oilpanMaximumSafeG"]
found = found or partData["mainEngine"]["oilpanNodes:"]
end

if found then
lookForLeakNodes(partData)
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

if found then
lookForLeakNodes(partData)
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
if v["deformGroup"] and type(v["deformGroup"]) == "string" then
if (v["deformGroup"] == "mainEngine_intake" or string.find(v["deformGroup"], "mainEngine_turbo") or string.find(v["deformGroup"], "mainEngine_supercharger")) then
found = true
break
end
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
leakNodes = nil
nodeRef = nil

-- Start with oilpan, trying to find using string matching first since some vehicles
-- have oilpan deform groups attached to engine so first try finding actual oilpan part
local foundSlot = false -- if found slot but not found part it means oilpan is separate
local foundPart = false -- part but not currently installed on vehicle
for k,v in pairs(v.data.slotPartMap) do
if string.find(k, "oilpan") then
foundSlot = true
foundPart = (v ~= "")
if foundPart then toRet["oilpan"] = k .. v end
break
end
end

local cdata = {}
local ckey = ""

-- Now dealing with other powertrain parts
for slotPath,part in pairs(v.data.slotPartMap) do
if part ~= "" then

cdata = v.data.activePartsData[part]
ckey = slotPath .. part


if (not toRet["engine"]) and lookForEngine(cdata) then
toRet["engine"] = ckey 
end

-- this will likely set engine as oilpan part, happens if vehicle has no separate oilpan part
if (not toRet["oilpan"]) and (not foundSlot) and lookForOilpan(cdata) then
toRet["oilpan"] = ckey 
end

if (not toRet["longblock"]) and lookForLongBlock(cdata) then
toRet["longblock"] = ckey 
end

if (not toRet["radiator"]) and lookForRadiator(cdata) then
toRet["radiator"] = ckey 
end

if (not toRet["intake"]) and lookForIntake(cdata) then
toRet["intake"] = ckey 
end

if (not toRet["turbocharger"]) and lookForTurbocharger(cdata) then
toRet["turbocharger"] = ckey 
end

if (not toRet["supercharger"]) and lookForSupercharger(cdata) then
toRet["supercharger"] = ckey 
end

if (not toRet["transmission"]) and lookForTransmission(cdata) then
toRet["transmission"] = ckey 
end

if (not toRet["exhaust"]) and lookForExhaust(cdata) then
toRet["exhaust"] = ckey 
end

if (not toRet["nitrous"]) and lookForNitrous(cdata) then
toRet["nitrous"] = ckey 
end

end
end

return toRet
end

local function sendLeakNodes()
local toSend = serialize(leakNodes or "")
obj:queueGameEngineLua("extensions.blrdecals.receiveLeakNodes('" .. toSend .. "')")
end

local function sendClues()
local clues = getClues()
for k,v in pairs(clues) do
obj:queueGameEngineLua("extensions.mechDamageLoader.receivePowertrainClues('" .. k .. "','".. v .."')")
end
obj:queueGameEngineLua("extensions.mechDamageLoader.processPowertrainClues()")

sendLeakNodes()
end

M.sendLeakNodes = sendLeakNodes

M.getLeakPosition = getLeakPosition
M.getLeakNodes = getLeakNodes
M.sendClues = sendClues
M.getClues = getClues


return M