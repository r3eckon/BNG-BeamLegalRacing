local M = {}

local extensions = require("extensions")
local couplings = {}
local playerID = 0


local function init()
couplings = {}
end

local function setPlayerVID(id)
playerID = id
end

local function getPlayerTrailerID()
return couplings[playerID]
end

local function couplerAttached(objId1, objId2, nodeId, obj2nodeId)
couplings[objId1] = objId2
couplings[objId2] = objId1
print(objId1 .. " coupled with " .. objId2)
end
local function couplerDetached(objId1, objId2, nodeId, obj2nodeId)
couplings[objId1] = nil
couplings[objId2] = nil
print(objId1 .. " decoupled from " .. objId2)
end

local function towhitchCheck()
local parts = extensions.blrpartmgmt.getVehicleParts()
local toRet = false
-- 1.13 advanced vehicle building needs to check pickup receiver for attachment
-- because parent tow hitch slot no longer fills with default ball hitch
if parts["pickup_towhitch"] and parts["pickup_towhitch"] ~= "" then
toRet = parts["pickup_receiver_attachment"] ~= ""
end
if not toRet then -- can skip loop if valid pickup tow hitch found
for k,v in pairs(parts) do
if k~= "pickup_towhitch" and string.find(v, "towhitch") then 
toRet = true break 
end
end
end
return toRet
end

local function gooseneckCheck()
local parts = extensions.blrpartmgmt.getVehicleParts()
local toRet = false
for k,v in pairs(parts) do
if string.find(v, "gooseneck_ball") then toRet = true break end
end
return toRet
end

-- Custom impact G force based damage to workaround trailer wobble
-- causing damage during spawning and 40ft tiltdeck bending
local tdamage = 0
local function getTrailerDamage()
return tdamage
end

local function setTrailerDamage(dmg)
tdamage = dmg
end

M.setTrailerDamage = setTrailerDamage
M.getTrailerDamage = getTrailerDamage
M.gooseneckCheck = gooseneckCheck
M.towhitchCheck = towhitchCheck
M.getPlayerTrailerID = getPlayerTrailerID
M.setPlayerVID = setPlayerVID
M.init = init
M.couplerAttached = couplerAttached
M.couplerDetached = couplerDetached

return M