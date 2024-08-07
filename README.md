
[latest]: https://github.com/r3eckon/BNG-BeamLegalRacing/releases/download/1.15.4/beamLegalRacing1.15.4.zip
[userfolder]: https://documentation.beamng.com/support/userfolder/

# Beam Legal Racing 1.15.4
BeamLR is a persistent career BeamNG mod inspired by SLRR aiming to bring hardcore game mechanics to BeamNG such as external and mechanical damage persistence, money, paying for repairs, player health and injuries with fatal crashes resetting your save file, etc. The mod adds interaction to the sandbox with gas stations, repair shops, in world vehicle store system, dynamic race events, enabled traffic and more to achieve a sandbox career experience. 

Perform missions, races and challenges to earn money to buy vehicles and parts. Drive carefully as repairs can be quite costly and a hard enough crash could mean game over!

## Quick Links
### More Info | [Forum thread](https://www.beamng.com/threads/87394/) 

### Career Maps | [Utah](utahmap.md) | [East Coast](eastcoastmap.md) | [Italy](italymap.md) | [West Coast](westcoastmap.md)

### Track Event Maps | [Hirochi Raceway](hirochimap.md) | [Automation Test Track](automationmap.md) | [Johnson Valley](map_johnson.md) | [Nordschleife](map_ks_nord.md)

### [Addons](Addons) | [Nordschleife](Addons/ks_nord) | [Part Images](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main/Addons/Part%20Images)

### Enjoying the mod and looking to support the project? [Donate here!](https://www.paypal.com/donate/?hosted_button_id=QQ7SKC6XK7PAE)

### Having issues with the mod? [Please follow this troubleshooting guide.](troubleshooting.md)

## Install Instructions
**BeamLR cannot be installed like a normal mod due to data persistence issues when zipped**. 

Carefully follow the instructions to ensure all features are working properly:
* [Download the latest release][latest].
* Extract zip file contents directly to your [BeamNG userfolder][userfolder].
* Tell your operating system to replace existing files if asked.

**After installing check the *Read Before Playing* section of this readme for important information and a quick overview of major update features.**

**Installing BeamLR may overwrite custom changes made to levels.** 
Modders should back up the userfolder before installing.

## Update Instructions
**BEFORE UPDATING**:  Back up the userfolder/beamLR folder to archive your career
* [Download the latest release][latest].
* Extract updated mod zip contents to the [BeamNG userfolder][userfolder].
* Tell OS to replace existing files when asked. **This will apply the update.**
* Use the BeamLR options menu to restore your backup.

**Remember to update your addons if you have any installed!**

If the backup system fails to work properly you can manually replace the following files/folders using your backed up beamLR folder:

* beamLR/beamstate                                    (External and mechanical damage)
* beamLR/garage                                       (Garage vehicle data & config)
* beamLR/mainData                                     (Main career data file for money,rep,etc)
* beamLR/shop/daydata                                 (Vehicle shop daily data, aka bought slots)
* beamLR/races/INSERT RACE CLUB/progress              (Race club progress, repeat for each club)
* beamLR/currentTrackEvent                            (Current track event progress)
* beamLR/partInv                                      (Part inventory)
* beamLR/itemInventory                                (Item inventory)
* beamLR/options                                      (User settings)

**After updating check the *Read Before Playing* section of this readme for important information and a quick overview of major update features**

If you are experiencing issues after updating the mod, try a **clean** userfolder install and copy over your backup.

## BeamNG Update Userfolder Migration Process

With major updates to BeamNG a new userfolder is created. Not all BeamLR files are automatically migrated.

It is recommended to do a fresh install of BeamLR in the new userfolder before moving your career files.

To restore your career use the process for a normal mod update after installing in the new userfolder.

The game will give you a chance to view the contents of your old userfolder containing career files on first launch after updating so don't worry about steam update deleting your save.


## Read Before Playing
This mod requires specific gameplay options to work properly. As of version 1.11 the mod will automatically set the following gameplay options when you start playing for best experience:

![settings](https://i.imgur.com/ZIor6iw.png)

**Do not change the above settings while playing BeamLR**. The settings should be automatically restored to your previous values when you abandon the scenario. Keep in mind game crashes and other forceful exit from the scenario may prevent your old setting from being restored.

**IMPORTANT**: You must abandon the scenario to properly save your progress. Do not exit the game from main menu until you have abandonned the scenario and are back in freeroam. ALT-F4 or other forceful exit from the game are likely to cause lost progress and/or corrupted save files. Copy the **userfolder/beamLR** folder somewhere if you want to manually backup your career files.

BeamLR relies on a UI app and custom UI layout in order to access features such as:
* Options Menu
* Part Edit Menu
* Part Shop Menu
* Tuning Menu
* Paint Edit Menu

Since version 1.5 there is no setup required for the UI to work. The "BeamLR" layout should now be loaded on scenario start. Any changes made to this UI layout will be reflected when playing BeamLR in case the default layout doesn't fit on your screen.

First time players: the imgui unit detection feature may fail to properly register your unit setting. Switching between metric and imperial fixes this issue. The UI will then show correct units.

### Major Feature Update Overview

Version 1.6 adds N2O tank persistence. Garage files from previous versions are missing this value and will default to empty N2O tanks. Nitrous tanks can be refilled at the repair shop.

Version 1.8 adds difficulty settings and different start vehicles (randomly picked using seed), the default difficulty is medium ($1000 start money). 

Version 1.9.1 temporarily disables beamstate loading (visual damage) due to issue with advanced couplers. It can be turned back on from the options menu. If you decide to use beamstates, advanced couplers can be fixed from the options menu. This is not a guaranteed fix and it may crash the game.

Version 1.10 adds race track events to the mod which can be joined from career mode. Track events work using a different lightweight loader mission and work differently than regular career.  This version also adds a bunch of QoL improvements to the UI, saving/loading configs for your vehicles. Backups are now saved automatically when you stop the mission to ensure all files are updated before a backup is saved.

Version 1.11 adds new trailer deliveries, RNG based pink slips and various new restrictions relating to time of day. Car shops are now closed at night while new "high stakes" race clubs are only available at night. This version also adds a new death screen UI allowing you to immediately reload your last backup.

Version 1.12 adds Italy map content, Soliad Lansdale in shops, traffic and opponents, various improvements relating to ease of modding as well as the first addon to the mod which adds support for track events on the Nürburgring Nordschleife mod map.

Version 1.13 adds advanced vehicle building, advanced repair cost calculation, a GPS system and gooseneck trailer deliveries. Make sure you read the [Advanced Vehicle Building](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#advanced-vehicle-building) section of this readme before playing after installing this update.

Version 1.14 adds West Coast USA map content, part specific repairs, improved UX for the options menu and layout options for IMGUI menus as well as options to force enable/disable traffic in races, groundmarkers and floating markers. Make sure you read the [Part Specific Repairs](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#part-specific-repairs) section of this readme to get a grasp on this new feature.

Version 1.14.1 adds smooth refueling, instant traffic toggling and dynamic gas station displays linked with randomly generated gas price. Instant traffic toggling removes lag caused by spawning traffic after races and challenges that disable it but will reduce traffic diversity by keeping the same vehicle pool and may reduce expected performance with disabled traffic on systems with low RAM as it prevents freeing up memory while traffic is disabled.

Version 1.14.2 adds improved fuel system (fuel tiers, diesel) and a safe mode option for part edits used to prevent damage when removing certain parts. Read the [Improved Fuel System](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#improved-fuel-system) and [Part Edit Safe Mode](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#part-edit-safe-mode) section of this readme for more information on these new features. As always make sure to manually back up your current beamLR folder in case the fuel system changes cause issues with your old career files.

Version 1.14.3 adds part images (see [addon](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main/Addons/Part%20Images)) and a rep & reward scaling option.

Version 1.15 adds walk mode integration, consumable item inventory system, oil value persistence, slow oil leaks for high odometer vehicles, ability to tow to specific locations and "The Race of Heroes" endgame track event. See [improved oil system](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#improved-oil-system) and [consumable item inventory](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#consumable-item-inventory) for more information.

Version 1.15.4 adds dynamic weather controlled from options menu (cloud cover, wind speed & fog density slowly change) and restored the injury system that was disabled in a previous update. Injury is disabled by default and must be enabled through the options menu. BeamNG G force sensors are still buggy, use the injury system at your own risk!

Further instructions and various tips on this mods' various features are listed in the BeamLR UI Main Menu.

## Getting started
BeamLR is loaded as a freeroam mission. Use the following spawn point depending on map choice:

* Utah: **Auto Repair Zone**
* East Coast: **Gas Station Parking Lot**
* Italy: **BeamLR Spawn**
* West Coast: **BeamLR Spawn**

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

Version 1.11 updated delivery mission system works using a set of items and destinations. Each destination has a base reward that is scaled to give up to 100% bonus depending on item fragility. Experiencing more Gs than the item can endure will fail the mission. If your vehicle has a tow hitch you can accept trailer delivery missions. 

![race clubs](https://i.imgur.com/yPLsjIc.png)

Race club opponents are sorted into performance leagues of **Bronze**, **Silver**, **Gold** and **Hero**. You must complete every race in a league to progress to the next league. Opponent vehicle performance and wager values will increase as you progress through leagues.

The **Hero** league has no progression and can be used for endless races against max performance opponents.

Some races have pink slips instead of monetary wagers. Some races have enabled traffic while others don't. Make sure to check race parameters before accepting to know what you're getting into. 

Since version 1.8 you can use the options menu to set a wager target for races. If your bet is outside of opponent range the final race wager will be capped to the opponent min/max.

Since version 1.11 races have chance based pink slips opponents. All races have a low chance of having a pink slips bet. The chance of getting a pink slips race decreases with increasing leagues. High stakes night only race clubs have the highest chance of pink slips being offered.

You can spend money on part upgrades or new vehicles by visiting the various shops. Vehicles can also be sold at vehicle shops, sale price will depend on vehicle condition, added parts and player reputation. 

Since version 1.8 part shops offer different price scale percentages that changes daily. This percentage is indicated in the title for the part buying menu. Buying parts outside part shops (player & repair garages) is considered a remote purchase and has a 150% price scale applied, also indicated in the title. Different part shops can offer different ranges of price scales.

To repair your vehicle you must visit a repair garage or call a mechanic to your garage (+100% cost).

The towing button will teleport your vehicle to the player garage for a cost. 

Use the top menu to access part shop, part edit, painting and tuning interface.

You can back up, restore and reset your career at any time using the options menu.

BeamLR relies on seeded RNG for various aspects of the mod such as selected start vehicle, available shop vehicles and price fluctuations. Since version 1.8 by default when your career is reset the seed value will be incremented by 1 to get a different career every time you reset. Current career seed is indicated in the options menu. If you want to replay the same seed you can turn off auto increment. Setting a custom or random seed also disables the increment feature. 

Keep an eye out for you health value! There is a slow passive health regeneration but you can also restore your health by using the "Sleep / Heal" button. This fast forward function can also be used to skip ahead to next day which will get vehicle shops to spawn new vehicles, prices for gas stations and part shops will also change. 

When the in game day changes since version 1.8 a small amount of reputation (25 points) is lost. Rep can be gained with races and challenges so this feature acts as a small daily cost to prevent skipping ahead a lot of days without racing. 

## Track Events
Once you have earned enough reputation and money you may enter race track events which are multi round, multi opponent races.

Keep in mind this is the first iteration of this system, some features may change and more events will be added in future versions.

Race events work using a lightweight event loader flowgraph project. They work a bit differently than regular career: 

* Regular health is disabled
* Fatal crashes are still possible at higher needed G force
* Vehicle damage does not carry over to and from career
* Repairs and refuels are free but do not carry over to career
* Vehicle must be fully repaired and pass event inspection before joining
* Vehicle used for current event cannot be sold, scrapped or edited

Event inspection requirements can involve performance class, powertrain layout, induction type, vehicle brand and model.

Track events can be started from their respective level (see maps for mission loader location).

Once a round is started it cannot be restarted. Giving up a round comes with a heavy time penalty. If you crash, some tracks have a pit lane allowing for repair and refuel to tuning fuel load.

Time penalties will be added for shortcuts and pit lane overspeed. Penalty time is added to total time at round end. 

Race leaderboard is sorted by smallest total time at the end of each event.

Events usually reward 1st, 2nd and 3rd position money and rep. More special rewards can go to 1st position. 

Opponent names are randomly selected from the **beamLR/opnames** file which can be edited with custom names. 

Track events use randomized parameters for replayability, such as opponent config choice and count, time of day, lap and round count as well as rewards.

Each event has a unique seed which changes daily and after event completion. Sleep to next day to refresh event parameters.

Track event modding is possible using a similar process to regular race clubs. Event files can be added and modified to have different parameters. 

This system will be used in a future version to create a final boss type race like SLRR.

As of version 1.12 mod levels are now supported for track events. Events for maps you do not have installed will not be offered in the browser. You must also install the **addon** for a specific map otherwise events will not work properly.

### The Race of Heroes
Version 1.15 adds a SLRR "Race of Champions" inspired endgame track event called "The Race of Heroes". This event takes place on the Johnson Valley  map and requires the player to have completed every other race club in the game (completion means "Hero" league has been reached). The race is point based unlike time based events and is against the same opponent using a different vehicle each round. Winning this event basically means the player has beat the mod and rewards a large sum of money, rep as well as a supercar.


## Advanced Vehicle Building
### NOTE: As of version 1.14 advanced vehicle building is enabled by default.
Added in version 1.13, advanced vehicle building (AVB) allows for a more realistic or SLRR-like vehicle building experience. Jbeam loading scripts have been modified to remove all slot defaults, which for instance makes it so  wheels spawn without tires, pickup bed spawns without tailgate, taillights or bed accessory. Sub-parts must therefore be purchased and added manually. 

When AVB is enabled, removing a part will add all attached sub-parts to your inventory. It will also be possible to sell parts at a scaled down value compared to purchase cost. Part selling is disabled when playing without AVB due to the fact that slot defaults could be used as infinite money exploit.

This feature is not recommended for casual players as it can make part edits more complex and confusing. For example, engine swaps can be frustrating because a single missing part can prevent your vehicle from moving. If this happens, make sure you added all drivetrain related parts (transmission, driveshaft, halfshafts, etc) some of which may not be located under the 'Engine' category of the part edit menu.

BeamNG is not built to fully handle this type of feature. Engines will still be running even when missing important parts like the oil pan, intake, exhaust manifold, long block or ECU. If you experience issues with vehicles missing parts in freeroam after force exiting from BeamLR, restarting the game should fix it.

## Advanced Repair Cost Calculation
### NOTE: As of version 1.14 Advanced repair cost calculation is enabled by default.

Added in version 1.13, advanced repair cost calculation makes use of broken/deformed beams specific to each part on the vehicle to detect 'ruined' parts and add their actual cost to the repair value of the vehicle. This results in a more realistic and accurate representation of vehicle damage. 

Since repair cost becomes related to vehicle part value, repair costs will be higher especially for high end vehicles like the scintilla or vehicles using costly parts. Race wagers have been increased to help balance this change.

## Part Specific Repairs
Added in version 1.14 part specific repairs adds a menu allowing players to choose which parts to repair. Damaged parts that aren't repaired will be removed from the vehicle config and **will not be added to inventory**. Some parts must be repaired such as mechanical damage and the vehicle 'main' part and cannot be deselected. To repair a sub-part, damaged parent parts must be repaired and will be force selected if an attached sub-part is selected for repair. Undamaged sub-parts removed by a damaged parent part will be added to the part inventory. When repairing your vehicle from the player garage an on-site mechanic fee is added to the repair cost.

## GPS System
Added in version 1.13 is a new GPS system that allows you to find specific destinations or nearest destinations of certain types like gas stations, vehicle shops, repair garages, part shops, etc. By default, the GPS UI will only show when using a vehicle that has a GPS (BeamNavigator) installed. It is also possible to force enable or disable the GPS UI through the options menu. Regardless of chosen setting, the GPS UI will be disabled in some situations where groundmarkers are required, such as during delivery missions and daredevil challenges.

## Improved Fuel System
Added in version 1.14.2 the improved fuel system now features diesel fuel and gasoline tiers which give slight performance boost to vehicles. Diesel fuel must now be used with diesel engines. Using the incorrect fuel type will disable the engine until the tank is drained. Draining the tank will allow you to add the correct fuel and start the engine again. Gasoline quality is calculated based on ratio of each fuel tier in the tank, higher quality will slightly increase the vehicle output torque. The maximum increase for each tier (for a fuel tank containing only this tier) is as follows:
* Premium: 20%
* Mid-Grade: 10%
* Regular: 0%

For example, if a fuel tank contains a 50/50 mix of premium and mid-grade the increase is 15%. For a mix of regular and mid-grade, the increase is 5%. If a fuel tank contains only premium grade, the increase is 20%. While not realistic, BeamNG does not have fuel octane ratings for engines and side effects of incorrect fuel being used, so this is a compromise to give a purpose to higher fuel tiers that makes sense for a racing game. If BeamNG eventually adds this feature the fuel system will be changed to implement fuel tiers in a more realistic way.

## Part Edit Safe Mode
Added in version 1.14.2 part edit safe mode is a new advanced option used to help prevent damage during part edits. Certain parts may cause damage when removed, for instance wheels, which cause the vehicle to fall and damage the bumper. This option will temporarily increase beam strength to help prevent taking damage. While in safe mode, the vehicle will be frozen in place. To unfreeze the vehicle you must exit safe mode, at which point the game will reload the normal beam strength values. This option can be kept off for the vast majority of part edits but should help with certain edits that tend to cause damage.

## Walk Mode Integration
Walk mode is now integrated with certain mod features as of version 1.15 allowing you to exit your own vehicle, to interact with the controls of gooseneck trailers, to interact with shop vehicles (which will properly reflect currently entered vehicle details in UI) and to access a new consumable item shop at gas stations.

## Consumable Item Inventory
Added in version 1.15 is a new inventory system for "consumable" type items. The first iteration of this system comes with two consumable items: fuel canisters and oil bottles. Both can be used to refill your vehicle in an emergency. Items can be purchased by walking at a gas station ("convenience store" menu). Gas canisters can contain gasoline or diesel and like regular gas station refuelling using the incorrect fuel type will disable the engine. 

## Improved Oil System
Added in version 1.15 is an improved oil system that now saves oil value for your vehicles. This improved system also simulates a slow oil leak on vehicles with high odometer (above 100,000 km). The first iteration of this system is designed to leak all the oil in 2 hours for 100,000 km, 1 hour for 200,000 km and 30 minutes for 400,000 km. While this may not be realistic it is to give an incentive to upgrade to low mileage vehicles by having oil leak fully within the span of a play session. 

Breaking the oilpan will now require refilling the oil as the emptied out value is restored even after repairing. Refill bottles can be purchased at gas stations with the walk mode menu.


## WIP Notice
This mod is a work in progress. At this stage it is a decent vertical slice of the gameplay the project is trying to achieve with some bugs and quirks remaining that should get better as BeamNG and the mod are updated. That being said a lot of content is missing and reward values may be unbalanced relative to part prices.

Due to the nature of BeamNG some features available to players may break the experience when playing BeamLR, such as the circular menu, world editor and other UI apps. If playing seriously (not actively trying to break stuff) try avoiding features that aren't directly offered in UI menus from the mod. While I still appreciate bug reports related to said features, some of them simply can't be disabled and related issues won't be prioritized.

Beamstate is a very experimental BeamNG feature being used by this project for damage saving. If a vehicle suddenly breaks after being stored in good condition, the beamstate file got corrupted. Flowgraph has been added to detect and fix this, however it may not always work properly. You can fix this two ways: move your vehicle using the F11 world editor (will force a vehicle reset) or delete the vehicle beamstate file before launching the scenario to force a fresh vehicle beamstate. Beamstate also breaks Covet "advanced hinges" and may cause game crashes with the Scintilla.

## Final Word
Feedback and bug reports are appreciated! 

Thank you for playing BeamLR!

## Special thanks to donors!

* Luka Rupnik (fabio)
* Dimitriu Dragos-Alexandru (rapturereaperALEX)
* Bartosz Falba (enouqh)
* Mikołaj Bartosz Kuliński
* Gál Ádám (Buksikutya77)
* Petr Brůžek (NikdoNicNevi)
* Jukka-Pekka Tuppurainen
* Lauri Kabur
* Liam Wood (liamwood15)
* Benjamin Rogers (thisvelologist)
* Leon Makepeace
* Ethan Rapp
* Mattia Morris (Mattia83)
* Michael Mckinley
* Ecril
* Jude Thaddeus Persia

## Known Issues 

* As of BeamNG version 0.28 beamstate loading is broken. This is listed in known issues for the game and should hopefully be fixed soon.
* ~~Towing mechanic may repair your vehicle. This is due to problems with a teleport function that shouldn't cause a reset yet sometimes does.~~ Should be fixed as of version 1.10
* Some tuning configurations can cause unfair damage when a vehicle is loaded. A workaround is implemented but may fail to work in certain situations.
* ~~Various UI problems, input fields stop registering keystrokes, whole UI can refuse to work. Workaround is to keep cursor above input fields.~~ Seems fixed as of 1.11 if any issues arise try CTRL+F5.
* ~~Race checkpoints sometimes fail to trigger properly.~~ Should be fixed as of version 1.6
* ~~Beamstate file corruption breaking pristine vehicles. Workaround is implemented but may fail. Use world editor for repair or delete the corrupted beamstate file.~~ Seems fixed.
* ~~Player can get stuck in place while walking and trying to take bus home. Currently investigating this issue. Reload the mission to get unstuck.~~ Seems fixed.
* Pausing the game during part edits will reset your vehicle odometer. Try to make sure the game isn't paused when interacting with BeamLR features to prevent issues.
* ~~Health mechanic is temporarily removed due to vehicle "wiggle" after crashes causing erroneous high enough G forces to injure the player. Fatal crashes from a single high G impact are still enabled like track events.~~ As of version 1.15.4 the health mechanic has been re-introduced into the mod. This feature is disabled by default as G force sensors are still buggy and may lead to unfair deaths. Use at your own risk!


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

### 1.10
* Added race track event system and UI menus
* Added race track events on Hirochi Raceway and Automation Test Track
* Added vehicle config save and load menu
* Added time scale option
* Added new ETK800 & ETKC configs to shops & race clubs
* Further improved fuel related code (should now work with all vehicles)
* Increased race start parking markers length
* Using new towing code to fix free repair issue
* Fixed main menu layering issue
* Tuning menu now sorted by category & ordered alphabetically
* Part edit & part shop menu now ordered alphabetically
* Fixed rep loss happening on fast forward instead of daily
* Fixed paint loading issue introduced by 0.28 changes
* Race opponents now use nitrous and lights (lights only turned on during night)
* Now calculating G forces using airspeed to workaround erratic G forces
* Backup now happens automatically on mission abandon (ensures updated files)
* Fixed reset and backup load feature not restarting mission
* Delivery mission UI now uses confirmation requesting buttons
* Fixed bug when buying parts using default fallback price
* Some race clubs now using class system for simplified config loading

### 1.10.1
* Fixed backup saving process not clearing old backup data
* Fixed career reset from towing while moving (added speed check before tow)
* Disabled big map UI to remove fast travel
* Fixed missing slots in part shop and part edit
* Fixed rear struts missing from suspension part category
* Fixed automation induction specific track events using wrong data 
* Fixed race club league progress bug
* Hero league now shows completion message instead of 0/X progress

### 1.11
* Added trailer delivery missions
* Added night time race clubs to utah and east coast
* Added death screen UI (offers choice to reset career or reload save)
* Added SFX for various money related actions
* Updated delivery mission system (added random items & fragility)
* Pink slips races are now RNG based for all races
* Vehicle shops now closed at night (open from 8:00 to 16:00)
* Fixed deprecated pickup configs in perfclass files
* Garage UI buttons now disabled while car loads (fixes config saving issue)
* Fixed Update Current Day node error when event UID is nil
* Some race clubs are now only open during certain hours
* Fixed Gavril brand event using incorrect name
* Needed game options now automatically set (user options reloaded when stopping)
* Health mechanic temporarily removed due to body panel wiggle still causing injury
* Reverted to more accurate sensor G forces due to health being disabled
* Fixed mission IMGUI letting other windows appear during mission
* Removed track event tuning sliders that can change engine performance
* Fixed empty template folders remaining after garage car delete
* Fixed fast forward button skipping 2 days in some situations
* Now showing current day instead of health in stats window
* Fixed some track events using incorrect data
* Slightly reduced max amount of rounds for most track events
* Mechanical damage cost now based on linked parts values
* Fixed N2O check flowgraph node throwing error when vehicle has no engine

### 1.12
* Added Italy map content
* Added Soliad Lansdale to race clubs and shops
* Added new simple traffic configs to traffic spawn group
* Added pink slips blacklist (no pink slips for fancy vehicles unless player has one)
* Added Nürburgring Nordschleife Track Events (ks_nord_v20230416)
* Improved mission files and items loading process using list files
* Fixed mouse input not registering on bottom of performance class app
* Slight increase in maximum tolerable G forces
* Car shop files now using list files for models
* Randomized parts now controlled with shop specific chance
* Shop cars without random parts now spawn with factory paints
* Fixed paint mismatch with pink slips and shops on some vehicles
* Trying fix for walk mode stuck in place after selling vehicle
* Drift challenge now adds current drift to total score on completion
* Fixed hours not showing in race event leaderboard times
* Fixed stuck walk mode after exiting car shop buy mode
* Fixed time scale reset after fast forward (sleep)
* Fixed day change detection not working properly with fast time scale
* Increased upper reward limit for most challenges
* Improved level mod compatibility for track event browser (only shows installed maps)

### 1.12.1 
* Added GP circuit layout for Nürburgring track event map
* Added donors special thanks to main menu
* Updated level files for BeamNG 0.30 update
* Fixed track event bug causing incorrect join state in UI

### 1.12.2
* Fixed missing airport gas station prefab on italy
### 1.13
* Added "Advanced Vehicle Building" option (more realistic/SLRR like part edits)
* Added part selling feature (enabled when using Advanced Vehicle Building)
* Added "Advanced Repair Cost" option (more realistic, uses part specific values)
* Added police Lansdale to US police spawn group
* Added map specific traffic spawn goups (European police on italy)
* Added new tow hitch trailer types to delivery missions
* Added optional weight based reward scaling field to delivery items
* Added gooseneck trailer deliveries
* Added GPS feature (default GPS mode shows UI if vehicle has GPS installed)
* Trying fix for stuck walk mode after loading into scenario
* Fixed Buy Parts and Edit Car menu empty when loading car in walk mode
* Garage & Part Shop triggers no longer cause lag spike when entered
* Abandoning track event scenario when race is in progress now ends round
* Fixed trailer G force calculation not counting gravity
* Fixed wheel hubs slot missing from wheel category
* Fixed paint setting not working with roughness,metallic,etc. parameters
* Fixed incorrect centerlug wheel defaults for covet & midsize with custom jbeam files
* Part buying now shows message if player has not enough money
* Part edit and buying menu now shows internal part names with internal slot names
* Updated police ticket offense specific values
* Trailer missions now fail if trailer is damaged (uses g force based damage for now)
* Updated delivery UI for trailer damage & meters now colored red close to failure val
* Mission failure now has rep penalty specific to mission type
* Removed "Not Enough Money" message from empty car shop slots
* Abandon request now checks for car shop browsing to prevent car files corruption
* Improved tow hitch check for Advanced Vehicle Building (pickup receiver comes empty)
* Increased race wagers to better balance with delivery missions & advanced repair cost calc
* Increased target wager slider max value to $10000

### 1.14
* Added West Coast USA map content
* Added race file parameters for looping subsection
* Added IMGUI scaling and layout persistence options
* Added dragstrip implementation for West Coast (start lights, time & speed, slowmo)
* Added option to hide floating markers and groundmarkers (gps arrows)
* Added option to force enable or disable traffic in races
* Added Advanced Repair Menu (part specific repairs when using Advanced Repair Cost)
* Fixed issues and updated level files for BeamNG 0.31 update
* Updated offense cost for failure to stop at intersection
* Increased battlehawk bastion cost (was incorrectly using base model cost)
* Fixed UI not using default value for missing part sell value
* Fixed advanced repair cost option not loading on scenario start
* Fixed incorrect rep reward and opponent integrity for some east coast races
* Looping race wagers are now linked to lap count
* Fixed empty mission giver window appearing at part shop
* Fixed config loading & paint edit available outside garage & with damaged car
* Removed sub-parts now added to inventory even when advanced vehicle building is off
* Improved UX for the options menu (current values and toggle states now shown)
* Moved player name to options file & removed dedicated playername file
* Fixed sorted part names conflicting with search results (ex: wheel size search)
* Race file traffic parameter now works as percent chance to use traffic
* Race menu now shows opponent vehicle name and brand from jbeam info file
* Improved trigger system to work with multi-trigger interactive areas
* Fixed part search function to find currently used parts
* Disabled remove button for vehicle main part (bugs game when removed)
* Fixed race club league bug when claiming rewards inside a different club trigger
* Updated truck traffic spawn group to use configs added in 0.31 
* Some hero leagues now have 50% chance of using traffic
* Replaced bolide 350usdm config for gold race club with amateur racing config
* Reduced "call mechanic" fee from 200% to 150% of total repair cost
* Removed caravans from trailer item list for construction basement mission

### 1.14.1
* Added smooth refueling mechanic & new gas station sound effects
* Added Instant Traffic Toggle option (removes lag when spawning traffic after race)
* Added Manual Traffic Toggle to options menu
* Added dynamic gas station display implementation (only works on west coast for now)
* Modified "Play Sound" flowgraph node to allow stopping looping sounds
* Fixed game wide T-series coupler issue due to outdated beamstate.lua script
* Fixed repair cost not using saved minimum value with enabled advanced repair cost
* Updated ks_nord addon mod version to v20231124_v2
* Fixed west coast scrapyard missing data

### 1.14.2
* Added improved fuel system (fuel tiers, diesel, wrong fuel type disables engine)
* Added part edit safe mode (prevents taking damage during part edits)
* Fixed config loading function using partmgmt.load (renamed to partmgmt.loadLocal)
* Fixed missing waypoints on East Coast
* Fixed missions in incorrect list on West Coast
* Fixed part selling with missing jbeam value causing $nan player money
* Fixed track events not loading due to removed playername file
* Fixed GPS Select Destination menu empty list data due to duplicate names
* Trying fix for player garage menu not visible after towing
* Fixed police tickets while walking (no cost to pay & removed impound button)
* Decreased part sell value from 50% to 20% of buy value

### 1.14.3
* Added part images for most vanilla vehicles (see new addon)
* Added part image preview UI app & options (click thumbnail to view full size)
* Added race wager & rep reward scaling options
* Updated part edit & buy UI to load part image overrides for some vehicles
* Fixed player not frozen during track event countdown
* Mission cleanup node now resets blrflags to avoid issues
* Fixed map.objects not containing vehicle in some situations 
* Fixed errors when loading mechanical damage & odometer of missing devices
* Wheel damage loading should now work with non 4 wheel vehicles
* Trying fixes for performance UI showing NaN values
* Fixed part edit & buy menu layout breaking due to missing slot names
* Fixed bug causing target wager option not to work
* Fixed missing script for part edit safe mode

### 1.15
* Added "Race of Heroes" endgame track event on Johnson Valley
* Added different tow locations (gas station, garage, used car shop, part shop)
* Added walk mode integration (freely exit car, immersive car shop, gas station)
* Added item inventory system (accessed using new BeamLR Main Menu page)
* Added fuel canisters item (bought at gas station while walking)
* Added oil systems (saved quantity, leaks at high odometer, oil bottle item to fill)
* Added "Teleport To Start" button in track event UI
* Fixed engine not disabled after removing fuel tank part (check loops over tanks)
* Fixed condition checking part count before removing from inventory
* Track event list now sorted by rep required (also sorted by name at same rep values)
* Lowered rep required for Automation Drag Class X event (from 25k to 15k)
* Updated modified lua/vehicle/jbeam/stage2.lua with 0.32 edits
* Updated modified lua/vehicle/beamstate.lua with 0.32 edits
* Replaced all "coupe" configs with remastered BX-series (shops, traffic, opponents)
* Updated traffic spawngroups with new simple traffic configs
* Updated WCUSA concrete plant delivery mission for 0.32 edits
* Updated part images addon with BX-Series parts
* Updated track event mission file to work with point based leaderboard system
* Fixed incorrect orbit cam initial angle in car shops (caused by 0.32 edits)
* Updated gps detection system for new gps_alt slot (used in BX-Series)
* Temporary fix for audio "blur" effect bug in 0.32
* Fixed incorrect default value for IMGUI scale

### 1.15.1
* Fixed item inventory not cleared after career reset
* Fixed game crash when trying to pull out car from garage from walk mode
* Fixed garage saving incorrect AVB config when walking
* Fixed garage not saving fuel, oil, nos, etc. values when walking
* Fixed item inventory not loading oil bottles from save file

### 1.15.2
* Fixed West Coast USA issues (old decals, garage trigger name change)
* Fixed vehicle scrapping not deleting vehicle when not walking
* Fixed options menu not reloading current seed during UI init
* Fixed item inventory not saved during career backup

### 1.15.3
* Added custom timer UI app to fix vanilla app (clock & race modes, lap & delta time)
* Fixed waypoint & AI roads issues for some WCUSA race files
* Fixed checkpoint & lap counter UI apps not appearing
* Trying fix for delayed updatevehid function error (be:getPlayerVehicle(0) is nil) 
* Fixed "Set UI Timer" fg node stuck at 0 after first lap (using BLR modified version)
* Fixed jbeam table causing issue with slotType field on BX-Series
* Fixed AI pathing issues on Utah near ranger cabin
* Fixed vanilla traffic script collision bug (added edited script to userfolder lua)
* Used car shop random parts now avoids cargo boxes (caused issues with rollcage)

### 1.15.4
* Added dynamic weather system (Cloud cover, wind speed & fog slowly change over time)
* Added injury screen effect (red corners on impact or health below 50%)
* Fixed clock timer not updating fast enough with increased time scale
* Restored health/injury system (off by default, can be turned on in options)
* Fixed used car shop random slots bug due to missing BX-Series underglow 
