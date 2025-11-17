local M = {}

local extensions = require("extensions")
local guihooks = require("guihooks")
local guiapps = require("ui/apps")
local appOnLayout = extensions.blrutils.isAppOnLayout("beamlrshopvehutil",core_gamestate.state.appLayout)
local uicache = {}
local originalConfig = {}
local originalSlots = {}
local replaceNoClearCache = false

local function showMessage(msg, icon, ttl, cat)
guihooks.trigger('Message', {ttl = ttl or 10,category=cat or "shopVehUtil", msg = msg or "", icon = icon or "warning"})
end

local function deepcopy(t)
local toRet = {}
for k,v in pairs(t) do
if type(v) == "table" then
toRet[k] = deepcopy(v)
else
toRet[k] = v
end
end
return toRet
end


local function sendUIData(withCache)

local cacheValid = extensions.blrpartmgmt.isJbeamCacheValid()

if not cacheValid then
print("BeamLR Dealership Util could not load due to invalid cache")
guihooks.trigger("beamlrShopVehCacheValid", false)
return
end

guihooks.trigger("beamlrShopVehCacheValid", true)

-- extensions.blrpartmgmt.generateJbeamLibraries()

local toSend = {}

local model = extensions.blrpartmgmt.getVehicleModel()  -- 1.19 fix for mods that don't use main part name as model
if model == "unicycle" then 
guihooks.trigger("beamlrShopVehUtilWalking", true)
return 
else
guihooks.trigger("beamlrShopVehUtilWalking", false)
end

local slots = extensions.blrpartmgmt.getSortedActualSlots()
local names = extensions.blrpartmgmt.getSlotNameLibrary()
local carinfo = extensions.blrutils.getVehicleInfoFile()
local carname = carinfo["Brand"] .. " " .. carinfo["Name"]
local config = extensions.blrpartmgmt.getVehicleData().config.partConfigFilename
local vid = be:getPlayerVehicle(0):getId()

if config then
originalConfig[vid] = config
originalSlots[vid] = deepcopy(slots)
else
config = originalConfig[vid]
slots = deepcopy(originalSlots[vid])
end

local mainPartChild = extensions.blrpartmgmt.getMainPartChild(nil,true)--nil to get current veh, true to get slot only
local listFiles = {}
local listAddonFolders = {}
local listAddonFiles = {}
local carFiles = {}
local sortedCarFiles = {}
local carFilesData = {}
local listFilesData = {}
local addonFilesData = {}
local sortedListFiles = {}
local sortedAddonFolders = {}
local sortedAddonFiles = {}
local sortedShopFiles = {}
local shopFilesData = {}

local cldata = {}
for _,file in valueSortedPairs(FS:findFiles("beamLR/shop/car", "list*", 0, false, false)) do
	table.insert(sortedListFiles, file)
	listFiles[file] = true
	cldata = extensions.blrutils.loadDataFile(file)
	for _,car in pairs(cldata) do
		if not listFilesData[file] then listFilesData[file] = {} end
		listFilesData[file][car] = true
	end
end

local cadata = {}
for _,dir in valueSortedPairs(FS:findFiles("beamLR/shop/car", "addon*", 0, true, true)) do
	if FS:directoryExists(dir) and not FS:fileExists(dir) then
		listAddonFolders[dir] = true
		table.insert(sortedAddonFolders, dir)
		for _,file in valueSortedPairs(FS:findFiles(dir, "*", 0)) do
			if not listAddonFiles[dir] then listAddonFiles[dir] = {} end
			if not sortedAddonFiles[dir] then sortedAddonFiles[dir] = {} end
			table.insert(sortedAddonFiles[dir], file)
			listAddonFiles[dir][file] = true

			cadata = extensions.blrutils.loadDataFile(file)
			for _,car in pairs(cadata) do
				if not addonFilesData[file] then addonFilesData[file] = {} end
				addonFilesData[file][car] = true
			end
		end

	end
end


local ccdata = {}
for _,file in valueSortedPairs(FS:findFiles("beamLR/shop/car", "*", 0, false, false)) do
	if not listFiles[file] then
		carFiles[file] = true
		table.insert(sortedCarFiles, file)
		ccdata = extensions.blrutils.loadDataTable(file)
		carFilesData[file] = {model = ccdata.type, config = ccdata.config}
	end
end

local csdata = {}
for _,file in valueSortedPairs(FS:findFiles("beamLR/shop/", "*", 0, false, false)) do
table.insert(sortedShopFiles, file)
csdata = extensions.blrutils.loadDataTable(file)
shopFilesData[file] = csdata
end


toSend["slots"] = slots
toSend["slotName"] = names
toSend["model"] = model
toSend["modelName"] = carname
toSend["mainPartChild"] = mainPartChild
toSend["config"] = config
toSend["listFiles"] = listFiles
toSend["listAddonFolders"] = listAddonFolders
toSend["listAddonFiles"] = listAddonFiles
toSend["carFiles"] = carFiles
toSend["sortedCarFiles"] = sortedCarFiles
toSend["carFilesData"] = carFilesData
toSend["listFilesData"] = listFilesData
toSend["addonFilesData"] = addonFilesData
toSend["sortedListFiles"] = sortedListFiles
toSend["sortedAddonFolders"] = sortedAddonFolders
toSend["sortedAddonFiles"] = sortedAddonFiles
toSend["sortedShopFiles"] = sortedShopFiles
toSend["shopFilesData"] = shopFilesData

guihooks.trigger("beamlrShopVehUtilData", toSend)

if withCache then
guihooks.trigger("beamlrShopVehUtilCache", uicache[vid])
end

end

local function onVehicleReplaced(id)
if appOnLayout then
if not replaceNoClearCache then -- don't clear cache when spawning random configs for same car
uicache[id] = nil
end
if be:getPlayerVehicle(0) then
sendUIData(true)
end
end

replaceNoClearCache = false
end

local function onVehicleDestroyed(id)
if appOnLayout then
uicache[id] = nil
end
end

local function onVehicleSwitched(old,new)
if appOnLayout and be:getPlayerVehicle(0) then
sendUIData(true)
end
end

local function onGameStateUpdate(newState)
appOnLayout = extensions.blrutils.isAppOnLayout("beamlrshopvehutil",core_gamestate.state.appLayout)
end


local uiparams = {}

local function resetParams()
uiparams = {}
end
local function resetCache()
uicache = {}
end
local function receiveParam(k,v)
uiparams[k] = v
end
local function receiveParamTableValue(t,k,v)
if not uiparams[t] then uiparams[t] = {} end
uiparams[t][k] = v
end
local function receiveCacheParam(k,v)
local vid = be:getPlayerVehicle(0):getId()
if not uicache[vid] then uicache[vid] = {} end
uicache[vid][k] = v
end
local function receiveCacheParamTableValue(t,k,v)
local vid = be:getPlayerVehicle(0):getId()
if not uicache[vid] then uicache[vid] = {} end
if not uicache[t] then uicache[t] = {} end
uicache[vid][t][k] = v
end

local fun = {}

fun["saveCarFile"] = function()
print("Saving car file with params:")
dump(uiparams)

local fmt = {"name", "type", "config", "baseprice", "odometer", "scrapval", "partprice", "paint", "randslots"}
local saveData = {}

saveData["name"] = uiparams["name"]
saveData["type"] = uiparams["type"]
saveData["config"] = uiparams["config"]
if uiparams["maxcost"] ~= uiparams["mincost"] then
saveData["baseprice"] = uiparams["mincost"] .. "," .. uiparams["maxcost"]
else
saveData["baseprice"] = uiparams["mincost"]
end
if uiparams["minodo"] ~= uiparams["maxodo"] then
saveData["odometer"] = (uiparams["minodo"] * 1000) .. "," .. (uiparams["maxodo"] * 1000)
else
saveData["odometer"] = uiparams["minodo"] * 1000
end
saveData["scrapval"] = uiparams["scrapval"]
saveData["partprice"] = 0
saveData["paint"] = "0,0,0,0,0.1,0.1,0.1,0.1"

if uiparams["randslots"] then
saveData["randslots"] = ""
for k,v in pairs(uiparams["randslots"]) do
saveData["randslots"] = saveData["randslots"] .. k .. ","
end
saveData["randslots"] = saveData["randslots"]:sub(1,-2)
end



extensions.blrutils.saveDataTable("beamLR/shop/car/" .. uiparams["filename"], saveData, fmt)

showMessage("Vehicle file " .. uiparams["filename"] .. " has been saved", "save")

-- update ui
sendUIData(true)

end


fun["addToList"] = function()
print("Adding to list with params:")
dump(uiparams)

local currentCars = {}
local cldata = {}

if uiparams["addonMode"] then

	for list,addon in pairs(uiparams["selectedAddons"]) do
		currentCars = {}
		
		-- used addon for a list that doesn't exist yet, create empty list file
		if not FS:fileExists(list) then
			writeFile(list,"")
		end

		-- skip duplicate check if addon doesn't exist yet
		if FS:fileExists(addon) then
			cldata = extensions.blrutils.loadDataFile(addon)
			for _,car in pairs(cldata) do
				if car ~= "" then
					currentCars[car] = true
				end
			end
		end
		
		currentCars[uiparams["filename"]] = true
		extensions.blrutils.saveDataFile(addon, currentCars, true)
	end

else

	for list,_ in pairs(uiparams["selectedLists"]) do
		currentCars = {}
		if FS:fileExists(list) then -- skip duplicate check if list doesn't exist yet
			cldata = extensions.blrutils.loadDataFile(list)
			for _,car in pairs(cldata) do
				if car ~= "" then
					currentCars[car] = true
				end
			end
		end
		currentCars[uiparams["filename"]] = true
		extensions.blrutils.saveDataFile(list, currentCars, true)
	end
	
end

showMessage("Vehicle file " .. uiparams["filename"] .. " has been saved and added to selected lists/addons", "save")
end

fun["loadCarFile"] = function()
local cfile = extensions.blrutils.loadDataTable(uiparams["carfile"])
local toSend = {}
local csplit = {}
local cmodel = extensions.blrutils.getVehicleMainPartName()
local cconfig = extensions.blrpartmgmt.getVehicleData().config.partConfigFilename
local vid = be:getPlayerVehicle(0):getId()

toSend["name"] = cfile.name

csplit = extensions.blrutils.ssplit(cfile.baseprice, ",")
if(#csplit==1) then
toSend["mincost"] = tonumber(csplit[1])
toSend["maxcost"] = tonumber(csplit[1])
else
toSend["mincost"] = tonumber(csplit[1])
toSend["maxcost"] = tonumber(csplit[2])
end

csplit = extensions.blrutils.ssplit(cfile.odometer, ",")
if(#csplit==1) then
toSend["minodo"] = tonumber(csplit[1]) / 1000
toSend["maxodo"] = tonumber(csplit[1]) / 1000
else
toSend["minodo"] = tonumber(csplit[1]) / 1000
toSend["maxodo"] = tonumber(csplit[2]) / 1000
end

toSend["scrapval"] = tonumber(cfile.scrapval)

if cfile.randslots then
toSend["randslots"] = {}
csplit = extensions.blrutils.ssplit(cfile.randslots, ",")
for _,v in pairs(csplit) do
toSend["randslots"][v] = true
end
end

-- skip reloading car if it's the exact same model and config while in replace mode
if uiparams["replace"] and (cfile.type ~= cmodel or cfile.config ~= cconfig) then
extensions.core_vehicles.replaceVehicle(cfile.type, {config=cfile.config})
else -- otherwise always spawn 
extensions.core_vehicles.spawnNewVehicle(cfile.type, {config=cfile.config})
end

-- also send filename to ui to be able to save edits using filename without having to type it again
csplit = extensions.blrutils.ssplit(uiparams["carfile"], "/")
toSend["carfile"] = csplit[#csplit] 

guihooks.trigger("beamlrShopLoadedCarParams", toSend)
end


fun["editList"] = function()
local list = uiparams["list"]
local selected = uiparams["selected"] or {}
local saveData = {}
local csplit = {}
local ccar = ""

dump(uiparams)

for _,file in valueSortedPairs(FS:findFiles("beamLR/shop/car", "*", 0, false, false)) do
csplit = extensions.blrutils.ssplit(file, "/")
ccar = csplit[#csplit]
if selected[ccar] then
table.insert(saveData, ccar)
end
end

dump(saveData)

extensions.blrutils.saveDataFile(list, saveData)

showMessage("Edits made to list/addon " .. uiparams["list"] .. " have been saved", "save")
end

fun["deleteCar"] = function()
local carfile = uiparams["carfile"]
local csplit = extensions.blrutils.ssplit(carfile, "/")
local name = csplit[#csplit]

-- start with main lists 
local cldata = {}
for _,file in pairs(FS:findFiles("beamLR/shop/car", "list*", 0, false, false)) do
cldata = readFile(file)
if string.find(cldata, name) or string.find(cldata,name .. "\n") or string.find(cldata,name .. "\r\n") then
print("Found car file " .. name .. " in list " .. file .. ", removing")
cldata = cldata:gsub(name .. "\r\n", ""):gsub(name .. "\n", ""):gsub(name, "")
writeFile(file, cldata)
end
end

-- next checking addons
local cadata = {}
for _,dir in pairs(FS:findFiles("beamLR/shop/car", "addon*", 0, true, true)) do
if FS:directoryExists(dir) and not FS:fileExists(dir) then
for _,file in pairs(FS:findFiles(dir, "*", 0)) do
cadata = readFile(file)
if string.find(cadata, name) or string.find(cadata,name .. "\n") or string.find(cadata,name .. "\r\n") then
print("Found car file " .. name .. " in addon " .. file .. ", removing")
cadata = cadata:gsub(name .. "\r\n", ""):gsub(name .. "\n", ""):gsub(name, "")
writeFile(file, cadata)
end
end
end
end

-- remove actual car file
extensions.blrutils.deleteFile(carfile)

-- send updated car file list
sendUIData()

showMessage("Deleted car file " .. uiparams["carfile"], "delete_forever")
end

fun["createList"] = function()
print("Creating list/addon file at path: " .. uiparams["path"])
writeFile(uiparams["path"], "")
sendUIData() -- refresh list
showMessage("Created list/addon file at path " .. uiparams["path"], "save")
end

fun["deleteList"] = function()
print("Deleting list/addon file at path: " .. uiparams["path"])
local addon = extensions.blrutils.ssplit(uiparams["path"], "/")
addon = addon[#addon]
addon = "beamLR/shop/car/addon_" .. addon:sub(6)
print("Also deleting potential addon folder at path: " .. addon)
extensions.blrutils.deleteFile(uiparams["path"])
extensions.blrutils.deleteFolder(addon)-- remove addon folder associated with list file if it exists
sendUIData() -- refresh list
showMessage("Deleted list file at path " .. uiparams["path"], "delete_forever")
end

fun["showMessage"] = function()
local msg = uiparams["msg"] or ""
local icon = uiparams["icon"] or "warning"
local ttl = uiparams["ttl"] or 10
local cat = uiparams["cat"] or "shopVehUtil"
dump(uiparams)
guihooks.trigger('Message', {ttl = ttl,category=cat, msg = msg, icon = icon})
end



fun["spawnRandomConfig"] = function()
local selectedSlots = uiparams["randslots"] or {}
local seed = os.clock() * 1000
local vid = be:getPlayerVehicle(0):getId()
local model = extensions.blrpartmgmt.getVehicleModel()  -- 1.19 fix for mods that don't use main part name as model
local config = extensions.blrpartmgmt.getVehicleData().config.partConfigFilename or originalConfig[vid]
local ioctx = extensions.blrpartmgmt.getCustomIOCTX(model)
local slotMap = extensions.blrpartmgmt.getSlotMap(ioctx)
local randomSlots = {}
for k,v in pairs(selectedSlots) do
table.insert(randomSlots, k)
end
local filteredMap = extensions.blrpartmgmt.getFilteredSlotMap(slotMap, randomSlots, {"cargo"}) -- 1.15.3 fix, avoids cargo boxes since they cause issue with roll cages
local randomConfig = extensions.blrpartmgmt.generateConfigVariant(config, filteredMap,seed)
replaceNoClearCache = true -- avoids clearing cache when vehicleReplaced hook is called
extensions.core_vehicles.replaceVehicle(model, {config=randomConfig})
sendUIData()
end

fun["spawnOriginalConfig"] = function()
local model = extensions.blrpartmgmt.getVehicleModel()  -- 1.19 fix for mods that don't use main part name as model
local vid = be:getPlayerVehicle(0):getId()
local config = originalConfig[vid]
replaceNoClearCache = true -- avoids clearing cache when vehicleReplaced hook is called
extensions.core_vehicles.replaceVehicle(model, {config=config})
sendUIData()
end


fun["loadShop"] = function()
local toSend = {}
local shop = uiparams["shop"]
local sdata = extensions.blrutils.loadDataTable(shop)

toSend["name"] = sdata["name"]
toSend["models"] = sdata["models"]
toSend["chance"] = tonumber(sdata["chance"])
toSend["rpchance"] = tonumber(sdata["rpchance"])
toSend["dchance"] = tonumber(sdata["dchance"])

guihooks.trigger("beamlrShopLoadedShopParams", toSend)
end

fun["saveShop"] = function()
local file = uiparams["shop"]
local cdata = extensions.blrutils.loadDataTable(file)
local slots = tonumber(cdata["slots"])
local fmt = {"name", "chance", "rpchance", "dchance", "shopid", "models", "slots"}

for i=0,slots-1 do
table.insert(fmt, "slotp" .. i)
table.insert(fmt, "slotr" .. i)
end

cdata["name"] = uiparams["name"]
cdata["chance"] = uiparams["chance"]
cdata["rpchance"] = uiparams["rpchance"]
cdata["dchance"] = uiparams["dchance"]
cdata["models"] = uiparams["models"]

extensions.blrutils.saveDataTable(file,cdata,fmt)
showMessage("Saved edits for shop file at path " .. file, "save")
end


local function exec(f)
fun[f]()
resetParams()
end

M.onVehicleReplaced = onVehicleReplaced
M.onVehicleDestroyed = onVehicleDestroyed
M.exec = exec
M.receiveCacheParamTableValue = receiveCacheParamTableValue
M.receiveCacheParam = receiveCacheParam
M.receiveParamTableValue = receiveParamTableValue
M.receiveParam = receiveParam
M.resetParams = resetParams
M.onVehicleSwitched = onVehicleSwitched
M.onGameStateUpdate = onGameStateUpdate
M.sendUIData = sendUIData

return M