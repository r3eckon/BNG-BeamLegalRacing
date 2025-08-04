local M = {}

local extensions = require("extensions")

-- main vars
local parts = {}
local cpart = 1
local visible = {}
local toSet = {}
local vehid = 0
local cslot = ""
local vehpos = {}
local vehrot = {}
local running = false
local skipped = 0
local replacemode = false
local cparent = 1
local cmode = false
local pparts = {}
local pslot = ""
local loadParts = false -- true when parent just changed so child part list can be reloaded before next iteration
local took = 0
local keyword = ""
local batch = ""
local forceVisible = {}
local hidenothing = false
local noshutoff = false

local gpslot = ""
local cgparent = 1
local gpparts = {}
local gkeyword = ""

-- delay vars
local cframe = 0
local iterframe = 0
local iterqueued = false
local iterdelay = 10
local singlequeued = false
local singledelay = 10
local singleframe = 0

-- Resets parent to first selected so don't have to manually do it in part editor
local autoreset = true
local iparent = ""


local logdata = ""


local function timestring()
local t = os.date("*t")
return string.format("[%.2d:%.2d:%.2d] ", t["hour"], t["min"], t["sec"])
end

local function logfile(tolog, reset)
logdata = logdata .. timestring() .. tolog .. "\n"
writeFile("blrPartImages/log.txt", logdata)
end

local function resetParent()
logfile("Resetting parent slot " .. pslot .. " to initial chosen part " .. iparent)
toSet = extensions.blrpartmgmt.getVehicleData().chosenParts
toSet[pslot] = iparent
extensions.core_vehicle_partmgmt.setPartsConfig(toSet)
end

local loadParentParts = false

local function nextGrandparent()
toSet = extensions.blrpartmgmt.getVehicleData().chosenParts
toSet[gpslot] = gpparts[cgparent]
extensions.core_vehicle_partmgmt.setPartsConfig(toSet)
loadParts = true
loadParentParts = true
logfile("Next grandparent called\ngpslot=" .. gpslot .. "\ncgparent=" .. cgparent .. "\nname=" .. gpparts[cgparent])
end

local function nextParent()
toSet = extensions.blrpartmgmt.getVehicleData().chosenParts
toSet[pslot] = pparts[cparent]
extensions.core_vehicle_partmgmt.setPartsConfig(toSet)
loadParts = true
logfile("Next parent called\npslot=" .. pslot .. "\ncparent=" .. cparent .. "\nname=" .. pparts[cparent])
end

local function finish()
if autoreset and cmode then resetParent() end
logfile("Part screenshots finished!")
logfile("Took " .. took .. " new screenshots")
logfile("Skipped " .. skipped .. " screenshots due to existing part images")
running = false
end

local function backgroundScreenshot()
logfile("Taking background screenshot")
screenshot.doScreenshot(nil,false, "blrPartImages/" .. batch .. "BACKGROUND" , ".png")
end

local singlepart = ""
local singlebatch = ""


-- manual screenshot for specific parts (like mainpart body)
local function singleScreenshot(part, batch, delay)
extensions.ui_console.hide()
singlepart = part
if batch then
singlebatch = (batch .. "/")
else
singlebatch = ""
end
singleframe = cframe + (delay or 10)
singlequeued = true
end

local ssqueued = false

local function iteration(part)
logfile("Iteration for part: " .. part)
if (not FS:fileExists("blrPartImages/" .. batch .. part .. ".png")) or replacemode then
logfile("Setting slot " .. cslot .. " to part " .. part)
toSet = extensions.blrpartmgmt.getVehicleData().chosenParts
toSet[cslot] = part
visible = {}
visible[part] = true
if forceVisible then
for k,v in pairs(forceVisible) do
visible[v] = true
end
end
ssqueued = true
extensions.core_vehicle_partmgmt.setPartsConfig(toSet)
if not hidenothing then
extensions.core_vehicle_partmgmt.highlightParts({}, vehid)
extensions.core_vehicle_partmgmt.highlightParts(visible, vehid)
end
else
logfile("Found existing part screenshot, skipping")
if cpart < #parts then
logfile("Skipping to next part")
skipped = skipped + 1
cpart = cpart + 1
iteration(parts[cpart])
elseif cparent < #pparts then
cpart = 1
cparent = cparent + 1
logfile("Skipping to next parent")
nextParent()
elseif cgparent < #gpparts then
cpart = 1
cparent = 1
cgparent = cgparent + 1
logfile("Skipping to next grandparent")
nextGrandparent()
else
finish()
end
end
end

local function teleport()
local playerVehicle = be:getPlayerVehicle(0)
local spot = {}
spot["pos"] = {0,0,0.3}
spot["rot"] = {0,0,0,0}
if not playerVehicle then return end
local vehRot = quat(playerVehicle:getClusterRotationSlow(playerVehicle:getRefNodeId()))
local pos = vec3(spot["pos"][1], spot["pos"][2], spot["pos"][3])
local rot = quat(spot["rot"][1],spot["rot"][2],spot["rot"][3],spot["rot"][4] )
local diffRot = vehRot:inversed() * rot
playerVehicle:setClusterPosRelRot(playerVehicle:getRefNodeId(), pos.x, pos.y, pos.z, diffRot.x, diffRot.y, diffRot.z, diffRot.w)
playerVehicle:applyClusterVelocityScaleAdd(playerVehicle:getRefNodeId(), 0, 0, 0, 0)
playerVehicle:setOriginalTransform(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)
end

local execqueued = false
local execframe = 0

local exec_slot = ""
local exec_idelay = 0
local exec_rmode = false
local exec_cmode = false
local exec_pslot = ""
local exec_keyword = ""
local exec_batch = ""
local exec_gpslot = ""

local delayscreenshot = false

local ignition = -1

--set _ignition at -1 for old "noshutoff" feature, default is 0 (turns car off), otherwise will set specific level
local function start(slot, idelay, rmode, _cmode, _pslot, _keyword, _batch, _forceVisible, delayss, nohide, _ignition, _gpslot, _gkeyword)
extensions.ui_console.hide()
hidenothing = nohide
delayscreenshot = delayss
if not hidenothing then
extensions.core_vehicle_partmgmt.highlightParts({}, vehid)
end
exec_slot = slot
exec_idelay = idelay
exec_rmode = rmode
exec_cmode = _cmode
exec_pslot = _pslot
exec_keyword = _keyword
exec_batch = _batch
execqueued = true
execframe = cframe+idelay
exec_gpslot = _gpslot
exec_gkeyword = _gkeyword
forceVisible = _forceVisible
ignition = _ignition or 0
ssqueued = false
end

local function getHighlightedParts()
local toRet = {}
local vehObj, vehData, vehID, partsData = extensions.core_vehicle_partmgmt.getVehData(be:getPlayerVehicle(0):getId())
local highlighted = partsData.partsHighlighted
local chosen = vehData.chosenParts

for k,v in pairs(chosen) do
if highlighted[k] then
toRet[v] = true
end
end

return toRet
end

local hbatch = ""
local hframe = 0
local hqueued = false
local hparts = {}

local function highlightedScreenshot(batch, delay)
extensions.ui_console.hide()
hparts = getHighlightedParts()
hframe = cframe + (delay or 10)
hqueued = true
if batch then hbatch = batch .. "/"
else hbatch = "" end
end

local lastqueued = false

local function exec(slot, idelay, rmode, _cmode, _pslot, _keyword, _batch, _gpslot, _gkeyword)
if _batch then
batch = (_batch .. "/")
else
batch = ""
end
took = 0
keyword = _keyword
gkeyword = _gkeyword
logdata = ""
logfile("Execution started", true)
replacemode = rmode
skipped = 0
iterdelay = idelay or 10
cslot = slot
backgroundScreenshot()
vehid = be:getPlayerVehicle(0):getId()
extensions.core_vehicle_partmgmt.clearVehicleHighlights(vehid)
parts = extensions.blrpartmgmt.getAvailablePartList()[slot]
loadParts=false
loadParentParts = false
lastqueued = true
cpart = 1
cgparent = 1
running = true
cmode = _cmode
pparts = {}
gpparts = {}
gpslot = _gpslot
if cmode then
pslot = _pslot
cparent = 1
-- below code added to fix issue where parent loop would skip first item if
-- that item isn't the currently set part for parent ex if list contains A,B,C
-- and current part is B, A was skipped. This adds all parts and makes sure the
-- currently set parent is first item in list
pparts = {}
local ptemp = extensions.blrpartmgmt.getAvailablePartList()[pslot]
local pcurr = extensions.blrpartmgmt.getVehicleData().chosenParts[pslot]
iparent = pcurr
table.insert(pparts, pcurr)
for k,v in pairs(ptemp) do
if v ~= pcurr then table.insert(pparts, v) end
end
-- do same thing for grandparent slot if specified
if _gpslot then
gpparts = {}
ptemp = extensions.blrpartmgmt.getAvailablePartList()[gpslot]
pcurr = extensions.blrpartmgmt.getVehicleData().chosenParts[gpslot]
table.insert(gpparts, pcurr)
for k,v in pairs(ptemp) do
if v ~= pcurr then table.insert(gpparts, v) end
end
end
end

iteration(parts[cpart])
end

local sfound = false

local function onVehicleResetted(vehicleID)
if ignition >= 0 then
be:getPlayerVehicle(0):queueLuaCommand("electrics.setIgnitionLevel(".. ignition .. ")")
end
be:getPlayerVehicle(0):queueLuaCommand("electrics.values.underglow = 1")
logfile("onVehicleResetted called")
if not running then return end

if loadParentParts then
sfound = false
logfile("loadParentParts was true, loading parts for parent slot")
for k,v in pairs(extensions.blrpartmgmt.getChildMap()[gpparts[cgparent]]) do
if string.find(k, gkeyword) then
pslot = k
logfile("Setting pslot to " .. k)
sfound = true
pparts = extensions.blrpartmgmt.getAvailablePartList()[pslot]
break
end
end
end

if (sfound and loadParts) or ((not gpslot) and loadParts) then
sfound = false
logfile("loadParts was true, loading parts for new slot")
if extensions.blrpartmgmt.getChildMap()[pparts[cparent]] then
for k,v in pairs(extensions.blrpartmgmt.getChildMap()[pparts[cparent]]) do
if string.find(k, keyword) then
cslot = k
logfile("Setting cslot to " .. k)
sfound = true
break 
end
end
else
logfile("Child map pparts issue!\ncparent=".. cparent .. "\npparts=" .. dumps(pparts))
end


if not sfound and cparent < #pparts then
logfile("Child parts did not match keyword: " .. keyword .. ". Skipping to next parent.")
cpart = 1
cparent = cparent + 1
nextParent()
return
elseif not sfound and cgparent < #gpparts then
logfile("Child parts did not match keyword: " .. keyword .. ". Current parent list exhausted. Skipping to next grandparent.")
cpart = 1
cparent = 1
cgparent = cgparent + 1
nextGrandparent()
return
else
parts = extensions.blrpartmgmt.getAvailablePartList()[cslot]
logfile("Part list for slot " .. cslot .. ":" .. dumps(parts))
loadParts = false
cpart = 0 --just so next increment sets cpart to 1 for first child part
end
else
if not delayscreenshot and ssqueued then
teleport()
if cpart == 0 then cpart = 1 end
logfile("Taking screenshot, path: " .. "blrPartImages/" .. parts[cpart], ".png")
screenshot.doScreenshot(nil,false, "blrPartImages/" .. batch .. parts[cpart], ".png")
took = took + 1
ssqueued = false
end
end

if parts and cpart < #parts then 
logfile("cpart (" .. cpart .. ") was less than #parts (" .. #parts ..  ") incrementing to next part")
if not delayscreenshot then
cpart = cpart + 1
end
iterqueued=true
iterframe = cframe + iterdelay
else -- Arrived at end of parts
if not parts then 
logfile("Parts list for slot " .. cslot .. " was empty, could be jbeam file bug, skipping") 
else
logfile("Arrived at end of current parts list. cpart=" .. cpart .. " VS #parts" .. #parts)
end
if cmode and cparent < #pparts then -- when child mode, reset cpart and go to next parent
logfile("cmode was true and cparent (".. cparent .. ") was less than #pparts (".. #pparts ..") going to next parent")
cpart = 1
cparent = cparent + 1
nextParent()
return
elseif gpslot and cgparent < #gpparts then
logfile("cmode was true but parent list exhausted but cgparent (".. cgparent .. ") was less than #gpparts (".. #gpparts ..") going to next grandparent")
cpart = 1
cparent = 1
cgparent = cgparent + 1
nextGrandparent()
return
else
logfile("cmode was false or parent list exhausted, finishing")
if delayscreenshot and cpart == #parts and lastqueued then
iterqueued = true
iterframe = cframe + iterdelay
lastqueued = false
else
finish()
end
end
end
end

local function onPreRender(dtReal,dtSim,dtRaw)
cframe = cframe + 1
if cframe >= iterframe and iterqueued and running then
if delayscreenshot then
teleport()
if cpart == 0 then cpart = 1 end
logfile("Taking delayed screenshot, path: " .. "blrPartImages/" .. parts[cpart], ".png")
screenshot.doScreenshot(nil,false, "blrPartImages/" .. batch .. parts[cpart], ".png")
took = took + 1
if cpart < #parts then
cpart = cpart + 1
end
end
logfile("Calling iteration from onPreRender")
iterqueued=false
iteration(parts[cpart])
end
if cframe >= execframe and execqueued then
execqueued=false
exec(exec_slot, exec_idelay, exec_rmode, exec_cmode, exec_pslot, exec_keyword, exec_batch, exec_gpslot, exec_gkeyword)
end
if cframe >= singleframe and singlequeued then
screenshot.doScreenshot(nil,false, "blrPartImages/" .. singlebatch .. singlepart , ".png")
singlequeued = false
running = false
end
if cframe >= hframe and hqueued then
for k,v in pairs(hparts) do
screenshot.doScreenshot(nil,false, "blrPartImages/" .. hbatch .. k , ".png")
end
hqueued=false
running = false
end
end

local function cancel()
logfile("CANCELLED BY USER")
running = false
end

local function toggleAutoParentReset(toggle)
autoreset = toggle
end


M.toggleAutoParentReset = toggleAutoParentReset
M.highlightedScreenshot = highlightedScreenshot
M.getHighlightedParts = getHighlightedParts
M.singleScreenshot = singleScreenshot
M.backgroundScreenshot = backgroundScreenshot
M.logfile = logfile
M.teleport = teleport
M.cancel = cancel
M.onPreRender = onPreRender
M.onVehicleResetted = onVehicleResetted
M.start = start


return M