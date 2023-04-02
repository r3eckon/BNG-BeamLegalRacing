-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local guihooks = require('guihooks')

local uidata = {}


local function sendDataToUI(k,v)
local d = {}
d.key = k
d.val = v
guihooks.trigger("beamlrData", d)
end

local function sendDataToEngine(k,v)
uidata[k] = v
end

local function getUIData(k)
return uidata[k]
end

local function sendCurrentDrift(v)
guihooks.trigger("beamlrCurrentDrift", v)
end

local function sendTotalDrift(v)
guihooks.trigger("beamlrTotalDrift", v)
end

local function toggleDriftUI(t)
guihooks.trigger("beamlrToggleDriftUI", t)
end

M.toggleDriftUI = toggleDriftUI
M.sendTotalDrift = sendTotalDrift
M.sendCurrentDrift = sendCurrentDrift
M.sendDataToEngine = sendDataToEngine
M.sendDataToUI = sendDataToUI
M.getUIData = getUIData

return M



