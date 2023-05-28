-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local guihooks = require('guihooks')

local uidata = {}


local function sendDataToUI(k,v) -- For BLR main menu
local d = {}
d.key = k
d.val = v
guihooks.trigger("beamlrData", d)
end

local function sendDataToEngine(k,v)
uidata[k] = v
end

local function getUIData(k)
return uidata[k]
end

local function sendCurrentDrift(v)
guihooks.trigger("beamlrCurrentDrift", v)
end

local function sendTotalDrift(v)
guihooks.trigger("beamlrTotalDrift", v)
end

local function toggleDriftUI(t)
guihooks.trigger("beamlrToggleDriftUI", t)
end

local function sendEventData(d)
guihooks.trigger("beamlrEventData", d)
end

local function toggleTrackEventUI(t)
guihooks.trigger("beamlrToggleTrackEventUI", t)
end

local function sendLeaderboard(l)
guihooks.trigger("beamlrEventLeaderboard", l)
end

local function sendRewards(r)
guihooks.trigger("beamlrEventRewards", r)
end

local function toggleTrackTuningUI(t)
guihooks.trigger("beamlrToggleTrackTuningUI", t)
end

local function sendTrackTuningData(d)
guihooks.trigger("beamlrTrackTuningData", d)
end

local function sendTrackTuningValues(d)
guihooks.trigger("beamlrTrackTuningValues", d)
end

local function sendEventBrowserData(d)
guihooks.trigger("beamlrEventBrowserData", d)
end

local function sendEventBrowserList(d)
guihooks.trigger("beamlrEventBrowserList", d)
end

local function sendEventBrowserGarage(d)
guihooks.trigger("beamlrEventBrowserGarage", d)
end
	  
local function sendEventBrowserCarData(d)
guihooks.trigger("beamlrEventBrowserCarData", d)
end

local function toggleTrackEventBrowser(d)
guihooks.trigger("beamlrToggleTrackEventBrowser", d)
end

local function sendEventBrowserPlayerData(d)
guihooks.trigger("beamlrEventBrowserPlayerData", d)
end

local function sendEventBrowserVehicleDamage(d)
guihooks.trigger("beamlrEventBrowserVehicleDamage", d)
end

local function sendEventBrowserInspectionStatus(d)
guihooks.trigger("beamlrEventBrowserInspectionStatus", d)
end

local function sendEventBrowserCurrentEventData(d)
guihooks.trigger("beamlrEventBrowserCurrentEvent", d)
end

local function sendTrackTuningCategories(d)
guihooks.trigger("beamlrTrackTuningCategories", d)
end

local function sendTrackTuningFields(d)
guihooks.trigger("beamlrTrackTuningFields", d)
end

local function sendPerfUIData(d)
guihooks.trigger("beamlrPerfUIData", d)
end

local function togglePerfUI(d)
guihooks.trigger("beamlrTogglePerfUI", d)
end

local function sendPerfUIModes(d)
guihooks.trigger("beamlrPerfUIModes", d)
end

local function sendEventBrowserSelectedUID(d)
guihooks.trigger("beamlrEventBrowserReloadUID", d)
end

M.sendPerfUIModes = sendPerfUIModes
M.sendEventBrowserSelectedUID = sendEventBrowserSelectedUID
M.togglePerfUI = togglePerfUI
M.sendPerfUIData = sendPerfUIData
M.sendTrackTuningFields = sendTrackTuningFields
M.sendTrackTuningCategories = sendTrackTuningCategories
M.sendEventBrowserCurrentEventData = sendEventBrowserCurrentEventData
M.sendEventBrowserInspectionStatus = sendEventBrowserInspectionStatus
M.sendEventBrowserVehicleDamage = sendEventBrowserVehicleDamage
M.sendEventBrowserPlayerData = sendEventBrowserPlayerData
M.toggleTrackEventBrowser = toggleTrackEventBrowser
M.sendEventBrowserCarData = sendEventBrowserCarData
M.sendEventBrowserGarage = sendEventBrowserGarage
M.sendEventBrowserList = sendEventBrowserList
M.sendEventBrowserData = sendEventBrowserData
M.sendTrackTuningValues = sendTrackTuningValues
M.sendTrackTuningData = sendTrackTuningData
M.toggleTrackTuningUI = toggleTrackTuningUI
M.sendRewards = sendRewards
M.toggleTrackEventUI = toggleTrackEventUI
M.sendLeaderboard = sendLeaderboard
M.sendEventData = sendEventData
M.toggleDriftUI = toggleDriftUI
M.sendTotalDrift = sendTotalDrift
M.sendCurrentDrift = sendCurrentDrift
M.sendDataToEngine = sendDataToEngine
M.sendDataToUI = sendDataToUI
M.getUIData = getUIData

return M



