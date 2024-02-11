local M = {}

local shfile = "beamLR/sharedflags"

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

local function updateDataTable(file, mergeData)
local dtable = loadDataTable(file)
for k,v in pairs(mergeData) do
dtable[k] = v
end
saveDataTable(file, dtable)
end

local function get(flag)
local data = loadDataTable(shfile)
if data[flag] then
return data[flag] == "true"
else
return false
end
end


local function set(flag, value)
local sval = "false"
local dtable = {}
if value then sval = "true" end
dtable[flag] = sval
updateDataTable(shfile, dtable)
end

M.get = get
M.set = set

return M