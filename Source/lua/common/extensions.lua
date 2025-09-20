-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- BEAMLR FIXED FOR getSerializationData FORCING EXTENSIONS TO RELOAD
-- WHICH RESETS VLUA SCRIPTS WHEN CALLING beamstate.save() BECAUSE IT
-- SAVES SERIALIZED VLUA DATA IN THE BEAMSTATE FILE

local M = {}
local MT = {} -- metatable
local logTag = 'extensions'
local useProfiledHooks = not shipping_build
local profileAllExtensionFunctions = false

--------------------------------------------------------------------------
---    Deprecating Extensions format and Information                   ---
--------------------------------------------------------------------------
--[[ {
    replacement = <string>
    obsolete = true | false
    executeOnLoad = true or false --This is here to support executing previous onLoad / init functions
    returnOnFail = true or false --Early out on failure
}]]--
local deprecatedExtensions = {
    onLoad = {replacement = 'onExtensionLoaded', executeOnModuleLoad=true, returnOnFail = true},
    init = {replacement = 'onExtensionLoaded', executeOnModuleLoad=true},
    onRaceWaypoint = {replacement = 'onRaceWaypointReached'},
    onScenarioRaceCountingDone = {replacement = 'onCountdownEnded', disablePatching=false},
    activated = {replacement = 'onPlayersChanged'}
}

local luaMods = {} -- local var that tracks the loaded modules state
local doNotSerializeModules = {} -- local var for the modules TO NOT serialize when reloading LUA VM (CTRL + L)

local luaExtensionFuncs = {}
local packagePathTemp = nil
local resolvedModules = {}
local resolvedNameToModule = {}
local resolvedNormalizedNameToModule = {}
local trackOnExtensionUnloaded = {}
local trackOnRefresh = {}
local loadedFreshModules = {}
local deserializedData = nil

local childExtensions = {} -- for force unloading virtual extensions

local _uniqueVirtualExtensionCounter = 0 -- always upcounting
local function getUniqueVirtualExtensionNumber()
  _uniqueVirtualExtensionCounter = _uniqueVirtualExtensionCounter + 1
  return _uniqueVirtualExtensionCounter
end

-- fwd decl of functions
local extensionLoadInternal

local function luaPathToExtName(filepath)
  -- log('I', logTag, 'luaPathToExtName called '..tostring(filepath))
  if not filepath then
    return
  end

  return (filepath:gsub('_', '__'):gsub('/', '_'))
end

local function extNameToLuaPath(extName)
  if not extName then
    return
  end

  local res = extName:gsub('__', '#'):gsub('_', '/'):gsub('#', '_')
  -- log('I', logTag, 'extNameToLuaPath >> ' .. tostring(extName) .. ' => ' .. tostring(res))
  return res
end

local function isAvailable(extPath)
  -- log('I', logTag, 'isAvailable called: '..tostring(extPath))
  if package.loaded[extPath] then
    return true
  end

  -- Note(AK): DO not mess with package tables e.g. package.preload
  for _, searcher in ipairs(package.searchers or package.loaders) do
    local state, loader = xpcall(function() return searcher(extPath) end, debug.traceback)
    if state == false then
      log('E', "", "Unable to load extension '"..tostring(extPath).."':\n"..loader)
    else
      if type(loader) == 'function' then
        return true
      end
    end
  end
  return false
end

local function hookUpdate(funcName)
  luaExtensionFuncs[funcName] = nil
end

local function resolveDependencies()
  -- log('I', logTag, 'resolveDependencies called..')
  local toResolveModules = {}
  local automaticModules = {}
  local autoModulesSize = 0
  for k, m in pairs(luaMods) do
    if m.__manuallyLoaded__ then
      table.insert(toResolveModules, k)
    else
      automaticModules[k] = true
      autoModulesSize = autoModulesSize + 1
    end
  end
  table.sort(toResolveModules)

  local toResolveModulesSize = #toResolveModules
  resolvedModules = table.new(toResolveModulesSize, 0)
  resolvedNameToModule = table.new(0, toResolveModulesSize)
  resolvedNormalizedNameToModule = table.new(0, toResolveModulesSize)

  repeat
    -- log('I', logTag, 'resolving dependencies loop: '..tostring(toResolveModulesSize))
    local preToResolveModulesSize = toResolveModulesSize
    local preAutoModulesSize = autoModulesSize
    local i = 1
    while i <= toResolveModulesSize do
      local mname = toResolveModules[i]
      local m = luaMods[mname]
      local resolve = true
      if m.dependencies then
        for _, dname in ipairs(m.dependencies) do
          if not resolvedNameToModule[dname] then
            resolve = false
            if automaticModules[dname] then
              automaticModules[dname] = nil
              autoModulesSize = autoModulesSize - 1
              table.insert(toResolveModules, dname)
              toResolveModulesSize = toResolveModulesSize + 1
            end
          end
        end
      end

      if resolve then
        table.insert(resolvedModules, m)
        resolvedNameToModule[mname] = m
        resolvedNormalizedNameToModule[string.lower(mname)] = m
        resolvedNormalizedNameToModule.extensions = nil
        toResolveModules[i], toResolveModules[toResolveModulesSize] = toResolveModules[toResolveModulesSize], toResolveModules[i]
        table.remove(toResolveModules, toResolveModulesSize)
        toResolveModulesSize = toResolveModulesSize - 1
      else
        i = i + 1
      end
    end
  until toResolveModulesSize == preToResolveModulesSize and autoModulesSize == preAutoModulesSize

  if not tableIsEmpty(toResolveModules) then
    -- Note(AK) 27/10/2020: This is IMPORTANT. For these remaining modules, they could not be resolved because
    -- a. there is a cyclic dependency between a few
    -- b. the module they depend on was not found to be loaded.
    -- For these cases, we want to use the loaded modules table i.e. luaMods and not the resolvedNameToModule
    -- or any other table used in resolving dependencies.
    local failedModules = {}
    local toPrint = {}
    for _, mname in ipairs(toResolveModules) do
      local m = luaMods[mname]
      local resolved = true
      if m.dependencies then
        for _, dname in ipairs(m.dependencies) do
          if not luaMods[dname] then
            resolved = false
            if not failedModules[mname] then failedModules[mname] = {} end
            table.insert(failedModules[mname], dname)
          end
        end
      end

      if resolved then
        table.insert(resolvedModules, m)
        resolvedNameToModule[mname] = m
        resolvedNormalizedNameToModule[string.lower(mname)] = m
        resolvedNormalizedNameToModule.extensions = nil
        table.insert(toPrint, mname)
      end
    end

    if not tableIsEmpty(toPrint) then
      log('D', logTag, 'Force resolved cycle dependencies for: '..dumps(toPrint))
    end

    if not tableIsEmpty(failedModules) then
      log('W', logTag, 'Unloading the following modules. Their dependencies could not be resolved:')
      for k, v in pairs(failedModules) do
        log('W', logTag, '    ' .. tostring(k) .. ' dependencies not resolved: '..dumps(v))
      end
    end
  end
end

local function unloadInternal(extNames, forceUnloadVirtual)
  -- nop the function cache so that existing hook iterations do not get invalidated as they are used
  for fName, fList in pairs(luaExtensionFuncs) do
    for i, _ in ipairs(fList) do
      if useProfiledHooks then
        fList[i].func = nop
      else
        fList[i] = nop
      end
    end
  end
  table.clear(luaExtensionFuncs)  -- clear the hook function cache

  if type(extNames) ~= 'table' then
    extNames = {extNames}
  end

  -- Note(AK) 27/10/2020 IMPORTANT - call hooks all at once to prevent reloading modules that were previous unloaded
  for _, extName in ipairs(extNames) do
    local m = rawget(M, extName)

    -- do not unload virtual modules
    if not forceUnloadVirtual and m and m.__virtual__ then goto continue end

    --print("Unloading "..vmType.." extension: "..dumps(extName, extPath).."\n"..debug.tracesimple())
    --print("Unloading "..vmType.." extension: "..dumps(extName, extPath))

    -- kill any virtual childs
    local knownChildExtensions = childExtensions[m]
    if knownChildExtensions then
      for _, e in ipairs(knownChildExtensions) do
        if e ~= m then
          unloadInternal(e.extName, true)
        end
      end
      childExtensions[m] = {}
    end

    if m == nil then
      --log('I', logTag, 'unable to unload module ' .. tostring(extName) .. ': not loaded')
      goto continue
    end

    if trackOnExtensionUnloaded[m] == nil then
      trackOnExtensionUnloaded[m] = true

      if type(m.onExtensionUnloaded) == 'function' then
        m.onExtensionUnloaded()
      elseif type(m.onUnload) == 'function' then
        log('W', logTag, "Lua extension '".. extName.."' uses deprecated 'onUnload()' method, please use 'onExtensionUnloaded()' instead")
        m.onUnload()
      end

      trackOnExtensionUnloaded[m] = nil
    end

    ::continue::
  end

  -- Note(AK) 27/10/2020 IMPORTANT - unload everything together to prevent ping pong loading of unloaded modules again
  for _, extName in ipairs(extNames) do
    local m = rawget(M, extName)
    -- rawset avoids global setter wrapper detections
    rawset(_G, extName, nil)

    -- unload it finally
    if m and not m.__virtual__ then
      -- clear lua file cache
      local path = m.__extensionPath__
      if not package.loaded[path] then
        -- because of loadAtRoot()
        if not m.__originalExtPath__ and not package.loaded[m.__originalExtPath__] then
          log('E', logTag, 'unloading '..tostring(extName)..' failed. Trying to clear package with invalid path: ' .. tostring(path))
        else
          path = m.__originalExtPath__
        end
      end
      package.loaded[path] = nil
      -- Note(AK) 13/08/2020 : if unloading a module ever stops working correctly, check if package.preload[path] needs to be cleared
      -- package.preload[path] = nil
    end
    luaMods[extName] = nil
    M[extName] = nil
  end
end

local function isExtensionLoaded(extName)
  return extName and _G[extName] ~= nil
end

local function unload(extName)
  if not isExtensionLoaded(extName) then
    return
  end

  if type(extName) == "table" and type(extName.__extensionName__) == "string" then
    extName = extName.__extensionName__
  end
  local oldResolvedModules = shallowcopy(resolvedModules)
  -- Note(AK) 27/10/2020: Setting luaMods[extName] = nil is IMPORTANT. This allows resolveDependencies to generate a new set of resolved tables
  --                      that do not include all the other modules that also need unloading due to the module extName being unloaded
  local extMod = luaMods[extName]
  luaMods[extName] = nil
  resolveDependencies()
  luaMods[extName] = extMod

  -- Now delete modules that are no longer needed due to unloading module extName
  local extrasToUnloadModuleName = {}

  for i = #oldResolvedModules, 1, -1 do
    if oldResolvedModules[i] then
      local moduleName = oldResolvedModules[i].__extensionName__
      if not resolvedNameToModule[moduleName] then
        table.insert(extrasToUnloadModuleName, moduleName)
      end
    end
  end

  -- --TODO(AK) 15/09/2021: Improving the blind addition of the extName added to get 0.23 out of the door. We should not need to add a manual entry for extName
  -- --                     As comparing the oldResolvedModules to the new resolvedModules should make extName fail and get added as
  -- --                     well to the list of things that are to be unloaded.
  local found = false
  for _,name in ipairs(extrasToUnloadModuleName) do
    if name == extName then
      found = true
      break
    end
  end
  if not found then
    log("W", logTag, "Had to manually add the extension name to the list to unload. Auto resolution design did not work - "..tostring(extName))
    table.insert(extrasToUnloadModuleName, extName)
  end
  -- -------
  -- ------
  unloadInternal(extrasToUnloadModuleName)
  resolveDependencies()
end

M.unloadModule = function(extName)
                   log("W", logTag, "unloadModule(extName) is deprecated. Please switch to unload(extName)")
                   unload(extName)
                 end

local function unloadExcept(...)
  -- log('I', logTag, "unloadExcept called...")
  local exceptionList = {}

  if #{...} > 1 then
    for k,array in pairs({...}) do
      for i, v in pairs(array) do
        table.insert(exceptionList, v)
      end
    end
  else
    exceptionList = ... or {}
  end

  -- IMPORTANT: Expand the exception list to include their dependencies.
  local expandedExceptionDict = {}

  for _,mName in ipairs(exceptionList) do
    expandedExceptionDict[mName] = true
  end

  local numToExclude = #exceptionList
  local prevNumExcluded = 1
  while true do
    for i = prevNumExcluded, numToExclude do
      local mName = exceptionList[i]
      local m = luaMods[mName] or resolvedNameToModule[mName] or resolvedNormalizedNameToModule[mName]
      if m and m.dependencies then
        for _, depName in ipairs(m.dependencies) do
          if not expandedExceptionDict[depName] then
            table.insert(exceptionList, depName)
            expandedExceptionDict[depName] = true
          end
        end
      end
    end
    if numToExclude == #exceptionList then break end
    prevNumExcluded = numToExclude + 1
    numToExclude = #exceptionList
  end

  -- Now process the EXPANDED exception list to get the list of modules that need to be unloaded.
  local modulesToUnload = {}
  for i = #resolvedModules, 1, -1 do
    -- check if its null because a previous unload may have also unloaded child extensions e.g. scenario unloads
    -- its extensions so the entry for those extensions here would be null
    if resolvedModules[i] then
      local moduleName = resolvedModules[i].__extensionName__
      if not expandedExceptionDict[moduleName] then
        table.insert(modulesToUnload, moduleName)
      end
    end
  end

  if not tableIsEmpty(modulesToUnload) then
    unloadInternal(modulesToUnload)
  end

  resolveDependencies()
end

local function refreshInternal(m, extName, extPath, loadedFresh, extRequested)
  extRequested = extRequested or {}
  m.__extensionName__ = extName
  m.__extensionPath__ = extPath

  if trackOnRefresh[m] then return m end

  trackOnRefresh[m] = true

  if m.onPreLoad then
    m.onPreLoad()
  end

  if m.dependencies then
    for _, depName in ipairs(m.dependencies) do
      -- log('I', logTag, 'Loading dependency for '..extName..': '..depName)
      if not extRequested[depName] then
        extRequested[depName] = true
        local dependencyLoaded = extensionLoadInternal(depName, nil, extRequested)
        if not dependencyLoaded and not luaMods[depName] then
          log('W', logTag, 'Failed to load dependency: '..depName)
        end
      end
    end
  end

  if type(m) ~= "table" and type(m) ~= "function" then
    log('I', logTag, "Lua extension invalid: " .. extPath .. '. Does it return M? It returned this: ' .. tostring(m))
    trackOnRefresh[m] = nil
    return nil
  end

  if type(m) == "table" then
    -- check for deprecated functions being used in this module
    if deprecatedExtensions then
      for name,data in pairs(deprecatedExtensions) do
        if type(m[name]) == 'function' then
          log('W', logTag, "Lua extension '".. extPath.."' uses deprecated '" ..name.."()' function, please use '"..data.replacement.."()' instead")
          if not data.disablePatching and not m[data.replacement] then
            log('W', logTag, "Patching function " ..name.."() to "..data.replacement.."()")
            m[data.replacement] = m[name]
            m[name] = nil
          end
          if data.executeOnModuleLoad then
            local res = m[data.replacement]()
            if res == false and data.returnOnFail then
              log('W', logTag, "Earlying out of loading module "..extPath)
              trackOnRefresh[m] = nil
              return nil
            end
          end
        end
      end
    end

    -- allow the module to refuse loading
    if loadedFresh and (type(m.onExtensionLoaded)=='function' or type(m.onInit)=='function') then
      table.insert(loadedFreshModules, m.__extensionName__)
    end
  end

  -- ok, register now
  luaMods[extName] = m
  M[extName] = m

  -- also add to global scope:
  rawset(_G, extName, m) -- rawset avoids global setter wrapper detections

  trackOnRefresh[m] = nil
  return m
end

local function wrapFunctionWithProfiler(func, name)
  return function(...)
    profilerPushEvent(name)
    local results = {func(...)}
    profilerPopEvent(name)
    return unpack(results)
  end
end

local function wrapAllExtensionsForProfiler()
  for j, m in ipairs(resolvedModules) do
    for name, value in pairs(m) do
      if type(value) == "function" and name ~= "wrapAllExtensions" then
        m[name] = wrapFunctionWithProfiler(value, m.__extensionName__ .. "." .. name)
      end
    end
  end
end

-- do some safety checks on loaded extensions
local function extSafetyCheck(m, extName, extPath)
  for k, v in pairs(m) do
    if type(v) == 'function' then
      local d = debug.getinfo(v)
      local s = d.source
      if s:sub(1,1) == '@' then s = s:sub(2) end
      if not s:find(extPath) and s ~= 'lua/ge/extensions/core/jobsystem.lua' and s ~= 'lua/common/luaCore.lua' and s ~= '=[C]' then
        log('E', 'extensions', dumps{'function ', k, ' using external reference?', extName, extPath, v, d})
      end
    end
  end
end

extensionLoadInternal = function(extName, extPath, extRequested)
  if not extPath then
    extPath = extNameToLuaPath(extName)
  end
  -- log('I', logTag, 'extensionLoadInternal: '.. tostring(extName).. ' from '..tostring(extPath))
  local m = luaMods[extName] or resolvedNormalizedNameToModule[string.lower(extName)]
  if m ~= nil then
    --log('D', logTag, 'extension already loaded: '..tostring(extName))
    return m
  end

  if not isAvailable(extPath) then
    log('E', logTag, 'extension unavailable: ' .. dumps(extName)..' at location: '..dumps(extPath))
    return
  end

  --print("Loading "..vmType.." extension: "..dumps(extName, extPath).."\n"..debug.tracesimple())
  --print("Loading "..vmType.." extension: "..dumps(extName, extPath))
  --dump{vmType, "LOADING EXT: ", extPath}
  m = require(extPath)
  if type(m) ~= 'table' then
    log('E', 'logtag', 'Module does not return the module exports M. is "return M" missing at the end of the file? Extension unavailable: ' .. dumps(extName)..' at location: '..dumps(extPath))
    return
  end

  if profileAllExtensionFunctions then
    for memberName, member in pairs(m) do
      if type(member) == "function" then
        m[memberName] = wrapFunctionWithProfiler(member, extName .. "." .. memberName)
      end
    end
  end

  if not shipping_build then
    -- commented out for now because it triggers an error in some intended cases
    -- extSafetyCheck(m, extName, extPath)
  end

  extRequested = extRequested or {}
  extRequested[extName] = true
  return refreshInternal(m, extName, extPath, true, extRequested)
end

local function loadInternal(manualLoad, ...)
  local moduleDataArray = {}
  for _,entry in ipairs({...}) do
    if type(entry) == 'string' then
      table.insert(moduleDataArray, entry)
    else
      for _, v in ipairs(entry) do
        if type(v) == 'string' then
          table.insert(moduleDataArray, v)
        else
          log('W', logTag, "Loading extension enty is not valid. It should be a string. entry = " .. dumps(v))
        end
      end
    end
  end

  if tableIsEmpty(moduleDataArray) then return end

  local extPath
  for _, extName in ipairs(moduleDataArray) do
    if string.find(extName, "/") then -- loading from directory path
      extPath = extName
      if string.sub(extPath, 1, 1) == '/' then -- strip leading '/' if present
        extPath = string.gsub(extPath, "/(.*)", "%1")
      end
      extName = luaPathToExtName(extPath)
    else
       -- loading using namespace format e.g. ext_etc
      extPath = extNameToLuaPath(extName)
    end

    local m = extensionLoadInternal(extName, extPath)
    if m and manualLoad then
      m.__manuallyLoaded__ = manualLoad
    end
  end
  resolveDependencies()
  table.clear(luaExtensionFuncs)  -- clear the hook function cache
end

local function processLoadedFreshList()
  local modulesToUnload = {}
  local modulesToInit = {}
  deserializedData = deserializedData or {}
  for i, moduleName in ipairs(loadedFreshModules) do
    -- Because modules can load other modules from within onExtensionLoaded, we do the nil clear to prevent reentrant issues
    if moduleName then
      loadedFreshModules[i] = false
      local m = rawget(_G, moduleName)
      if m then
        local res = true
        if m.onExtensionLoaded then
          -- log('I','','  '..m.__extensionName__..'.onExtensionLoaded('..dumps(deserializedData[m.__extensionName__])..')')
          res = m.onExtensionLoaded(deserializedData[m.__extensionName__])
          if res == false then
            table.insert(modulesToUnload, m.__extensionName__)
          end
        end
        if res ~= false then
          table.insert(modulesToInit, m.__extensionName__)
        end
      end
    end
  end

  table.clear(loadedFreshModules)

  unloadInternal(modulesToUnload)

  -- CRITICAL: Call resolveDependencies immediately after unloadInternal to prevent
  -- race condition where failed modules remain in resolvedModules and can still
  -- have their hooks called before the cleanup happens
  resolveDependencies()

  if vmType == 'game' then
    for i, moduleName in ipairs(modulesToInit) do
      if moduleName then
        modulesToInit[i] = false
        local m = rawget(_G, moduleName)
        if m and type(m.onInit) == 'function' then
          -- log('I','','  '..m.__extensionName__..'.onInit('..dumps(deserializedData[m.__extensionName__])..')')
          m.onInit(deserializedData[m.__extensionName__])
        end
      end
    end
  end
end

local function loadExt(...)
  loadInternal(true, ...)
  processLoadedFreshList()
end

local function loadAutoClean(...)
  loadInternal(false, ...)
  processLoadedFreshList()
end

local function loadAtRoot(extPath, rootName)
  -- log("I", logTag, "loadAtRoot called...")

  if not rootName then
    log("E", logTag, "loadAtRoot failed: root name not specified")
    return
  end

  if string.find(rootName, "_") then
    log("E", logTag, "loadAtRoot failed: root name cannot contain underscores")
    return
  end

  if not string.find(extPath, "/") then
    log("E", logTag, "loadAtRoot failed: extension path is not a valid file path")
    return
  end

  if string.sub(extPath, 1, 1) == '/' then
    extPath = string.gsub(extPath, "/(.*)", "%1") -- strip leading '/' if present
  end

  local extName
  if string.len(rootName) > 0 then
    extName = rootName..'_'..string.gsub(extPath, "(.*/)(.*)", "%2")
  else
    extName = string.gsub(extPath, "(.*/)(.*)", "%2")
  end

  local m = extensionLoadInternal(extName, extPath)

  if m then
    m.__manuallyLoaded__ = true
    m.__originalExtPath__ = extPath
  end

  resolveDependencies()
  table.clear(luaExtensionFuncs)  -- clear the hook function cache
  processLoadedFreshList()

  return extName, m
end

local function addModulePath(directory)
  --local savedPath = package.path
  local newPath = directory .. "/?.lua;"
  newPath = newPath:gsub('//', '/') -- prevent having double slashes in the lookup path
  package.path = newPath .. package.path
end

local function loadModulesInDirectory(directory, excludeSubdirectories)
  -- log('I', logTag, "loadModulesInDirectory called...")
  --[[ -- Game engine version not working on libbeamng side

  local luaFiles = FS:findFiles(directory, '*.lua', -1, true, false)
  for _,luaFilename in pairs(luaFiles) do
    load(luaFilename:sub(1,-5))  -- strip '.lua'
  end
  ]]

  --local savedPath = package.path
  --package.path = directory .. "/?.lua;".. package.path
  -- addModulePath(directory)
  local filePaths = FS:findFiles(directory, "*.lua", -1, true, false)

  if type(excludeSubdirectories) == 'table' then
    local processed = {}
    for _, file in ipairs(filePaths) do
      local skip = false
      for _,subDir in pairs(excludeSubdirectories) do
        if string.find(file, subDir) then
          skip = true
          break
        end
      end
      if not skip then
        table.insert(processed, file)
      end
    end
    filePaths = processed
  end

  for _, file in ipairs(filePaths) do
    -- find the lua module files now
    if not file then break end
    if FS:fileExists(file) then
      -- loading at a root "" which signifies "global space", maintains backwards compatibility with the old
      -- behaviour of just loading using the filename from the path. This is NECESSARY to not break mods
      -- without it, vehicle extensions like custom_input would come out as custom/input which is wrong
      loadAtRoot(file:sub(1,-5), "")
    end
  end
  --package.path = savedPath
  resolveDependencies()
  table.clear(luaExtensionFuncs)  -- clear the hook function cache
  processLoadedFreshList()
end

local completedCallbacks = {}
local function setCompletedCallback(funcName, callback)
  if callback then
    if not completedCallbacks[funcName] then
      completedCallbacks[funcName] = {}
    end
    table.insert(completedCallbacks[funcName], callback)
  end
end

local profiler
local function hookSingleFrameProfiled(funcName, ... )
  for _, m in ipairs(resolvedModules) do
    if type(m) == "table" then
      local func = m[funcName]
      if func ~= nop and type(func) == 'function' then
        local extCallName = "extensions."..m.__extensionName__..'.'..funcName
        profiler:start()
        func(...)
        profiler:add(extCallName)
      end
    end
  end
end

local function hookProfiled(funcName, ...)
  -- This is performance sensitive, please disable transient debug code
  -- dump("Extension Hook: " .. funcName .. " : " .. dumps(... or {}))
  local funcList = luaExtensionFuncs[funcName]
  if funcList == nil then
    -- rebuild the cache for the function from all loaded modules
    local hookFuncs = {}
    luaExtensionFuncs[funcName] = hookFuncs
    for _, m in ipairs(resolvedModules) do
      local func = m[funcName]
      if func ~= nop and type(func) == 'function' then
        local funcInfo = {func = func, extCallName = m.__extensionName__..'.'..funcName}
        table.insert(hookFuncs, funcInfo)
        if not profileAllExtensionFunctions then profilerPushEvent(funcInfo.extCallName) end
        func(...)
        if not profileAllExtensionFunctions then profilerPopEvent(funcInfo.extCallName) end
      end
    end
  else
    for _, funcInfo in ipairs(funcList) do
      if not profileAllExtensionFunctions then profilerPushEvent(funcInfo.extCallName) end
      funcInfo.func(...)
      if not profileAllExtensionFunctions then profilerPopEvent(funcInfo.extCallName) end
    end
  end
end

local function hookDebug(funcName, ... )
  for _, m in ipairs(resolvedModules) do
    if type(m) == "table" then
      local func = m[funcName]
      if func ~= nop and type(func) == 'function' then
        local extCallName = "extensions."..m.__extensionName__..'.'..funcName
        print("->"..extCallName)
        func(...)
      end
    end
  end
end

local function hookFast(funcName, ...)
  -- This is performance sensitive, please disable transient debug code
  -- dump("Extension Hook: " .. funcName .. " : " .. dumps(... or {}))
  local funcList = luaExtensionFuncs[funcName]
  if funcList == nil then
    -- rebuild the cache for the function from all loaded modules
    local hookFuncs = {}
    luaExtensionFuncs[funcName] = hookFuncs
    for _, m in ipairs(resolvedModules) do
      local func = m[funcName]
      if func ~= nop and type(func) == 'function' then
        table.insert(hookFuncs, func)
        func(...)
      end
    end
  else
    for _, func in ipairs(funcList) do
      func(...)
    end
  end
end

local function setProfiler(p)
  profiler = p
  if p then
    M.hook = hookSingleFrameProfiled
  else
    M.hook = useProfiledHooks and hookProfiled or hookFast
  end
end

local function printExtensions()
  log("I", "", "Full list of loaded extensions:")
  for j, m in ipairs(resolvedModules) do
    log("I", "", " - ".. m.__extensionName__ .. " : " .. dumps(m.dependencies))
  end
end

local function printHooks(funcName)
  local hasHook = false
  for _, m in ipairs(resolvedModules) do
    if type(m) == "table" then
      local func = m[funcName]
      if func ~= nop and type(func) == 'function' then
        print(m.__extensionName__..'.'..funcName)
        hasHook = true
      end
    end
  end

  if hasHook then
    print('-')
  end
end

local function hookExcept(exceptionList, func, ...)
  local exceptionDict = {}
  for _,value in ipairs(exceptionList) do
    exceptionDict[value] = true
  end

  for _, m in ipairs(resolvedModules) do
    if not exceptionDict[m.__extensionsModulePath__] then
      if m[func] and type(m[func]) == 'function' then
        m[func](...)
      end
    end
  end
end

local function hookNotify(func, ...)
  -- log("I", logTag, "hookNotify called..."..func)
  M.hook(func, ...)

  local completedList = completedCallbacks[func]
  if completedList then
    -- dump(completedList)
    for i = 1, #completedList do
      completedList[i](...)
    end
    completedCallbacks[func] = nil
  end
end

local function saveModulePath()
  packagePathTemp = package.path
end

local function restoreModulePath()
  package.path = packagePathTemp
end

-- reload from disk, enforce cache clear
local function reload(extPath)
  unload(extPath)
  loadExt(extPath)
end

-- reload live data, no disk reload
local function refresh(extName)
  local extPath = extNameToLuaPath(extName)

  if luaMods[extName] == nil then
    log('E', logTag, 'Unable to refresh extension. Not loaded: '..tostring(extName))
    return false
  end
  local m = refreshInternal(luaMods[extName], extName, extPath, false)
  resolveDependencies()
  table.clear(luaExtensionFuncs)  -- clear the hook function cache
  processLoadedFreshList()
  return m
end

M.reloadModule =  function(modulePath)
                     log("W", logTag, "reloadModule(modulePath) is deprecated. Please switch to reload(modulePath)")
                     reload( modulePath )
                   end

local function disableSerialization(...)

  -- Try to make this table only hold unique entries, no duplicates
  for _,entry in ipairs({...}) do
    if type(entry) == 'string' then
      table.insert(doNotSerializeModules, entry)
    else
      for _, v in ipairs(entry) do
        if type(v) == 'string' then
          table.insert(doNotSerializeModules, v)
        else
          log('W', logTag, "Disabling extension from serialization entry is not valid. It should be a string. entry = " .. dumps(v))
        end
      end
    end
  end
end

local function getSerializationData(reason)
  if reason == nil then reason = 'reload' end
  local tmp = {}
  tmp['extensions'] = {}

  -- filter out virtual extensions
  local loadedModules = {}
  for k, m in pairs(luaMods) do
    local ignoreExtension = tableContains(doNotSerializeModules, m.__extensionName__)
    if not ignoreExtension then
      if not m.__virtual__ then
        loadedModules[k] = m.__extensionPath__
      end
    end
  end
  tmp['extensions'].loadedModules = loadedModules

  -- We need to make a copy of the resolvedModules table as modules calls extensions.unloadExcept will alter it as part of the execution flow.
  -- This fixes the bug where some modules do not get onDeserialize called because they have been dropped from these tables
  local tempResolvedModules = shallowcopy(resolvedModules)

  for _, v in ipairs(tempResolvedModules) do
    local ignoreExtension = tableContains(doNotSerializeModules, v.__extensionName__)
    if ignoreExtension then
      goto continue
    end
    local k = v.__extensionName__
    if type(v) == 'table' and v.__virtual__ ~= true and (v['onDeserialized'] ~= nil or v['onDeserialize'] ~= nil or v['onSerialize'] ~= nil) then
      if type(v['onSerialize']) == 'function' then
        -- if serialization function is existing, use that
        tmp[k] = v['onSerialize'](reason)
      elseif v['state']  then
        -- if M.state is existing, use only that
        tmp[k] = v.state
      else
        -- fallback: whole M
        tmp[k] = v
      end
    end
    ::continue::
  end

  -- unload all extension modules
  -- BEAMLR FIXED
  if reason == 'reload' then
	unloadExcept()
  end

  return tmp
end

local function deserialize(data, filter)
  if data == nil then return end
  deserializedData = data
  local extensionsData = data['extensions']
  if extensionsData and extensionsData.loadedModules then
    local extbatch = {}
    for extName,extPath in pairs(extensionsData.loadedModules) do
      local tempExtName = luaPathToExtName(extPath)
      if extName == tempExtName then
        table.insert(extbatch, extName)
      else
        -- determine is root is the global root or a specfied root
        local root
        local extFilename = string.gsub(extPath, "(.*/)(.*)", "%2")
        if extFilename == extName then
          -- global root was used. for example in loadModulesInDirectory to load the extension
          root = ""
        else
          -- grab specified root
          root = string.sub(extName, 1, string.find(extName, "_") - 1)
        end
        loadAtRoot(extPath, root)
      end
    end
    loadExt(extbatch)
  end

  -- We need to make a copy of these 2 tables as modules processing onDeserialize can alter them when they call extensions.load as
  -- part of their execution flow. This fixes the bug where some modules do not get onDeserialize called because they have been
  -- dropped from these tables
  local tempResolvedModules = shallowcopy(resolvedModules)

  for _, v in ipairs(tempResolvedModules) do
    local k = v.__extensionName__
    --print("k="..tostring(k) .. " = " .. tostring(v))
    if (filter == nil or k == filter) and type(v) == 'table' and (v['onDeserialized'] ~= nil or v['onDeserialize'] ~= nil) and data[k] ~= nil then
      if type(v['onDeserialize']) == 'function' then
        -- having a deserilization function? then use that!
        v['onDeserialize'](data[k])
      elseif v['state'] then
        -- only merge M.state
        tableMerge(v['state'], data[k])
      else
        -- merge whole M
        tableMerge(v, data[k])
      end
      if type(v['onDeserialized']) == 'function' then
        v['onDeserialized'](data[k])
      end
    end
    data[k] = nil
  end
  deserializedData = nil
end


-- this system is used to forward extension events into OOP/class instances
--== ExtensionProxy ==--
-- for usage, see extension util_testExtensionProxies
local ExtensionProxy = {}
ExtensionProxy.__index = ExtensionProxy

-- creation method of the object, inits the member variables
function newExtensionProxy(parentExtension, identifierPrefix)
  if parentExtension then
    if not parentExtension.__extensionName__ then
      log('E', '', 'Parent extension is not a valid extension: ' .. dumps(parentExtension))
      return
    end
    if identifierPrefix == nil then identifierPrefix = parentExtension.__extensionName__ end
  end
  if identifierPrefix == nil then identifierPrefix = '' end
  local extName = identifierPrefix .. '_virtual_' .. tostring(getUniqueVirtualExtensionNumber())
  local data = {
    extName = extName,
    extPath = extNameToLuaPath(extName),
    __virtual__ = true,
    __manuallyLoaded__ = true,
  }
  -- inform the extensions of this new virtual child
  if parentExtension then
    if not childExtensions[parentExtension] then childExtensions[parentExtension] = {} end
    table.insert(childExtensions[parentExtension], data)
  end
  setmetatable(data, ExtensionProxy)
  return data
end

function ExtensionProxy:submitEventSinks(hookableTablesInstances, dependencies)
  if not hookableTablesInstances then
    return
  end

  -- we need to walk the normal functions and the metatable ones
  local function walkTable(hookLists, m, obj)
    if not m then return end
    for k, func in pairs(m) do
      if string.sub(k, 1, 2) == 'on' and type(func) == 'function' then
        if not hookLists[k] then hookLists[k] = {} end
        table.insert(hookLists[k], obj)
      end
    end
  end

  -- compile the lists
  local hookLists = {}
  for _, m in pairs(hookableTablesInstances) do
    walkTable(hookLists, m, m)
    walkTable(hookLists, getmetatable(m), m)
  end

  -- convert the lists into proxies
  self.hookProxies = {}
  for k, sinkList in pairs(hookLists) do
    self.hookProxies[k] = function(...)
      for _, m in pairs(sinkList) do
        m[k](m, ...)
      end
    end
  end

  -- add dependencies here
  self.hookProxies.dependencies = dependencies or {}

  self:_updateHooks()
end

function ExtensionProxy:_updateHooks()
  local m = refreshInternal(self.hookProxies, self.extName, self.extPath, false) -- not loading fresh
  m.__virtual__ = true
  m.__manuallyLoaded__ = true
  resolveDependencies()
  table.clear(luaExtensionFuncs)  -- clear the hook function cache
  return m
end

function ExtensionProxy:destroy()
  self.hookProxies = {}
  self:_updateHooks()
  M.unload(self.extName)
end

-- public interface
MT.__index = function(tbl, key)
  if key == nil then return nil end
  --print('__index called: ' .. tostring(tbl) .. ', ' .. tostring(key))

  local m = resolvedNormalizedNameToModule[key]
  if m then return m end

  m = resolvedNormalizedNameToModule[string.lower(key)]
  if m then
    resolvedNormalizedNameToModule[key] = m
    return m
  end

  tbl.load(key)

  -- return the new module if existing, this only happens once as its cached in M
  return _G[key]
end

-- backward compatibility things below
M.loadModule = function(extName)
  log("W", logTag, "loadModule(extName) is deprecated. Please switch to load(extName)")
  loadExt(extName)
end

M.use = function(key)
  loadExt(key)
  --log("W", logTag, "use(extName) is deprecated. Please use the following syntax: core_extensions.<modulename>.doSomething()")
  return rawget(M, key)
end

-- normal interface
M.getLoadedExtensionsNames = function(excludeVirtual)
  local loadedNames = {}
  for k, data in pairs(luaMods) do
    if not excludeVirtual or not data.__virtual__ then
      table.insert(loadedNames, k)
    end
  end
  table.sort(loadedNames)
  return loadedNames
end

M.load = loadExt
M.loadModulesInDirectory = loadModulesInDirectory
M.loadAtRoot = loadAtRoot
M.reload = reload
M.refresh = refresh
M.unload = unload
M.unloadExcept = unloadExcept
M.isExtensionLoaded = isExtensionLoaded
M.hook = useProfiledHooks and hookProfiled or hookFast
M.hookExcept = hookExcept
M.hookNotify = hookNotify
M.hookUpdate = hookUpdate
M.printHooks = printHooks
M.printExtensions = printExtensions
M.addModulePath = addModulePath
M.saveModulePath = saveModulePath
M.restoreModulePath = restoreModulePath
M.disableSerialization = disableSerialization
M.getSerializationData = getSerializationData
M.deserialize = deserialize
M.setCompletedCallback = setCompletedCallback
M.luaPathToExtName = luaPathToExtName
M.extNameToLuaPath = extNameToLuaPath
M.setProfiler = setProfiler
M.wrapAllExtensionsForProfiler = wrapAllExtensionsForProfiler

M.onDeserialized = nop
M.onDeserialize = nop
M.onSerialize = nop

setmetatable(M, MT)

--getmetatable(_G).__index = MT.__index

return M
