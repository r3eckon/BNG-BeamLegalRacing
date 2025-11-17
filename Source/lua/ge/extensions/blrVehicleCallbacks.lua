local M = {}

local extensions = require("extensions")

local function usedFuelcan(ikey, quantity, disabled)
local item = extensions.blrItemInventory.getInventoryItem(ikey)
local units = extensions.blrutils.getSettingValue("uiUnits")
item:use(quantity)
if item.quantity <= 0 then extensions.blrItemInventory.removeFromInventory(ikey) end
extensions.blrItemInventory.saveInventory()
extensions.customGuiStream.sendItemInventory()

if disabled then
guihooks.trigger('Message', {ttl = 10, category="inventory", msg = extensions.blrlocales.translate("beamlr.msgapp.wrongfuel"), icon = 'directions_car'})
else
if units == "imperial" then
guihooks.trigger('Message', {ttl = 10, category="inventory", msg = extensions.blrlocales.translate("beamlr.msgapp.fuelcanused") .. string.format("%.2f", quantity / 3.785) .. " gal." , icon = 'directions_car'})
else
guihooks.trigger('Message', {ttl = 10, category="inventory", msg = extensions.blrlocales.translate("beamlr.msgapp.fuelcanused") .. string.format("%.2f", quantity) .. " L.", icon = 'directions_car'})
end
end
end

local function usedConsumableBottle(ikey, quantity)
local item = extensions.blrItemInventory.getInventoryItem(ikey)
item:use(quantity)
if item.quantity <= 0 then extensions.blrItemInventory.removeFromInventory(ikey) end
extensions.blrItemInventory.saveInventory()
extensions.customGuiStream.sendItemInventory()
end


local function usedOilBottle(ikey, quantity)
local units = extensions.blrutils.getSettingValue("uiUnits")

usedConsumableBottle(ikey,quantity)

if units == "imperial" then
guihooks.trigger('Message', {ttl = 10, category="inventory", msg = extensions.blrlocales.translate("beamlr.msgapp.oilbottleused") .. string.format("%.2f", quantity / 3.785) .. " gal." , icon = 'directions_car'})
else
guihooks.trigger('Message', {ttl = 10, category="inventory", msg = extensions.blrlocales.translate("beamlr.msgapp.oilbottleused") .. string.format("%.2f", quantity) .. " L.", icon = 'directions_car'})
end
end

local function usedCoolantBottle(ikey, quantity)
local units = extensions.blrutils.getSettingValue("uiUnits")

usedConsumableBottle(ikey,quantity)

if units == "imperial" then
guihooks.trigger('Message', {ttl = 10, category="inventory", msg = extensions.blrlocales.translate("beamlr.msgapp.coolantbottleused") .. string.format("%.2f", quantity / 3.785) .. " gal." , icon = 'directions_car'})
else
guihooks.trigger('Message', {ttl = 10, category="inventory", msg = extensions.blrlocales.translate("beamlr.msgapp.coolantbottleused") .. string.format("%.2f", quantity) .. " L.", icon = 'directions_car'})
end
end

M.usedCoolantBottle = usedCoolantBottle
M.usedOilBottle = usedOilBottle
M.usedFuelcan = usedFuelcan

return M