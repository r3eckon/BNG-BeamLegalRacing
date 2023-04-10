
# Beam Legal Racing 1.9.1
BeamLR is a persistent career BeamNG mod inspired by SLRR aiming to bring hardcore game mechanics to BeamNG such as external and mechanical damage persistence, money, paying for repairs, player health and injuries with fatal crashes resetting your save file, etc. The mod adds interaction to the sandbox with gas stations, repair shops, in world vehicle store system, dynamic race events, enabled traffic and more to achieve a sandbox career experience. 

Perform missions, races and challenges to earn money to buy vehicles and parts. Drive carefully as repairs can be quite costly and a hard enough crash could mean game over!

## Quick Links
### [Forum thread](https://www.beamng.com/threads/87394/) | [Utah Map](utahmap.md) | [East Coast Map](eastcoastmap.md)

## Install Instructions
**BeamLR cannot be installed like a normal mod due to data persistence issues when zipped**. 

Carefully follow the instructions to ensure all features are working properly:
* Download the latest zip file from the **Releases** folder.
* Extract zip file contents directly to your [BeamNG userfolder](https://documentation.beamng.com/support/userfolder/).
* Tell your operating system to replace existing files if asked.

**Installing BeamLR may overwrite custom changes made to levels.** 
Modders should back up the userfolder before installing.

## Update Instructions
**BEFORE UPDATING**:  Back up your userfolder/beamLR folder to save your career
* Download the latest zip file from the **Releases** folder.
* Use the BeamLR options menu to back up your career.
* Extract updated mod zip contents to the userfolder. 
* Tell OS to replace existing files when asked. **This will apply the update.**
* Use the BeamLR options menu to restore your backup.

If the backup system fails to work properly you can manually replace the following files/folders using your backed up beamLR folder:

* beamLR/beamstate                                    (External and mechanical damage)
* beamLR/garage                                       (Garage vehicle data & config)
* beamLR/mainData                                     (Main career data file for money,rep,etc)
* beamLR/shop/daydata                                 (Vehicle shop daily data, aka bought slots)
* beamLR/races/INSERT RACE CLUB/progress              (Race club progress, repeat for each club)

If you are experiencing issues after updating the mod, try a **clean** userfolder install and copy over your backup.

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

Since version 1.5 there is no setup required for the UI to work. The "BeamLR" layout should now be loaded on scenario start. Any changes made to this UI layout will be reflected when playing BeamLR in case the default layout doesn't fit on your screen.

First time players: the imgui unit detection feature may fail to properly register your unit setting. Switching between metric and imperial fixes this issue. The UI will then show correct units.

Remember to save the **userfolder/beamLR** folder if you want to backup your career! The scenario has no autosave feature. Abandon the scenario and wait until you are back in freeroam before closing the game to ensure all progress is saved. Game crashes or hard quit may result in lost progress.

Version 1.6 adds N2O tank persistence. Garage files from previous versions are missing this value and will default to empty N2O tanks. Nitrous tanks can be refilled at the repair shop.

Version 1.8 adds difficulty settings and different start vehicles (randomly picked using seed), the default difficulty is medium ($1000 start money). 

Version 1.9.1 temporarily disables beamstate loading (visual damage) due to issue with advanced couplers. It can be turned back on from the options menu.

If you decide to use beamstates, advanced couplers can be fixed from the options menu. This is not a guaranteed fix and it may crash the game.

Further instructions and various tips on this mods' various features are listed in the BeamLR UI Main Menu.

## Getting started
BeamLR is loaded as a freeroam mission. Use the following spawn point depending on map choice:

* Utah Spawn: **Auto Repair Zone**
* East Coast Spawn: **Gas Station Parking Lot**

Drive into the BeamLR Career mission marker and use the UI to start the mission.

![mission marker](https://i.imgur.com/uSx4849.png)

The scenario will load your last used vehicle and spawn traffic. 

**Be patient while the scenario is loading** especially if using lots of traffic. 

Once in the scenario floating markers indicate interactive areas for the player garage, repair shop, gas stations, race clubs, part shops, etc. 

![part shop marker](https://i.imgur.com/84A5emi.png)

Purchased or won vehicles are sent to your player garage. You can also scrap vehicles for some money using the player garage menu.

Depending on your chosen difficulty setting (default is medium) you may need to perform delivery missions from part shops before you have enough money to wager in races or challenges. Amount of money depending on start difficulty goes as follows:
* Easy: $5000
* Medium: $1000
* Hard: $20

![race clubs](https://i.imgur.com/yPLsjIc.png)

Race club opponents are sorted into performance leagues of **Bronze**, **Silver**, **Gold** and **Hero**. You must complete every race in a league to progress to the next league. Opponent vehicle performance and wager values will increase as you progress through leagues.

The **Hero** league has no progression and can be used for endless races against max performance opponents.

Some races have pink slips instead of monetary wagers. Some races have enabled traffic while others don't. Make sure to check race parameters before accepting to know what you're getting into. 

Since version 1.8 you can use the options menu to set a wager target for races. If your bet is outside of opponent range the final race wager will be capped to the opponent min/max.

You can spend money on part upgrades or new vehicles by visiting the various shops. Vehicles can also be sold at vehicle shops, sale price will depend on vehicle condition, added parts and player reputation. 

Since version 1.8 part shops offer different price scale percentages that changes daily. This percentage is indicated in the title for the part buying menu. Buying parts outside part shops (player & repair garages) is considered a remote purchase and has a 150% price scale applied, also indicated in the title. Different part shops can offer different ranges of price scales.

To repair your vehicle you must visit a repair garage or call a mechanic to your garage (+100% cost).

The towing button will teleport your vehicle to the player garage for a cost (may repair vehicle due to bug). 

Use the top menu to access part shop, part edit, painting and tuning interface.

You can back up, restore and reset your career at any time using the options menu.

BeamLR relies on seeded RNG for various aspects of the mod such as selected start vehicle, available shop vehicles and price fluctuations. Since version 1.8 by default when your career is reset the seed value will be incremented by 1 to get a different career every time you reset. Current career seed is indicated in the options menu. If you want to replay the same seed you can turn off auto increment. Setting a custom or random seed also disables the increment feature. 

Keep an eye out for you health value! There is a slow passive health regeneration but you can also restore your health by using the "Sleep / Heal" button. This fast forward function can also be used to skip ahead to next day which will get vehicle shops to spawn new vehicles, prices for gas stations and part shops will also change. 

When the in game day changes since version 1.8 a small amount of reputation (25 points) is lost. For now reputation isn't used for anything except vehicle sell price scaling. It will be used in a future version to unlock official race track events and other unique events. Rep can easily be gained with races and challenges so this feature acts as a small daily cost to prevent skipping ahead a lot of days without racing. 


## WIP Notice
This mod is a work in progress. At this stage it is a decent vertical slice of the gameplay the project is trying to achieve with some bugs and quirks remaining that should get better as BeamNG and the mod are updated. That being said a lot of content is missing and reward values may be unbalanced relative to part prices.

Due to the nature of BeamNG some features available to players may break the experience when playing BeamLR, such as the circular menu, world editor and other UI apps. If playing seriously (not actively trying to break stuff) try avoiding features that aren't directly offered in UI menus from the mod. While I still appreciate bug reports related to said features, some of them simply can't be disabled and related issues won't be prioritized.

Beamstate is a very experimental BeamNG feature being used by this project for damage saving. If a vehicle suddenly breaks after being stored in good condition, the beamstate file got corrupted. Flowgraph has been added to detect and fix this, however it may not always work properly. You can fix this two ways: move your vehicle using the F11 world editor (will force a vehicle reset) or delete the vehicle beamstate file before launching the scenario to force a fresh vehicle beamstate. Beamstate also breaks Covet "advanced hinges" and may cause game crashes with the Scintilla.

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

### Money cheat
* Open beamLR/mainData with notepad.
* Add a bunch of 0s to your money value.
*  Save the file.
* Restart the scenario for changes to take effect.

### Adding new races

Brand new races are created by adding triggers to the map where you want checkpoints. The AI uses waypoints to define the race path, make sure waypoint path takes the AI through checkpoint triggers.

Race files also define opponent parameters like what vehicle and config to use, risk value, wager amounts, etc.

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

Since version 1.7 race files can contain a **waypoint speed** value list to set a target speed for the AI at a particular waypoint. This feature can be used to fix or refine AI behavior. For instance, adding brake zones at a spot where the AI keeps crashing due to high speeds.

Format for this list is **wpspd=WPNAME:SPEED,WPNAME:SPEED, ...** 

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

Start money can be customized, check the **beamLR/init** folder for the various start difficulties.

Mod vehicles *should* also work but beamstate loading is a very unstable feature so some may have issues. 

This remains untested and I will not focus on fixing issues related to other mods.

The flowgraph mission can also be tweaked, this is for advanced users only as it's very easy to break things.

Same things goes for LUA scripts.

## Final Word
Feedback and bug reports are appreciated! 

Thank you for playing BeamLR!

## Known Issues 

* Covet beamstate saving breaks advanced coupler beams, doors won't close, hood won't open. Current best workaround is to simply repair the vehicle. Scintilla beamstate can crash the game.
* Towing mechanic may repair your vehicle. This is due to problems with a teleport function that shouldn't cause a reset yet sometimes does.
* Some tuning configurations can cause unfair damage when a vehicle is loaded. A workaround is implemented but may fail to work in certain situations.
* Various UI problems, input fields stop registering keystrokes, whole UI can refuse to work. Workaround is to keep cursor above input fields. CTRL+F5 to fix the frozen UI.
* ~~Race checkpoints sometimes fail to trigger properly.~~ Should be fixed as of version 1.6
* Beamstate file corruption breaking pristine vehicles. Workaround is implemented but may fail. Use world editor for repair or delete the corrupted beamstate file.


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

### 1.6
* Added random paint option for race opponents
* Added passive healing mechanic
* Added reputation value to stats window
* Added custom onBeamNGTrigger hook to fix trigger problems
* Added missing device to mechanical damage loader
* Added N2O persistence and refill game mechanics
* Fixed shop menu bug with different slot counts
* Updated pink slips system to work with random paints
* Fixed race system occasionally showing incorrect league data
* Increased route speed parameter for race opponents
* Decreased remaining gas in career start vehicle
* Further increased wagers for some races
* Fixed integrity loading overwriting mechanical damage states

### 1.7
* Added East Coast map content
* Added optional wpSpeeds parameter to race files to improve AI
* Fixed node error when giving up race before AI spawned
* Increased selection of race opponent for some leagues
* Increased wager range for all races 
* Stats UI damage val replaced with repair cost

### 1.8 
* Added target wager slider option for races
* Added part UI slot toggle buttons
* Added randomized shop vehicle parts
* Added parking markers based race start system
* Added fuel capacity to stats display
* Added career difficulty setting (changes starting money, default is medium)
* Added different starting vehicles (randomly picked using seed)
* Added part shop specific daily price scale
* Added automatic seed increment option (adds 1 to seed value on career reset)
* Shop vehicles now entered by player (able to rev engine, turn wheels, etc) 
* Vehicle shops using game cam instead of static cam (defaults to orbit cam)
* Vehicle shops now add cone in empty slots (for orbit cam implementation)
* Improved part UI search function string matching process
* Fixed part shop & part edit UI staying available outside triggers
* Fixed missing scrapyard moonhawk car shop file
* Improved fuel handling to work with multiple tanks (mainTank,auxTank)
* Gas stations no longer charge for fuel that doesn't fit in vehicle
* Visual damage based repair cost value capped between $10 and $100k
* Fixed garage UI layout issues after part edit
* Part shop now shows owned part indicator with count
* Small amount of reputation is now lost daily
* Fixed part edit UI inventory data only updating on search/category button

### 1.9
* Added drift challenges
* Fixed police chase state bug with UI menus
* Fixed bug caused by pulling cars out of garage while towing
* Fixed interaction markers moving away from origin point
* Time of day settings should now resets after scenario end
* Fixed scrapyard moonhawk paint bug
* Some buttons will now ask for confirmation
* Fixed bugs causing police to keep chasing player after escape
* Disabled towing & sleep buttons during events
* Implemented workaround for beamstate damage cost changes
* Disabled quick access menu (radial menu)
* Fixed UI not resetting to freeroam after scenario end
* Removed missing apps from custom UI layout
* Improved car shop RNG seeding process

### 1.9.1 (BeamNG Update 0.28 Hotfix)
* Added beamstate loading toggle option (workaround for advanced coupler problem)
* Added button to attempt to fix hinges after beamstate loading (may crash game)
* Fixed traffic pooling amount calculation
* Updated level files for new BeamNG version