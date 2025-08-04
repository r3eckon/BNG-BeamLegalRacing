local M = {}

local carMeetScoreData = {}
local carMeetIDTable = {}
local selectedCar = 1
local scores = {}
local averageScore = 0
local minScore = math.huge
local maxScore = 0

local resetCarMeetData = function()
carMeetScoreData = {}
carMeetIDTable = {}
selectedCar = 1
scores = {}
averageScore = 0
minScore = math.huge
maxScore = 0
end

local getCarMeetScoreData = function()
return carMeetScoreData
end

local getCarMeetIDTable = function()
return carMeetIDTable
end

local setCarMeetIDTable = function(tab)
carMeetIDTable = tab
end



local function getSelectedCar()
return selectedCar
end

local function setSelectedCar(index)
if index >= 1 and index <= #carMeetIDTable then
selectedCar = index
end
end

local function getCarCount()
return #carMeetIDTable
end

local function averageScores()
averageScore = 0

for k,v in pairs(carMeetScoreData) do
averageScore = averageScore + v.total
end

averageScore = averageScore / #carMeetIDTable
end

local function getAverageScore()
return averageScore
end

local function getscores()
return scores
end

local function getPosition(index)
local position = 1
local pid = carMeetIDTable[index]

for k,v in valueSortedPairs(scores) do
if k == pid then break end
position = position + 1
end

position = (#carMeetIDTable + 1) - position

return position
end


local onCarMeetScoreReceived = function(index, data)
carMeetScoreData[index] = jsonDecode(data)
local cscore = carMeetScoreData[index].total
scores[carMeetIDTable[index]] = cscore
averageScores()
if cscore < minScore then minScore = cscore end
if cscore > maxScore then maxScore = cscore end
end

local detailedMode = false

local function getDetailedMode()
return detailedMode
end

local function toggleDetailedMode(mode)
detailedMode = not detailedMode
end

local dnames = {spoiler = "Spoilers", underglow = "Underglow", lip="Splitters & Lips", race_seat = "Race Seats", strut_bar="Strut Bars", rollcage="Rollcage", paint = "Paint Design", carbon="Carbon Fiber", performance="Raw Performance", turbocharger="Turbocharger", supercharger="Supercharger", nitrous="N2O"}
local function getDetailItemNames()
return dnames
end


local function getCarRating(index)
local cscore = carMeetScoreData[index].total
local avg = averageScore
local toRetText = "unknown"
local toRetRep = 0

if cscore < averageScore - 100 then
toRetText = "Below Average" 
toRetRep = -100

if cscore == minScore then -- car has worst rating of meet, 2x rep loss
toRetText = "Worst"
toRetRep = -200
end

elseif cscore > averageScore + 100 then
toRetText = "Above Average"
toRetRep = 100

if cscore == maxScore then -- car has best rating of meet, 2x rep reward
toRetText = "Best"
toRetRep = 200
end

else -- if rating is within 100 points of average, no rep is gained or lost
toRetText = "Average"
toRetRep = 0
end

return toRetText,toRetRep
end

local daydata = {}

local function loadDayData()
local filedata = extensions.blrutils.loadDataTable("beamLR/carMeetDayData")
daydata = {}
if filedata["visited"] == "none" then
return
end

local visited = extensions.blrutils.ssplitnum(filedata["visited"], ",")

for k,v in pairs(visited) do
daydata[v] = true
end

end


local function getDayData()
return daydata
end

local function updateDayData(id)
if id then
daydata[id] = true
end

local savedata = {}
local visited = "none"

local index = 1

for k,v in pairs(daydata) do
if index == 1 then visited = "" end
visited = visited .. k .. ","
index = index + 1
end

if visited ~= "none" then
savedata["visited"] = visited:sub(1,-2)
else
savedata["visited"] = visited
end
extensions.blrutils.saveDataTable("beamLR/carMeetDayData", savedata)
end

local function resetDayData()
daydata = {}
local savedata = {visited="none"}
extensions.blrutils.saveDataTable("beamLR/carMeetDayData", savedata)
end


M.resetDayData = resetDayData
M.updateDayData = updateDayData
M.getDayData = getDayData
M.loadDayData = loadDayData
M.getCarRating = getCarRating
M.getDetailItemNames = getDetailItemNames
M.getDetailedMode = getDetailedMode
M.toggleDetailedMode = toggleDetailedMode
M.getPosition = getPosition
M.getAverageScore = getAverageScore
M.getCarCount = getCarCount
M.getSelectedCar = getSelectedCar
M.setSelectedCar = setSelectedCar
M.setCarMeetIDTable = setCarMeetIDTable
M.getCarMeetIDTable = getCarMeetIDTable
M.onCarMeetScoreReceived = onCarMeetScoreReceived
M.getCarMeetScoreData = getCarMeetScoreData
M.resetCarMeetData = resetCarMeetData


return M