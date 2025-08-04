local M = {}

local todone = false
local fromdone = false
local inprogress = false
local toready = true
local fromready = true

local function fadeToBlack(duration)
if inprogress or not toready then return end
todone = false
inprogress = true
toready = false
ui_fadeScreen.start(duration or 1)
end

local function fadeFromBlack(duration)
if inprogress or not fromready then return end
fromdone = false
inprogress = true
fromready = false
ui_fadeScreen.stop(duration or 1)
end

-- state value
-- 1 = screen fully black
-- 2 = screen fading in
-- 3 = screen fully visible
local function onScreenFadeState(state)
if state == 1 then todone = true end
if state == 3 then fromdone = true end
end

local function getFromDone()
local toRet = fromdone
if fromdone then 
fromdone = false 
inprogress = false
end
return toRet
end

local function getToDone()
local toRet = todone
if todone then 
todone = false 
inprogress = false
end
return toRet
end

local function setToReady()
toready = true
end

local function setFromReady()
fromready = true
end

M.setFromReady = setFromReady
M.setToReady = setToReady
M.getToDone = getToDone
M.getFromDone = getFromDone
M.fadeToBlack = fadeToBlack
M.fadeFromBlack = fadeFromBlack
M.onScreenFadeState = onScreenFadeState

return M