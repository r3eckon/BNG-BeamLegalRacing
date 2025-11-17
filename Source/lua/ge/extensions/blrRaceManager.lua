local M = {}
local extensions = require("extensions")
local guihooks = require("guihooks")

local raceCheckpoints = {}
local raceLaps = 0
local raceVehicles = {}

local ccptable = {} -- CONTAINS CURRENT CHECKPOINT INDICES USED BY THE raceCheckpoints TABLE
local claptable = {}
local finishState = {}
local leaderboard = {}
local finishTime = {}
local finishCount = 0

-- Final boss event mode, uses victory count instead of time for leaderboard
local bossmode = false
local points = {}

local idtable = {}
local nametable = {}

local started = false
local winner = -1
local blrtime = 0
local startTime = 0

local ppos = 0 -- Manually set in flowgraph during position calculation

local uidata = {}

local pentrigs = {}
local pentimes = {}
local pentracker = {} -- Ensures each penalty trigger can only be hit once per lap

local pitlane = false -- Do not confuse with pitenabled, global flag telling if track has pit data
local pittrigs = {}
local pitentry = ""
local pitexit = ""
local pitenabler = ""
local pitdisabler = ""
local pitpos = {}
local pitrot = {}
local pitpenalty = false
local pitenabled = false -- Turns on when pit enabler is hit, prevents player skipping laps using pit lane


local prefabs = {}

local function spawnPrefabs(list)
local ptable = extensions.blrutils.ssplit(list, ",")
prefabs = {}

local cprefab = {}
local cid = {}
local ccount = 1

for k,v in pairs(ptable) do
cprefab = spawnPrefab("blrTrackEventPrefab_" .. ccount, v, "0 0 0", "0 0 1 0", "1 1 1", false)
cid = cprefab:getId()
scenetree.missionGroup:add(cprefab)
ccount = ccount + 1
table.insert(prefabs, cid)
end

be:reloadCollision()
end

local function deletePrefabs()
for k,v in pairs(prefabs) do
scenetree.findObjectById(v):delete()
end
prefabs = {}
be:reloadCollision()
end




local function getPitMarkerData()
local toRet = {}
toRet["pos"] = pitpos
toRet["rot"] = pitrot
return toRet
end

local function setPitData(haspit, trigs, spos, srot)
pitlane = haspit
if pitlane then
pittrigs = {}
pitentry = trigs[1]
pitexit = trigs[2]
pitenabler = trigs[3]
pitdisabler = trigs[4]
pittrigs[pitentry] = true
pittrigs[pitexit] = true
pittrigs[pitenabler] = true
pittrigs[pitdisabler] = true
pitpos = spos
pitrot = srot
end
end


local function setUIData(d)
uidata = d
end

local function getUIData()
return uidata
end

local function generateNameTable(seed, count) -- Doesn't generate name for player at ID 1
local picks = extensions.blrutils.loadDataFile("beamLR/opnames")
local cpick = ""
local used = {}
math.randomseed(seed)
for i=2,count do
cpick = math.random(1, #picks)
while used[cpick] do -- Need to ensure there are enough picks to avoid infinite loop
cpick = math.random(1, #picks)
end
nametable[i] = picks[cpick]
used[cpick] = true
end
end

local function resetNameTable()
nametable = {}
end

local function getRacerName(id)
return nametable[id]
end

local function setPlayerName(name)
nametable[1] = name
end

local function getPlayerPosition()
return ppos
end

local function setPlayerPosition(pos)
ppos = pos
end

local function getIDtable()
return idtable
end

local function resetIDtable()
idtable = {}
end

local function setRacerID(vehid, racerid)
idtable[vehid] = racerid
end

local function racerFinished(racer)
finishCount = finishCount+1  -- increment finish counter (val init at 0, first id in table is 1 as expected)
leaderboard[finishCount] = racer -- add racer to leaderboard
finishState[racer] = true	 -- set racer finish state
finishTime[racer] = (blrtime - startTime) + (pentimes[racer] or 0)  -- set finish time, now with penalty time added
if bossmode and finishCount == 1 then points[idtable[racer] or racer] = 1 end
if idtable[racer] == 1 then -- player finished
--print("PLAYER FINISHED, TRIGGERING HOOK!")
guihooks.trigger("BeamLRRaceFinished")
end
end

local function onCheckpointReached(racer, checkpoint)
if started and not finishState[racer] then -- check if race is running and racer hasn't finished yet
local ccpid = ccptable[racer]
local clap = claptable[racer]
local ccp = raceCheckpoints[ccpid]

if checkpoint == ccp then -- racer reached current checkpoint
if ccpid == #raceCheckpoints then -- racer reached last checkpoint in path
if clap == raceLaps then	 -- racer was on last lap
racerFinished(racer)
if winner == -1 then		 -- no one finished before this racer
winner = racer				-- set racer as winner
end

else					  --racer wasn't on last lap
claptable[racer] = clap+1 --increment to next lap and
ccptable[racer] = 1		  --return to first checkpoint
pentracker[racer] = {} 	  -- Reset penalty tracker for new lap
end
else					  -- checkpoint reached isn't last checkpoint
ccptable[racer] = ccpid+1 -- increment to next checkpoint
end
end

end

end

local function onPenaltyTriggerEntered(racer, trig) -- Could have different penalty for each trig, using +10 seconds for now
if not pentracker[racer][trig] then -- Prevents same penalty from being added twice in same lap
pentimes[racer] = (pentimes[racer] or 0) + 10000 -- Adds penalty time for racer
pentracker[racer][trig] = true -- Set tracked penalty state
if idtable[racer] == 1 then -- Player was racer, trigger penalty message
extensions.blrglobals.blrFlagSet("showPenaltyMessage", true)
extensions.blrutils.blrvarSet("penaltyMessage", extensions.blrlocales.translate("beamlr.imgui.track.penalty_shortcut"))
end
end
end


local function onPitOverspeed(racer)
if not pitpenalty then
pentimes[racer] = (pentimes[racer] or 0) + 10000 -- Adds penalty time for racer
pitpenalty = true
if idtable[racer] == 1 then -- Player was racer, trigger penalty message
extensions.blrglobals.blrFlagSet("showPenaltyMessage", true)
extensions.blrutils.blrvarSet("penaltyMessage", extensions.blrlocales.translate("beamlr.imgui.track.penalty_pitspeed"))
end
end
end


local function onPitLaneExit(racer) -- Force set to next lap & first checkpoint, handles pit finish
if started and not finishState[racer] then -- check if race is running and racer hasn't finished yet

local ccpid = ccptable[racer]
local clap = claptable[racer]
local ccp = raceCheckpoints[ccpid]

if clap == raceLaps then	 -- racer was on last lap
racerFinished(racer)
if winner == -1 then		 -- no one finished before this racer
winner = racer				-- set racer as winner
end
else					  --racer wasn't on last lap
claptable[racer] = clap+1 --increment to next lap and
ccptable[racer] = 1		  --return to first checkpoint
pentracker[racer] = {} 	  -- Reset penalty tracker for new lap
end
end


end


local function onPitTriggerEntered(racer, trig)
if idtable[racer] == 1 then -- Only allow player pitting for now

if trig == pitentry and pitenabled then
extensions.blrglobals.blrFlagSet("playerPitting", true)
elseif trig == pitexit and pitenabled then
extensions.blrglobals.blrFlagSet("playerPitting", false)
pitenabled=false
pitpenalty=false
onPitLaneExit(racer)
elseif trig == pitenabler then
pitenabled = true
elseif trig == pitdisabler then
pitenabled = false
pitpenalty = false
extensions.blrglobals.blrFlagSet("playerPitting", false) -- To prevent any exploit caused by entering then leaving pit backwards
end

end
end

local function processTriggerUpdate(eventTable, triggerTable)
local cevent = ""
local ctrig = ""
for k,v in pairs(raceVehicles) do
cevent = eventTable[v] or ""
ctrig = triggerTable[v] or ""

if cevent == "enter" and ctrig == raceCheckpoints[ccptable[v]] and not finishState[v] then --racer has entered current cp trigger
onCheckpointReached(v, ctrig)
end

if cevent == "enter" and pentrigs[ctrig] and not finishState[v] then --racer has entered a penalty trigger
onPenaltyTriggerEntered(v, ctrig)
end

if cevent == "enter" and pittrigs[ctrig] and not finishState[v] then --racer has entered a pit trigger
onPitTriggerEntered(v, ctrig)
end

end
end

local function setRaceParams(racers, checkpoints, laps)
raceVehicles = racers
raceCheckpoints = checkpoints
claptable = {}
finishState = {}
finishTime = {}
points = {}
pentimes = {}
pentracker = {}
ccptable = {}
leaderboard = {}
finishCount = 0
winner = -1
raceLaps = laps
pitpenalty=false
pitenabled=false
for k,v in pairs(racers) do -- sets current cp for all racers to first cp
ccptable[v] = 1
claptable[v] = 1
finishState[v] = false
pentracker[v] = {} -- Reset penalty tracker
points[k] = 0
end
end

local function setRaceRunning(running)
started = running
if started then 
startTime = blrtime
end
end

local function getWinner()
return winner
end

local function getLeaderboard()
return leaderboard
end

local function getCurrentCheckpoint(racer)
return raceCheckpoints[ccptable[racer]]
end

local function getFollowingCheckpoint(racer)
local toRet = ""
if ccptable[racer] == #raceCheckpoints then
toRet = raceCheckpoints[1]
else
toRet = raceCheckpoints[ccptable[racer]+1]
end
return toRet
end

local function blackMarkerCheck(racer) -- true if next (black) checkpoint marker should be rendered
local toRet = true
if claptable[racer] == raceLaps and ccptable[racer] == #raceCheckpoints then
toRet = false
end
return toRet
end

local function getCurrentLap(racer)
return claptable[racer]
end

local function getRacerFinished(racer)
return finishState[racer]
end

local function getLeaderboardPosition(racer)
local toRet = -1
for k,v in pairs(leaderboard) do
if racer == v then
toRet = k
end
end
return toRet
end

local function getCCPID(racer)
return ccptable[racer]
end

local function isRaceStarted()
return started
end

-- Used to keep track of race times with working pause function
local function onPreRender(dtReal,dtSim,dtRaw)
blrtime = blrtime + dtSim * 1000
end

local function getTotalRaceTime()
return blrtime - startTime
end

local function getRaceStartTime()
return startTime
end

local function getRacerTime(racer)
local toRet = getTotalRaceTime()
if not started then
toRet = 0
elseif finishState[racer] then
toRet = finishTime[racer]
end
return toRet
end

local function getTimes()
return finishTime
end

local function msTimeFormat(time)
local toRet = {}
toRet["hours"] = math.floor(time / 3600000)
toRet["minutes"] = math.floor((time / 60000) - toRet["hours"] * 60)
toRet["seconds"] = math.floor((time / 1000) - ((toRet["hours"] * 3600) + toRet["minutes"] * 60))
toRet["milliseconds"] = time - (toRet["hours"] * 3600000 + toRet["minutes"] * 60000 + toRet["seconds"]*1000)
return toRet
end

local function raceTimeString(time)
if time["hours"] > 0 then
return string.format("%02d:%02d:%02d.%03d",time["hours"], time["minutes"], time["seconds"], time["milliseconds"])
else
return string.format("%02d:%02d.%03d", time["minutes"], time["seconds"], time["milliseconds"])
end
end

local function setPenaltyTriggers(trigs)
pentrigs = {}
for k,v in pairs(trigs) do
pentrigs[v] = true
end
end

local function getPenaltyTriggers()
return pentrigs
end

local function getPointCounts()
return points
end

local function setBossMode(mode)
bossmode = mode
end

M.deletePrefabs = deletePrefabs
M.spawnPrefabs = spawnPrefabs
M.racerFinished = racerFinished
M.setBossMode = setBossMode
M.getPointCounts = getPointCounts
M.getPenaltyTriggers = getPenaltyTriggers
M.getPitMarkerData = getPitMarkerData
M.onPitOverspeed = onPitOverspeed
M.onPitLaneExit = onPitLaneExit
M.onPitTriggerEntered = onPitTriggerEntered
M.setPitData = setPitData
M.onPenaltyTriggerEntered = onPenaltyTriggerEntered
M.setPenaltyTriggers = setPenaltyTriggers
M.getUIData = getUIData
M.setUIData = setUIData
M.generateNameTable = generateNameTable
M.resetNameTable = resetNameTable
M.getRacerName = getRacerName
M.setPlayerName = setPlayerName
M.setPlayerPosition = setPlayerPosition
M.getPlayerPosition = getPlayerPosition
M.getIDtable = getIDtable
M.resetIDtable = resetIDtable
M.setRacerID = setRacerID
M.raceTimeString = raceTimeString
M.msTimeFormat = msTimeFormat
M.getTimes = getTimes
M.getRacerTime = getRacerTime
M.getRaceStartTime = getRaceStartTime
M.onPreRender = onPreRender
M.getTotalRaceTime = getTotalRaceTime
M.isRaceStarted = isRaceStarted
M.getCCPID = getCCPID
M.getRacerFinished = getRacerFinished
M.getLeaderboardPosition = getLeaderboardPosition
M.processTriggerUpdate = processTriggerUpdate
M.blackMarkerCheck = blackMarkerCheck
M.getCurrentLap = getCurrentLap
M.getFollowingCheckpoint = getFollowingCheckpoint
M.getCurrentCheckpoint = getCurrentCheckpoint
M.getLeaderboard = getLeaderboard
M.getWinner = getWinner
M.setRaceRunning = setRaceRunning
M.setRaceParams = setRaceParams
M.onCheckpointReached = onCheckpointReached

return M