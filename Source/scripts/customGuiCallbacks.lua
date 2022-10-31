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
extensions.blrglobals.gmSetVal("podo", extensions.blrglobals.gmGetVal("codo"))	-- Do same thing with odometer
extensions.blrhooks.linkHook("vehReset", "postedit")							-- Hooks post edit actions to the vehicle restored callback
extensions.betterpartmgmt.setSlot(p["slot"], p["item"])							-- which restores proper camera and gas value
end

ftable["addInventory"] = function(p)
extensions.betterpartmgmt.addToInventory(p["item"])
end

ftable["buyPart"] = function(p)
local money = extensions.blrglobals.gmGetVal("playerMoney")
if money >= p["price"] then
extensions.betterpartmgmt.addToInventory(p["item"])
extensions.blrglobals.gmSetVal("playerMoney", money - p["price"])
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
list = extensions.betterpartmgmt.getAvailablePartList()
list = extensions.betterpartmgmt.searchFilter(list, true)
extensions.customGuiStream.sendDataToUI("availParts", list)
list = extensions.betterpartmgmt.getPartPriceLibrary()
extensions.customGuiStream.sendDataToUI("partPrices", list)
elseif p == 1 then
list = extensions.betterpartmgmt.getGarageUIData()
list = extensions.betterpartmgmt.searchFilter(list, true)
extensions.customGuiStream.sendDataToUI("garageData", list)
end
end		


ftable["partUICategory"] = function(p)
local list = {}
searching = false -- Filter not used as search term
if p == 0 then
list = extensions.betterpartmgmt.getAvailablePartList()
list = extensions.betterpartmgmt.categoryFilter(list, true)
extensions.customGuiStream.sendDataToUI("availParts", list)
list = extensions.betterpartmgmt.getPartPriceLibrary()
extensions.customGuiStream.sendDataToUI("partPrices", list)
elseif p == 1 then
list = extensions.betterpartmgmt.getGarageUIData()
list = extensions.betterpartmgmt.categoryFilter(list, true)
extensions.customGuiStream.sendDataToUI("garageData", list)
end
end																											  

ftable["inventoryRefresh"] = function(p)
local list = {}
list = extensions.betterpartmgmt.getGarageUIData()
if searching then
list = extensions.betterpartmgmt.searchFilter(list, true)
else
list = extensions.betterpartmgmt.categoryFilter(list, true)
end
extensions.customGuiStream.sendDataToUI("garageData", list)
end

ftable["uiinit"] = function(p)
extensions.blrglobals.blrFlagSet("uiInitRequest", true)
print("UI Init Request Received")
end

ftable["setTune"] = function(p)
local dtable = extensions.betterpartmgmt.tuningTableFromUIData(p, false)
extensions.blrglobals.gmSetVal("pgas", extensions.blrglobals.gmGetVal("cgas")) 	-- Gets current gas value and stores it for after tune apply
extensions.blrglobals.gmSetVal("podo", extensions.blrglobals.gmGetVal("codo"))	-- Do same thing with odometer
extensions.blrhooks.linkHook("vehReset", "postedit")							-- Link to post edit action hook, reuse the code for tune
extensions.betterpartmgmt.applyTuningData(dtable)
end

ftable["resetTune"] = function(p)
extensions.blrglobals.gmSetVal("pgas", extensions.blrglobals.gmGetVal("cgas")) 	-- Gets current gas value and stores it for after tune apply
extensions.blrglobals.gmSetVal("podo", extensions.blrglobals.gmGetVal("codo"))	-- Do same thing with odometer
extensions.blrhooks.linkHook("vehReset", "postedit")							-- Link to post edit action hook, reuse the code for tune
extensions.betterpartmgmt.resetTuningData()
end

ftable["uiResetCareer"] = function(p)
extensions.blrglobals.blrFlagSet("careerResetRequest", true)					-- Send career reset request to flowgraph using blrglobals
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
local mc = extensions.blrutils.convertUIPaintToMeshColors(p)
extensions.blrutils.repaintFullMesh(vehid, mc.car,mc.cag, mc.cab, mc.caa, mc.cbr,mc.cbg,mc.cbb, mc.cba, mc.ccr,mc.ccg,mc.ccb, mc.cca)
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
extensions.blrutils.updateDataTable("beamLR/options", dtable)
end
end

ftable["setRandomSeed"] = function(p)
local dtable = {}
math.randomseed(os.time())
dtable["nseed"] = math.random(1,9999999999)
extensions.blrutils.updateDataTable("beamLR/options", dtable)
end



local ptable = {}

local rtable = {}

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



