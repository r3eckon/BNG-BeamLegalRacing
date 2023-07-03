

# Beam Legal Racing 1.11
BeamLR is a persistent career BeamNG mod inspired by SLRR aiming to bring hardcore game mechanics to BeamNG such as external and mechanical damage persistence, money, paying for repairs, player health and injuries with fatal crashes resetting your save file, etc. The mod adds interaction to the sandbox with gas stations, repair shops, in world vehicle store system, dynamic race events, enabled traffic and more to achieve a sandbox career experience. 

Perform missions, races and challenges to earn money to buy vehicles and parts. Drive carefully as repairs can be quite costly and a hard enough crash could mean game over!

## Quick Links
### More Info [Forum thread](https://www.beamng.com/threads/87394/) 

### Career Maps [Utah](utahmap.md) | [East Coast](eastcoastmap.md)

### Track Event Maps [Hirochi Raceway](hirochimap.md) | [Automation Test Track](automationmap.md)

### Enjoying the mod and looking to support the project? [Donate here!](https://www.paypal.com/donate/?hosted_button_id=QQ7SKC6XK7PAE)

## Install Instructions
**BeamLR cannot be installed like a normal mod due to data persistence issues when zipped**. 

Carefully follow the instructions to ensure all features are working properly:
* Download the latest zip file from the **Releases** folder.
* Extract zip file contents directly to your [BeamNG userfolder](https://documentation.beamng.com/support/userfolder/).
* Tell your operating system to replace existing files if asked.

**After installing check the *Read Before Playing* section of this readme for important information and a quick overview of major update features**

**Installing BeamLR may overwrite custom changes made to levels.** 
Modders should back up the userfolder before installing.

## Update Instructions
**BEFORE UPDATING**:  Back up the userfolder/beamLR folder to archive your career
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
* beamLR/currentTrackEvent                            (Current track event progress)

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

Version 1.9.1 temporarily disables beamstate loading (visual damage) due to issue with advanced couplers. It can be turned back on from the options menu. If you decide to use beamstates, advanced couplers can be fixed from the options menu. This is not a guaranteed fix and it may crash the game.

Version 1.10 adds race track events to the mod which can be joined from career mode. Track events work using a different lightweight loader mission and work differently than regular career.  This version also adds a bunch of QoL improvements to the UI, saving/loading configs for your vehicles. Backups are now saved automatically when you stop the mission to ensure all files are updated before a backup is saved.

Version 1.11 adds new trailer deliveries, RNG based pink slips and various new restrictions relating to time of day. Car shops are now closed at night while new "high stakes" race clubs are only available at night. This version also adds a new death screen UI allowing you to immediately reload your last backup.


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

Since version 1.10 race files have been simplified, model list is no longer required as it is parsed from the config list. Configs for most races are now passed as **config=class:PATH_TO_CLASS_FILE** to help organize race opponents in easy to edit files for each club tier, as well as other track event related config categories which can be sorted by induction type, drivetrain type and vehicle brand.

Version 1.11 makes the **slips** field a float value working as percent chance for a race to offer a pink slips bet.

Also new in 1.11 is the ability to set race club open hours. The below trigger data file example is for a night only race club on east coast, open from 20:00 to 07:00. 

```
club=eastCoastNightRaceClub
opsp=-755.02685546875,506.66494750977,23.37056350708
opsr=0.0096882955460253,-0.018372787351004,0.89616867455903,0.44322712501998
pspos=-758.22436523438,503.17645263672,23.403123855591
psrot=0.010362435751454,-0.016063638166846,0.89713974366614,0.44133304860252
psscl=3.5,5.8,10
cname=Night Drag Race Club
hours=20,7
```
Format is 24 hours with minutes as fraction of 1 hour so 30 minutes is 0.5 added to the hour value.
For example to set the club open time from 20:30 to 7:30 use **hours=20.5,7.5**
To keep race clubs open all the time use **hours=0,0**

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

### Adding New Missions

For small item delivery you need to add a trigger on the map where you want the destination to be so just open world editor and duplicate an existing delivery destination so you get the correct settings. Rename then move it where you want the destination and add a waypoint for the GPS system (or just pick one that's close enough). Save the map and restart the game (otherwise the trigger doesn't work). Copy a delivery file and alter the values to reflect your new destination.

```
dest=DESTINATION_TRIGGER
desc=Deliver $item to DESTINATION
reward=200
items=beer,books,coffee_lid,coffee_nolid,fastfood,fishingequipment,gameconsoles,graphicscards,monitors,motoroil,mufflers,pistons,pizza,powertools,scrapmetal,soda,sparkplugs,tools
gmwp=DESTINATION_GPS_WAYPOINT
type=small
```

For trailer deliveries you don't need triggers. Drive up to the location where the trailer should be placed. In lua console use extensions.blrutils.slotHelper() to dump vehicle and camera positions in the beamLR/slotHelper file (which will be created if it doesn't exist yet). Some vehicles tend to have slight offset when using this code but the ETK 800 works well enough. File will look like this:

```
slotp=-767.92095947266,474.75573730469,23.898416519165
slotr=0.0077511852342431,0.0054148582438654,0.344295775316,0.93881362236454
```

Use the values to replace data in an existing trailer delivery file and fill in the remaining values accordingly.

```
destpos=SLOT_HELPER_SLOTP
destrot=SLOT_HELPER_SLOTR
desc=Deliver $item to DESTINATION
reward=350
items=smallflatbed_armchairs,smallflatbed_couch,smallflatbed_1400planks,smallflatbed_2100planks,smallflatbed_400crate_bodypanels,smallflatbed_400crate_eggs,smallflatbed_400crate_engineparts,smallflatbed_400crate_fineart,smallflatbed_400crate_graphicscards,smallflatbed_400crate_scrapmetal,smallflatbed_800crate_engineparts,smallflatbed_800crate_fridge,smallflatbed_800crate_metalingots,smallflatbed_800crate_science
gmwp=DESTINATION_GPS_WAYPOINT
type=trailer
```

Then last step so your mission is available in game is to add it to a mission giver file (like beamLR/missions/utah/utahGiver0). Increment the mission count for the type of mission you added and point to the new mission file following the existing format:

```
tspos=775.04846191406,-168.5132598877,144.50952148438
tsrot=0.0033254586916255,-0.0011244714208908,0.1608575760131,0.98697138617475
smallcount=7
trailercount=7
small1=caravanDelivery
small2=airfieldDelivery
small3=topshopDelivery
small4=constructionDelivery
small5=parkingLotDelivery
small6=touristAreaDelivery
small7=rangerCabinDelivery
trailer1=trailerDeliveryAirfield
trailer2=trailerDeliveryCanyonFuel
trailer3=trailerDeliveryConstructionBasement
trailer4=trailerDeliveryInfoCenter
trailer5=trailerDeliveryNewShop
trailer6=trailerDeliveryParking
trailer7=trailerDeliveryRanger
```

So if you added a trailer mission you get trailercount=8 and trailer8=MISSION FILENAME is added at the end of the file. East coast has two mission giver files so make sure you add the mission to the correct one (or both if that's what you want). eastCoastGiver0 is the town part shop while eastCoastGiver1 is near the player spawn.

You can also add extra delivery items. Item files for small deliveries are very simple, only item name which will be used to replace $item in the mission description and a G force value where the mission fails, basically the fragility of the item being delivered. Mission reward bonus scales with fragility. Just copy a file and change the values. Trailer items have an extra parameter for what trailer config should spawn, usually it will be one of the crate trailers for generic items but specific configs are also be used.

```
name=a couch
failg=20.0
trailer=vehicles/tsfb/loaded_couch.pc
```

After adding an item file you need to point to it in the mission files. As this is the first iteration of this new system this part will be a bit annoying because you need to change every mission file. One way to do it quickly is to use notepad++ and do "find and replace in files" in the mission folder. Search for the old item list, replace with the list that has your item added. I will be improving this part of the process and the mission giver mission lists in a future update likely using list files that are more easy to manage when modding.


### Adding modded vehicles and custom configs to shops

First step is to copy a file in the **beamLR/shop/car** folder so you have a new car file ready to replace values. Rename it to a unique file name.
Opening that file you then replace the fields for your modded cars or custom configs. For this example the file used is **autobello_110AM**.

```
name=Autobello Piccolina (text value shown in car shop UI)
type=autobello (internal BeamNG model of the vehicle)
config=vehicles/autobello/110_m.pc (actual config file to spawn)
baseprice=1000,3000 (price range, calculated as inverse of odometer so small odometer means higher price, for new vehicle use a single value)
odometer=80000000,130000000 (odometer range in meters, for new vehicle use 0)
scrapval=300 (value of vehicle when sold as scrap)
partprice=0 (no longer used, can be ignored)
paint=0,0,0,0,0.1,0.1,0.1,0.1 (only used as fallback paint color if random paints are turned off)
randslots=autobello_fender_FL,autobello_bumper_F,...,..., (list of internal slot names to be randomized, usually only body panels)
```

The **randslots** line simply isn't there on new cars as they do not spawn with randomized parts. To look through all the slots for body panels spawn the config in game and in lua console use the function **extensions.blrutils.actualSlotDebug()** to dump the slots of that vehicle in the file **beamLR/actualSlotsDebug** so you can create the list of body panel slots.

What I do is look through the list to remove slots I don't want randomized (such as engine parts, wheels, other important parts) then using Notepad++ search and replace extended mode to replace **\n** with a **comma** and append that list to the randslots field. Keep in mind if you hit enter when removing slots it might add **\r\n** so if the list isn't in a single line that's probably why.

Once you're done with the car file itself the next step is to make it available in shops. That's done within shop files in **beamLR/shops**. We're interested in the **models** line and associated **model0,model1,...** lines to add a car. This example file is **utahNewCarShop** process is the same for used shops.

```
name=New Car Shop
slots=5
chance=0.7
shopid=1
models=13
model0=etk800_844M_new
model1=bastion_SE35A
model2=bastion_battlehawkM
model3=bolide_350USDM
model4=vivace_100M_new
model5=etkc_kc4M
model6=sbr_rwdbaseM
model7=scintilla_GT
model8=scintilla_spyderGTs
model9=sunburst_20sportM
model10=etk800_854M_new
model11=etkc_kc6M
model12=etkc_kc8M
slotp0=-809.82904052734,-135.27842712402,296.84014892578
slotr0=0.0030195300350944,-0.0044971101883625,0.79615106486364,0.60507366522996
camp0=-805.90307617188,-137.25805664063,298.81729125977
camr0=0.1438989341259,0.083446733653545,-0.49466302990913,0.85301703214645
slotp1=-808.48980712891,-130.46528625488,296.82257080078
slotr1=-0.0020591345820029,-0.002938413974088,0.79541885852035,0.60604947421665
camp1=-804.58197021484,-132.46055603027,298.81381225586
camr1=0.14540919661522,0.083938360214233,-0.49284192919731,0.85376650094986
slotp2=-807.16265869141,-125.64483642578,296.83483886719
slotr2=0.0034723356938514,-0.0054626919924033,0.7954801701488,0.60594504765784
camp2=-803.23175048828,-127.61531066895,298.81381225586
camr2=0.14388573169708,0.083665773272514,-0.49565941095352,0.852419257164
slotp3=-805.83636474609,-120.82448577881,296.82476806641
slotr3=0.0034576713507743,-0.0044816834397327,0.79550292794515,0.60592330426637
camp3=-801.91857910156,-122.78488922119,298.84783935547
camr3=0.14785739779472,0.086016781628132,-0.495441198349,0.8516321182251
slotp4=-804.50823974609,-116.00479125977,296.80920410156
slotr4=0.0046553285357728,-0.0064758269101433,0.79550978787762,0.60588824792445
camp4=-800.55853271484,-117.96599578857,298.75772094727
camr4=0.14097069203854,0.08230085670948,-0.49741896986961,0.85201412439346
```

Increase the value of **models** by **1** and then add a new line following the **modelN** format that points to your file, keep in mind the first model has index **0**. So for the above file to add a car you would set **models** to **14** and then add the line **model13=filename** at the bottom of the models list, using the file name you used after copying a car file. Repeat this part of the process for all shops you want your car to spawn in.

This part of the process is a bit tedious with the hard count list and will likely be improved to work with list files that are shared for multiple shops and easier to manage when modding.

Your car should now be spawning in shops you added it to. 

One way to test to make sure the new car works is to backup the contents of a specific shop file to restore later and then set **models** to **1**, delete every single **modelN** line except for **model0** pointing to your car. This will make it so that shop only has that one car to sell and it'll be the only thing that can spawn so you don't wait for RNG to know if you made a mistake. You can also set the **chance** value to **1.0** so the shop has 100% chance to spawn cars in every slot, a good way to see different variations with randomized parts.


### Other modding
Start money can be customized, check the **beamLR/init** folder for the various start difficulties.

Mod vehicles *should* also work but beamstate loading is a very unstable feature so some may have issues and I will not focus on fixing issues related to other mods.

The flowgraph mission can also be tweaked, this is for advanced users only as it's very easy to break things.

Same things goes for LUA scripts.

## Final Word
Feedback and bug reports are appreciated! 

Thank you for playing BeamLR!

## Known Issues 

* As of BeamNG version 0.28 beamstate loading is broken. This is listed in known issues for the game and should hopefully be fixed soon.
* ~~Towing mechanic may repair your vehicle. This is due to problems with a teleport function that shouldn't cause a reset yet sometimes does.~~ Should be fixed as of version 1.10
* Some tuning configurations can cause unfair damage when a vehicle is loaded. A workaround is implemented but may fail to work in certain situations.
* ~~Various UI problems, input fields stop registering keystrokes, whole UI can refuse to work. Workaround is to keep cursor above input fields.~~ Seems fixed as of 1.11 if any issues arise try CTRL+F5.
* ~~Race checkpoints sometimes fail to trigger properly.~~ Should be fixed as of version 1.6
* Beamstate file corruption breaking pristine vehicles. Workaround is implemented but may fail. Use world editor for repair or delete the corrupted beamstate file.
* Player can get stuck in place while walking and trying to take bus home. Currently investigating this issue. Reload the mission to get unstuck.
* Health mechanic is temporarily removed due to vehicle "wiggle" after crashes causing erroneous high enough G forces to injure the player. Fatal crashes from a single high G impact are still enabled like track events.


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
