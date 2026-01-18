--[[
This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
If a copy of the bCDDL was not distributed with this
file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
This module contains a set of functions which manipulate behaviours of vehicles.
]]

-- /!\ do not change this file without speaking to tdev

-- BEAMLR EDITED

local M = {}

local tableInsert, tableClear = table.insert, table.clear

local jbeamUtils = require("jbeam/utils")
local jbeamTableSchema = require('jbeam/tableSchema')
local json = require("json")
local stringBuffer = require('string.buffer')

-- part caches
local fileCache = {} -- BEAMLR EDITED STRUCTURE, SEE BELOW CACHE MODE EDIT

-- below are rebuild from fresh using fileCache[cmode], on any change
local partFileMap = {} -- BEAMLR EDITED STRUCTURE, SEE BELOW CACHE MODE EDIT
local partSlotMap = {} -- BEAMLR EDITED STRUCTURE, SEE BELOW CACHE MODE EDIT
local partNameMap = {} -- BEAMLR EDITED STRUCTURE, SEE BELOW CACHE MODE EDIT

local modManager = nil
local lastStartLoadingStats = { total = 0, cachedHits = 0 }

-- BEAMLR EDIT BEGIN
local cmode = "vanilla" -- BEAMLR CACHE MODE CAN BE avb OR vanilla
local function setCacheMode(mode)
cmode = mode
if not fileCache[cmode] then fileCache[cmode] = {} end
if not partFileMap[cmode] then partFileMap[cmode] = {} end
if not partSlotMap[cmode] then partSlotMap[cmode] = {} end
if not partNameMap[cmode] then partNameMap[cmode] = {} end
end
M.setCacheMode = setCacheMode
-- BEAMLR EDIT END


local function _processSlotsV1DestructiveBackwardCompatibility(slots, newSlots)
  local addedSlots = 0
  for k, slotSectionRow in ipairs(slots) do
    if slotSectionRow[1] == "type" then goto continue end -- ignore the header

    local slot = {}

    slot.type = slotSectionRow[1]
    slot.default = slotSectionRow[2]
    slot.description = slot.type

    if #slotSectionRow > 2 and type(slotSectionRow[3]) == 'string' then
      slot.description = slotSectionRow[3]
    end
    if #slotSectionRow > 3 and type(slotSectionRow[4]) == 'table' then
      tableMerge(slot, slotSectionRow[4])
    end
    tableInsert(newSlots, slot)
    addedSlots = addedSlots + 1

    ::continue::
  end
  return addedSlots
end

local function _processSlotsDestructiveLegacy(part, sourceFilename)
  if type(part.slots) ~= 'table' then return nil end

  local newSlots = {}
  if #part.slots > 0 and type(part.slots[1]) == 'table' and part.slots[1][1] ~= 'type' then
    -- backward compatibility: some parts miss the table header, which worked due to limitations before.
    log('W', 'slotSystem', 'Slot section of part ' .. tostring(part.partName) .. ' in file ' .. tostring(sourceFilename) ..' misses the table header. Adding default: ["type", "default", "description"]. Please fix.')
    tableInsert(part.slots, 1, {"type", "default", "description"})
  end
  local newListSize = jbeamTableSchema.processTableWithSchemaDestructive(part.slots, newSlots)
  if newListSize < 0 then
    -- fallback: use old code for old mods with errors
    newSlots = {}
    newListSize = _processSlotsV1DestructiveBackwardCompatibility(part.slots, newSlots)
    if newListSize < 0 then
      log('E', "", "Slots section in file " .. tostring(sourceFilename) .. " invalid. Unable to recover: " .. dumpsz(part.slots, 2))
    else
      log('W', "", "Slots section in file " .. tostring(sourceFilename) .. " invalid. Please fix. Partly reconstructed: " .. dumpsz(part.slots, 2))
    end
  end
  part.slots = newSlots
end

-- this function processes the slots / slots2
local function processSlotsDestructive(part, sourceFilename)
  --log('I', "", "Processing slots in file " .. tostring(sourceFilename) .. " ..." .. dumpsz(part, 2))
  if type(part.slots) ~= 'table' and type(part.slots2) ~= 'table' then return nil end

  if part.slots then
    _processSlotsDestructiveLegacy(part, sourceFilename)
    -- now upgrade to the new slots2 data structure
    for _, slot in ipairs(part.slots) do
      slot.name = slot.name or slot.type
      slot.allowTypes = {slot.type}
      slot.type = nil
      slot.denyTypes = {}
    end
    part.slots2 = part.slots
    part.slots = nil
  elseif part.slots2 then
    -- slots 2
    -- ["name", "allowTypes", "denyTypes", "default", "description"],
    local newSlots2 = {}
    local newListSize = jbeamTableSchema.processTableWithSchemaDestructive(part.slots2, newSlots2)
    if newListSize < 0 then
      log('E', "", "Slots section in file " .. tostring(sourceFilename) .. " invalid. Unable to recover: " .. dumpsz(part.slots2, 2))
    end
    --log('I', "", "Slots section in file " .. tostring(sourceFilename) .. " processed: " .. dumpsz(newSlots2, 2))
    part.slots2 = newSlots2
  end
  -- from here on we only have slots2 available
end

-- this filters the data we send to the UI as there is a lot of additonal data in there that we do not want
  local function getSlotInfoDataForUi(slots)
    local res = table.new(0, #slots)
    for _, slot in ipairs(slots) do
      local s = {}
      s.name = slot.name or slot.type -- slots2 - new feature for uniquely identifying slots
      s.type = slot.type -- slots1, replaced by allowTypes and denyTypes
      --s.default = slot.default,
      s.allowTypes = slot.allowTypes -- slots2
      s.denyTypes = slot.denyTypes  -- slots2
      s.description = slot.description
      s.coreSlot = slot.coreSlot
      res[slot.name or slot.type] = s
    end
    return res
  end

-- json decode the file
local function _parseFileIntoCache(filename)
  local plainFileContent = readFile(filename)
  if plainFileContent then
    local ok, data = pcall(json.decode, plainFileContent)
    if ok == false then
      log('E', "jbeam.parseFile","unable to decode JSON: "..tostring(filename))
      log('E', "jbeam.parseFile","JSON decoding error: "..tostring(data))
      return nil
    end
    -- fix the slots sections
    local res = {}
    local parts = {}
    local partCounter = 0
    for partName, part in pairs(data) do
      parts[partName] = {}
      -- this processes the slot and slot2 section
      processSlotsDestructive(part, filename)

		-- BeamLR 1.13 Advanced Vehicle Building Code Start
		-- Updated in 1.16 due to change in jbeam table format preventing
		-- old AVB code from working properly, processSlotsDestructive converts
		-- old jbeam table format to new format which itself is a bit different
		-- from "slot2" format in previous versions of the game
		if extensions.blrglobals.blrFlagGet("avbToggle") then
		if extensions.blrglobals.blrFlagGet("advancedVehicleBuilding") then
		if part["slots2"] then -- Now all slots are updated to newer "slot2" format
			for k,v in pairs(part["slots2"]) do
				v["default"] = ""
				if v["coreSlot"] then v["coreSlot"] = nil end
			end
		end
		end
		end
		-- BeamLR 1.13 Advanced Vehicle Building Code end	



      if type(part.slotType) ~= 'string' and type(part.slotType) ~= 'table' then
        log('E', "jbeam.loadJBeamFile", "part does not have a slot type. Ignoring: "..tostring(filename) .. ' - ' .. dumpsz(part, 2))
        parts[partName].slotTypes = {}
        goto continue2
      end
      -- support for a part that fits in the correct slottype
      if type(part.slotType) == 'string' then
        parts[partName].slotTypes = {part.slotType}
      elseif type(part.slotType) == 'table' then
        parts[partName].slotTypes = part.slotType
      end
      local partDesc = {
        description = part.information.name or "",
        authors = part.information.authors or "",
        isAuxiliary = part.information.isAuxiliary,
        slotInfoUi = getSlotInfoDataForUi(part.slots2 or {})
      }
      if modManager then -- only available on the game engine side
        -- enrich the part with modName and ID
        local modName, modInfo = modManager.getModForFilename(filename)
        if modName then
          partDesc.modName = modName
          --partDesc.modID   = modInfo.modID
          --partDesc.modInfo = modInfo -- too much data
        end
      end

      part.partName = partName -- this is for backward compatibility of the surrounding code

      parts[partName].partDesc = partDesc
      parts[partName].partEncoded = stringBuffer.encode(part)
      partCounter = partCounter + 1
      ::continue2::
    end
    res.partCount = partCounter
    res.parts = parts
    res.namespace = string.match(filename, "(/vehicles/[^/]*/).*$") -- yeah it's weird to have no leading slash :/
    return res
  else
    log('E', "jbeam.parseFile","unable to read file: "..tostring(filename))
  end
end

-- this function updates all the caches when one file changes or on rebuild
local function _updateGlobalCache()
  -- invalidate all caches as parts might have changed
  partFileMap[cmode] = {}
  partSlotMap[cmode] = {}
  partNameMap[cmode] = {}

  -- walk all file caches to build the global caches together
  for filename, cacheData in pairs(fileCache[cmode]) do
    --dumpz({"cacheData: ", cacheData}, 8)
    for partName, partData in pairs(cacheData.parts) do
      for _, slotType in ipairs(partData.slotTypes) do
        partSlotMap[cmode][cacheData.namespace] = partSlotMap[cmode][cacheData.namespace] or {}
        partSlotMap[cmode][cacheData.namespace][slotType] = partSlotMap[cmode][cacheData.namespace][slotType] or {}
        if tableContains(partSlotMap[cmode][cacheData.namespace][slotType], partName) then
          log('E', 'jbeam.loadJBeamFile', 'Duplicate part found: ' .. tostring(partName) .. ' from file ' .. tostring(filename))
        end
        tableInsert(partSlotMap[cmode][cacheData.namespace][slotType], partName)
      end
      partFileMap[cmode][cacheData.namespace] = partFileMap[cmode][cacheData.namespace] or {}
      partFileMap[cmode][cacheData.namespace][partName] = filename

      partNameMap[cmode][cacheData.namespace] = partNameMap[cmode][cacheData.namespace] or {}
      partNameMap[cmode][cacheData.namespace][partName] = partData.partDesc
    end
  end

  --dumpz({"partFileMap[cmode]: ", partFileMap[cmode]}, 4)
  --dumpz({"partSlotMap[cmode]: ", partSlotMap[cmode]}, 4)
  --dumpz({"partNameMap[cmode]: ", partNameMap[cmode]}, 4)
end

local function _ensureJBeamFileLoaded(filename)
  if fileCache[cmode][filename] then
    return true
  end
  fileCache[cmode][filename] = _parseFileIntoCache(filename)
  return false
end

local function startLoading(directories)
  profilerPushEvent('jbeam/io.startLoading')
  
  -- BEAMLR EDIT START
  if not fileCache[cmode] then fileCache[cmode] = {} end
  if not partFileMap[cmode] then partFileMap[cmode] = {} end
  if not partSlotMap[cmode] then partSlotMap[cmode] = {} end
  if not partNameMap[cmode] then partNameMap[cmode] = {} end
  -- BEAMLR EDIT END

  --log('I', "jbeam.startLoading", "*** loading jbeam files: " .. dumps(directories))

  local cacheDirty = false
  local wasCached
  lastStartLoadingStats = { total = 0, cachedHits = 0 }
  for _, dir in ipairs(directories) do
    local filenames = FS:findFiles(dir, "*.jbeam", -1, false, false)
    for _, filename in ipairs(filenames) do
      wasCached = _ensureJBeamFileLoaded(filename)
      cacheDirty = cacheDirty or (not wasCached)
      lastStartLoadingStats.total = lastStartLoadingStats.total + 1
      if wasCached then lastStartLoadingStats.cachedHits = lastStartLoadingStats.cachedHits + 1 end
    end
    log('D', 'jbeam.startLoading', "Loaded " .. tostring(partCountTotal) .. " parts from " .. tostring(tableSize(fileCache[cmode])) .. ' jbeam files in ' .. tostring(dir))
  end

  -- we finished loading all the files, now create the lookup tables
  if cacheDirty then
    _updateGlobalCache()
  end

  profilerPopEvent('jbeam/io.startLoading')
  return { preloadedDirs = directories }
end

local function getPart(ioCtx, partName)
  if not partName then return end
  for _, dir in ipairs(ioCtx.preloadedDirs) do
  
	if not (partFileMap[cmode] and partFileMap[cmode][dir]) then
		startLoading(ioCtx.preloadedDirs)
		--_updateGlobalCache()
	end
  
    local jbeamFilename = partFileMap[cmode][dir][partName]
    if jbeamFilename then
      if not fileCache[cmode][jbeamFilename] then
        -- file got missing, maybe it changed, reload it and rebuild all caches
        _ensureJBeamFileLoaded(jbeamFilename)
        _updateGlobalCache()
      end
      -- realize the object from the cache
      local partCached = fileCache[cmode][jbeamFilename].parts[partName]
      return stringBuffer.decode(partCached.partEncoded), jbeamFilename
    end
  end
end

local function isContextValid(ioCtx)
  return type(ioCtx.preloadedDirs) == 'table'
end

local function getMainPartName(ioCtx)
  if not isContextValid(ioCtx) then return end
  for _, dir in ipairs(ioCtx.preloadedDirs) do
  
    if not (partSlotMap[cmode] and partSlotMap[cmode][dir]) then
		startLoading(ioCtx.preloadedDirs)
		--_updateGlobalCache()
	end
  
    if partSlotMap[cmode][dir] and partSlotMap[cmode][dir]['main'] then
      return partSlotMap[cmode][dir]['main'][1]
    end
  end
end

-- BEAMLR EDITED FUNCTION
local function finishLoading()
  -- tableClear(jbeamCache) -- NO LONGER NEEDED AS OF 0.38, ONLY fileCache[cmode] IS USED
  -- fileCache[cmode]Old = {} -- NO LONGER NEEDED AS OF 0.38, ONLY fileCache[cmode] is USED
  -- fileCache[cmode] = {} -- THIS CAUSES PROBLEMS
end

local function getAvailableParts(ioCtx)
  if not isContextValid(ioCtx) then return end

  local res = {}
  local loaded = false
  for _, dir in ipairs(ioCtx.preloadedDirs) do
    if not (partSlotMap[cmode] and partSlotMap[cmode][dir]) then
      startLoading(ioCtx.preloadedDirs)
      loaded = true
    end
    -- merge manually to catch errors
    for partName, partDesc in pairs(partNameMap[cmode][dir]) do
      if res[partName] then
        log('E', "jbeam.getAvailableParts", "parts names are duplicate: " .. tostring(partName) .. ' in folders: ' .. dumps(ioCtx.preloadedDirs))
      end
      res[partName] = partDesc
    end
  end
  if loaded then finishLoading() end
  return res
end

-- DEPRECATED FUNCTION: IT IS NOT COMPATIBLE WITH SLOTS2, USE getCompatiblePartNamesForSlot() INSTEAD
local function getAvailableSlotNameMap(ioCtx)
  if not isContextValid(ioCtx) then return end

  local slotsPartMap, res = {}, {}
  local loaded = false
  for _, dir in ipairs(ioCtx.preloadedDirs) do
    if not (partSlotMap[cmode] and partSlotMap[cmode][dir]) then
      startLoading(ioCtx.preloadedDirs)
      loaded = true
    end
    -- merge manually to catch errors
    for slotName, partList in pairs(partSlotMap[cmode][dir]) do
      if not res[slotName] then res[slotName], slotsPartMap[slotName] = {}, {} end
      local partMap = slotsPartMap[slotName]
      for _, partName in ipairs(partList) do
        if partMap[partName] then
          log('E', "jbeam.getAvailableSlotNameMap", "parts names are duplicate: " .. tostring(partName) .. ' in folders: ' .. dumps(ioCtx.preloadedDirs))
        end
        tableInsert(res[slotName], partName)
        partMap[partName] = true
      end
    end
  end
  if loaded then finishLoading() end
  return res
end

local function getAvailablePartNamesForSlot(ioCtx, slotType)
  local slotMap = getAvailableSlotNameMap(ioCtx)
  return slotMap and slotMap[slotType] or {}
end

-- supply slotMap with getAvailableSlotNameMap() , especially if you will be calling this function multiple times as an optimization
-- slotDef comes from:
--  local part = getPart(ioCtx, partName)
--  local slots = part.slots2 or part.slots
--  local slotDef = slots[i]
local function getCompatiblePartNamesForSlot(ioCtx, slotDef, slotMap)
  slotMap = slotMap or getAvailableSlotNameMap(ioCtx)
  if not slotMap then return {}, {} end

  -- slot version 1
  if slotDef.type then
    return slotMap[slotDef.type] or {}, {}

  -- slot version 2
  elseif slotDef.allowTypes then
    local suitablePartNames, unsuitablePartNames = {}, {}
    local suitablePartsMap = {}
    local denyTypesMap = next(slotDef.denyTypes) and {}
    if denyTypesMap then
      for _, denyType in ipairs(slotDef.denyTypes) do
        denyTypesMap[denyType] = true
      end
    end
    for _, slotType in ipairs(slotDef.allowTypes) do
      -- get all parts that fit the slot allow type
      local allowedParts = slotMap[slotType] or {}
      for _, partName in ipairs(allowedParts) do
        if not suitablePartsMap[partName] then
          local part = getPart(ioCtx, partName)
          if part then
            local partSlotType = type(part.slotType)
            if partSlotType == 'string' then
              -- case 1: the slotType on the part side is a string only
              -- check if the part is denied by any of the slot deny types
              if denyTypesMap then
                if not denyTypesMap[part.slotType] then
                  tableInsert(suitablePartNames, partName)
                  suitablePartsMap[partName] = true
                else
                  tableInsert(unsuitablePartNames, {partName = partName, reason = "Part type is in deny list"})
                end
              else
                tableInsert(suitablePartNames, partName)
                suitablePartsMap[partName] = true
              end
            elseif partSlotType == 'table' then
              -- case 2: the slotType on the part is a table
              -- check if the part is denied by any of the slot deny types
              if denyTypesMap then
                local allowed = true
                for _, slotType in ipairs(part.slotType) do
                  if denyTypesMap[slotType] then
                    allowed = false
                    break
                  end
                end
                if allowed then
                  tableInsert(suitablePartNames, partName)
                  suitablePartsMap[partName] = true
                else
                  tableInsert(unsuitablePartNames, {partName = partName, reason = "Part type is in deny list"})
                end
              else
                tableInsert(suitablePartNames, partName)
                suitablePartsMap[partName] = true
              end
            end
          else
            log("E", "jbeam.getCompatiblePartNamesForSlot", "Part \"" .. tostring(partName) .. "\" not found; skipping.")
          end
        end
      end
    end
    return suitablePartNames, unsuitablePartNames
  end

  return {}, {}
end

local function updateAllVehiclesCompatibleParts()
  local function updateSlotRec(ioCtx, slotTreeEntry, slotMap)
    local part = getPart(ioCtx, slotTreeEntry.chosenPartName)
    if part then
      local slots = part.slots2 or part.slots
      if slots then
        for _, slotDef in ipairs(slots) do
          local slotId = slotDef.name or slotDef.type
          local childSlotTreeEntry = slotTreeEntry.children[slotId]
          if childSlotTreeEntry then
            childSlotTreeEntry.suitablePartNames, childSlotTreeEntry.unsuitablePartNames = getCompatiblePartNamesForSlot(ioCtx, slotDef, slotMap)
            updateSlotRec(ioCtx, childSlotTreeEntry, slotMap)
          end
        end
      end
    end
  end

  for vehId, veh in vehiclesIterator() do
    local vehData = core_vehicle_manager.getVehicleData(vehId)
    local ioCtx = vehData.ioCtx
    startLoading(ioCtx.preloadedDirs)
    local slotMap = getAvailableSlotNameMap(ioCtx)
    if not slotMap then
      log('E', "jbeam.updateAllVehiclesCompatibleParts", "unable to get slot map, unable to update compatible parts")
      return
    end
    updateSlotRec(ioCtx, vehData.config.partsTree, slotMap)
  end
end

local function onFileChanged(filename, type)
  --local dir = string.match(filename, "(/vehicles/[^/]*/).*$") -- yeah it's weird to have no leading slash :/
  local _, _, ext = path.split(filename)
  if ext ~= 'jbeam' then return end
  
  -- BEAMLR EDIT, AVOID ERROR IF HOOK IS CALLED BEFORE CACHES ARE INITIALIZED
  if not fileCache[cmode] then
	fileCache[cmode] = {}
  end

  -- invalidate everthing from that file in all the caches.
  -- important: the other caches will be stale until we reload. This is by design.
  if fileCache[cmode][filename] then
    log('I', 'jbeam.onFileChanged', 'File changed: ' .. tostring(filename) .. ' (' .. tostring(type) .. ')')
  end
  fileCache[cmode][filename] = nil
end

local function getLastStartLoadingStats()
  return lastStartLoadingStats
end

local function onExtensionLoaded()
  modManager = extensions.core_modmanager
end

M.onExtensionLoaded = onExtensionLoaded
M.onFileChanged = onFileChanged

M.startLoading = startLoading
M.finishLoading = finishLoading
M.getPart = getPart
M.getMainPartName = getMainPartName

M.getAvailableParts = getAvailableParts
M.getAvailableSlotNameMap = getAvailableSlotNameMap
M.getAvailablePartNamesForSlot = getAvailablePartNamesForSlot
M.getCompatiblePartNamesForSlot = getCompatiblePartNamesForSlot
M.getLastStartLoadingStats = getLastStartLoadingStats


return M