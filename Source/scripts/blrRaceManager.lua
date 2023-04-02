local M = {}
local extensions = require("extensions")


local raceCheckpoints = {}
local raceLaps = 0
local raceVehicles = {}

local ccptable = {} -- CONTAINS CURRENT CHECKPOINT INDICES USED BY THE raceCheckpoints TABLE
local claptable = {}
local finishState = {}
local leaderboard = {}
local finishTime = {}
local finishCount = 0

local started = false
local winner = -1
local blrtime = 0
local startTime = 0

local function racerFinished(racer)
finishCount = finishCount+1  -- increment finish counter (val init at 0, first id in table is 1 as expected)
leaderboard[finishCount] = racer -- add racer to leaderboard
finishState[racer] = true	 -- set racer finish state
finishTime[racer] = blrtime - startTime  -- set finish time
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
end
else					  -- checkpoint reached isn't last checkpoint
ccptable[racer] = ccpid+1 -- increment to next checkpoint
end
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
end
end

local function setRaceParams(racers, checkpoints, laps)
raceVehicles = racers
raceCheckpoints = checkpoints
claptable = {}
finishState = {}
finishTime = {}
ccptable = {}
leaderboard = {}
finishCount = 0
winner = -1
raceLaps = laps
for k,v in pairs(racers) do -- sets current cp for all racers to first cp
ccptable[v] = 1
claptable[v] = 1
finishState[v] = false
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
return string.format("%02d:%02d.%03d", time["minutes"], time["seconds"], time["milliseconds"])
end

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