local M = {}

local utils = require("extensions").blrutils

local inventory = {}
local idstore = {}
local idmax = 9999999

local function reset()
inventory = {}
idstore = {}
end

local function copytable(input)
local output = {}
for k,v in pairs(input) do
output[k] = v
end
return output
end

-- for ui adds empty table at index 0 if it doesn't exist
-- to ensure part ids stay the same between 0 indexed arrays in js
-- and 1 indexed array in lua
local function getInventory(forui)
local toRet = copytable(inventory)
if forui then toRet[0] = {} end
return toRet
end

local function getPart(id)
return inventory[id]
end

local function add(part, odometer, condition, used)
local id = -1
for i=1,idmax do 
if not idstore[i] then 
id = i
idstore[id] = true
break
end
end
inventory[id] = {part, odometer, condition, used and 1 or 0}
return id 
end

local function edit(id, odometer, condition, used)
if inventory[id] then
if odometer then inventory[id][2] = odometer end
if condition then inventory[id][3] = condition end
if used ~= nil then inventory[id][4] = used and 1 or 0 end
end
end

local function setPartOdometer(id, val, increment)
local current = 0
if increment then current = inventory[id][2] end
edit(id, current + val)
end

local function setPartIntegrity(id, val)
print("SHOULD HAVE SET INTEGRITY FOR " .. id .. " TO " .. val)
edit(id, nil, val)
end

-- MUST pass BOOLEAN as val otherwise the "and 1 or 0" in edit function always gives 1
local function setPartUsed(id, val)
edit(id, nil, nil, val)
end



local function remove(id)
idstore[id] = nil
inventory[id] = nil
end

local function save()
local filedata = ""
for k,v in pairs(inventory) do
filedata = filedata .. k .. "=" .. v[1] .. "," .. v[2] .. "," .. v[3] .. "," .. v[4] .. "\n"
end
writeFile("beamLR/partInventory", filedata)
end

local function load()
reset()

local dtable = utils.loadDataTable("beamLR/partInventory")
local csplit = {}
local cid = 0
for k,v in pairs(dtable) do
csplit = utils.ssplit(v, ",")
cid = tonumber(k)
--				   name			odometer			integrity 			 in use (1=true, 0=false)
inventory[cid] = {csplit[1], tonumber(csplit[2]), tonumber(csplit[3]), tonumber(csplit[4])}
idstore[cid] = true
end

end

local function debugDump()
for k,v in pairs(inventory) do print(k .. " = " .. dumps(v)) end
end

local function getPartCounts()
local toRet = {}
for k,v in pairs(inventory) do
if not toRet[v[1]] then toRet[v[1]] = 0 end
if v[4] == 0 then
toRet[v[1]] = toRet[v[1]] + 1
end
end
return toRet
end

-- unused toggle only returns unused parts
local function getPartKeyedIDLists(unused)
local toRet = {}
local cname = ""

for k,v in pairs(inventory) do
cname = v[1]
if not toRet[cname] then toRet[cname] = {} end
if (v[4] == 0) or (not unused) then
table.insert(toRet[cname], k)
end
end

return toRet
end



-- Below code deals with part shop used parts, so they're only purchasable once per shop
-- not directly related to inventory but part of new system so added it here anyway
local usedPartShopDayData = {}

local function onUsedPartPurchased(part, shopid)
if not usedPartShopDayData["shop" .. shopid] then
usedPartShopDayData["shop" .. shopid] = {}
end
usedPartShopDayData["shop" .. shopid][part] = true
end

local function getUsedPartShopDayData(shopid)
return usedPartShopDayData["shop" .. shopid] or {}
end

local function loadUsedPartShopDayData()
local dtable = extensions.blrutils.loadDataTable("beamLR/usedPartDayData")
usedPartShopDayData = {}
local csplit = {}
for k,v in pairs(dtable) do
usedPartShopDayData[k] = {}
csplit = extensions.blrutils.ssplit(v, ",")
for _,p in pairs(csplit) do
usedPartShopDayData[k][p] = true
end
end
end

local function saveUsedPartShopDayData()
local filedata = ""

for k,v in pairs(usedPartShopDayData) do
filedata = filedata .. k .. "=" 
for p,_ in pairs(v) do
filedata = filedata .. p .. ","
end
filedata = filedata:sub(1,-2) -- remove last comma
filedata = filedata .. "\n"
end

writeFile("beamLR/usedPartDayData", filedata)
end

local function resetUsedPartShopDayData()
usedPartShopDayData = {}
end


M.onUsedPartPurchased = onUsedPartPurchased
M.getUsedPartShopDayData = getUsedPartShopDayData
M.resetUsedPartShopDayData = resetUsedPartShopDayData
M.loadUsedPartShopDayData = loadUsedPartShopDayData
M.saveUsedPartShopDayData = saveUsedPartShopDayData

M.getPartKeyedIDLists = getPartKeyedIDLists
M.getPartCounts = getPartCounts
M.setPartUsed = setPartUsed
M.setPartIntegrity = setPartIntegrity
M.setPartOdometer = setPartOdometer
M.edit = edit
M.getPart = getPart
M.getInventory = getInventory
M.add = add
M.remove = remove
M.save = save
M.load = load
M.reset = reset
M.debugDump = debugDump

return M