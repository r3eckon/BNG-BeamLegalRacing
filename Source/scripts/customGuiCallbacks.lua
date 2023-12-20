-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local ftable = { }
local lastSearch = ""
local searching = false


ftable["writeFile"] = function(p) 
writeFile(p["filename"], p["filedata"]) 
end

ftable["test"] = function(p)
print("TEST! Param : " .. p) 
end

ftable["setPart"] = function(p)
extensions.blrglobals.gmSetVal("pgas", extensions.blrglobals.gmGetVal("cgas")) 	-- Gets current gas value and stores it for after part edit
extensions.blrglobals.gmSetVal("podo", extensions.blrglobals.gmGetVal("codo"))	-- do same thing with odometer
extensions.blrglobals.gmSetVal("pnos", extensions.blrglobals.gmGetVal("cnos"))	-- do same thing with NOS
extensions.blrglobals.blrFlagSet("hasNos", false) -- Setting hasNos to false to avoid vlua fetching bug before flag is set by N2O Check node
extensions.blrhooks.linkHook("vehReset", "postedit")							-- Hooks post edit actions to the vehicle restored callback

--1.13 advanced vehicle building edits																				-- which restores proper camera and gas value
if extensions.blrglobals.blrFlagGet("avbToggle") then
extensions.blrglobals.blrFlagSet("advancedVehicleBuilding", true)
-- BELOW FUNCTION CALL FIXED ISSUE WITH FIRST EDIT NOT USING AVB
require("jbeam/io").finishLoading() -- clearing jbeam cache before edit
extensions.betterpartmgmt.setSlotWithChildren(p["slot"], p["item"])
else--use legacy slot setting function if avb toggle is off
extensions.betterpartmgmt.setSlot(p["slot"], p["item"])						
end



end

ftable["addInventory"] = function(p)
extensions.betterpartmgmt.addToInventory(p["item"])
end

ftable["buyPart"] = function(p)
local money = extensions.blrglobals.gmGetVal("playerMoney")
if money >= p["price"] then
extensions.betterpartmgmt.addToInventory(p["item"])
extensions.blrglobals.gmSetVal("playerMoney", money - p["price"])
extensions.blrutils.playSFX("event:>UI>Career>Buy_01")
local inventory = extensions.betterpartmgmt.getPartInventory()
extensions.customGuiStream.sendDataToUI("ownedParts", inventory)
local list = extensions.betterpartmgmt.getGarageUIData()
if searching then
list = extensions.betterpartmgmt.searchFilter(list, true, true)
else
list = extensions.betterpartmgmt.categoryFilter(list, true)
end
extensions.customGuiStream.sendDataToUI("garageData", list)
list = extensions.betterpartmgmt.getSortedGarageSlots()
extensions.customGuiStream.sendDataToUI("sortedGarageSlots", list)
list = extensions.betterpartmgmt.getSortedGarageParts()
extensions.customGuiStream.sendDataToUI("sortedGarageParts", list)
else
guihooks.trigger('Message', {ttl = 10, msg = 'You don\'t have enough money to buy this part!', icon = 'directions_car'})
end
end

ftable["setFilter"] = function(p)
local filter = p
extensions.betterpartmgmt.setFilter(filter)
lastSearch = p -- For reloading search results 
end


ftable["partUISearch"] = function(p)
local list = {}
searching = true -- Filter used as search term
if p == 0 then
list = extensions.betterpartmgmt.getPartShopList()
list = extensions.betterpartmgmt.searchFilter(list, true, true)
extensions.customGuiStream.sendDataToUI("availParts", list)
list = extensions.betterpartmgmt.getFullPartPrices()
extensions.customGuiStream.sendDataToUI("partPrices", list)
list = extensions.betterpartmgmt.getPartNameLibrary()
extensions.customGuiStream.sendDataToUI("partNames", list)
list = extensions.betterpartmgmt.getVehicleParts()
extensions.customGuiStream.sendDataToUI("usedParts", list)
list = extensions.betterpartmgmt.getSlotNameLibrary()
extensions.customGuiStream.sendDataToUI("slotNames", list)
local inventory = extensions.betterpartmgmt.getPartInventory()
extensions.customGuiStream.sendDataToUI("ownedParts", inventory)
list = extensions.betterpartmgmt.getSortedShopSlots()
extensions.customGuiStream.sendDataToUI("sortedShopSlots", list)
list = extensions.betterpartmgmt.getSortedShopParts()
extensions.customGuiStream.sendDataToUI("sortedShopParts", list)
elseif p == 1 then
list = extensions.betterpartmgmt.getGarageUIData()
list = extensions.betterpartmgmt.searchFilter(list, true, true)
extensions.customGuiStream.sendDataToUI("garageData", list)
list = extensions.betterpartmgmt.getPartNameLibrary()
extensions.customGuiStream.sendDataToUI("partNames", list)
list = extensions.betterpartmgmt.getVehicleParts()
extensions.customGuiStream.sendDataToUI("usedParts", list)
list = extensions.betterpartmgmt.getSlotNameLibrary()
extensions.customGuiStream.sendDataToUI("slotNames", list)
list = extensions.betterpartmgmt.getSortedGarageSlots()
extensions.customGuiStream.sendDataToUI("sortedGarageSlots", list)
list = extensions.betterpartmgmt.getSortedGarageParts()
extensions.customGuiStream.sendDataToUI("sortedGarageParts", list)
end
end		


ftable["partUICategory"] = function(p)
local list = {}
searching = false -- Filter not used as search term
if p == 0 then
list = extensions.betterpartmgmt.getPartShopList()
list = extensions.betterpartmgmt.categoryFilter(list, true)
extensions.customGuiStream.sendDataToUI("availParts", list)
list = extensions.betterpartmgmt.getFullPartPrices()
extensions.customGuiStream.sendDataToUI("partPrices", list)
list = extensions.betterpartmgmt.getPartNameLibrary()
extensions.customGuiStream.sendDataToUI("partNames", list)
list = extensions.betterpartmgmt.getVehicleParts()
extensions.customGuiStream.sendDataToUI("usedParts", list)
list = extensions.betterpartmgmt.getSlotNameLibrary()
extensions.customGuiStream.sendDataToUI("slotNames", list)
local inventory = extensions.betterpartmgmt.getPartInventory()
extensions.customGuiStream.sendDataToUI("ownedParts", inventory)
list = extensions.betterpartmgmt.getSortedShopSlots()
extensions.customGuiStream.sendDataToUI("sortedShopSlots", list)
list = extensions.betterpartmgmt.getSortedShopParts()
extensions.customGuiStream.sendDataToUI("sortedShopParts", list)
elseif p == 1 then
list = extensions.betterpartmgmt.getGarageUIData()
list = extensions.betterpartmgmt.categoryFilter(list, true)
extensions.customGuiStream.sendDataToUI("garageData", list)
list = extensions.betterpartmgmt.getPartNameLibrary()
extensions.customGuiStream.sendDataToUI("partNames", list)
list = extensions.betterpartmgmt.getVehicleParts()
extensions.customGuiStream.sendDataToUI("usedParts", list)
list = extensions.betterpartmgmt.getSlotNameLibrary()
extensions.customGuiStream.sendDataToUI("slotNames", list)
list = extensions.betterpartmgmt.getSortedGarageSlots()
extensions.customGuiStream.sendDataToUI("sortedGarageSlots", list)
list = extensions.betterpartmgmt.getSortedGarageParts()
extensions.customGuiStream.sendDataToUI("sortedGarageParts", list)
end
end																											  

ftable["inventoryRefresh"] = function(p) -- This function is now called as post edit action to fix layout bug
local list = {}
list = extensions.betterpartmgmt.getGarageUIData()
if searching then
list = extensions.betterpartmgmt.searchFilter(list, true, true)
else
list = extensions.betterpartmgmt.categoryFilter(list, true)
end
extensions.customGuiStream.sendDataToUI("garageData", list)
list = extensions.betterpartmgmt.getVehicleParts()
extensions.customGuiStream.sendDataToUI("usedParts", list) -- Used to be individual fg node
list = extensions.betterpartmgmt.getPartNameLibrary()
extensions.customGuiStream.sendDataToUI("partNames", list)
list = extensions.betterpartmgmt.getSlotNameLibrary()
extensions.customGuiStream.sendDataToUI("slotNames", list)
local inventory = extensions.betterpartmgmt.getPartInventory()
extensions.customGuiStream.sendDataToUI("ownedParts", inventory)
 -- Below added in 1.10, should reload proper tuning data for UI after part edits
list = extensions.betterpartmgmt.getTuningUIData()
extensions.customGuiStream.sendDataToUI("tuningData", list)
list = extensions.betterpartmgmt.getTuningUIValues()
extensions.customGuiStream.sendDataToUI("tuningValues", list)
extensions.customGuiStream.sendDataToUI("tuningValuesSlider", list)
extensions.customGuiStream.sendDataToUI("tuningValuesNumfield", list)
list = extensions.betterpartmgmt.getSortedTuningCategories(false)
extensions.customGuiStream.sendDataToUI("tuningSortedCategories", list)
list = extensions.betterpartmgmt.getSortedTuningFields(false)
extensions.customGuiStream.sendDataToUI("tuningSortedFields", list)
list = extensions.betterpartmgmt.getSortedShopSlots()
extensions.customGuiStream.sendDataToUI("sortedShopSlots", list)
list = extensions.betterpartmgmt.getSortedShopParts()
extensions.customGuiStream.sendDataToUI("sortedShopParts", list)
list = extensions.betterpartmgmt.getSortedGarageSlots()
extensions.customGuiStream.sendDataToUI("sortedGarageSlots", list)
list = extensions.betterpartmgmt.getSortedGarageParts()
extensions.customGuiStream.sendDataToUI("sortedGarageParts", list)
-- 1.13 part selling needs updated part prices updated after part edit
list = extensions.betterpartmgmt.getFullPartPrices()
extensions.customGuiStream.sendDataToUI("partPrices", list)
--1.14 selective repair maps
local cmap = extensions.betterpartmgmt.getChildMap()
local pmap = extensions.betterpartmgmt.getParentMap()
extensions.customGuiStream.sendRepairUIMaps(pmap, cmap)
local mainpart = extensions.betterpartmgmt.getMainPartChild()
extensions.customGuiStream.sendRepairUIMainPart(mainpart)
-- 1.14 fix to prevent removing main part (bugs the game)
local mainpart = extensions.betterpartmgmt.getMainPartChild()
extensions.customGuiStream.sendDataToUI("mainpart", mainpart)
end

ftable["uiinit"] = function(p)
extensions.blrglobals.blrFlagSet("uiInitRequest", true)
print("UI Init Request Received")
end

ftable["setTune"] = function(p)
local dtable = extensions.betterpartmgmt.tuningTableFromUIData(p, false)
extensions.blrglobals.gmSetVal("pgas", extensions.blrglobals.gmGetVal("cgas")) 	-- Gets current gas value and stores it for after tune apply
extensions.blrglobals.gmSetVal("podo", extensions.blrglobals.gmGetVal("codo"))	-- do same thing with odometer
extensions.blrglobals.gmSetVal("pnos", extensions.blrglobals.gmGetVal("cnos"))	-- do same thing with NOS
extensions.blrhooks.linkHook("vehReset", "postedit")							-- Link to post edit action hook, reuse the code for tune
extensions.betterpartmgmt.applyTuningData(dtable)
end

ftable["resetTune"] = function(p)
extensions.blrglobals.gmSetVal("pgas", extensions.blrglobals.gmGetVal("cgas")) 	-- Gets current gas value and stores it for after tune apply
extensions.blrglobals.gmSetVal("podo", extensions.blrglobals.gmGetVal("codo"))	-- do same thing with odometer
extensions.blrglobals.gmSetVal("pnos", extensions.blrglobals.gmGetVal("cnos"))	-- do same thing with NOS
extensions.blrhooks.linkHook("vehReset", "postedit")							-- Link to post edit action hook, reuse the code for tune
extensions.betterpartmgmt.resetTuningData()
end

ftable["uiResetCareer"] = function(p)
extensions.blrglobals.blrFlagSet("careerResetRequest", true)					-- Send career reset request to flowgraph using blrglobals
end

ftable["playerRename"] = function(p)
local otable = extensions.blrutils.loadDataTable("beamLR/options")
otable["playername"] = p
extensions.blrutils.saveDataTable("beamLR/options", otable)
end

ftable["vehicleRename"] = function(p)
local cvgid = extensions.blrglobals.gmGetVal("cvgid")
if cvgid ~= -1 then
local cartable = {}
cartable["name"] = p
extensions.blrutils.updateDataTable("beamLR/garage/car" .. cvgid, cartable)
end
end

ftable["applyPaint"] = function(p)
local vehid = be:getPlayerVehicleID(0)
local cvgid = extensions.blrglobals.gmGetVal("cvgid")
if cvgid ~= -1 then
extensions.blrutils.saveUIPaintToGarageFile(cvgid, p)
local paint = extensions.blrutils.convertUIPaintToVehiclePaint(p)
extensions.blrutils.livePaintUpdate(vehid, paint)
--local mc = extensions.blrutils.convertUIPaintToMeshColors(p)
--extensions.blrutils.repaintFullMesh(vehid, mc.car,mc.cag, mc.cab, mc.caa, mc.cbr,mc.cbg,mc.cbb, mc.cba, mc.ccr,mc.ccg,mc.ccb, mc.cca)
end
end

ftable["previewPaint"] = function(p)
local vehid = be:getPlayerVehicleID(0)
local paint = extensions.blrutils.convertUIPaintToVehiclePaint(p)
extensions.blrutils.livePaintUpdate(vehid, paint)
end

ftable["reloadPaint"] = function(p)
local cvgid = extensions.blrglobals.gmGetVal("cvgid")
local paintTable = extensions.blrutils.getGarageCarPaint(cvgid)
extensions.customGuiStream.sendDataToUI("paint", paintTable)
end

ftable["setTrafficDensity"] = function(p)
local density = p
local otable = extensions.blrutils.loadDataTable("beamLR/options")
otable["traffic"] = p
extensions.blrutils.saveDataTable("beamLR/options", otable)
end

ftable["setPoliceDensity"] = function(p)
local density = p
local otable = extensions.blrutils.loadDataTable("beamLR/options")
otable["police"] = p
extensions.blrutils.saveDataTable("beamLR/options", otable)
end

ftable["setTruckDensity"] = function(p)
local density = p
local otable = extensions.blrutils.loadDataTable("beamLR/options")
otable["trucks"] = p
extensions.blrutils.saveDataTable("beamLR/options", otable)
end

ftable["setSeed"] = function(p)
local dtable = {}
if tonumber(p) ~= nil and tonumber(p) > 0 and tonumber(p) < 9999999999 then 
dtable["nseed"] = p
dtable["autoseed"] = 0
extensions.blrutils.updateDataTable("beamLR/options", dtable)
end
end

ftable["setAutoSeed"] = function(p)
local dtable = {}
dtable["autoseed"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
end


ftable["setRandomSeed"] = function(p)
local dtable = {}
math.randomseed(os.time())
dtable["nseed"] = math.random(1,9999999999)
dtable["autoseed"] = 0
extensions.blrutils.updateDataTable("beamLR/options", dtable)
end

ftable["backupCareer"] = function(p)
extensions.blrutils.backupCareer()
end

ftable["restoreBackup"] = function(p)
extensions.blrutils.restoreBackup()
end

ftable["setTrafficRisk"] = function(p)
local dtable = {}
if tonumber(p) ~= nil and tonumber(p) >= 0 and tonumber(p) <= 1 then 
dtable["trisk"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
end
end

ftable["setPoliceStrictness"] = function(p)
local dtable = {}
if tonumber(p) ~= nil and tonumber(p) >= 0 and tonumber(p) <= 1 then 
dtable["copstrict"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
end
end

ftable["setSleepDuration"] = function(p)
local dtable = {}
if tonumber(p) ~= nil and tonumber(p) >= 0 and tonumber(p) <= 24 then 
dtable["sleeptime"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.blrglobals.blrFlagSet("reloadOptions", true)	-- Force reload options for immediate change
end
end

ftable["setOpponentRandomPaint"] = function(p)
local dtable = {}
dtable["raceRandPaint"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.blrglobals.blrFlagSet("reloadOptions", true)	-- Force reload options for immediate change
end

ftable["setRaceWager"] = function(p)
local dtable = {}
dtable["targetwager"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.blrutils.setWager(p)
extensions.blrglobals.blrFlagSet("reloadRace", true)	-- Force reload of race parameters after wager change
end

ftable["setDifficulty"] = function(p)
local dtable = { }
dtable["difficulty"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
end

ftable["forcedCopfix"] = function(p)
extensions.blrglobals.blrFlagSet("policeResetRequest", true)
extensions.blrutils.copfixReset()
extensions.blrutils.copfixInit()
end

ftable["setAutoCopfix"] = function(p)
local dtable = {}
dtable["autoCopfix"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
if tonumber(p) == 1 then 
extensions.blrglobals.blrFlagSet("roleFixToggle", true)
else
extensions.blrglobals.blrFlagSet("roleFixToggle", false)
end
end

ftable["setBeamstateToggle"] = function(p)
local dtable = {}
dtable["bstoggle"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
if tonumber(p) == 1 then 
extensions.blrglobals.blrFlagSet("beamstateToggle", true)
else
extensions.blrglobals.blrFlagSet("beamstateToggle", false)
end
end

ftable["resetCouplers"] = function(p)
local vehid = be:getPlayerVehicleID(0)
local vobj = be:getObjectByID(vehid)
vobj:queueLuaCommand("extensions.blrVehicleUtils.advancedCouplersFix()")
end

ftable["setTuneTrack"] = function(p)
local dtable = extensions.betterpartmgmt.tuningTableFromUIData(p, false)
extensions.blrhooks.linkHook("vehReset", "tracktune")
extensions.betterpartmgmt.applyTuningData(dtable)
end

ftable["resetTuneTrack"] = function(p)
extensions.blrhooks.linkHook("vehReset", "tracktune")
extensions.betterpartmgmt.resetTuningData()
end

ftable["selectEventFile"] = function(p)
local eseed = extensions.blrutils.getEventSeed(tonumber(p["uid"]))
local edata = extensions.blrutils.eventBrowserGetData(p["file"], eseed)
extensions.customGuiStream.sendEventBrowserData(edata)
extensions.blrutils.blrvarSet("uiinitSelectedEventFile", p["file"]) -- For ui init request when ESC is pressed
extensions.blrutils.blrvarSet("uiinitSelectedEventUID", tonumber(p["uid"])) -- For ui init request when ESC is pressed
local inspection = extensions.blrutils.getEventInspectionStatus()
extensions.customGuiStream.sendEventBrowserInspectionStatus(inspection)
local pdata = extensions.blrutils.eventBrowserGetPlayerData()
extensions.customGuiStream.sendEventBrowserPlayerData(pdata)
end

ftable["updateEventMenuPage"] = function(p)
local cdata = extensions.blrutils.getCurrentEventData()
extensions.customGuiStream.sendDataToUI("currentTrackEvent", cdata)
end

ftable["showEventBrowser"] = function(p)
local elist = extensions.blrutils.eventBrowserGetList()
extensions.customGuiStream.sendEventBrowserList(elist)
extensions.customGuiStream.toggleTrackEventBrowser(true)
local pdata = extensions.blrutils.eventBrowserGetPlayerData()
extensions.customGuiStream.sendEventBrowserPlayerData(pdata)
local cdata = extensions.blrutils.getCurrentEventData()
extensions.customGuiStream.sendEventBrowserCurrentEventData(cdata)
extensions.blrglobals.blrFlagSet("eventBrowserEnabled", true)
end

ftable["hideEventBrowser"] = function(p)
extensions.blrglobals.blrFlagSet("eventBrowserEnabled", false)
end

ftable["abandonEvent"] = function(p)
local cdata = extensions.blrutils.loadDataTable("beamLR/currentTrackEvent")
cdata["status"] = "over"
extensions.blrutils.updateDataTable("beamLR/currentTrackEvent", cdata)
local cdata = extensions.blrutils.getCurrentEventData() -- Should refresh event menu page data after abandon, do this after event joining too
extensions.customGuiStream.sendDataToUI("currentTrackEvent", cdata)
extensions.customGuiStream.sendEventBrowserCurrentEventData(cdata)
local elist = extensions.blrutils.eventBrowserGetList()
extensions.customGuiStream.sendEventBrowserList(elist)
extensions.blrglobals.blrFlagSet("eventRestrictUpdate", true) -- Request updated vehicle restriction state
end

ftable["joinEvent"] = function(p)
extensions.blrutils.blrvarSet("joinedEventFile", p["file"]) 
extensions.blrutils.blrvarSet("joinedEventUID", p["uid"]) 
extensions.blrglobals.blrFlagSet("joinEventRequest", true) -- Flowgraph will get current garage ID to feed to blrutils join function
end

ftable["togglePerfUI"] = function(p)
if tonumber(p) == 1 then
local options = extensions.blrutils.loadDataTable("beamLR/options")
local mdata = {}
mdata["torque"] = tonumber(options["perfmodetorque"] or "0")
mdata["power"] = tonumber(options["perfmodepower"] or "0")
mdata["weight"] = tonumber(options["perfmodeweight"] or "0")
extensions.customGuiStream.sendPerfUIModes(mdata)
extensions.customGuiStream.togglePerfUI(true)
else
extensions.customGuiStream.togglePerfUI(false)
end
end

ftable["setTimeScale"] = function(p)
local dtable = { }
dtable["timescale"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
end

ftable["uiRequestTemplates"] = function(p)
extensions.blrutils.uiRefreshTemplates()
end


ftable["saveTemplate"] = function(p)
local fullpath = p["templateFolder"] .. p["templateName"]
extensions.betterpartmgmt.saveConfig(fullpath)
extensions.blrutils.uiRefreshTemplates()
end

ftable["deleteTemplate"] = function(p)
local fullpath = p["templateFolder"] .. p["templateName"]
extensions.blrutils.deleteFile(fullpath)
extensions.blrutils.uiRefreshTemplates()
end

ftable["loadTemplate"] = function(p)
local fullpath = p["templateFolder"] .. p["templateName"]
local inventory = extensions.blrutils.loadDataTable("beamLR/partInv")
local cvgid = extensions.blrglobals.gmGetVal("cvgid")
local currentConfig = jsonReadFile("beamLR/garage/config/car" .. cvgid)["parts"]
local targetConfig = jsonReadFile(fullpath)["parts"]
local targetPart = ""
local currentPart = ""

local canload = extensions.blrutils.templateLoadCheck(currentConfig, targetConfig)

if canload then
-- Below code taken from part edit process, since parts change this should reload UI menus and gas,odo,nos values
extensions.blrglobals.gmSetVal("pgas", extensions.blrglobals.gmGetVal("cgas"))
extensions.blrglobals.gmSetVal("podo", extensions.blrglobals.gmGetVal("codo"))
extensions.blrglobals.gmSetVal("pnos", extensions.blrglobals.gmGetVal("cnos"))	
extensions.blrglobals.blrFlagSet("hasNos", false)
extensions.blrhooks.linkHook("vehReset", "postedit")	

-- Need to handle inventory updates by comparing current config to target config
extensions.betterpartmgmt.templateLoadInventorySwap(currentConfig, targetConfig)

-- finally load the actual config
extensions.betterpartmgmt.loadConfig(fullpath) 
else
guihooks.trigger('Message', {ttl = 10, msg = 'You don\'t have the parts needed to load this config!', icon = 'directions_car'})
end
end

ftable["perfuiSetMode"] = function(p)
local dtable = extensions.blrutils.loadDataTable("beamLR/options")
dtable["perfmode" .. p["field"]] = tonumber(p["mode"])
extensions.blrutils.updateDataTable("beamLR/options", dtable)
end

ftable["setAVBToggle"] = function(p)
local dtable = {}
dtable["avbtoggle"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
end

ftable["setARCToggle"] = function(p)
local dtable = {}
dtable["advrepaircost"] = p
if p==0 then -- also disable advanced repair ui if arc is turned off
dtable["useadvrepairui"] = 0 
extensions.blrglobals.blrFlagSet("useadvrepairui", false)
extensions.customGuiStream.toggleAdvancedRepairUI(false)
end
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.blrglobals.blrFlagSet("advrepaircost", p == 1)
end

ftable["setGroundmarkersToggle"] = function(p)
local dtable = {}
dtable["gmtoggle"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.blrglobals.blrFlagSet("gmtoggle", p == 1)
end


ftable["garagePartSell"] = function(p)
local part = p["part"]
local value = p["value"]
extensions.betterpartmgmt.removeFromInventory(part)
local money = extensions.blrglobals.gmGetVal("playerMoney")
extensions.blrglobals.gmSetVal("playerMoney", money + value)
extensions.blrutils.playSFX("event:>UI>Career>Buy_01")
local inventory = extensions.betterpartmgmt.getPartInventory()
extensions.customGuiStream.sendDataToUI("ownedParts", inventory)
local list = extensions.betterpartmgmt.getGarageUIData()
if searching then
list = extensions.betterpartmgmt.searchFilter(list, true, true)
else
list = extensions.betterpartmgmt.categoryFilter(list, true)
end
extensions.customGuiStream.sendDataToUI("garageData", list)
list = extensions.betterpartmgmt.getSortedGarageSlots()
extensions.customGuiStream.sendDataToUI("sortedGarageSlots", list)
list = extensions.betterpartmgmt.getSortedGarageParts()
extensions.customGuiStream.sendDataToUI("sortedGarageParts", list)
end

ftable["gpsSelectDestination"] = function(p)
extensions.blrutils.setGPSDestination(p)
extensions.customGuiStream.gpsSetLastPage(3)
end

ftable["gpsFindNearest"] = function(p)
extensions.blrutils.gpsFindNearest(p)
extensions.customGuiStream.gpsSetLastPage(3)
end

ftable["gpsCancelRoute"] = function(p)
extensions.blrutils.setGPSDestination()
extensions.customGuiStream.gpsSetLastPage(0)
end

ftable["setGPSMode"] = function(p)
local dtable = {}
dtable["gpsmode"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.blrutils.blrvarSet("gpsmode", p)
extensions.blrutils.gpsToggleStateUpdate()
end

ftable["setRaceTrafficMode"] = function(p)
local dtable = {}
dtable["rtmode"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.blrutils.blrvarSet("raceTrafficMode", p)
end

ftable["setIMGUIScale"] = function(p)
local dtable = {}
dtable["imscale"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.ui_imguiUtils.changeUIScale(tonumber(p))
end

ftable["autosaveIMGUI"] = function(p)
local dtable = {}
dtable["imautosave"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.blrglobals.blrFlagSet("imautosave", tonumber(p) == 1)
end

ftable["loadIMGUI"] = function()
extensions.blrutils.loadCustomIMGUILayout()
end

ftable["saveIMGUI"] = function()
extensions.ui_imgui.saveIniSettingsToDisk("settings/beamlr_imgui.ini")
end

ftable["setDragSlowmoToggle"] = function(p)
local dtable = {}
dtable["dragslowmo"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.blrglobals.blrFlagSet("dragslowmo", p == 1)
end

ftable["setMarkersToggle"] = function(p)
local dtable = {}
dtable["fmtoggle"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.blrglobals.blrFlagSet("fmtoggle", p == 1)

if p == 0 then
extensions.blrutils.deleteMarkers()
else
local markers = extensions.blrutils.loadDataTable("beamLR/mapdata/" .. extensions.blrutils.getLevelName() .. "/markers")
extensions.blrutils.deleteMarkers()
extensions.blrutils.spawnMarkers(markers)
end

end

ftable["optionsUIReload"] = function(p)
extensions.customGuiStream.sendCurrentOptionValues()
end

ftable["advancedRepairUIClosed"] = function()
extensions.blrglobals.blrFlagSet("advancedRepairUI", false)
end

ftable["advancedRepairSelected"] = function(p)
local dmgstr = extensions.vluaFetchModule.getVal("advdmgstr")
local damage = extensions.blrutils.advancedDamageStringToTable(dmgstr)
local partslot = extensions.betterpartmgmt.getPartKeyedSlots()
local money = extensions.blrglobals.gmGetVal("playerMoney")
local childmap = extensions.betterpartmgmt.getChildMap()
local cchilds = {}
local removed = {}

-- since advanced repair is just like part edit, need to store veh values
extensions.blrglobals.gmSetVal("pgas", extensions.blrglobals.gmGetVal("cgas")) 	-- gets current gas value to restore later
extensions.blrglobals.gmSetVal("podo", extensions.blrglobals.gmGetVal("codo"))	-- do same thing with odometer
extensions.blrglobals.gmSetVal("pnos", extensions.blrglobals.gmGetVal("cnos"))	-- do same thing with NOS
extensions.blrhooks.linkHook("vehReset", "postedit")							-- link to post edit action hook

-- charge player for repair
extensions.blrglobals.gmSetVal("playerMoney", money - p["cost"])
extensions.blrutils.playSFX("event:>UI>Career>Buy_01")

-- load current config data into delayed slot set table
extensions.betterpartmgmt.initDelayedSlotTable()

-- now loop over parts and check for damaged & selected states
for k,v in pairs(partslot) do
if damage[k] and (not p[k]) then --damaged part not selected, remove from config
extensions.betterpartmgmt.setSlotDelayedNoInventory(v, "")
table.insert(removed, k)
end
end

-- loop over removed parts, checked childs for damage, add undamaged to inventory
for k,v in pairs(removed) do
cchilds = childmap[v]
for s,p in pairs(cchilds) do
if not damage[p] and p~="" then
extensions.betterpartmgmt.addToInventory(p)
print("ADDED UNDAMAGED CHILD TO INVENTORY: " .. p)
end
end
end


-- finally execute delayed slot set
extensions.betterpartmgmt.executeDelayedSlotSet()
end

ftable["advancedRepairAll"] = function(p)
-- charging player here since cost multiplier comes from ui
local money = extensions.blrglobals.gmGetVal("playerMoney")
extensions.blrglobals.gmSetVal("playerMoney", money - p["cost"])
extensions.blrutils.playSFX("event:>UI>Career>Buy_01")
-- repair all can just trigger flowgraph repair with flag, skipping part that charges player
extensions.blrglobals.blrFlagSet("uiAdvancedRepairRequest", true)
end

ftable["setARUIToggle"] = function(p)
local dtable = {}
dtable["useadvrepairui"] = p
extensions.blrutils.updateDataTable("beamLR/options", dtable)
extensions.blrglobals.blrFlagSet("useadvrepairui", p == 1)
if p==0 then extensions.customGuiStream.toggleAdvancedRepairUI(false) end
end



local ptable = {}
local rtable = {}

local function resetParamTable(p)
ptable[p] = {}
end

local function setParamTableValue(p,ti,v)
if ptable[p] == nil then ptable[p] = {} end
ptable[p][ti] = v
end

local function setParam(p,v)
ptable[p] = v
end

local function exec(f,p)
if p ~= nil then
rtable[f] = ftable[f](ptable[p])
if type(ptable[p]) then resetParamTable(p) end
else
rtable[f] = ftable[f](0)
end
end

local function getReturnValue(f)
return rtable[f] or "nil"
end


M.setParamTableValue = setParamTableValue
M.setParam = setParam
M.exec = exec
M.getReturnValue = getReturnValue

return M



