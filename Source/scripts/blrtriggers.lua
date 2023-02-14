local M = {}
local extensions = require("extensions")

local registeredNodes = {}	-- Needed to have every trigger node consume data without race conditions

local triggerData = {}
local triggerStatus = {}
local triggerDataState = {}

-- For menu interaction triggers are filtered by name to avoid menus closing
-- due to adjacent triggers "exit" events firing while still inside menu trig
-- (problem happens mostly in race clubs with close checkpoints / race start)

local menuFilters = {}
local menuTriggerData = {}
local menuTriggerStatus = {}
local menuTriggerDataState = {}


local function blrTrigger(data)
local menuMatch = false

for k,v in pairs(registeredNodes) do
triggerData[k][data.subjectID] = data
triggerDataState[k][data.subjectID] = true

if triggerStatus[k][data.subjectID] == nil then
triggerStatus[k][data.subjectID] = {}
end

if data.event == "enter" then
triggerStatus[k][data.subjectID][data.triggerName] = true
else
triggerStatus[k][data.subjectID][data.triggerName] = nil --to remove from table
end

end

for k,v in pairs(menuFilters) do
menuMatch = data.triggerName == k
if menuMatch then break end
end

if menuMatch then
for k,v in pairs(registeredNodes) do
menuTriggerData[k][data.subjectID] = data
menuTriggerDataState[k][data.subjectID] = true

if menuTriggerStatus[k][data.subjectID] == nil then
menuTriggerStatus[k][data.subjectID] = {}
end

if data.event == "enter" then
menuTriggerStatus[k][data.subjectID][data.triggerName] = true
else
menuTriggerStatus[k][data.subjectID][data.triggerName] = nil --to remove from table
end

end
end

end

local function getGlobalTriggerStatus(nid,vid,menuMode)
local toRet = false
if menuMode then
if menuTriggerStatus[nid][vid] then
for k,v in pairs(menuTriggerStatus[nid][vid]) do
toRet = true
break
end
end
else
if triggerStatus[nid][vid] then
for k,v in pairs(triggerStatus[nid][vid]) do
toRet = true
break
end
end
end
return toRet
end

local function getTriggerStatus(nid,vid, trigger, menuMode)
local toRet = false
if menuMode then
if menuTriggerStatus[nid][vid] then
toRet = menuTriggerStatus[nid][vid][trigger] or false
end
else
if triggerStatus[nid][vid] then
toRet = triggerStatus[nid][vid][trigger] or false
end
end
return toRet
end

local function poolTriggerData(nid,vid, menuMode)
local toRet
if menuMode then
if menuTriggerDataState[nid][vid] then
menuTriggerDataState[nid][vid] = false
toRet = menuTriggerData[nid][vid]
end
else
if triggerDataState[nid][vid] then
triggerDataState[nid][vid] = false
toRet = triggerData[nid][vid]
end
end
return toRet
end

local function loadMenuFilters()
local dtable = extensions.blrutils.loadDataTable("beamLR/mapdata/" .. extensions.blrutils.getLevelName() .. "/triggers")
menuFilters = {} 
for k,v in pairs(dtable) do
menuFilters[k] = true
end
end

local function blrTriggerInit(useMenuFilters)
registeredNodes = {}
triggerData = {}
triggerStatus = {}
triggerDataState = {}
menuTriggerData = {}
menuTriggerStatus = {}
menuTriggerDataState = {}
if useMenuFilters then
loadMenuFilters()
end
end

local function registerNode(nid)
if not registeredNodes[nid] then
registeredNodes[nid] = true
triggerData[nid] = {}
triggerStatus[nid] = {}
triggerDataState[nid] = {}
menuTriggerData[nid] = {}
menuTriggerStatus[nid] = {}
menuTriggerDataState[nid] = {}
end
end

local function isNodeRegistered(nid)
return registeredNodes[nid] or false
end

M.isNodeRegistered = isNodeRegistered
M.registerNode = registerNode
M.loadMenuFilters = loadMenuFilters
M.getGlobalTriggerStatus = getGlobalTriggerStatus
M.blrTriggerInit = blrTriggerInit
M.getTriggerStatus = getTriggerStatus
M.poolTriggerData = poolTriggerData
M.blrTrigger = blrTrigger

return M