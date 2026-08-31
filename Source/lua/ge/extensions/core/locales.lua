-- BEAMLR EDITED TO ALLOW FORCING en-US TRANSLATIONS
-- USED IN CASES WHERE STRING COMPARES ARE NEEDED ON
-- STRINGS THAT NOW USE TRANSLATION KEYS 
-- (EX: TRACK EVENT BRAND/MODEL CHECK)

local M = {}

local locales = {}
local fallbackLanguage = "en-US" -- Using this for forced translations, make sure it stays "en-US" 
local language = nil
local localePath = "/locales/translations/"
local logTag = "core_locales"

local translateCache = {}
local scrambleTranslationDebugEnabled = false
local scrambleTranslationDebugSuffix = "✓"

local function getRandomLetterLike(char)
  local byte = string.byte(char)
  if not byte then
    return char
  end

  if byte >= 65 and byte <= 90 then
    return string.char(math.random(65, 90))
  end

  if byte >= 97 and byte <= 122 then
    return string.char(math.random(97, 122))
  end

  return char
end

local function scrambleTranslationWordStarts(text)
  local segments = {}
  local function protectPattern(input, pattern)
    return input:gsub(pattern, function(segment)
      table.insert(segments, segment)
      return "\1" .. tostring(#segments) .. "\2"
    end)
  end

  local result = protectPattern(text, "({{.-}})")
  result = protectPattern(result, "(%b[])")

  result = result:gsub("(%a)([%w_]*)", function(firstLetter, rest)
    return getRandomLetterLike(firstLetter) .. rest
  end)

  result = result:gsub("\1(%d+)\2", function(index)
    return segments[tonumber(index)] or ""
  end)

  return result
end

-- Helper function to process nested translations
local function processNestedTranslations(text, forceFallback)
  if not text or type(text) ~= "string" then
    return text
  end

  local result = text
  local changed = true
  local iterations = 0
  local maxIterations = 10 -- Prevent infinite loops

  while changed and iterations < maxIterations do
    changed = false
    iterations = iterations + 1

    -- Pattern 1: {{ 'foo' | translate}} or {{::'foo' | translate}} - quoted string with pipe syntax
    local newResult = result:gsub("{{%s*::%s*'([^'|}]+)'%s*|%s*translate%s*}}", function(key)
      changed = true
      return M.translate(key, nil, nil, forceFallback)
    end)
    newResult = newResult:gsub("{{%s*'([^'|}]+)'%s*|%s*translate%s*}}", function(key)
      changed = true
      return M.translate(key, nil, nil, forceFallback)
    end)

    -- Pattern 2: {{ foo | translate}} - unquoted translation with pipe syntax
    newResult = newResult:gsub("{{%s*([^%s|}]+)%s*|%s*translate%s*}}", function(key)
      changed = true
      return M.translate(key, nil, nil, forceFallback)
    end)

    -- Pattern 3: {{foo}} - simple variable substitution (context translations)
    newResult = newResult:gsub("{{%s*([a-zA-Z0-9_.]+)%s*}}", function(key)
      changed = true
      return M.translate(key, nil, nil, forceFallback)
    end)

    result = newResult
  end

  return result
end

local function translateLanguage(key, fallback, forceFallback)
  if not key or type(key) ~= "string" then
    return key or "Missing Translation Key!"
  end
  if locales[language] and not forceFallback then -- BEAMLR EDIT
    for _, fileData in ipairs(locales[language]) do
      if fileData.data[key] then
        return fileData.data[key]
      end
    end
  end
  if locales[fallbackLanguage] then
    for _, fileData in ipairs(locales[fallbackLanguage]) do
      if fileData.data[key] then
        return fileData.data[key]
      end
    end
  end
  return fallback or key
end

local function translate(key, fallback, dontProcessNestedTrans, forceFallback)
  if not key or type(key) ~= "string" then
    return key or "Missing Translation Key!"
  end

  if translateCache[key] and not forceFallback then -- BEAMLR EDIT, don't use cache when forceFallback is true
    return translateCache[key]
  end

  local translated = translateLanguage(key, fallback, forceFallback) -- BEAMLR EDIT

  if not dontProcessNestedTrans then
    -- Process nested translations in the result
    translated = processNestedTranslations(translated, forceFallback)
  end

  if M.getScrambleTranslationDebugEnabled() and type(translated) == "string" and translated ~= "" then
    translated = scrambleTranslationWordStarts(translated) .. scrambleTranslationDebugSuffix
  end

  -- BEAMLR EDIT START
  if not forceFallback then -- don't cache forcedFallback translations so they don't show up when not needed
	translateCache[key] = translated
  end
  -- BEAMLR EDIT END

  return translated
end

local function contextTranslate(key, varsTable, forceFallback)
  return (translate(key, key, true, forceFallback):gsub("{{(.-)}}", function(varName)
    varName = varName:match("^%s*(.-)%s*$")
    varName = varName:gsub("%s*|%s*translate%s*$", "")
    varName = varName:gsub("%s*|%s*contextTranslate%s*$", "")
    varName = varName:match("^::%s*'(.-)'$") or varName:match("^'(.-)'$") or varName
    local val = varsTable[varName]
    if val == nil then return "" end
    if type(val) == 'table' and val.txt then
      if val.ctx and type(val.ctx) == 'table' then
        return contextTranslate(val.txt, val.ctx, forceFallback)
      end
      return translate(tostring(val.txt), nil, nil, forceFallback)
    end
    return translate(tostring(val), nil, nil, forceFallback)
  end))
end

local function translateWithOrWithoutContext(data, forceFallback)
  if type(data) == 'table' and data.txt then
    return
         data.ctx and contextTranslate(data.txt, data.ctx, forceFallback)
      or data.context and contextTranslate(data.txt, data.context, forceFallback)
      or translate(data.txt, nil, nil, forceFallback)
  elseif data then
    return translate(data, nil, nil, forceFallback)
  end
  return ""
end

local function translateWithPrefixFallback(name, prefix)
  if prefix then
    local translation = translate(prefix .. name, "", nil, forceFallback)
    if translation ~= "" then return translation end
  end
  return translate(name, nil, nil, forceFallback)
end

local function loadLocaleFile(filename)
  local localeData = jsonReadFile(filename)
  if type(localeData) == "table" then
    return {filename = filename, data = localeData}
  end
  return nil
end

local function loadLocaleFiles(id)
  local localeDir = localePath .. id .. "/"
  if not FS:directoryExists(localeDir) then
    log("E", logTag, "Locale folder not found: " .. localeDir)
    return {}
  end

  local localeFiles = FS:findFiles(localeDir, "*.json", -1, true, false) or {}
  if #localeFiles == 0 then
    log("E", logTag, "No locale files found in: " .. localeDir)
    return {}
  end

  local filesData = {}

  table.sort(localeFiles)
  for _, localeFile in ipairs(localeFiles) do
    local localeData = loadLocaleFile(localeFile)
    if type(localeData) == "table" then
      table.insert(filesData, localeData)
    else
      log("E", logTag, "Failed to load locale file: " .. localeFile)
    end
  end
  log("I", logTag, "Locale files loaded from: " .. localeDir)
  return filesData
end

local function loadLocale(id)
  if locales[id] then
    return locales[id]
  end
  local loadedLocale = loadLocaleFiles(id)
  locales[id] = loadedLocale
  return loadedLocale
end

local function getLocale(id)
  if not id or type(id) ~= "string" then
    return {}
  end
  local localeData = loadLocale(id)
  -- Merge localeData files from last to first (later files take precedence)
  local merged = {}
  for i = #localeData, 1, -1 do
    local dataTbl = localeData[i].data
    tableMerge(merged, dataTbl)
  end
  return merged
end

local function getAvailableLanguages()
  local localeFolders = FS:directoryList(localePath, false, true) or {}
  local result = {}

  for _, folderPath in ipairs(localeFolders) do
    local folderKey = tostring(folderPath):gsub("\\", "/"):match("([^/]+)/?$")
    if folderKey then
      table.insert(result, {key = folderKey, path = folderPath})
    end
  end

  table.sort(result, function(a, b)
    return a.key < b.key
  end)

  return result
end

local function clearTranslateCache()
  table.clear(translateCache)
end

local function isTranslationScrambleDebugEnabled()
  return scrambleTranslationDebugEnabled
end

local function setTranslationScrambleDebugEnabled(enabled)
  local newValue = enabled == true
  if scrambleTranslationDebugEnabled == newValue then
    return scrambleTranslationDebugEnabled
  end

  scrambleTranslationDebugEnabled = newValue
  clearTranslateCache()
  log("I","","Translation Scramble Debug Enabled: " .. tostring(newValue) .. ". This requires a lua reload for lua-based translations to take effect.")
  guihooks.trigger('onTranslationsReloaded')
  return scrambleTranslationDebugEnabled
end

local function onExtensionLoaded()
  scrambleTranslationDebugEnabled = parseArgs and parseArgs.args and parseArgs.args.translationScrambleDebug == true

  dump(parseArgs)
  loadLocale(fallbackLanguage)
  _tr = translate
end

local function onFilesChanged(files)
  local reloadedAny = false
  for _, v in pairs(files) do
    if string.startswith(v.filename, localePath) and string.endswith(v.filename, ".json") then
      local langId = v.filename:sub(#localePath + 1):match("^([^/]+)")
      if langId and locales[langId] then
        local existingFile = false
        local updatedFileData = loadLocaleFile(v.filename)

        for i, fileData in ipairs(locales[langId]) do
          if fileData.filename == v.filename then
            if updatedFileData then
              fileData.data = updatedFileData.data
            else
              table.remove(locales[langId], i)
            end
            existingFile = true
            reloadedAny = true
            break
          end
        end
        if not existingFile and updatedFileData then
          table.insert(locales[langId], updatedFileData)
          table.sort(locales[langId], function(a, b)
            return a.filename < b.filename
          end)
          reloadedAny = true
        end
      end
    end
  end
  if reloadedAny then
    clearTranslateCache()
    extensions.hook('onReloadLocales')
    guihooks.trigger('onTranslationsReloaded')
  end
end

local function onSettingsChanged()
  local newLanguage = Lua:getSelectedLanguage()
  loadLocale(newLanguage)
  if newLanguage ~= language then
    language = newLanguage
    clearTranslateCache()
    extensions.hook('onLanguageChanged')
  end
end

M.translate = translate
M.contextTranslate = contextTranslate
M.translateWithPrefixFallback = translateWithPrefixFallback
M.translateWithOrWithoutContext = translateWithOrWithoutContext
M.getLocale = getLocale
M.getAvailableLanguages = getAvailableLanguages
M.clearTranslateCache = clearTranslateCache
M.getScrambleTranslationDebugEnabled = isTranslationScrambleDebugEnabled
M.setScrambleTranslationDebugEnabled = setTranslationScrambleDebugEnabled

M.onExtensionLoaded = onExtensionLoaded
M.onSettingsChanged = onSettingsChanged
M.onFilesChanged = onFilesChanged

M.onSerialize = function()
  return {
    scrambleTranslationDebugEnabled = scrambleTranslationDebugEnabled
  }
end
M.onDeserialized = function(data)
  if data and data.scrambleTranslationDebugEnabled ~= nil then
    setTranslationScrambleDebugEnabled(data.scrambleTranslationDebugEnabled)
  end
end

return M