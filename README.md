# Beam Legal Racing 1.0
BeamLR is a persistent career BeamNG mod inspired by SLRR aiming to bring hardcore game mechanics to BeamNG such as external and mechanical damage persistence, money, paying for repairs, player health and injuries with fatal crashes resetting your save file, etc. The mod adds interaction to the sandbox with gas stations, repair shops, in world vehicle store system, dynamic race events, enabled traffic and more to achieve a sandbox career experience. 

Perform missions, races and challenges to earn money to buy vehicles and parts. Drive carefully as repairs can be quite costly and a hard enough crash could mean game over!

## Install Instructions

### Player install (Allows career data cheating)
* Drop the zip in your mods folder. 
### Modder install (Allows further tweaking, adding races, shop vehicles & more)
* Unpack the zip or clone the repo
* Copy or merge contents to your BeamNG user folder

If you are experiencing issues with the mod using the player install, try modder install before making a bug report. Since the mod relies heavily on data persistence some files may fail to load properly when zipped as a mod.


## Before Playing
BeamLR relies on a UI app that you must add to your "Scenario" UI layout in order to access features such as:
* Options Menu
* Part Edit Menu
* Part Shop Menu
* Tuning Menu
* Paint Edit Menu

The UI app is best placed at the top center of the screen with a size of at least **500x500**.

First time players: the imgui unit detection feature may fail to properly register your unit setting. 

Toggling back and forth between metric and imperial fixes this issue. The UI will then show correct units.


Remember to save the **userfolder/beamLR** folder if you want to backup your career!

The scenario has no autosave feature. Game crashes or hard quit may result in lost progress.

## Getting started
Spawn on Utah at the Auto Repair Zone. The mission marker near the parking lot garage is used to play your BeamLR career.

![mission marker](https://i.imgur.com/uSx4849.png)

The scenario will load your last used vehicle and spawn traffic. Be patient while the scenario is loading especially if using lots of traffic.

Once in the scenario floating markers indicate interactive areas for the player garage, repair shop, gas stations, race clubs, etc.

![part shop marker](https://i.imgur.com/84A5emi.png)

Before you can race, you need some money to wager. The first thing to do is delivery missions.

There are 3 race clubs implemented: Highway Race Club, Offroad Racing Club and Pure Drag Race Club.

![race clubs](https://i.imgur.com/yPLsjIc.png)

You must complete every race in a league to progress to the next league. Opponent vehicle performance increases with leagues.

You can spend money on part upgrades or new vehicles by visiting the various shops.


## WIP Notice
This mod is a work in progress. At this stage it is a decent vertical slice of the gameplay the project is trying to achieve with some bugs and quirks remaining that should get better as BeamNG and the mod are updated. 

That being said a lot of content is missing and unbalanced, for instance part prices are set to a default value. This means you can build top performance vehicles for cheap. Still, a decent amount of unique races have been added to try and keep this initial version as entertaining as possible.

## Modding & Cheating
It is easy to change or add to the mod since BeamLR relies on plaintext files to define things such as:
* Player Money
* Player Health
* Player Reputation
* Owned Vehicles (Model, Config, Gas in tank, Impound Cost, Sell values)
* Race Parameters (Opponent Model, Config, Risk, Race Path, Rewards)
* Store Vehicles (Model, Config, Cost, Odometer)
* Store Vehicle Availability (Which stores sell which vehicles)
* Race Club Completion

With the player install only career files can be changed, everything else is stored in the zip.

Want easy money to play around with expensive cars without grinding? 

Just add a bunch of 0s to your money value and restart the scenario for changes to take effect! 


With modder install almost everything about the mod can be quickly changed.

### Adding new races

Brand new races are created by adding triggers to the map where you want checkpoints.
The AI uses waypoints, one waypoint per checkpoint some distance after the trigger.
Race files also define opponent parameters like what vehicle and config to use.
Here is an example from one of the included race files:
```
desc=Drag race to the end of the highway
wager=50,100
slips=0
enemyModel=sunburst
enemyConfig=vehicles/sunburst/base_M.pc
enemyRisk=0.98
enemyBasePrice=0
enemyPartPrice=0
enemyScrapVal=0
enemyPaint=0,0,0,0,0.1,0.1,0.1,0.1
enemyAvoid=1
triggers=BeamNGTrigger_HighwayDragFinish
waypoints=ut_wp_53
laps=1
ifile=beamLR/races/integrity/bad
traffic=1
parts=none
rep=5,20
```
The easiest way to create a new race is to copy a race file and giving it the next available file name.

If the folder contains race0, race1 and race2 the copied file is renamed to **race3**.


Then it is trivial to change the model and config. 

Model name is the name of the zip file for that vehicle

Config files are found in the zip files for each vehicle.


Values separated by commas are interpreted as random ranges or choices.

Works with wager, rep, laps and enemyRisk, enemyModel and enemyConfig.

This is used to create randomized races that still use the same path. Used to make the endless "hero" race league more interesting.

### UI Modding
Part Images can be added to enhance the UX of the part shop.
To add more part images:
* Navigate to **userfolder/ui/modules/apps/beamlrui/partimg**
* Inside BeamNG grab a small screencap of the part
* Crop or resize the image to be square 200x200 resolution
* Save the image in PNG format using the internal name of the part (**pickup_bed.png**)

The UI will automatically look for PNG files with the various part names in order to show previews.

Internal names for parts are shown in the part shop and part edit UI for now as reference to help this process


Part Categories can be added to make it easier to navigate the list of available parts.
The **userfolder/beamLR/partCategories** file contains the data needed for category matching:
```
sparetire=misc
bed=body
bumper=body
radiator=engine
...
TEXT_TO_MATCH=CATEGORY
```

It relies on basic string matching so all part names with the text to match will be listed under that category.

The UI is overall a heavy WIP and will need a ton of work to become more user friendly. 

### Other modding
Want to add your custom config to the vehicle store? That's also possible.

Mod vehicles *should* also work but beamstate loading is a very unstable feature so some may have issues. 

This remains untested and I will not focus on fixing issues related to other mods.

The flowgraph mission can also be tweaked, this is for advanced users only as it's very easy to break things.

Same things goes for LUA scripts.

## Final Word
Feedback and bug reports are appreciated! 

Thank you for playing BeamLR!

## Known Issues 

* Covet beamstate saving breaks advanced coupler beams, doors won't close, hood won't open. Current best workaround is to simply repair the vehicle.
* Towing mechanic may repair your vehicle. This is due to problems with a teleport function that shouldn't cause a reset yet sometimes does.
* Game may freeze upon loading into the scenario, with vehicle disappearing. Still investigating this problem.
* Some tuning configurations can cause unfair damage when a vehicle is loaded. A workaround is implemented but may fail to work in certain situations.
* Various UI problems, input fields stop registering keystrokes, whole UI can refuse to work. Workaround is to keep cursor above input fields. CTRL+F5 to fix the frozen UI.
* Race checkpoints sometimes fail to trigger properly. Still investigating this problem.


## Changelog

### 1.0 
* Initial Release
