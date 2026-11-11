local M = {}

local function getAvailableSeats(vehid)
local id = vehid or be:getPlayerVehicle(0):getId()
if not id then 
blrlog("getAvailableSeats error, vehid is nil and player isn't using a vehicle", lvl_warn)
return
end
return extensions.gameplay_seatOccupants.getSeats(id)
end

local function getDriverSeatID(vehid)
local seats = getAvailableSeats(vehid)
for _,sdata in pairs(seats) do
if sdata.isDriver then 
return sdata.seatId
end
end
blrlog("getDriverSeatID error, couldn't find driver seat", lvl_warn)
return nil
end

-- returns two lists for occupied and unoccupied seats
local function getSeatIDsByOccupiedStatus(vehid)
local seats = getAvailableSeats(vehid)
local toRet = {}
toRet.occupied = {}
toRet.unoccupied = {}

for _,sdata in pairs(seats) do
if sdata.occupied then 
table.insert(toRet.occupied, sdata.seatId)
else
table.insert(toRet.unoccupied, sdata.seatId)
end
end

return toRet
end

local function getRandomSeatByOccupiedStatus(vehid, occupied, seed)
local avail = getSeatIDsByOccupiedStatus(vehid)
local status = (occupied and "occupied") or "unoccupied"
local count = #avail[status]

if count < 1 then 
blrlog("getRandomSeatByOccupiedStatus didn't find any seat for status " .. status)
return
end

if seed then
math.randomseed(seed)
else
math.randomseed(os.clock() * 10000000)
end

local pick = math.random(1, count)

return avail[status][pick]
end

local occupants = {}

-- don't pass occupant to clear seat
local function setSeatOccupant(vid, seat, occupant)
local vehid = vid or be:getPlayerVehicle(0):getId()
if not vehid then 
blrlog("setSeatOccupant error, vehid is nil and player isn't using a vehicle", lvl_warn)
return
end
if not seat then
blrlog("setSeatOccupant error, seat is nil", lvl_warn)
return
end

if occupant then 
blrlog("Should have added occupant to seat " .. seat)
occupants[seat] = occupant
extensions.gameplay_seatOccupants.setDummyOccupant(vehid, seat, occupant.weight)
else
blrlog("Should have cleared occupant from seat " .. seat)
occupants[seat] = nil
extensions.gameplay_seatOccupants.clearDummyOccupant(vehid, seat)
end
end

-- util function to remove all passengers from car
local function clearNonDriverSeats(vid)
local vehid = vid or be:getPlayerVehicle(0):getId()
if not vehid then 
blrlog("clearNonDriverSeats error, vehid is nil and player isn't using a vehicle", lvl_warn)
end

local seats = getAvailableSeats(vehid)
local driver = getDriverSeatID(vehid)
for _,sdata in pairs(seats) do
if sdata.seatId ~= driver then
setSeatOccupant(vehid, sdata.seatId)
end
end
end

local function getOccupantsData()
return occupants
end

local function generateLicensePlateText(vid)
local vehid = vid or be:getPlayerVehicle(0):getId()
if not vehid then 
blrlog("generateLicensePlateText failed, vid is nil and player doesn't have an active vehicle", lvl_warn)
return 
end
local plateDesign = require('core/licensePlateDesign')
local veh = getObjectByID(vehid)

if not veh then 
blrlog("generateLicensePlateText failed, vehicle specified by id " .. vehid .. " is nil", lvl_warn)
return
end

local designPath = veh:getDynDataFieldbyName("licenseDesign", 0) or ''
local design = designPath and plateDesign.loadDesign(designPath)
return extensions.core_skiaTemplate.generateText(design, veh) or "ABC123"
end

M.generateLicensePlateText = generateLicensePlateText
M.getOccupantsData = getOccupantsData
M.clearNonDriverSeats = clearNonDriverSeats
M.setSeatOccupant = setSeatOccupant
M.getRandomSeatByOccupiedStatus = getRandomSeatByOccupiedStatus
M.getSeatIDsByOccupiedStatus = getSeatIDsByOccupiedStatus
M.getDriverSeatID = getDriverSeatID
M.getAvailableSeats = getAvailableSeats


return M