local M = {}

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

local function loadDataFile(path, asKeys) -- For files not in table format, load each line as a table element
local filedata = readFile(path)
local toRet = {}
if not FS:fileExists(path) then return toRet end
if string.sub(filedata, #filedata, #filedata) == "\n" then -- Remove last newline if it exists to prevent empty last element
filedata = string.sub(filedata, 1, #filedata-1) 
end
filedata = filedata:gsub("\r", "") -- Clear \r character leaving only \n 
local filesplit = ssplit(filedata, "\n")
for k,v in pairs(filesplit) do
if asKeys then
toRet[v] = true
else
toRet[k] = v
end
end
return toRet
end

local function getOrderedMods(mods)
local ofilekeys = loadDataFile("mods/order.txt", true)
local ofilevals = loadDataFile("mods/order.txt", false)
local toRet = {}
for k,v in pairs(mods) do
if not ofilekeys[v] then
table.insert(toRet, v)
end
end
for k,v in ipairs(ofilevals) do
if FS:fileExists(v) or FS:directoryExists(v) then -- Check that order file entry is actually installed
table.insert(toRet, v)
end
end
return toRet
end

M.ssplit = ssplit
M.loadDataFile = loadDataFile
M.getOrderedMods = getOrderedMods

return M