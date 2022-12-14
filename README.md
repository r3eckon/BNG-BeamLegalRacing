# Beam Legal Racing 1.5.1
BeamLR is a persistent career BeamNG mod inspired by SLRR aiming to bring hardcore game mechanics to BeamNG such as external and mechanical damage persistence, money, paying for repairs, player health and injuries with fatal crashes resetting your save file, etc. The mod adds interaction to the sandbox with gas stations, repair shops, in world vehicle store system, dynamic race events, enabled traffic and more to achieve a sandbox career experience. 

Perform missions, races and challenges to earn money to buy vehicles and parts. Drive carefully as repairs can be quite costly and a hard enough crash could mean game over!

## Install Instructions

### Player install (Allows career data cheating)
* Drop the zip in your mods folder. 

### Modder install (Allows further tweaking, adding races, shop vehicles & more)
* Unpack the zip or clone the repo
* Copy or merge contents to your BeamNG user folder

### Player Install Notice

If you are experiencing issues with the mod using the player install, try modder install before making a bug report. Since the mod relies heavily on data persistence some files may fail to load properly when zipped as a mod.

## Update Instructions
BEFORE UPDATING:  Back up your userfolder/beamLR folder to save your career

### Player install
* Replace mod zip file with updated zip. 
* Done.

### Modder install
* Use in game UI to back up your career
* Copy updated mod folders to userfolder. 
* Tell OS to replace existing files when asked. This applies the update.
* Use in game UI to restore your backup

If the in game backup system fails to work properly:

* Replace the following files/folders using your backed up beamLR folder:
* beamLR/beamstate                                    (External and mechanical damage)
* beamLR/garage                                       (Garage vehicle data & config)
* beamLR/mainData                                     (Main career data file for money,rep,etc)
* beamLR/shop/daydata                                 (Vehicle shop daily data, aka bought slots)
* beamLR/races/INSERT RACE CLUB/progress              (Race club progress, repeat for each club)

## BeamNG Update Userfolder Migration Process

With major updates to BeamNG a new userfolder is created. Not all BeamLR files are automatically migrated.

It is recommended to do a fresh install of BeamLR in the new userfolder before moving your career files.

To restore your career use the process for a normal mod update after installing in the new userfolder.

The game will give you a chance to view the contents of your old userfolder containing career files on first launch after updating so don't worry about steam update deleting your save.

## Read Before Playing
BeamLR relies on a UI app and custom UI layout in order to access features such as:
* Options Menu
* Part Edit Menu
* Part Shop Menu
* Tuning Menu
* Paint Edit Menu

Since version 1.5 there is no setup required for the UI to work. The "BeamLR" ui layout should now be loaded on scenario start. Any changes made to this UI layout will be reflected when playing BeamLR in case the default layout doesn't fit on your screen.

First time players: the imgui unit detection feature may fail to properly register your unit setting. 

Toggling back and forth between metric and imperial fixes this issue. The UI will then show correct units.


Remember to save the **userfolder/beamLR** folder if you want to backup your career!

The scenario has no autosave feature. Game crashes or hard quit may result in lost progress.

Further instructions and various tips on this mods' various features are listed in the BeamLR UI Main Menu.

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

Use the top menu to access part shop & part edit UIs.

You can reset your career at any time using the options menu.


## WIP Notice
This mod is a work in progress. At this stage it is a decent vertical slice of the gameplay the project is trying to achieve with some bugs and quirks remaining that should get better as BeamNG and the mod are updated. 

That being said a lot of content is missing and unbalanced, for instance part prices are set to a default value. This means you can build top performance vehicles for cheap. Still, a decent amount of unique races have been added to try and keep this initial version as entertaining as possible.

Due to the nature of BeamNG some features available to players may break the experience when playing BeamLR, such as the circular menu, world editor and other UI apps. If playing seriously (not actively trying to break stuff) try  avoiding features that aren't directly offered in UI menus from the mod. While I still appreciate bug reports related to said features, some of them simply can't be disabled and related issues won't be prioritized.

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

Open beamLR/mainData with notepad and add a bunch of 0s to your money value. 

Restart the scenario for changes to take effect! 


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
* Some tuning configurations can cause unfair damage when a vehicle is loaded. A workaround is implemented but may fail to work in certain situations.
* Various UI problems, input fields stop registering keystrokes, whole UI can refuse to work. Workaround is to keep cursor above input fields. CTRL+F5 to fix the frozen UI.
* Race checkpoints sometimes fail to trigger properly. Fix has been implemented but this may still be a problem. 


## Changelog

### 1.0 
* Initial Release

### 1.1
* Potential fix for checkpoint triggers not working in some situations 	
* Fixed game freeze upon scenario loading			
* Fixed "Call Mechanic" button not checking player money before repair
* Fixed car shop UI letting players sell non existent car while walking
* Fixed walk mode problem causing player to be stuck in place after selling car
* Added proper monetary value display to car shop sell menu
* Fixed walk mode integration for various UI menus
* Starting new race no longer allowed while police chase is active

### 1.2
* Added new jump and speed trap challenges
* Added new delivery missions
* Added career backup system with UI buttons to save and load
* Added traffic risk and police strictness options
* Fixed groundmarker system staying active after career reset
* Fixed problem with towing flowgraph staying active after tow
* Fixed car shop randomly placing player in traffic vehicles
* Improved challenge & mission loading process for easier modding

### 1.3
* Added part prices from jbeam files to part shop
* Added part names from jbeam files to part shop & garage
* Added sleep & heal button time setting in options menu
* Added and improved part shop & garage categories
* Improved part shop and garage search function
* Part shop now shows all parts for vehicle not just current slots
* Fixed mission completion button staying active for next mission
* Fixed stutters caused by triggers sending UI data when not needed
* Part shop and garage UI now indicate currently installed part
* Vehicle sell price now based on installed parts
* Part shop indicates part compatibility with warning symbol and yellow slot name
* Part shop now showing proper slot names
* Garage UI updated to show current part & remove button seamlessly in list
* Tweaked race and mission rewards to better fit new part prices

### 1.4
* Added new races to the offroad race club
* Tweaked existing offroad race club race files
* Updated car file format to fix issue with selling & scrapping
* Fixed walk mode issues with bus ride and garage
* Updated fix for car shop and garage placing player in traffic

### 1.5
* Added time limit based daredevil challenges 
* Added custom UI layout
* Added new scrapyard vehicle shop
* Added race and challenge UI app checkpoints, laps & time
* Tweaked race rewards balance
* Buying parts now possible from garages
* Fixed buttons being clicked during time skip causing issues
* Challenges can now toggle traffic on or off
* Challenges can now use shared RNG roll for rewards & targets
* Races and Challenges now show traffic parameter in description

### 1.5.1 (BeamNG Update 0.27 Hotfix)
* Fixed sound effects not playing due to 0.27 update
* Fixed police parameters not working due to 0.27 update
* Fixed used cars with incorrect odometer ranges 
* Slight changes to cost and odometer ranges for some shop cars
* Increased injury G force threshold and tweaked injury scaling
