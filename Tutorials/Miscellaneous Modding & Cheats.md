# Miscellaneous Modding & Cheats

## Money cheat
* Open beamLR/mainData with notepad.
* Add a bunch of 0s to your money value.
*  Save the file.
* Restart the scenario for changes to take effect.

## Other modding
Start money can be customized, check the **beamLR/init** folder for the various start difficulties.

Mod vehicles *should* also work but beamstate loading is a very unstable feature so some may have issues and I will not focus on fixing issues related to other mods.

The flowgraph mission can also be tweaked, this is for advanced users only as it's very easy to break things.

Same things goes for LUA scripts.

As of version 1.12 pink slip races are now restricted for certain vehicle models listed in the file **beamLR/pinkslipsBlacklist**. Blacklisted (fancy) vehicles will only allow pink slips when player is also using a blacklisted vehicle. This list can be edited.