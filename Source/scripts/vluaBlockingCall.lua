local M = {}

local unblocked = {}

local blockgroups = {}
blockgroups["playergarage"] = {1,2,3,4}

local function setBlocked(b, id)
unblocked[id] = not b
end

local function isBlocked(id)
return not unblocked[id]
end

local function exec(vehid, f, p, id)
local veh = be:getObjectByID(vehid)
unblocked[id] = false
veh:queueLuaCommand("extensions.vluaBlockingCall.exec('" .. f .. "','" .. p .. "'," .. id .. ")")
end

local function setParam(vehid, p, v)
local veh = be:getObjectByID(vehid)
local cmd = ""
if type(v) == "string" then
cmd = string.format("extensions.vluaBlockingCall.setParam(%q,%q)", p, v)
elseif type(v) == "boolean" then
if v then
cmd = "extensions.vluaBlockingCall.setParam('" .. p .. "',true)"
else
cmd = "extensions.vluaBlockingCall.setParam('" .. p .. "',false)"
end
else
cmd = "extensions.vluaBlockingCall.setParam('" .. p .. "'," .. v .. ")"
end
veh:queueLuaCommand(cmd)
end

local function setParamTableValue(vehid, t, p, v)
local veh = be:getObjectByID(vehid)
local cmd = ""
if type(v) == "string" then
cmd = string.format("extensions.vluaBlockingCall.setParamTableValue(%q,%q,%q)", t, p, v)
elseif type(v) == "boolean" then
if v then
cmd = "extensions.vluaBlockingCall.setParamTableValue('" .. t .. "','" .. p .. "',true)"
else
cmd = "extensions.vluaBlockingCall.setParamTableValue('" .. t .. "','" .. p .. "',false)"
end
else
cmd = "extensions.vluaBlockingCall.setParamTableValue('" .. t .. "','" .. p .. "'," .. v .. ")"
end
veh:queueLuaCommand(cmd)
end

local function reset()
unblocked = {}
end

local function resetGroup(group)
if not blockgroups[group] then return end
for _,v in pairs(blockgroups[group]) do
setBlocked(true, v)
end
end


M.resetGroup = resetGroup
M.isBlocked = isBlocked
M.setBlocked = setBlocked
M.exec = exec
M.setParam = setParam
M.setParamTableValue = setParamTableValue
M.reset = reset

return M