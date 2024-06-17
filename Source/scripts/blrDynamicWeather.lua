local M = {}
local extensions = require("extensions")
local env = core_environment

local cloudCoverMax = 5.0
local cloudCoverMin = 0.0
local cloudCoverDefault = 0.2
local cloudCoverRange = { 0.0, 5.0 }
local cloudCoverFrames = {}

local windSpeedMax = 10.0
local windSpeedMin = 0.0
local windSpeedDefault = 0.03
local windSpeedRange = { 0.03, 4.6 }
local windSpeedFrames = {}

local fogDensityMax = 20.0
local fogDensityMin = 0.0
local fogDensityDefault = 0.0006
local fogDensityRange = { 0.0002, 0.04 }
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
cstate.fogDensity = fd * 1000.0 -- multiply by 1000 since setState expects UI data
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
savedState = env.getState()
end

local function restoreSavedState()
--env.setState(savedState)
env.setCloudCover(savedState.cloudCover)
env.setWindSpeed(savedState.windSpeed)
setFogDensity(savedState.fogDensity / 1000.0)
end

local function getTOD()
return math.fmod(env.getTimeOfDay()["time"] + 0.5, 1.0)
end

local function generateWeatherFrames()
local s = extensions.blrutils.getDailySeed()
local o = extensions.blrutils.getDailySeedOffset()

cacheID = s -- used to invalidate cached frames on new day


local ccvar = extensions.blrutils.blrvarGet("ccvar") or 0
local wsvar = extensions.blrutils.blrvarGet("wsvar") or 0
local fdvar = extensions.blrutils.blrvarGet("fdvar") or 0

local ccpow = 1.0 + (1.0 - ccvar) * 3.0
local wspow = 1.0 + (1.0 - wsvar) * 2.0
local fdpow = 1.0 + (1.0 - fdvar) * 6.0 -- high power to make heavy fog less likely

local frames = {}
frames["cloudCover"] = {}
frames["windSpeed"] = {}
frames["fogDensity"] = {}

-- start by generating initial frame using previous day seed
math.randomseed(s-o)
math.random() -- skip one to get previous day's last frame
frames["cloudCover"][1] = math.random() ^ ccpow
math.random()
frames["windSpeed"][1] = math.random() ^ wspow
math.random()
frames["fogDensity"][1] = math.random() ^ fdpow

-- now generating new frames for current day
math.randomseed(s)
frames["cloudCover"][2] = math.random() ^ ccpow
frames["cloudCover"][3] = math.random() ^ ccpow

frames["windSpeed"][2] = math.random() ^ wspow
frames["windSpeed"][3] = math.random() ^ wspow

frames["fogDensity"][2] = math.random() ^ fdpow 
frames["fogDensity"][3] = math.random() ^ fdpow 

-- cache generated frames 
cloudCoverFrames = frames["cloudCover"]
windSpeedFrames = frames["windSpeed"]
fogDensityFrames = frames["fogDensity"]

--print("GENERATED FRAME DATA (SEED: " .. s .. ")")
--dump(frames)

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

local ccval = lerp(cloudCoverFrames[sframe], cloudCoverFrames[eframe], lerpval)
local wsval = lerp(windSpeedFrames[sframe], windSpeedFrames[eframe], lerpval)
local fdval = lerp(fogDensityFrames[sframe], fogDensityFrames[eframe], lerpval)

--print("LERP VALS: " .. ccval .. "\t" .. wsval .. "\t" .. fdval)

local cloudCover = lerp(cloudCoverRange[1], cloudCoverRange[2], ccval)
local windSpeed = lerp(windSpeedRange[1], windSpeedRange[2], wsval)
local fogDensity = lerp(fogDensityRange[1], fogDensityRange[2], fdval)

--print("ACTUAL VALS: " .. cloudCover .. "\t" .. windSpeed .. "\t" .. fogDensity)

-- Setting UI variability values to 0 will force dynamic weather system
-- to use saved state values, keeping freeroam set parameters
if (extensions.blrutils.blrvarGet("ccvar") or 0) > 0 then
env.setCloudCover(cloudCover)
else 
env.setCloudCover(savedState.cloudCover)
end
if (extensions.blrutils.blrvarGet("wsvar") or 0) > 0 then
env.setWindSpeed(windSpeed)
else
env.setWindSpeed(savedState.windSpeed)
end
if (extensions.blrutils.blrvarGet("fdvar") or 0) > 0 then
setFogDensity(fogDensity)
else
setFogDensity(savedState.fogDensity / 1000.0)
end
end

local function onPreRender(dtReal,dtSim,dtRaw)
if enabled then updateWeather() end
end



M.initcache = initcache
M.saveCurrentState = saveCurrentState
M.restoreSavedState = restoreSavedState
M.setFogDensity = setFogDensity
M.toggle = toggle
M.onPreRender = onPreRender
M.generateWeatherFrames = generateWeatherFrames
M.updateWeather = updateWeather

return M