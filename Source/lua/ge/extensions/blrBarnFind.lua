local M = {}

local extensions = require("extensions")

-- lazy hashing just to offset seed using map name, doesn't really need to be unique
local function stringToNumHash(str)
local cbval = 0
local total = 0
local cchar = ""
for i=1,#str do
cchar = str:sub(i,i)
cbval = string.byte(cchar)
total = total + cbval
end
return total
end

local function getBarnFindSeed()
local level = testlvl or extensions.blrutils.getLevelName()
return extensions.blrutils.getStartSeed() + stringToNumHash(level)
end


local function getBarnFindID()
local level = testlvl or extensions.blrutils.getLevelName()
local seed = getBarnFindSeed()

local trigs = extensions.blrutils.loadDataTable("beamLR/mapdata/" .. level .. "/triggers")
local csplit = {}
local ctype = ""

local bfcount = 0

for k,v in pairs(trigs) do
csplit = extensions.blrutils.ssplit(v, ",")
ctype = csplit[1] or ""
if ctype == "barnfind" then bfcount = bfcount + 1 end 
end

if testcount then bfcount = testcount end

if bfcount == 0 then return -1 end -- no barnfind triggers on this map

math.randomseed(seed)

return math.random(0,bfcount-1)
end


local function getBarnFindCarFile(tdata)
local list = (tdata and tdata["list"]) or "barnfind_all"
local files = extensions.blrutils.loadCarShopList(list)
local seed = getBarnFindSeed()

math.randomseed(seed)

return files[math.random(1, #files)]
end

local function spawnBarnFind(tdata, carfile)
local seed = getBarnFindSeed() + getBarnFindID()
local pos = extensions.blrutils.ssplitnum(tdata["slotp"], ",")
local rot = extensions.blrutils.ssplitnum(tdata["slotr"], ",")
local cdata = extensions.blrutils.loadDataTable("beamLR/shop/car/" .. carfile)

local cconfig = jsonReadFile(cdata["config"])
local cmodel = cdata["type"]
local spawnpaint = {}
local retpaint = {}

local dtxt = ""
local processed = extensions.blrutils.processCarShopRandoms(cdata, seed, false)

pos = vec3(pos[1], pos[2], pos[3])
rot = quat(rot[1], rot[2], rot[3], rot[4])

cconfig["paints"] = nil

spawnpaint[1] = extensions.blrutils.createRandomFactoryPaint(seed, cmodel)
spawnpaint[2] = extensions.blrutils.createRandomFactoryPaint(seed + 1, cmodel)
spawnpaint[3] = extensions.blrutils.createRandomFactoryPaint(seed + 2, cmodel)
retpaint[1] = extensions.blrutils.vehiclePaintToGaragePaint(spawnpaint[1])
retpaint[2] = extensions.blrutils.vehiclePaintToGaragePaint(spawnpaint[2])
retpaint[3] = extensions.blrutils.vehiclePaintToGaragePaint(spawnpaint[3])

local toRet = {}
toRet["paints"] = retpaint
toRet["model"] = cmodel
toRet["config"] = cconfig
toRet["odometer"] = tonumber(processed["odometer"])
toRet["baseprice"] = tonumber(processed["baseprice"])
toRet["partprice"] = tonumber(cdata["partprice"])
toRet["scrapval"] = tonumber(cdata["scrapval"])
toRet["cost"] = toRet["baseprice"] + toRet["partprice"]

local odoval = tonumber(processed["odometer"]) / 1000
local units = extensions.blrutils.getSettingValue("uiUnits")
local fulldesc = cdata["name"] .. "\n" 
if units == "metric" then
fulldesc = fulldesc .. extensions.blrlocales.translate("beamlr.generic.button.odometer") .. ": " .. string.format("%.1f",odoval) .. " km\n"
else
odoval = odoval / 1.609344
fulldesc = fulldesc .. extensions.blrlocales.translate("beamlr.generic.button.odometer") .. ": " .. string.format("%.1f",odoval)  .. " mi\n"
end
fulldesc = fulldesc .. extensions.blrlocales.translate("beamlr.generic.term.cost") .. ": $" .. string.format("%.2f", tonumber(processed["baseprice"]) + tonumber(cdata["partprice"])) .. "\n"

toRet["desc"] = fulldesc

local spawnOptions = {config = cconfig, pos = pos, rot = rot, paint = spawnpaint[1],paint2 = spawnpaint[2], paint3 = spawnpaint[3], autoEnterVehicle = false }
local spawnedVeh = extensions.core_vehicles.spawnNewVehicle(cmodel, spawnOptions)

toRet["vehid"] = spawnedVeh:getId()

return toRet
end


M.spawnBarnFind = spawnBarnFind
M.getBarnFindCarFile = getBarnFindCarFile
M.getBarnFindID = getBarnFindID
M.stringToNumHash = stringToNumHash


return M