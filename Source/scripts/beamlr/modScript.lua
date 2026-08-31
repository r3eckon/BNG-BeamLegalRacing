-- BeamLR modscript for auto loading certain extensions
extensions.load("blrlogs")
extensions.load("blrutils") -- load blrutils as ge exclusive script used to make vlua vms load blrlog extension

setExtensionUnloadMode("blrlogs", "manual")
setExtensionUnloadMode("blrutils", "manual")

-- Custom extension hook that only runs ONCE per game startup
-- does not fire again even if lua is reloaded with CTRL+L
-- note: only fires for extensions that are already loaded
if not VariableRegistry.get("blr_gameEngineStarted") then
extensions.hook("onGameStartedBLR")
VariableRegistry.set("blr_gameEngineStarted", true)
end