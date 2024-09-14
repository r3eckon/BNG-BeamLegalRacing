local M = {}

local extensions = require("extensions")

local ftable = {}
local vidfilter = -1

ftable["postedit"] = function(p)
extensions.blrglobals.gmSetVal("postEditActionsQueued", true)
end

ftable["tracktune"] = function(p)
extensions.blrglobals.blrFlagSet("trackPostTuneActionsQueued", true)
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

if not be:getPlayerVehicle(0) then
print("onVehicleResetted hook called but player had no vehicle, skipping.\nHook vehicleID was " .. vehicleID)
return
end

if vehicleID == be:getPlayerVehicle(0):getId() then -- 1.15 fix for track event player not frozen, should also prevent other issues with reset hook from other vehicles
--1.13 advanced vehicle building, reset avb flag to false after spawn
--to avoid shop cars, race opponents & traffic from missing parts
if extensions.blrglobals.blrFlagGet("advancedVehicleBuilding") then
extensions.blrglobals.blrFlagSet("avbResetDelayed", true) -- Need to delay reset a bit
end

--1.14.2 part edit safe mode
if extensions.blrflags.get("garageSafeMode") then
be:getPlayerVehicle(0):queueLuaCommand("controller.setFreeze(1)")
elseif extensions.blrglobals.blrFlagGet("garageSafeModeToggle") then -- 1.15 fix for track event player not frozen
be:getPlayerVehicle(0):queueLuaCommand("controller.setFreeze(0)")
end
be:getPlayerVehicle(0):queueLuaCommand("extensions.blrVehicleUtils.buildAdvancedDamageTables()")

print("BLRHOOK: VEHICLE RESETTED")
end

end
end

local onVehicleSpawned = function(vehicleID)
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

local onVehicleActiveChanged = function(veid, active)
if extensions.blrglobals.blrFlagGet("policeResetRequest") then
if active then
extensions.blrutils.copfixHook(veid)
end
elseif extensions.blrglobals.blrFlagGet("roleFixToggle") then
extensions.blrutils.roleStateFixHook(veid, active)
end
end

local onMenuToggled = function(showMenu)
print("BLRHOOK: Menu Toggled")
extensions.blrglobals.blrFlagSet("disableQuickAccess", true)
end

function onCouplerAttached(objId1, objId2, nodeId, obj2nodeId)
extensions.blrTrailerManager.couplerAttached(objId1, objId2, nodeId, obj2nodeId)
end

function onCouplerDetached(objId1, objId2, nodeId, obj2nodeId)
extensions.blrTrailerManager.couplerDetached(objId1, objId2, nodeId, obj2nodeId)
end

function onVehicleSwitched(old, new, player)
extensions.blrdelay.setParam("oldid", old)
extensions.blrdelay.queue("onswitch", "oldid", 10)
end


M.onVehicleSwitched = onVehicleSwitched
M.onCouplerDetached = onCouplerDetached
M.onCouplerAttached = onCouplerAttached
M.onMenuToggled = onMenuToggled
M.onVehicleActiveChanged = onVehicleActiveChanged
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