local M = {}

local extensions = require("extensions")

local leftTimeDigits = {}
local leftSpeedDigits = {}
local rightTimeDigits = {}
local rightSpeedDigits = {}
local lights = {}

local finishState = {}

local function setDigit(i, d, t, s)
if t == "time" then
if s == "left" then
leftTimeDigits[i]:preApply()
leftTimeDigits[i]:setField('shapeName', 0, "art/shapes/quarter_mile_display/display_".. d ..".dae")
leftTimeDigits[i]:setHidden(false)
leftTimeDigits[i]:postApply()
elseif s == "right" then
rightTimeDigits[i]:preApply()
rightTimeDigits[i]:setField('shapeName', 0, "art/shapes/quarter_mile_display/display_".. d ..".dae")
rightTimeDigits[i]:setHidden(false)
rightTimeDigits[i]:postApply()
end
elseif t == "speed" then
if s == "left" then
leftSpeedDigits[i]:preApply()
leftSpeedDigits[i]:setField('shapeName', 0, "art/shapes/quarter_mile_display/display_".. d ..".dae")
leftSpeedDigits[i]:setHidden(false)
leftSpeedDigits[i]:postApply()
elseif s == "right" then
rightSpeedDigits[i]:preApply()
rightSpeedDigits[i]:setField('shapeName', 0, "art/shapes/quarter_mile_display/display_".. d ..".dae")
rightSpeedDigits[i]:setHidden(false)
rightSpeedDigits[i]:postApply()
end
end
end

local function resetDigits()
for i=1,5 do
leftTimeDigits[i]:setHidden(true)
leftSpeedDigits[i]:setHidden(true)
rightTimeDigits[i]:setHidden(true)
rightSpeedDigits[i]:setHidden(true)
end
end

local function toggleLight(light, toggle)
lights[light]:setHidden(not toggle)
end

local function resetLights()
for k,v in pairs(lights) do
v:setHidden(true)
end
extensions.blrutils.blrvarSet("dragLightSync", -1)
end

local function loadObjects()
-- load time and speed digits
for i=1, 5 do
local leftTimeDigit = scenetree.findObject("display_time_" .. i .. "_l")
table.insert(leftTimeDigits, leftTimeDigit)
local rightTimeDigit = scenetree.findObject("display_time_" .. i .. "_r")
table.insert(rightTimeDigits, rightTimeDigit)
local rightSpeedDigit = scenetree.findObject("display_speed_" .. i .. "_r")
table.insert(rightSpeedDigits, rightSpeedDigit)
local leftSpeedDigit = scenetree.findObject("display_speed_" .. i .. "_l")
table.insert(leftSpeedDigits, leftSpeedDigit)
end
-- load christmas tree
lights = {
prestageLightL  = scenetree.findObject("Prestagelight_l"),
prestageLightR  = scenetree.findObject("Prestagelight_r"),
stageLightL     = scenetree.findObject("Stagelight_l"),
stageLightR     = scenetree.findObject("Stagelight_r"),
amberLight1R    = scenetree.findObject("Amberlight1_R"),
amberLight2R    = scenetree.findObject("Amberlight2_R"),
amberLight3R    = scenetree.findObject("Amberlight3_R"),
amberLight1L    = scenetree.findObject("Amberlight1_L"),
amberLight2L    = scenetree.findObject("Amberlight2_L"),
amberLight3L    = scenetree.findObject("Amberlight3_L"),
greenLightR     = scenetree.findObject("Greenlight_R"),
greenLightL     = scenetree.findObject("Greenlight_L"),
redLightR       = scenetree.findObject("Redlight_R"),
redLightL       = scenetree.findObject("Redlight_L")
}
-- reset for good measure
resetLights()
resetDigits()
end

local function setTime(side, val)
local index=1
if val > 99.999 then val = 99.999 end
local integer = math.floor(val)
local fraction = math.fmod(val,1)
local istr = string.format("%02d", integer)
local fstr = string.sub(string.format("%.3f", fraction), 2,-1)
for n in string.gmatch((istr..fstr), "%d") do
setDigit(index, n, "time", side)
index = index+1
end
end

local function setSpeed(side, val)
local index=1
val = val * 3.6
if units == "imperial" then val = val / 1.609 end
if val > 999.99 then val = 999.99 end
local units = extensions.blrutils.getSettingValue("uiUnits")
local integer = math.floor(val)
local fraction = math.fmod(val,1)
local istr = string.format("%03d", integer)
local fstr = string.sub(string.format("%.2f", fraction), 2,-1)
for n in string.gmatch((istr..fstr), "%d") do
setDigit(index, n, "speed", side)
index = index+1
end
end

local function setFinished(side)
finishState[side] = true
end

local function getFinished(side)
return finishState[side]
end


local function countdown(step)
if step == "prestage" then
toggleLight("prestageLightL", true)
toggleLight("prestageLightR", true)
toggleLight("stageLightL", false)
toggleLight("stageLightR", false)
extensions.blrutils.blrvarSet("dragLightSync", "prestage")
elseif step == "stage" then
toggleLight("stageLightL", true)
toggleLight("stageLightR", true)
extensions.blrutils.blrvarSet("dragLightSync", "stage")
elseif step == "3" then
toggleLight("amberLight1L", true)
toggleLight("amberLight1R", true)
extensions.blrutils.blrvarSet("dragLightSync", 3)
elseif step == "2" then
toggleLight("amberLight2L", true)
toggleLight("amberLight2R", true)
extensions.blrutils.blrvarSet("dragLightSync", 2)
elseif step == "1" then
toggleLight("amberLight3L", true)
toggleLight("amberLight3R", true)
extensions.blrutils.blrvarSet("dragLightSync", 1)
elseif step == "0" then
resetLights()
toggleLight("greenLightL", true)
toggleLight("greenLightR", true)
extensions.blrutils.blrvarSet("dragLightSync", 0)
end
end

local currentCam = {}
local currentFOV = 0
local camTransforms = {
  west_coast_usa = "[123.70, 75.43, 120.50, -0.0177324, 0.0090892, 0.456055, 0.889729]"
}
local function finishCamera(rstDelay)
if extensions.blrglobals.blrFlagGet("dragslowmo") then
currentCam = core_camera.getActiveCamName()
currentFOV = core_camera.getFovDeg()
simTimeAuthority.set(1/100)
commands.setFreeCamera()
commands.setFreeCameraTransformJson(camTransforms[extensions.blrutils.getLevelName()])
core_camera.setFOV(0, 12)
extensions.blrdelay.queue("dragcamreset", nil, rstDelay, "time")
end
end

local function resetCamera()
simTimeAuthority.set(1)
if currentCam and core_camera then
commands.setGameCamera()
core_camera.setFOV(0, currentFOV)
core_camera.setByName(0, currentCam, true)
end
end

local function resetFinishedStates()
finishState = {}
end

M.resetFinishedStates = resetFinishedStates
M.getFinished = getFinished
M.setFinished = setFinished
M.resetCamera = resetCamera
M.finishCamera = finishCamera
M.countdown = countdown
M.setSpeed = setSpeed
M.setTime = setTime
M.toggleLight = toggleLight
M.resetLights = resetLights
M.setStageLight = setStageLight
M.resetDigits = resetDigits
M.setDigit = setDigit
M.loadObjects = loadObjects

return M