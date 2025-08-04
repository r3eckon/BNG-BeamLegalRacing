-- This script works similar to customGuiCallbacks except its used
-- to queue function calls with a set frame delay before execution
-- and can be called from flowgraph or other lua scripts.
-- queue function delay mode can be nil or "frame" for frames, "time" for seconds
-- time based delay will ignore slow motion but still work with pause

local M = {}

local extensions = require("extensions")
local cframe = 0
local ctime = 0

local ftable = {}

local fqueue = {} -- frame delay queue
local squeue = {} -- time delay queue

local ptable = {}
local rtable = {}

local function queue(f,p,d, mode)
if (not mode) or (mode == "frame") then
table.insert(fqueue, {f, p, cframe+d})
elseif mode == "time" then
table.insert(squeue, {f, p, ctime+d})
end
end


ftable["test"] = function(p)
print(p)
end

ftable["gpsinit"] = function(p)
local list = extensions.blrutils.getGPSDestinationUIList()
extensions.customGuiStream.sendGPSDestinationList(list)
extensions.blrutils.gpsToggleStateUpdate()
extensions.blrutils.setGPSDestination()
extensions.customGuiStream.sendGPSPage(0)
print("GPS INIT DONE")
end

ftable["guimsg"] = function(p)
guihooks.trigger('Message', {ttl = p["ttl"] or 10, msg = p["msg"], icon = p["icon"] or 'directions_car'})
end

ftable["iminit"] = function(p)
extensions.blrutils.loadCustomIMGUILayout()
end

ftable["dragcamreset"] = function(p)
extensions.blrdragdisplay.resetCamera()
end

ftable["uioptionsreload"] = function(p)
extensions.customGuiStream.sendCurrentOptionValues()
end

ftable["onswitch"] = function(p)
local oldid = p
local shopmode = extensions.blrglobals.blrFlagGet("shopmode")
local walking = extensions.blrpartmgmt.getMainPartName() == "unicycle"
if (not shopmode) and walking then
extensions.blrglobals.blrFlagSet("shopWalkingMode", true)
extensions.blrutils.blrvarSet("playervehid", oldid)
elseif (not shopmode) then
extensions.blrglobals.blrFlagSet("shopWalkingMode", false)
end
end

ftable["updateOilLeak"] = function(p)
local veh = scenetree.findObjectById(p)
if veh then
veh:queueLuaCommand("extensions.blrVehicleUtils.updateOilLeakRate()")
end
end

ftable["updatevehid"] = function(p)
if be:getPlayerVehicle(0) then
extensions.blrutils.blrvarSet("playervehid",be:getPlayerVehicle(0):getId())
else -- 1.15.3 fix, be:getPlayerVehicle(0) can returns nil after scrapping so trying to re-queue 
print("Delayed vehid update encountered nil be:getPlayerVehicle(0) result, re-queuing...")
queue("updatevehid",nil, 10)
end
end

ftable["loadAdvancedIntegrity"] = function(p)
local params = extensions.blrutils.blrvarGet("integrityLoadingData")
extensions.mechDamageLoader.loadAdvancedIntegrityData(params["vid"], params["cfile"], params["vehOdoOverride"], true)
end


ftable["initInventoryLinks"] = function(p)
extensions.blrpartmgmt.initVehicleInventoryLinks()
extensions.blrglobals.blrFlagSet("uiInitRequest", true)

-- This flag is turned on from integrity loading function when ilinks are missing
-- and waits for ilinks to be ready before retrying to load integrity data
if extensions.blrglobals.blrFlagGet("integrityLoadingQueued") then
print("Detected request for delayed integrity loading, queuing...")
queue("loadAdvancedIntegrity", nil, 10)
end

end

ftable["pinkSlipsCompensate"] = function(p)
local cmoney = extensions.blrglobals.gmGetVal("playerMoney")
extensions.blrglobals.gmSetVal("playerMoney", cmoney + 5000)
print("$5000 has been rewarded as compensation for pink slips issue.")
end


ftable["overloadDriftScoring"] = function(p)
gameplay_drift_scoring = require("gameplay/drift/scoringLegacy")
extensions.load("gameplay/drift/scoringLegacy") -- makes sure the extension is loaded so onUpdate gets called
gameplay_drift_scoring.reset()
end

ftable["reloadDriftScoring"] = function(p)
gameplay_drift_scoring = require("gameplay/drift/scoring")
extensions.unload("gameplay_drift_scoringLegacy") -- unloads legacy extension so it doesn't interfere with vanilla scoring
gameplay_drift_scoring.reset()
end


local function setParamTableValue(p,ti,v)
if ptable[p] == nil then ptable[p] = {} end
ptable[p][ti] = v
end

local function setParam(p,v)
ptable[p] = v
end


local function exec(f,p)
if p ~= nil then
rtable[f] = ftable[f](ptable[p])
else
rtable[f] = ftable[f](0)
end
end

local function getReturnValue(f)
return rtable[f] or "nil"
end


local fdequeue = {}
local sdequeue = {}
local simspeed = 1
local function onPreRender(dtReal,dtSim,dtRaw)
cframe = cframe+1
simspeed = simTimeAuthority.getReal()
if simspeed > 0 then
ctime = ctime+(dtSim / simspeed)
end
fdequeue = {}
sdequeue = {}
for k,v in pairs(fqueue) do
if cframe >= v[3] then
exec(v[1], v[2])
table.insert(fdequeue, k)
end
end
for k,v in pairs(squeue) do
if ctime >= v[3] then
exec(v[1], v[2])
table.insert(sdequeue, k)
end
end
for k,v in pairs(fdequeue) do
fqueue[v] = nil
end
for k,v in pairs(sdequeue) do
squeue[v] = nil
end
end

M.setParamTableValue = setParamTableValue
M.setParam = setParam
M.queue = queue
M.getReturnValue = getReturnValue
M.onPreRender = onPreRender

return M