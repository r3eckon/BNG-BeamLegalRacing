local M = {}

blrlogid = 0

-- global flags for debug mode
beamlr_loglevel = 0
beamlr_debug = false
beamlr_debug_bnglog = false
beamlr_debug_blrlog = false

lvl_err = 1
lvl_warn = 2
lvl_info = 4

-- debugmode option bit map:
-- 1 - E rrors 
-- 2 - W arnings
-- 4 - I nformation
-- 8 - also R eplicate to blrlog
-- ex: 7 = E+W+I , 15 = E+W+I+R, 5 = E+I

local level_label = {[1]="E", [2]="W", [4] = "I"}
local level_label_blrlog = {[1]="ERR", [2]="WARN", [4] = "INFO"}

local function loadDataTable(file, numkey)
local filedata = readFile(file)
local dtable = {}
if numkey then
for k,v in string.gmatch(filedata, "([^%c]+)=([^%c]+)") do
    dtable[tonumber(k)] = v
end
else
for k,v in string.gmatch(filedata, "([^%c]+)=([^%c]+)") do
    dtable[k] = v
end
end
return dtable
end


-- tail this file with powershell for instant logs during main thread locking loops
-- EX: Get-Content C:\Users\r3eck\AppData\Local\BeamNG.drive\current\beamlr.log  -Wait -Tail 1
-- sidp = bool, skip id print, only used if id print is done by print
function blrlogwrite(txt, level, wid)
-- handle nil and table printing
local toprint = txt
if not toprint then toprint = "nil" end
if type(toprint) == "table" then toprint = dumps(toprint) end

-- append prefixes to entry
local prefix = "[" .. string.format("%.3f",os.clock()) .. "]"
if (vmType == "vehicle") then prefix = prefix .. " VLUA " .. obj:getId() .. " |" end
if type(txt) == "table" then
toprint = dumps(txt)
end
if level then
prefix = prefix .. " " .. level .. " |"
end
if wid then
prefix = prefix .. " LOG ID " .. blrlogid .. " |"
blrlogid = blrlogid+1
end

-- write to log file
local f = io.open("beamlr.log", "a")
f:write(prefix .. " " .. toprint .. "\n")
f:flush()
f:close()
end


function blrlog(t, level)
if not beamlr_debug then return end

local txt = t
if type(t) == "nil" then txt = "nil" end

local lvl = level or 4

-- check if log has to be printed to regular console/beamng log file
if beamlr_debug_bnglog then
	if bit.band(lvl, beamlr_loglevel) ~= 0 then
		if beamlr_debug_blrlog then 
			if type(txt) == "table" then log(level_label[lvl], "BeamLR", "[BeamLR Log ID " .. blrlogid .. "]\n" .. dumps(txt)); else log(level_label[lvl], "BeamLR", "[BeamLR Log ID " .. blrlogid .. "] " .. txt) end
		else	
			if type(txt) == "table" then log(level_label[lvl], "BeamLR", dumps(txt)) else log(level_label[lvl], "BeamLR", txt) end
		end
	end
end

-- check if log has to be printed to blrlog
if beamlr_debug_blrlog then
	if bit.band(lvl, beamlr_loglevel) ~= 0 then
		blrlogwrite(txt, level_label_blrlog[lvl], true)
	end
end

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


M.onExtensionLoaded = function()
beamlr_loglevel = tonumber(loadDataTable("beamLR/options")["loglevel"] or "15")
beamlr_debug = beamlr_loglevel > 0
beamlr_debug_bnglog = bit.band(beamlr_loglevel, 7) ~= 0
beamlr_debug_blrlog = bit.band(beamlr_loglevel, 8) ~= 0
end

M.blrdump = blrdump
M.blrprint = blrprint
M.rotateLogs = rotateLogs
M.blrlog = blrlog
M.onGameStartedBLR = onGameStartedBLR

return M