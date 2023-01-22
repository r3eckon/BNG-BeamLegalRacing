local M = {}

local extensions = require("extensions")

local ftable = {}
local vidfilter = -1

ftable["postedit"] = function(p)
extensions.blrglobals.gmSetVal("postEditActionsQueued", true)
end

ftable["debug"] = function(p)
print(p)
end

local lftable = {}
local lptable = {}
local rtable = {}

local linkHook = function(h,f, p)
lftable[h] = f
lptable[h] = p
end

local unlinkHook = function(h)
lftable[h] = nil
lptable[h] = nil
end

local loadBLRHooks = function()	-- Seems like the game will not call custom hooks until the extension is loaded by calling it once before
print("BLRHooks Loaded") 		-- Just call this at start of scenario
end

local onVehicleLoaded = function(retainDebug)
local h = "vehloaded"
if lftable[h] ~= nil then
rtable[h] = ftable[lftable[h]](lptable[h])
unlinkHook(h)
end
print("BLRHOOK: VEHICLE LOADED")
end

local onVehicleResetted = function(vehicleID)
local h = "vehReset"
if vehicleID == vidfilter or vidfilter == -1 then
if lftable[h] ~= nil then
rtable[h] = ftable[lftable[h]](lptable[h])
unlinkHook(h)
end
print("BLRHOOK: VEHICLE RESETTED")
end
end

local onVehicleSpawned = function(vid)
local h = "vehSpawned"
if vehicleID == vidfilter or vidfilter == -1 then
if lftable[h] ~= nil then
rtable[h] = ftable[lftable[h]](lptable[h])
unlinkHook(h)
end
print("BLRHOOK: VEHICLE SPAWNED")
end
end

local onBeamNGTrigger = function(data) -- Hook for custom trigger function 
extensions.blrtriggers.blrTrigger(data)
end

local setFilter = function(vid)
vidfilter = vid
end

local getFilter = function(vid)
return vidfilter
end


M.getFilter = getFilter
M.setFilter = setFilter
M.getFunctionTable = ftable
M.linkHook = linkHook
M.unlinkHook = unlinkHook
M.loadBLRHooks = loadBLRHooks
M.onVehicleLoaded = onVehicleLoaded
M.onVehicleResetted = onVehicleResetted
M.onVehicleSpawned = onVehicleSpawned
M.onBeamNGTrigger = onBeamNGTrigger

return M