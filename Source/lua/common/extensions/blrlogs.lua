local M = {}

blrlogid = 0

-- tail this file with powershell for instant logs during main thread locking loops
-- EX: Get-Content C:\Users\r3eck\AppData\Local\BeamNG.drive\current\beamlr.log  -Wait -Tail 1
function blrlog(txt, wid)
if wid then
if (vmType == "vehicle") then print("Log from VEH " .. obj:getId() .. " to BeamLR log at ID: " .. blrlogid)
else print("Log from GE to BeamLR log at ID: " .. blrlogid)
end
end
local toprint = txt
if not toprint then toprint = "nil" end
local prefix = "[" .. string.format("%.3f",os.clock()) .. "]"
if (vmType == "vehicle") then prefix = prefix .. " VLUA " .. obj:getId() .. " |" end
if type(txt) == "table" then
toprint = dumps(txt)
end

if wid then
prefix = prefix .. " LOG ID " .. blrlogid .. " |"
blrlogid = blrlogid+1
end

local f = io.open("beamlr.log", "a")
f:write(prefix .. " " .. toprint .. "\n")
f:flush()
f:close()
end

-- rotate log files similar to how vanilla does it to keep 3 session specific logs
local function rotateLogs()
if FS:fileExists("beamlr.3.log") then FS:removeFile("beamlr.3.log") end
if FS:fileExists("beamlr.2.log") then FS:copyFile("beamlr.2.log", "beamlr.3.log") end
if FS:fileExists("beamlr.1.log") then FS:copyFile("beamlr.1.log", "beamlr.2.log") end
if FS:fileExists("beamlr.log") then FS:copyFile("beamlr.log", "beamlr.1.log") end
writeFile("beamlr.log", "")
end


local function onGameStartedBLR()
if vmType == "game" then -- avoid rotating logs with vlua vms
print("blrlogs should have rotated logs!")
rotateLogs()
blrlog("BeamLR log for session started on " .. os.date())
end
end

M.rotateLogs = rotateLogs

M.onGameStartedBLR = onGameStartedBLR

return M