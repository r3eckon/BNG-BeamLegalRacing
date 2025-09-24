-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local guihooks = require('guihooks')

local uidata = {}

local lastdata = {}

-- for simple data that doesn't need auto reload to use
-- within flowgraph without having to add extra code
local function customHook(h, d)
guihooks.trigger(h, d)
end

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

local function sendDriftCombo(v)
lastdata["driftCombo"] = val
guihooks.trigger("beamlrDriftCombo", v)
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
guihooks.trigger("beamlrDriftCombo", lastdata["driftCombo"] or 0)
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
-- sticking towing UI init in here also
guihooks.trigger("beamlrToggleTowUI",lastdata["towtoggle"])
end

local function sendCurrentOptionValues()
local options = extensions.blrutils.loadDataTable("beamLR/options")
local cvgid = extensions.blrglobals.gmGetVal("cvgid")
local vehname = ""
if cvgid and FS:fileExists("beamLR/garage/car" .. cvgid) then
local vehdata = extensions.blrutils.loadDataTable("beamLR/garage/car" .. cvgid)
if vehdata then vehname = vehdata["name"] end
end
local tosend = {}
for k,v in pairs(options) do
if tonumber(v) then tosend[k] = tonumber(v) else tosend[k] = v end 
end
tosend["vehname"] = vehname
guihooks.trigger("beamlrOptions", tosend)
guihooks.trigger("beamlrImageUIMode", tonumber(options["imgmode"] or "0"))
end

local function sendRepairData(damage, partnames, mech, minimum, engine)
if damage then guihooks.trigger("beamlrRepairUIDamageList", damage) end
if partnames then guihooks.trigger("beamlrRepairUIPartNames", partnames) end
if mech then guihooks.trigger("beamlrRepairUIMechanicalDamage", mech) end
if minimum then guihooks.trigger("beamlrRepairUIMinimumDamage", minimum) end -- 1.14.1 fix 
if engine then guihooks.trigger("beamlrRepairUIEngineDamage", engine) end -- 1.16 addition
end


local function toggleAdvancedRepairUI(toggle)
local otable = extensions.blrutils.loadDataTable("beamLR/options")
local warnack = tonumber(otable["advrepwarnack"]) == 1
guihooks.trigger("beamlrRepairUIToggle", toggle)
guihooks.trigger("beamlrRepairWarnAck", warnack)
extensions.blrglobals.blrFlagSet("advancedRepairUI", toggle)
end

local function sendRepairUIMaps(parent, child)
if parent then guihooks.trigger("beamlrRepairUIParentMap", parent) end
if child then guihooks.trigger("beamlrRepairUIChildMap", child) end
end

local function sendRepairUIMainPart(main)
guihooks.trigger("beamlrRepairUIMainPart", main)
end

local function sendRepairUIMultiplier(mult)
guihooks.trigger("beamlrRepairUIMultiplier", mult)
end

local function sendRepairUIPlayerMoney(pmoney)
guihooks.trigger("beamlrRepairUIMoney", pmoney)
end

local function advancedRepairUIResetPicks()
guihooks.trigger("beamlrRepairResetPicks", nil)
end

local function imageUIToggle(t)
guihooks.trigger("beamlrToggleImageUI", t)
end

local function imageUIMode(m)
guihooks.trigger("beamlrImageUIMode", m)
end

local function imageUIFile(f)
guihooks.trigger("beamlrImageUIFile", f)
end


local function towingUIToggle(toggle)
lastdata["towtoggle"] = toggle
guihooks.trigger("beamlrToggleTowUI", toggle)
end



local function sendItemInventory()
local uidata = {}
local inventory = extensions.blrItemInventory.getInventory()
local units = extensions.blrutils.getSettingValue("uiUnits")
local ctype = ""
local cname = ""
local cdata = ""
local cimage = ""
local ksplit = {}
local vsplit = {}
for k,v in keySortedPairs(inventory) do
ksplit = extensions.blrutils.ssplit(k, "_")
ctype = ksplit[2]
cname = extensions.blrItemInventory.getUIName(ctype)
cimage = "/ui/modules/apps/beamlrui/itemimg/" .. extensions.blrItemInventory.getUIImage(ctype)
cdata = extensions.blrItemInventory.getUIData(v, ctype, units)

--building table to send to ui
uidata[k] = {itype=ctype, iname=cname, idata=cdata, image=cimage}

end

sendDataToUI("itemInventory", uidata)

end

local timerdata = {}

local function consumeTimerData(data)
timerdata = data
end

local function sendTimerData()
guihooks.trigger("BeamLRTimerData", timerdata)
end

local function resetTimerData()
timerdata = {}
timerdata.offset = 0
timerdata.clap = 0
timerdata.sentforlap = 0
timerdata.deltacolor = "white"
timerdata.deltasymbol = ""
sendTimerData()
end

local function sendMirrorsData(toggle)
guihooks.trigger("beamlrMirrorsData", extensions.blrpartmgmt.getDynamicMirrorsData())
guihooks.trigger("beamlrSortedMirrors", extensions.blrpartmgmt.getSortedMirrors())
if toggle then
guihooks.trigger("beamlrToggleMirrorsUI", true)
end
end

local function sendTemplateFixData(missing)
guihooks.trigger("beamlrTemplateFix", missing)
end


local function sendPartBuyResult(result)
guihooks.trigger("beamlrPartBuyResult", result)
end

local function togglePastEventViewer(data)
local toSend = {}
local csplit = {}

for k,v in pairs(data) do
csplit = extensions.blrutils.ssplit(v, ",")
toSend[k] = {}
toSend[k]["title"] = csplit[1]
toSend[k]["layout"] = csplit[2]
toSend[k]["position"] = csplit[3]
toSend[k]["money"] = csplit[4]
toSend[k]["rep"] = csplit[5]
toSend[k]["parts"] = csplit[6]
toSend[k]["cars"] = csplit[7]
end

guihooks.trigger("beamlrPastEventData", toSend)
guihooks.trigger("beamlrTogglePastEventsList", true)
end


local function sendRepairUIParentSelect(toggle)
guihooks.trigger("beamlrRepairSelectParents", toggle)
end

local function showPartShopV2()
guihooks.trigger("beamlrPartShopV2Show", true)
end

M.showPartShopV2 = showPartShopV2
M.sendRepairUIParentSelect = sendRepairUIParentSelect
M.togglePastEventViewer = togglePastEventViewer
M.customHook = customHook
M.sendDriftCombo = sendDriftCombo
M.sendPartBuyResult = sendPartBuyResult
M.sendTemplateFixData = sendTemplateFixData
M.sendMirrorsData = sendMirrorsData
M.resetTimerData = resetTimerData
M.sendTimerData = sendTimerData
M.consumeTimerData = consumeTimerData
M.sendItemInventory = sendItemInventory
M.towingUIToggle = towingUIToggle
M.imageUIMode = imageUIMode
M.imageUIFile = imageUIFile
M.imageUIToggle = imageUIToggle
M.advancedRepairUIResetPicks = advancedRepairUIResetPicks
M.sendRepairUIPlayerMoney = sendRepairUIPlayerMoney
M.sendRepairUIMultiplier = sendRepairUIMultiplier
M.sendRepairUIMainPart = sendRepairUIMainPart
M.sendRepairUIMaps = sendRepairUIMaps
M.toggleAdvancedRepairUI = toggleAdvancedRepairUI
M.sendRepairData = sendRepairData
M.sendCurrentOptionValues = sendCurrentOptionValues
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



