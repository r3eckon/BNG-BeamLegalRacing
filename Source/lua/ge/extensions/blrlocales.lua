local M = {}
local extensions = require("extensions")

local localeCache = {}

local function getCurrentLanguage()
return Lua:getSelectedLanguage()
end


local function loadLocales()
local addons = FS:findFiles("beamLR/locales", "*.json", -1)

localeCache = {}

local aname = "" -- 1.19.1 fix for multiple translation files
local original = {}
local addon = {}

local opath = ""

for _,file in pairs(addons) do
aname = string.gsub(file,"/beamLR/locales/", ""):gsub(".json", "")
addon = jsonReadFile(file)
opath = "/locales/" .. aname .. ".json"
original = jsonReadFile(opath)

for k,v in pairs(addon) do
if not localeCache[aname] then localeCache[aname] = {} end
localeCache[aname][k] = v -- 1.19.1 fix, store each language in its own cache table
original[k] = v
end

jsonWriteFile(opath, original, true)
end






reloadUI()
end


local function unloadLocales()
local files = FS:findFiles("/locales/", "*.json", 1)
for k,v in pairs(files) do
extensions.blrutils.deleteFile(v)
end
localeCache = {}

reloadUI()
end

local function translate(key, language)
if not localeCache[language or getCurrentLanguage()] then language = "en-US" end -- 1.19.1 default to english for non translated languages
return localeCache[language or getCurrentLanguage()][key] or key
end

-- ttype and tmap are used to build translation keys: beamlr.ttype.tmap.ABCDEFG
-- key is key in data table where translation string is fetched and replaced with key
-- depth is depth of subfolders to check
-- ignore is list of strings in files to ignore, any string will cause file to be ignored
-- req is list of string in files to require, any string will cause file to be included
-- testmode won't edit mission file
-- skmode used shared translation keys whenever possible
local function generateTranslations(folder, ttype, tmap, key, depth, ignore, req, skmode, autotkeymode, testmode)
local files = FS:findFiles(folder , "*", depth)
local cfiledata = {}
local ckeyorder = {}
local cdescription = ""
local cfilename = {}
local skmap = {}

local tdata = ""
local tdkey = ""
local skip = false
local foundreq = false

local tdprefix = "beamlr." .. ttype .. "." .. tmap .. "."




for _,file in pairs(files) do
skip = false
foundreq = false
if ignore then
for k,v in pairs(req) do
if string.find(file:upper(), v:upper()) then foundreq = true break end
end
for k,v in pairs(ignore) do
if string.find(file:upper(), v:upper()) then skip = true break end
end
end
if not skip then skip = not foundreq end

if skip then
print("Skipped file: " .. file)
else


cfiledata = extensions.blrutils.loadDataTable(file)
ckeyorder = extensions.blrutils.getDataTableKeys(file)
cdescription = cfiledata[key]

cfilename = extensions.blrutils.ssplit(file, "/")
cfilename = cfilename[#cfilename]



if skmode then
if not skmap[cdescription] then
tdkey = tdprefix .. cfilename

if autotkeymode then
tdkey = string.sub(string.gsub(file, "/" , "."), 2):lower()
end

skmap[cdescription] = tdkey
tdata = tdata .. ' "' .. tdkey .. '" : "' .. cdescription .. '",\n'
else
tdkey = skmap[cdescription]
print("Reusing existing translation key (" .. tdkey .. ") for string (" .. cdescription .. ") in file" .. file)
end
else
tdkey = tdprefix .. cfilename

if autotkeymode then
tdkey = string.sub(string.gsub(file, "/" , "."), 2):lower()
end

tdata = tdata .. ' "' .. tdkey .. '" : "' .. cdescription .. '",\n'
end



 

if not testmode then
cfiledata[key] = tdkey
extensions.blrutils.saveDataTable(file, cfiledata, ckeyorder)
end


end
end

writeFile("mtgen_output", tdata)

end


M.generateTranslations = generateTranslations


M.translate = translate
M.getCurrentLanguage = getCurrentLanguage
M.loadLocales = loadLocales
M.unloadLocales = unloadLocales

return M