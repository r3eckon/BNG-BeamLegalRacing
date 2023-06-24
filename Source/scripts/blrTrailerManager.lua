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
local parts = extensions.betterpartmgmt.getVehicleParts()
local toRet = false
for k,v in pairs(parts) do
if string.find(v, "towhitch") then toRet = true break end
end
return toRet
end


M.towhitchCheck = towhitchCheck
M.getPlayerTrailerID = getPlayerTrailerID
M.setPlayerVID = setPlayerVID
M.init = init
M.couplerAttached = couplerAttached
M.couplerDetached = couplerDetached

return M