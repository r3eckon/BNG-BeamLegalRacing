-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local fetchTable = {}

local function fetch(msg,id)
fetchTable[id] = msg
end

local function getVal(id)
return fetchTable[id]
end

local function exec(vehid, toFetch, fetchid, strFetch)
local ve = scenetree.findObjectById(vehid)
if ve ~= nil then
local cmd = ""
if strFetch then
cmd = "obj:queueGameEngineLua(string.format('extensions.vluaFetchModule.fetch(%q,%q)', " .. toFetch .. ",'" .. fetchid .. "'))"
else
cmd = "obj:queueGameEngineLua(string.format('extensions.vluaFetchModule.fetch(%s,%q)', " .. toFetch .. ",'" .. fetchid .. "'))"
end
if ve.queueLuaCommand ~= nil then
ve:queueLuaCommand(cmd)
end
end
end

local function getFetchTable()
return fetchTable
end

M.exec = exec
M.fetch = fetch
M.getVal = getVal
M.getFetchTable = getFetchTable

return M

