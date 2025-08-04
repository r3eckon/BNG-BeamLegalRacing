-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local psid = 0

local ptable = {}
local rtable = {}
local ftable = {}

ftable["camreset"] = function(p)
extensions.blrutils.cameraReset()
end 



local function vehExists()
return be:getPlayerVehicle(0) ~= nil
end

local function getCurrentID()
return be:getPlayerVehicle(0):getId()
end

local function setPrespawnID(id)
psid = id
end

local function setParamTableValue(p,ti,v)
if ptable[p] == nil then ptable[p] = {} end
ptable[p][ti] = v
end

local function setParam(p,v)
ptable[p] = v
end

local function getReturnValue(f)
return rtable[f] or "nil"
end

local function exec(f, p)
while vehExists() == nil do end		-- 
while getCurrentID == psid do end	-- Should wait for new car to spawnSQ
if p ~= nil then
rtable[f] = ftable[f](ptable[p])
else
rtable[f] = ftable[f](0)
end
end


M.setPrespawnID = setPrespawnID
M.setParamTableValue = setParamTableValue
M.setParam = setParam
M.getReturnValue = getReturnValue
M.exec = exec


return M



