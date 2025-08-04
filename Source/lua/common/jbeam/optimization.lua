--[[
This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
If a copy of the bCDDL was not distributed with this
file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
This module contains a set of functions which manipulate behaviours of vehicles.
]]

-- BEAMLR EDITED 

local M = {}

local jbeamUtils = require("jbeam/utils")

local function optimizeNodes(nodes)
  -- Deterministic node ordering
  local sortedNodeKeys = tableKeys(nodes)
  table.sort(sortedNodeKeys)

  local maxID = 0
  local nonFixedNodes = table.new(#sortedNodeKeys, 0)
  local nonFixedNodesidx = 1
  local nonCollidableNodes = table.new(#sortedNodeKeys, 0)
  local nonCollidableNodesidx = 1

  -- nodes are a special kind
  for _, key in ipairs(sortedNodeKeys) do
    local node = nodes[key]
    if node.fixed then
      node.cid = maxID
      maxID = maxID + 1
    elseif node.collision ~= nil and node.collision == false then
      nonCollidableNodes[nonCollidableNodesidx] = node
      nonCollidableNodesidx = nonCollidableNodesidx + 1
    else
      nonFixedNodes[nonFixedNodesidx] = node
      nonFixedNodesidx = nonFixedNodesidx + 1
    end
  end

  -- add non collidable nodes
  for _, node in ipairs(nonCollidableNodes) do
    node.cid = maxID
    maxID = maxID + 1
  end

  -- put non fixed nodes at the end
  for _, node in ipairs(nonFixedNodes) do
    node.cid = maxID
    maxID = maxID + 1
  end

  return maxID
end

local function assignCIDs(vehicle)
  profilerPushEvent('jbeam/optimization.assignCIDs')
  vehicle.maxIDs = {}
  local ekeys = {}
  local vkeys = tableKeysSorted(vehicle)
  for _, keyEntry in ipairs(vkeys) do
    local entry = vehicle[keyEntry]
    if vehicle.validTables[keyEntry] then
      local maxID = 0
      if keyEntry ~= 'nodes' then
        -- everything except nodes
        table.clear(ekeys)
        tableKeysSorted(entry, ekeys)
        for _, rowKey in ipairs(ekeys) do
          entry[rowKey].cid = maxID
          maxID = maxID + 1
        end
      else
        maxID = optimizeNodes(entry)
      end
      vehicle.maxIDs[keyEntry] = maxID
    end
  end
  --log('D', "jbeam.assignCIDs", "- Vehicle numbering done.")
  profilerPopEvent('jbeam/optimization.assignCIDs')
  return true
end

local function optimize(vehicle)
  profilerPushEvent('jbeam/optimization.optimize')
  --log('D', "jbeam.optimize","- Optimizing ...")
  -- first: optimize beams
  if vehicle.beams == nil then
    return
  end
  for k, v in pairs(vehicle.beams) do
    if type(v) == "table" and type(v.id1) == "number" and type(v.id2) == "number" and v.id1 > v.id2 then
      v.id1, v.id2 = v.id2, v.id1
      v.cid = k
    end
  end

  --log('D', "jbeam.optimize","- Optimization done.")

  profilerPopEvent('jbeam/optimization.optimize')
  return true
end


-- cleans up some data that is not needed at runtime, but only during assembly of the vehicle
local function cleanupTable_rec(d, debugEnabled)
  if type(d) ~= 'table' then return end
  -- what to clean up now
  --d.skinName = nil
  --d.globalSkin = nil
  if not debugEnabled then
    d.group = nil
    d.engineGroup = nil
  end

  -- recurse
  for k, v in pairs(d) do
    if type(v) == 'string' and v == '' and k ~= 'mesh' then -- 'mesh' is a hack to prevent from cleaning flexbody.mesh values. Backward compatibility
      d[k] = nil
    end
	-- BEAMLR EDIT TO AVOID REMOVING EMPTY PARTS FROM SLOT PART MAP, REMOVE WHEN FIXED IN VANILLA
	if k~='slotPartMap' then
		cleanupTable_rec(v, debugEnabled)
	end
  end
end

local function cleanup(vehicle, debugEnabled)
  cleanupTable_rec(vehicle, debugEnabled)

  if vehicle.nodes then
    for _, n in pairs(vehicle.nodes) do
      if n.collision == true then n.collision = nil end -- the default
      if type(n.chemEnergy) ~= 'number' or n.chemEnergy == 0 then n.chemEnergy = nil end
      if not n.flashPoint then
        -- if not in fire system, clean out the data
        n.flashPoint = nil
        n.smokePoint = nil
        n.specHeat = nil
        n.vaporPoint = nil
        n.selfIgnitionCoef = nil
        n.burnRate = nil
        n.baseTemp = nil
        n.conductionRadius = nil
        n.containerBeam = nil
        n.selfIgnition = nil
      end
      if not n.selfCollision then n.selfCollision = nil end -- the default
    end
  end


  if vehicle.beams then
    for _, b in pairs(vehicle.beams) do
      if b.beamType == 0 then b.beamType = nil end -- the default
      if b.beamPrecompression == 1 then b.beamPrecompression = nil end
      if b.breakGroupType == 0 then b.breakGroupType = nil end
      if b.disableTriangleBreaking == false then b.disableTriangleBreaking = nil end
      if b.disableMeshBreaking == false then b.disableMeshBreaking = nil end
    end
  end

  if vehicle.triangles then
    for _, t in pairs(vehicle.triangles) do
      t.cid = nil
    end
  end
end

-- this is important to happen after we shift and renumber everything, so tha the cid fits
local function dereference(vehicle)
  if vehicle.hydros then
    for _, hydro in pairs(vehicle.hydros) do
      hydro.beamCID = hydro.beam.cid
      hydro.beam = nil
    end
  end
  if vehicle.wheels then
    for _, wheel in pairs(vehicle.wheels) do
      if wheel.sideBeams then
        for k, b in pairs(wheel.sideBeams) do
          wheel.sideBeams[k] = b.cid
        end
      end
      if wheel.rimBeams then
        for k, b in pairs(wheel.rimBeams) do
          wheel.rimBeams[k] = b.cid
        end
      end
      if wheel.peripheryBeams then
        for k, b in pairs(wheel.peripheryBeams) do
          wheel.peripheryBeams[k] = b.cid
        end
      end
      if wheel.treadBeams then
        for k, b in pairs(wheel.treadBeams) do
          wheel.treadBeams[k] = b.cid
        end
      end
      if wheel.reinfBeams then
        for k, b in pairs(wheel.reinfBeams) do
          wheel.reinfBeams[k] = b.cid
        end
      end
      if wheel.pressuredBeams then
        for k, b in pairs(wheel.pressuredBeams) do
          wheel.pressuredBeams[k] = b.cid
        end
      end
      if wheel.treadNodes then
        for k, tn in pairs(wheel.treadNodes) do
          wheel.treadNodes[k] = tn.cid
        end
      end
      if wheel.nodes then
        for k, tn in pairs(wheel.nodes) do
          wheel.nodes[k] = type(tn) == 'table' and tn.cid or tn
        end
      end
    end
  end
end

local function process(vehicle, debugEnabled)
  profilerPushEvent('jbeam/optimization.process')
  optimize(vehicle)
  cleanup(vehicle, debugEnabled)
  dereference(vehicle)

  -- removing disabled sections
  for keyEntry, entry in pairs(vehicle) do
    if type(entry) == "table" and tableIsDict(entry) and jbeamUtils.ignoreSections[keyEntry] == nil and tableIsDict(entry[0]) and entry[0]['disableSection'] ~= nil then
      --log('D', "jbeam.postProcess"," - removing disabled section '"..keyEntry.."'")
      vehicle[keyEntry] = nil
    end
  end

  vehicle.validTables = nil -- not needed anymore

  profilerPopEvent('jbeam/optimization.process')
  return true
end

M.assignCIDs = assignCIDs
M.process = process

return M
