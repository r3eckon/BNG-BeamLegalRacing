-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local fgtable = {}	-- Flowgraph table, updates from Flowgraph variables at regular interval
local blrtable = {}  -- BLRGlobals Manager table, need to tell Flowgraph to get this val using flag
local flag = {}		-- Value edit flag, tells the Flowgraph to load

local blrflags = {} -- Custom flags used for easier state update requests (traffic disable/enable)
					-- UNRELATED TO FG/BLR VARIABLE SYNC



local function fgSetVal(k,v) -- Saves a value into the FLOWGRAPH table to give to BLRGlobals Table
fgtable[k] = v
end

local function fgGetVal(k)	-- Gets a value from the BLRGlobals table to give to FLOWGRAPH
flag[k] = false				-- NEED TO getFlag BEFORE fgGetVal OTHERWISE IT IS ALREADY RESET
return blrtable[k]
end

local function fgPeekVal(k) -- Gets value without setting flag, needed in some cases. Flag should be set later
return blrtable[k]
end

local function forceSetFlag(k,v) -- To set flag some time after peek to check value
flag[k] = v
end

local function gmSetVal(k,v) -- Saves value into BLRGlobals Table for use by Flowgraph
blrtable[k] = v				
flag[k] = true
end

local function gmGetVal(k)	-- Gets a value from the FLOWGRAPH table to give to CUSTOM LUA / UI
if flag[k] == true then 	-- IF WE GOT EDITS NOT CONSUMED BY FLOWGRAPH, RETURN FROM BLRTABLE EDIT
return blrtable[k]			-- This works when player buys two parts within same money sync cycle as
else						-- the latest "real" remaining money value is the BLRTABLE stored one
return fgtable[k]
end
end

local function getFlag(k)	-- Returns flag state for key
if flag[k] == nil then		-- NEED TO getFlag BEFORE fgGetVal OTHERWISE IT IS ALREADY RESET
return false
else
return flag[k]
end
end

local function getFGTable()
return fgtable
end

local function getBLRTable()
return blrtable
end

local function blrFlagSet(name, val)
blrflags[name] = val
end

local function blrFlagGet(name)
return blrflags[name]
end

local function blrFlagsInit()
blrflags = {}
end

-- reference to active flowgraph manager, to access project variables more easily

local manager = {}

local function setManager(mgr)
manager = mgr
end

local function getManager()
return manager
end

local function getProjectVariable(var)
return manager.variables.variables[var].value
end

local function setProjectVariable(var, val)
manager.variables.variables[var].value = val
end


M.setManager = setManager
M.getManager = getManager
M.setProjectVariable = setProjectVariable
M.getProjectVariable = getProjectVariable

M.blrFlagsInit = blrFlagsInit
M.blrFlagSet = blrFlagSet
M.blrFlagGet = blrFlagGet
M.forceSetFlag = forceSetFlag
M.fgPeekVal = fgPeekVal
M.fgSetVal = fgSetVal
M.fgGetVal = fgGetVal
M.gmSetVal = gmSetVal
M.gmGetVal = gmGetVal
M.getFlag = getFlag
M.getFGTable = getFGTable
M.getBLRTable = getBLRTable

return M



