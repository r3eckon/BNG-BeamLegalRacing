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



local fqueue = {} -- frame delay queue
local squeue = {} -- time delay queue

local ptable = {}
local rtable = {}

local function setParamTableValue(p,ti,v)
if ptable[p] == nil then ptable[p] = {} end
ptable[p][ti] = v
end

local function setParam(p,v)
ptable[p] = v
end

local function queue(f,p,d, mode)
if (not mode) or (mode == "frame") then
table.insert(fqueue, {f, p, cframe+d})
elseif mode == "time" then
table.insert(squeue, {f, p, ctime+d})
end
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