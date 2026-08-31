local M = {}
local extensions = require("extensions")
local env = core_environment


-- BeamNG 0.39 updated values
-- higher variability power means values far from default are less likely, must be >= 1.0
local cloudCoverMax = 3.0
local cloudCoverMin = 0.0
local cloudCoverDefault = 1
local cloudCoverVariabilityPower = 1.5
local cloudCoverFrames = {}

local windSpeedMax = 2.0
local windSpeedMin = 0.01
local windSpeedDefault = 0.5
local windSpeedVariabilityPower = 4.0
local windSpeedFrames = {}

local fogDensityMax = 50.0
local fogDensityMin = 0.1
local fogDensityDefault = 0.3
local fogDensityVariabilityPower = 25.0
local fogDensityFrames = {}

local enabled = false

local cacheID = -1

local function initcache()
cacheID = -1
cloudCoverFrames = {}
windSpeedFrames = {}
fogDensityFrames = {}
end

-- need this otherwise setting fog density has a weird flickering effect
local function setFogDensity(fd)
local cstate = env.getState()
cstate.fogDensity = fd -- multiply by 1000 since setState expects UI data
env.setState(cstate)
end

local function toggle(t)
enabled = t
end

local function lerp(mn,mx,v)
local range = mx-mn
return mn + range * v
end

local savedState = {}

local function saveCurrentState()
savedState = deepcopy(env.getState())
end

local function restoreSavedState()
--env.setState(savedState)
env.setCloudCover(savedState.cloudCover)
env.setWindSpeed(savedState.windSpeed)
setFogDensity(savedState.fogDensity)
M.setEnvDate(savedState.day, savedState.month, savedState.year)
end

local function getTOD()
return math.fmod(env.getTimeOfDay()["time"] + 0.5, 1.0)
end

-- 1.20 updated function for more representative variability values 
--
-- var(iability) influences how spread out or close to default values are
-- var close to 0 = returned values close to default
-- var close to 1 = return values spread more evenly
-- var of exactly 1 will distribute evenly across range 
-- var of exactly 0 returns the default value
--
-- varpow influences how unlikely values get as they get far from default (between 1 and 10 is good)
-- varpow of 10 with variability of 0.1 = ~96% of values close to default, ~1% near min or max
-- varpow of 1 with variability of 0.1 = ~60% close to default, ~10% near min or max
--
-- basically:
-- high variability spreads values evenly regardless of varpow
-- low variability with low varpow = values mostly around default but decent chance of extremes
-- low variability with high varpow = values mostly very close to default with tiny chance of extremes

local function generateFrame(vmin, vmax, vdefault, var, varpow, seedskip)

if var == 0 then return vdefault end -- early return if variability is 0, just return default value

-- when seed skip value is defined skip that amount of rolls * 2 because each call of generateFrame has 2 rolls
if seedskip then
for i=1,seedskip do
math.random()
math.random()
end
end

local range = vmax - vmin
local rval = vmin + (math.random() * range)
local defoffset = rval - vdefault -- how far current value is from default
local defpull = (1.0 - var) - ((1.0 - var) * (math.random() ^ varpow)) -- how much to pull the value towards default

return rval - (defoffset * defpull)
end

local ccvar_last = -999
local wsvar_last = -999
local fdvar_last = -999

local ccvar_current = 0
local wsvar_current = 0
local fdvar_current = 0

-- 1.20 updated to use new generateFrame function
local function generateWeatherFrames(so, oo) -- so and oo are seed and offset overrides for testing purposes

local s = so or extensions.blrutils.getDailySeed()
local o = oo or extensions.blrutils.getDailySeedOffset()
cacheID = s -- used to invalidate cached frames on new day

local ccvar = extensions.blrutils.blrvarGet("ccvar") or 0
local wsvar = extensions.blrutils.blrvarGet("wsvar") or 0
local fdvar = extensions.blrutils.blrvarGet("fdvar") or 0


local frames = {}
frames["cloudCover"] = {}
frames["windSpeed"] = {}
frames["fogDensity"] = {}


-- start with previous day last frame as first frame for current day
-- need to skip 1,3,5 rolls respectively to get last rolled frame from last day for each item
math.randomseed(s - o)
frames["cloudCover"][1] = generateFrame(cloudCoverMin, cloudCoverMax, cloudCoverDefault, ccvar, cloudCoverVariabilityPower, 1)
frames["windSpeed"][1] = generateFrame(windSpeedMin, windSpeedMax, windSpeedDefault, wsvar, windSpeedVariabilityPower, 1)
frames["fogDensity"][1] = generateFrame(fogDensityMin, fogDensityMax, fogDensityDefault, fdvar, fogDensityVariabilityPower, 1)


-- now generating current day frames
math.randomseed(s)
frames["cloudCover"][2] = generateFrame(cloudCoverMin, cloudCoverMax, cloudCoverDefault, ccvar, cloudCoverVariabilityPower)
frames["cloudCover"][3] = generateFrame(cloudCoverMin, cloudCoverMax, cloudCoverDefault, ccvar, cloudCoverVariabilityPower)
frames["windSpeed"][2] = generateFrame(windSpeedMin, windSpeedMax, windSpeedDefault, wsvar, windSpeedVariabilityPower)
frames["windSpeed"][3] = generateFrame(windSpeedMin, windSpeedMax, windSpeedDefault, wsvar, windSpeedVariabilityPower)
frames["fogDensity"][2] = generateFrame(fogDensityMin, fogDensityMax, fogDensityDefault, fdvar, fogDensityVariabilityPower)
frames["fogDensity"][3] = generateFrame(fogDensityMin, fogDensityMax, fogDensityDefault, fdvar, fogDensityVariabilityPower)

-- cache generated frames 
cloudCoverFrames = frames["cloudCover"]
windSpeedFrames = frames["windSpeed"]
fogDensityFrames = frames["fogDensity"]

return frames
end

local function updateWeather()
local t = getTOD()

if cacheID ~= extensions.blrutils.getDailySeed() then
generateWeatherFrames()
--print("GENERATED WEATHER FRAMES USING SEED " .. extensions.blrutils.getDailySeed())
else
if t > 0.9999 or t < 0.0001 then 
--print("WAITING FOR DAY CHANGE...")
return 
end 
end

local sframe = 1
local eframe = 2
local lerpval = (t / 0.5)
if t >= 0.5 then
sframe = 2
eframe = 3
lerpval = ((t - 0.5) / 0.5)
end


--print("MAIN LERP: " .. lerpval)

local cloudCover = lerp(cloudCoverFrames[sframe], cloudCoverFrames[eframe], lerpval)
local windSpeed = lerp(windSpeedFrames[sframe], windSpeedFrames[eframe], lerpval)
local fogDensity = lerp(fogDensityFrames[sframe], fogDensityFrames[eframe], lerpval)

--print("LERP VALS: " .. cloudCover .. "\t" .. windSpeed .. "\t" .. fogDensity)

-- fetch current variability values
ccvar_current = extensions.blrutils.blrvarGet("ccvar") or 0
wsvar_current = extensions.blrutils.blrvarGet("wsvar") or 0
fdvar_current = extensions.blrutils.blrvarGet("fdvar") or 0

-- Setting UI variability values to 0 will force dynamic weather system
-- to use saved state values, keeping freeroam set parameters
if ccvar_current > 0 then
env.setCloudCover(cloudCover)
elseif ccvar_current ~= ccvar_last then -- optimization, avoid setting again if variability of 0 didn't change
env.setCloudCover(savedState.cloudCover)
end

if wsvar_current > 0 then
env.setWindSpeed(windSpeed)
elseif wsvar_current ~= wsvar_last then
env.setWindSpeed(savedState.windSpeed)
end

if fdvar_current > 0 then
setFogDensity(fogDensity)
elseif fdvar_current ~= fdvar_last then
setFogDensity(savedState.fogDensity)
end

-- update last variability values
ccvar_last = ccvar_current
wsvar_last = wsvar_current
fdvar_last = fdvar_current


end

-- 1.20 function to set environment date from lua
local function setEnvDate(day, month, year, dayOffset)
local state = env.getState()

if not dayOffset then
state.day = day
state.month = month
state.year = year
else
local cdate = {day = day, month = month, year = year}
local newtime = os.time{year=cdate.year, month=cdate.month, day=cdate.day+dayOffset}
local newdate = os.date("*t", newtime)
state.day = newdate.day
state.month = newdate.month
state.year = newdate.year
end

--print("TRIED TO SENT ENV DATE TO " .. state.day .. "/" .. state.month .. "/" .. state.year)

env.setState(state)
end

-- 1.20 function, goes to next environment day, used during day change detection
local function envIncrementDay(amount)
if amount and amount == 0 then return end
local state = env.getState()
local cdate = {day = state.day, month = state.month, year = state.year}
local newtime = os.time{year=cdate.year, month=cdate.month, day=cdate.day+(amount or 1)}
local newdate = os.date("*t", newtime)

state.day = newdate.day
state.month = newdate.month
state.year = newdate.year

env.setState(state)
end


local ctime = 0
local ltime = 0

local function updateDate()
ctime = env.getTimeOfDay().time
if ltime < 0.5 and ctime > 0.5 then
envIncrementDay()
end
ltime = ctime
end

local function onPreRender(dtReal,dtSim,dtRaw)
if enabled then 
updateWeather()
updateDate()
end
end

M.envIncrementDay = envIncrementDay
M.setEnvDate = setEnvDate
M.generateFrame = generateFrame
M.initcache = initcache
M.saveCurrentState = saveCurrentState
M.restoreSavedState = restoreSavedState
M.setFogDensity = setFogDensity
M.toggle = toggle
M.onPreRender = onPreRender
M.generateWeatherFrames = generateWeatherFrames
M.updateWeather = updateWeather

return M