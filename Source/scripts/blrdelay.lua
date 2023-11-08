-- This script works similar to customGuiCallbacks except its used
-- to queue function calls with a set frame delay before execution
-- and can be called from flowgraph or other lua scripts

local M = {}

local extensions = require("extensions")
local cframe = 0

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
end

ftable["guimsg"] = function(p)
guihooks.trigger('Message', {ttl = p["ttl"] or 10, msg = p["msg"], icon = p["icon"] or 'directions_car'})
end



local fqueue = {}

local ptable = {}

local rtable = {}

local function setParamTableValue(p,ti,v)
if ptable[p] == nil then ptable[p] = {} end
ptable[p][ti] = v
end

local function setParam(p,v)
ptable[p] = v
end

local function queue(f,p,d)
table.insert(fqueue, {f, p, cframe+d})
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

local dequeue = {}
local function onPreRender(dtReal,dtSim,dtRaw)
cframe = cframe+1
dequeue = {}
for k,v in pairs(fqueue) do
if cframe >= v[3] then
exec(v[1], v[2])
table.insert(dequeue, k)
end
end
for k,v in pairs(dequeue) do
fqueue[v] = nil
end
end

M.setParamTableValue = setParamTableValue
M.setParam = setParam
M.queue = queue
M.getReturnValue = getReturnValue
M.onPreRender = onPreRender

return M