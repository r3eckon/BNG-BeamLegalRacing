local M = {}

local extensions = require("extensions")

local ftable = {}
local ptable = {}


local mechdevices = nil

local function buildMechDevicesTable()
local dtable = {}
dtable["engine"] = {}
dtable["powertrain"] = {}
dtable["wheels"] = {}

table.insert(dtable["engine"], "engineReducedTorque")
table.insert(dtable["engine"], "engineDisabled")
table.insert(dtable["engine"], "engineLockedUp")
table.insert(dtable["engine"], "engineIsHydrolocking")
table.insert(dtable["engine"], "engineHydrolocked")
table.insert(dtable["engine"], "overRevDanger")
table.insert(dtable["engine"], "catastrophicOverrevDamage")
table.insert(dtable["engine"], "mildOverrevDamage")
table.insert(dtable["engine"], "overTorqueDanger")
table.insert(dtable["engine"], "catastrophicOverTorqueDamage")
table.insert(dtable["engine"], "impactDamage")
table.insert(dtable["engine"], "oilpanLeak")
table.insert(dtable["engine"], "oilRadiatorLeak")
table.insert(dtable["engine"], "headGasketDamaged")
table.insert(dtable["engine"], "pistonRingsDamaged")
table.insert(dtable["engine"], "rodBearingsDamaged")
table.insert(dtable["engine"], "blockMelted")
table.insert(dtable["engine"], "oilHot")
table.insert(dtable["engine"], "cylinderWallsMelted")
table.insert(dtable["engine"], "radiatorLeak")
table.insert(dtable["engine"], "coolantHot")
table.insert(dtable["engine"], "oilLevelCritical")
table.insert(dtable["engine"], "oilStarvation")
table.insert(dtable["engine"], "oilLevelTooHigh")
table.insert(dtable["engine"], "exhaustBroken")

table.insert(dtable["powertrain"], "mainEngine")
table.insert(dtable["powertrain"], "torqueConverter")
table.insert(dtable["powertrain"], "gearbox")
table.insert(dtable["powertrain"], "rangebox")
table.insert(dtable["powertrain"], "transfercase")
table.insert(dtable["powertrain"], "torsionReactorR")
table.insert(dtable["powertrain"], "driveshaft")
table.insert(dtable["powertrain"], "differential_R")
table.insert(dtable["powertrain"], "transfercase_F")
table.insert(dtable["powertrain"], "driveshaft_F")
table.insert(dtable["powertrain"], "torsionReactorF")
table.insert(dtable["powertrain"], "differential_F")
table.insert(dtable["powertrain"], "halfshaftFR")
table.insert(dtable["powertrain"], "halfshaftFL")
table.insert(dtable["powertrain"], "wheelaxleFL")
table.insert(dtable["powertrain"], "wheelaxleFR")
table.insert(dtable["powertrain"], "wheelaxleRL")
table.insert(dtable["powertrain"], "wheelaxleRR")
table.insert(dtable["powertrain"], "spindleRR")
table.insert(dtable["powertrain"], "spindleRL")
table.insert(dtable["powertrain"], "clutch")


-- Standard 4 wheel vehicles
table.insert(dtable["wheels"], "FR")
table.insert(dtable["wheels"], "brakeFR")
table.insert(dtable["wheels"], "brakeOverHeatFR")
table.insert(dtable["wheels"], "tireFR")

table.insert(dtable["wheels"], "FL")
table.insert(dtable["wheels"], "brakeFL")
table.insert(dtable["wheels"], "brakeOverHeatFL")
table.insert(dtable["wheels"], "tireFL")

table.insert(dtable["wheels"], "RR")
table.insert(dtable["wheels"], "brakeRR")
table.insert(dtable["wheels"], "brakeOverHeatRR")
table.insert(dtable["wheels"], "tireRR")

table.insert(dtable["wheels"], "RL")
table.insert(dtable["wheels"], "brakeRL")
table.insert(dtable["wheels"], "brakeOverHeatRL")
table.insert(dtable["wheels"], "tireRL")

--Pigeon
table.insert(dtable["wheels"], "F")
table.insert(dtable["wheels"], "brakeF")
table.insert(dtable["wheels"], "brakeOverHeatF")
table.insert(dtable["wheels"], "tireF")

--Gambler covet
table.insert(dtable["wheels"], "R")
table.insert(dtable["wheels"], "brakeR")
table.insert(dtable["wheels"], "brakeOverHeatR")
table.insert(dtable["wheels"], "tireR")

--Gambler bolide
table.insert(dtable["wheels"], "RRR")
table.insert(dtable["wheels"], "brakeRRR")
table.insert(dtable["wheels"], "brakeOverHeatRRR")
table.insert(dtable["wheels"], "tireRRR")

table.insert(dtable["wheels"], "RRL")
table.insert(dtable["wheels"], "brakeRRL")
table.insert(dtable["wheels"], "brakeOverHeatRRL")
table.insert(dtable["wheels"], "tireRRL")

--T series
table.insert(dtable["wheels"], "DW1R")
table.insert(dtable["wheels"], "brakeDW1R")
table.insert(dtable["wheels"], "brakeOverHeatDW1R")
table.insert(dtable["wheels"], "tireDW1R")

table.insert(dtable["wheels"], "DW1L")
table.insert(dtable["wheels"], "brakeDW1L")
table.insert(dtable["wheels"], "brakeOverHeatDW1L")
table.insert(dtable["wheels"], "tireDW1L")

table.insert(dtable["wheels"], "DW1RR")
table.insert(dtable["wheels"], "brakeDW1RR")
table.insert(dtable["wheels"], "brakeOverHeatDW1RR")
table.insert(dtable["wheels"], "tireDW1RR")

table.insert(dtable["wheels"], "DW1LL")
table.insert(dtable["wheels"], "brakeDW1LL")
table.insert(dtable["wheels"], "brakeOverHeatDW1LL")
table.insert(dtable["wheels"], "tireDW1LL")

table.insert(dtable["wheels"], "DW2R")
table.insert(dtable["wheels"], "brakeDW2R")
table.insert(dtable["wheels"], "brakeOverHeatDW2R")
table.insert(dtable["wheels"], "tireDW2R")

table.insert(dtable["wheels"], "DW2L")
table.insert(dtable["wheels"], "brakeDW2L")
table.insert(dtable["wheels"], "brakeOverHeatDW2L")
table.insert(dtable["wheels"], "tireDW2L")

table.insert(dtable["wheels"], "DW2RR")
table.insert(dtable["wheels"], "brakeDW2RR")
table.insert(dtable["wheels"], "brakeOverHeatDW2RR")
table.insert(dtable["wheels"], "tireDW2RR")

table.insert(dtable["wheels"], "DW2LL")
table.insert(dtable["wheels"], "brakeDW2LL")
table.insert(dtable["wheels"], "brakeOverHeatDW2LL")
table.insert(dtable["wheels"], "tireDW2LL")

--Dually pickup
table.insert(dtable["wheels"], "RR2")
table.insert(dtable["wheels"], "brakeRR2")
table.insert(dtable["wheels"], "brakeOverHeatRR2")
table.insert(dtable["wheels"], "tireRR2")

table.insert(dtable["wheels"], "RL2")
table.insert(dtable["wheels"], "brakeRL2")
table.insert(dtable["wheels"], "brakeOverHeatRL2")
table.insert(dtable["wheels"], "tireRL2")

return dtable
end

ftable["saveMechDamage"] = function(p)
if not mechdevices then mechdevices = buildMechDevicesTable() end
local dtable = {}
local file = p

local ctrack = ""
local cval = 0

for k,v in pairs(mechdevices) do
dtable[k] = {}
for _,dev in pairs(v) do
if dev == "engineReducedTorque" or dev == "mildOverrevDamage" then
	if powertrain and powertrain.getDevice('mainEngine') then
		dtable[k][dev] = tostring(damageTracker.getDamage(k,dev) or false) .. "," .. tostring(powertrain.getDevice('mainEngine').outputTorqueState)
	else
		dtable[k][dev] = tostring(damageTracker.getDamage(k,dev) or false) .. ",1.0" -- fallback to 1.0 outputTorqueState if engine missing
	end
elseif dev == "catastrophicOverTorqueDamage" then
	if powertrain and powertrain.getDevice('mainEngine') then
		dtable[k][dev] = tostring(damageTracker.getDamage(k,dev) or false) .. "," .. tostring(powertrain.getDevice('mainEngine').overTorqueDamage)
	else
		dtable[k][dev] = tostring(damageTracker.getDamage(k,dev) or false) .. ",0.0" -- fallback to 0.0 overTorqueDamage if engine missing
	end
else
dtable[k][dev] = tostring(damageTracker.getDamage(k,dev) or false)
end
end
end

local filedata = ""
local fullcat = ""
local fulldev = ""
local s,e = 0,0

for cat,dmgdat in pairs(dtable) do  -- Gotta detect some subcategories here for easier reloading (wheelBrake, wheelTire, etc..)
for dev,dmgval in pairs(dmgdat) do -- Subcategories are stored in the DEV part

if string.match(dev, "tire") then 
s,e = string.find(dev, "tire")
fullcat = "tire"
fulldev = string.sub(dev, e+1, #dev) -- Resulting format : tire.FR
elseif string.match(dev, "brakeOverHeat") then -- REMEMBER: NEED TO MATCH MORE COMPLEX SUBCATEGORIES FIRST (if "brake" checked first this device get matched there)
s,e = string.find(dev, "brakeOverHeat")
fullcat = "brakeOverHeat"
fulldev = string.sub(dev, e+1, #dev) -- Resulting format : brakeOverHeat.FR
elseif string.match(dev, "brake") then 
s,e = string.find(dev, "brake")
fullcat = "brake"
fulldev = string.sub(dev, e+1, #dev) -- Resulting format : brake.FR
else -- No subcategory just apply cat as fullcat
fullcat = cat
fulldev = dev
end

filedata = filedata .. fullcat .. "." .. fulldev .. "=" .. tostring(dmgval) .. "\n"
end
end

writeFile(file,filedata)

end

ftable["savePartIntegrity"] = function(p)
for k,cid in pairs(p) do
extensions.blrVehicleUtils.queueIntegrityUpdate(cid, k)
end
extensions.blrVehicleUtils.executeIntegrityUpdate()
end

ftable["saveBeamstate"] = function(p)
beamstate.save(p)
end

ftable["loadBeamstate"] = function(p)
beamstate.load(p)
end


local function exec(f, p, id)
ftable[f](ptable[p])
obj:queueGameEngineLua("extensions.vluaBlockingCall.setBlocked(false,".. id ..")")
end


local function setParam(p, v)
ptable[p] = v
end

local function setParamTableValue(t, p, v)
if not ptable[t] then ptable[t] = {} end
ptable[t][p] = v
end

M.exec = exec
M.setParam = setParam
M.setParamTableValue = setParamTableValue


return M