-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local inventory = {}
local iidstore = {}
local iidmax = 100

local function ssplit(s, delimiter) 
local result = {}
if delimiter == "." then
for match in (s..delimiter):gmatch("(.-)%"..delimiter) do
table.insert(result, match)
end
else
for match in (s..delimiter):gmatch("(.-)"..delimiter) do
table.insert(result, match)
end
end
return result
end

-- GENERAL ITEM DEFINITIONS

local uinames = {fuelcan = "Fuel Canister", oilbottle = "Oil Bottle"}
local uiimages = {fuelcan = "jerrycan.png", oilbottle = "oilbottles.png"}

-- FUEL CAN

local fuelcan = {ftype="", ftier="", quantity=0}

function fuelcan:use(quantity)
self.quantity = self.quantity - quantity
if (math.floor(self.quantity * 100.0) / 100.0) <= 0 then
self.quantity = 0
end
return self.quantity
end

function fuelcan:new(ftype, ftier, quantity)
local o = {ftype="", ftier="", quantity=0}
o.ftype = ftype or o.ftype
o.ftier = ftier or o.ftier
o.quantity = quantity or o.quantity
setmetatable(o, self)
self.__index = self
return o
end

function fuelcan:decode(data)
local dtable = ssplit(data, ",")
local o = {}
o.ftype = dtable[1]
o.ftier = dtable[2]
o.quantity = tonumber(dtable[3])
setmetatable(o, self)
self.__index = self
return o
end

function fuelcan:encode()
return "" .. self.ftype .. "," .. self.ftier .. "," .. self.quantity
end

-- Oil Bottle

local oilbottle = {brand="", grade="",quantity=0}

function oilbottle:use(quantity)
self.quantity = self.quantity - quantity
if (math.floor(self.quantity * 100.0) / 100.0) <= 0 then
self.quantity = 0
end
return self.quantity
end

function oilbottle:new(brand, grade, quantity)
local o = {brand="",grade="",quantity=0}
o.quantity = quantity or o.quantity
o.brand = brand or o.brand
o.grade = grade or o.grade
setmetatable(o, self)
self.__index = self
return o
end

function oilbottle:decode(data)
local dtable = ssplit(data, ",")
local o = {}
o.brand = dtable[1]
o.grade = dtable[2]
o.quantity = tonumber(dtable[3])
setmetatable(o, self)
self.__index = self
return o
end

function oilbottle:encode()
return "" .. self.brand .. "," .. self.grade .. "," .. self.quantity
end

-- INVENTORY FUNCTIONS

local function getNextIID()
local id = 0
for id=1,iidmax do
if not iidstore[id] then return id end
end
return -1
end

local function addToInventory(itype, item)
local iid = getNextIID()
inventory[iid .. "_" .. itype] = item
iidstore[iid] = true
return iid
end

local function getKeyByID(iid)
for k,v in pairs(inventory) do
if string.find(k, iid) then return k end
end
end

local function removeFromInventory(key)
local csplit = ssplit(key, "_")
local iid = tonumber(csplit[1])
local itype = csplit[2]
inventory[iid .. "_" .. itype] = nil
iidstore[iid] = nil
end

local function getInventoryItem(key)
local csplit = ssplit(key, "_")
local iid = tonumber(csplit[1])
local itype = csplit[2]
return inventory[iid .. "_" .. itype]
end

local function dumpInventory()
print("\n")
for k,v in pairs(inventory) do
print(k .. "=" .. v:encode()) 
end
end



local function loadDataTable(file)
local filedata = readFile(file)
local dtable = {}
for k,v in string.gmatch(filedata, "([^%c]+)=([^%c]+)") do
    dtable[k] = v
end
return dtable
end

local function saveDataTable(file, data)
local filedata = ""
for k,v in pairs(data) do
filedata = filedata .. k .. "=" .. v .. "\n"
end
writeFile(file, filedata)
end


local function loadInventory()
local dtable = loadDataTable("beamLR/itemInventory")
inventory = {}
iidstore = {}
local csplit_key = {}
local csplit_idata = {}
local iid = -1
local itype = ""
for k,v in pairs(dtable) do
csplit_key = ssplit(k, "_")
csplit_idata = ssplit(v, ",")
iid = tonumber(csplit_key[1])
itype = csplit_key[2]
iidstore[iid] = true
														-- fuel type  ,  fuel tier   , fuel quantity
if itype == "fuelcan" then inventory[k] = fuelcan:new(csplit_idata[1],csplit_idata[2],tonumber(csplit_idata[3])) end
														-- brand         ,    grade      ,  quantity
if itype == "oilbottle" then inventory[k] = oilbottle:new(csplit_idata[1],csplit_idata[2],tonumber(csplit_idata[3])) end

end
end

local function saveInventory()
local tosave = {}
for k,v in pairs(inventory) do
tosave[k] = v:encode()
end
saveDataTable("beamLR/itemInventory", tosave)
end

local function getInventory()
return inventory
end

local function getUIName(t)
return uinames[t]
end

local function getUIImage(t)
return uiimages[t]
end

local function resetInventory()
inventory = {}
iidstore = {}
end

M.oilbottle = oilbottle
M.fuelcan = fuelcan

M.resetInventory = resetInventory
M.getKeyByID = getKeyByID
M.getUIImage = getUIImage
M.getUIName = getUIName
M.getInventory = getInventory
M.getInventoryItem = getInventoryItem
M.removeFromInventory = removeFromInventory
M.addToInventory = addToInventory
M.loadInventory = loadInventory
M.saveInventory = saveInventory

return M

