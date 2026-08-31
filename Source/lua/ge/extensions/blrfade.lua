local M = {}

-- 1.20 reworked script with simplified state tracking from a bunch of bools to a single state var

-- state can be: 
-- off (play mode)
-- to (fading to black)
-- on (fade screen)
-- from (fading from black)
local state = "off"
local stateChanged = false

local function getState()
return state
end

local function setState(s)
if state ~= s then
state = s
stateChanged = true
end
end

-- state change flag gets consumed then reset to false
local function getStateChanged()
if stateChanged then
stateChanged = false
return true 
end
return false
end

local function fadeToBlack(duration)
if state == "off" then
print("Fading to black in " .. duration .. " seconds")
setState("to")
ui_fadeScreen.start(duration or 1)
end
end

local function fadeFromBlack(duration)
if state == "on" then
print("Fading from black in " .. duration .. " seconds")
setState("from")
ui_fadeScreen.stop(duration or 1)
end
end

-- vanilla state value
-- 1 = screen fully black
-- 3 = screen fully visible
local function onScreenFadeState(state)
if state == 1 then setState("on") end
if state == 3 then setState("off") end
end

local function isState(s)
return state == s
end

local function instantToBlack()
setState("on")
ui_fadeScreen.start(0.1)
end

local function instantFromBlack()
setState("off")
ui_fadeScreen.stop(0.1)
end

M.instantFromBlack = instantFromBlack
M.instantToBlack = instantToBlack
M.getStateChanged = getStateChanged
M.fadeFromBlack = fadeFromBlack
M.fadeToBlack = fadeToBlack
M.setState = setState
M.getState = getState
M.onScreenFadeState = onScreenFadeState
M.isState = isState


return M