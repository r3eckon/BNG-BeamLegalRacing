local M = {}
local im = ui_imgui
local bid = 0
local extensions = require("extensions")


local function imText(text)
local avail = im.GetContentRegionAvail()
im.PushTextWrapPos(avail.x)
im.TextWrapped(tostring(text))
im.PopTextWrapPos()
end

local function imButton(text)
local avail = im.GetContentRegionAvail()
im.Button(tostring(text or "Button"), im.ImVec2(avail.x, 0))
if im.IsItemHovered() then
local down = im.IsMouseClicked(0)
if down then return true end
end
return false
end

local function imSeparator(above, below)
if above > 0 then
im.Dummy(im.ImVec2(0,above))
end
im.Separator()
if below > 0 then
im.Dummy(im.ImVec2(0,below))
end
end



local showReport = false

local function vehfaxui(show, desc, daydata, shopfile, slot)
if not show then return end
if not daydata["vehfax"] then daydata["vehfax"] = "none" end

local csplit = extensions.blrutils.ssplit(daydata["vehfax"], ",")
local bought = false

for _,v in pairs(csplit) do
if tonumber(v) == slot then 
bought = true
break
end
end

imSeparator(5,0)
imText(extensions.blrlocales.translate("beamlr.vehfax.report.vfreport"))
if bought then
	if imButton((showReport and extensions.blrlocales.translate("beamlr.vehfax.report.hide")) or extensions.blrlocales.translate("beamlr.vehfax.report.show")) then showReport = not showReport end
	if showReport then imText(desc) end
else
	local money = extensions.blrglobals.gmGetVal("playerMoney")
	if money > 100.0 then
		if imButton(extensions.blrlocales.translate("beamlr.vehfax.report.buy")) then
			if money > 100.0 then 
				extensions.blrglobals.gmSetVal("playerMoney", money - 100.0)
				extensions.blrutils.playSFX("event:>UI>Career>Buy_01")
				if daydata["vehfax"] == "none" then daydata["vehfax"] = "" end
				daydata["vehfax"] = daydata["vehfax"] .. slot .. ","
				extensions.blrutils.saveDataTable("beamLR/shop/daydata/" .. shopfile, daydata)
				extensions.blrglobals.blrFlagSet("vehfaxDayDataReloadRequest", true)
			end
		end
	end
end


end


M.vehfaxui = vehfaxui

M.imSeparator = imSeparator
M.imText = imText
M.imButton = imButton


return M