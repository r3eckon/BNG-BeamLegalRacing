-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local fetchTable = {}

local function fetch(msg,id)
fetchTable[id] = msg
end

local function getVal(id)
return fetchTable[id]
end

M.fetch = fetch
M.getVal = getVal

return M
