-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local guihooks = require('guihooks')

local uidata = {}

local lastdata = {}

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
lastdata["driftCurrent"] = v
guihooks.trigger("beamlrCurrentDrift", v)
end

local function sendTotalDrift(v)
lastdata["driftTotal"] = val
guihooks.trigger("beamlrTotalDrift", v)
end

local function toggleDriftUI(t)
lastdata["driftToggled"] = t
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

local function sendDeliveryMaxForce(d)
lastdata["deliveryMax"] = d
guihooks.trigger("beamlrDeliveryMaxForce", d)
end

local function sendDeliveryCurrentForce(d)
lastdata["deliveryCurrent"] = d
guihooks.trigger("beamlrDeliveryCurrentForce", d)
end

local function toggleDeliveryUI(t)
lastdata["deliveryToggled"] = t
guihooks.trigger("beamlrToggleDeliveryUI", t)
end

local function sendDeliveryCurrentDamage(d)
lastdata["deliveryDamage"] = d
guihooks.trigger("beamlrDeliveryCurrentDamage", d)
end

local function toggleDeliveryDamage(d)
lastdata["deliveryDamageToggle"] = d
guihooks.trigger("beamlrToggleDeliveryDamage", d)
end

-- 1.11 fix for scoring windows not reloading with UI init
local function driftUIinitreload()
guihooks.trigger("beamlrCurrentDrift", lastdata["driftCurrent"] or 0)
guihooks.trigger("beamlrTotalDrift", lastdata["driftTotal"] or 0)
guihooks.trigger("beamlrToggleDriftUI", lastdata["driftToggled"] or false)
end
local function deliveryUIinitreload()
guihooks.trigger("beamlrDeliveryMaxForce", lastdata["deliveryMax"] or 0)
guihooks.trigger("beamlrDeliveryCurrentForce", lastdata["deliveryCurrent"] or 0)
guihooks.trigger("beamlrToggleDeliveryUI", lastdata["deliveryToggled"] or false)
guihooks.trigger("beamlrToggleDeliveryDamage", lastdata["deliveryDamage"] or 0)
guihooks.trigger("beamlrDeliveryCurrentDamage", lastdata["deliveryDamageToggle"] or false)
end
-- Called on startup to clear old data (prevents scoring windows opening due to quitting when open)
local function resetUIsavedData()
lastdata = {}
end

local function sendGameOverCareerStats(d)
lastdata["gameoverstats"] = d
guihooks.trigger("beamlrGameOverStats", d)
end

local function toggleGameOverUI(t)
lastdata["gameovertoggle"] = t
guihooks.trigger("beamlrToggleGameOverUI", t)
end

local function sendGameOverUIBackOpacity(d)
lastdata["gameoverbackopacity"] = d
guihooks.trigger("beamlrGameOverBackOpacity", d)
end

local function sendGameOverUITextOpacity(d)
lastdata["gameovertextopacity"] = d
guihooks.trigger("beamlrGameOverTextOpacity", d)
end

local function gameOverUIinitreload()
guihooks.trigger("beamlrGameOverStats", lastdata["gameoverstats"] or {})
guihooks.trigger("beamlrToggleGameOverUI", lastdata["gameovertoggle"] or false)
guihooks.trigger("beamlrGameOverBackOpacity", lastdata["gameoverbackopacity"] or 0)
guihooks.trigger("beamlrGameOverTextOpacity", lastdata["gameovertextopacity"] or 0)
end

local gpslastpage = 0

local function gpsSetLastPage(p)
gpslastpage = p
end

local function sendGPSDestinationList(list)
guihooks.trigger("beamlrGPSDestinationList", list)
lastdata["gpslist"] = list
end

local function sendGPSCurrentDestination(name)
guihooks.trigger("beamlrGPSCurrentDestination", name)
lastdata["gpsdest"] = name
end

local function sendGPSCurrentDistance(dist)
guihooks.trigger("beamlrGPSCurrentDistance", dist)
lastdata["gpsdist"] = dist
end

local function sendGPSDistanceUnit(unit)
guihooks.trigger("beamlrGPSDistanceUnit", unit)
lastdata["gpsunit"] = unit
end

local function sendGPSToggleState(toggle)
guihooks.trigger("beamlrGPSToggleState", toggle)
lastdata["gpstoggle"] = toggle
end

local function sendGPSPage(p)
guihooks.trigger("beamlrGPSPageReload", p)
gpslastpage = p
end

local function gpsUIInitReload()
guihooks.trigger("beamlrGPSPageReload", gpslastpage)
guihooks.trigger("beamlrGPSDestinationList", lastdata["gpslist"])
guihooks.trigger("beamlrGPSCurrentDestination", lastdata["gpsdest"])
-- distance and unit use fresh data to ensure unit change in options menu is reflected instantly
guihooks.trigger("beamlrGPSCurrentDistance", extensions.blrutils.getGPSDistance())
guihooks.trigger("beamlrGPSDistanceUnit", extensions.blrutils.gpsGetUnit())
guihooks.trigger("beamlrGPSToggleState", lastdata["gpstoggle"])
end

M.toggleDeliveryDamage = toggleDeliveryDamage
M.sendDeliveryCurrentDamage = sendDeliveryCurrentDamage
M.sendGPSPage = sendGPSPage
M.sendGPSToggleState = sendGPSToggleState
M.gpsUIInitReload = gpsUIInitReload
M.gpsSetLastPage = gpsSetLastPage
M.sendGPSDistanceUnit = sendGPSDistanceUnit
M.sendGPSCurrentDistance = sendGPSCurrentDistance
M.sendGPSCurrentDestination = sendGPSCurrentDestination
M.sendGPSDestinationList = sendGPSDestinationList
M.gameOverUIinitreload = gameOverUIinitreload
M.sendGameOverUITextOpacity = sendGameOverUITextOpacity
M.sendGameOverUIBackOpacity = sendGameOverUIBackOpacity
M.toggleGameOverUI = toggleGameOverUI
M.sendGameOverCareerStats = sendGameOverCareerStats
M.resetUIsavedData = resetUIsavedData
M.deliveryUIinitreload = deliveryUIinitreload
M.driftUIinitreload = driftUIinitreload
M.toggleDeliveryUI = toggleDeliveryUI
M.sendDeliveryCurrentForce = sendDeliveryCurrentForce
M.sendDeliveryMaxForce = sendDeliveryMaxForce
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



