
# Beam Legal Racing 1.13
BeamLR is a persistent career BeamNG mod inspired by SLRR aiming to bring hardcore game mechanics to BeamNG such as external and mechanical damage persistence, money, paying for repairs, player health and injuries with fatal crashes resetting your save file, etc. The mod adds interaction to the sandbox with gas stations, repair shops, in world vehicle store system, dynamic race events, enabled traffic and more to achieve a sandbox career experience. 

Perform missions, races and challenges to earn money to buy vehicles and parts. Drive carefully as repairs can be quite costly and a hard enough crash could mean game over!

## Quick Links
### More Info | [Forum thread](https://www.beamng.com/threads/87394/) 

### Career Maps | [Utah](utahmap.md) | [East Coast](eastcoastmap.md) | [Italy](italymap.md)

### Track Event Maps | [Hirochi Raceway](hirochimap.md) | [Automation Test Track](automationmap.md) | [Nordschleife](map_ks_nord.md)

### [Addons](Addons) | [Nordschleife](Addons/ks_nord)

### Enjoying the mod and looking to support the project? [Donate here!](https://www.paypal.com/donate/?hosted_button_id=QQ7SKC6XK7PAE)

## Install Instructions
**BeamLR cannot be installed like a normal mod due to data persistence issues when zipped**. 

Carefully follow the instructions to ensure all features are working properly:
* Download the latest zip file from the **Releases** folder.
* Extract zip file contents directly to your [BeamNG userfolder](https://documentation.beamng.com/support/userfolder/).
* Tell your operating system to replace existing files if asked.

**After installing check the *Read Before Playing* section of this readme for important information and a quick overview of major update features.**

**Installing BeamLR may overwrite custom changes made to levels.** 
Modders should back up the userfolder before installing.

## Update Instructions
**BEFORE UPDATING**:  Back up the userfolder/beamLR folder to archive your career
* Download the latest zip file from the **Releases** folder.
* Use the BeamLR options menu to back up your career.
* Extract updated mod zip contents to the userfolder. 
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

Version 1.12 adds Italy map content, Soliad Lansdale in shops, traffic and opponents, various improvements relating to ease of modding as well as the first addon to the mod which adds support for track events on the Nürburgring Nordschleife mod map.

Version 1.13 adds advanced vehicle building, advanced repair cost calculation, a GPS system and gooseneck trailer deliveries. Make sure you read the [Advanced Vehicle Building](README.md#advanced-vehicle-building) section of this readme before playing after installing this update.


Further instructions and various tips on this mods' various features are listed in the BeamLR UI Main Menu.

## Getting started
BeamLR is loaded as a freeroam mission. Use the following spawn point depending on map choice:

* Utah: **Auto Repair Zone**
* East Coast: **Gas Station Parking Lot**
* Italy: **BeamLR Spawn**

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

## Advanced Vehicle Building
### NOTE: Advanced vehicle building is disabled by default so your current career files are compatible with update 1.13, use the options menu to enable it. A career reset is highly recommended after enabling, otherwise vehicles will spawn with missing parts.
Added in version 1.13, advanced vehicle building (AVB) allows for a more realistic or SLRR-like vehicle building experience. Jbeam loading scripts have been modified to remove all slot defaults, which for instance makes it so  wheels spawn without tires, pickup bed spawns without tailgate, taillights or bed accessory. Sub-parts must therefore be purchased and added manually. 

When AVB is enabled, removing a part will add all attached sub-parts to your inventory. It will also be possible to sell parts at a scaled down value compared to purchase cost. Part selling is disabled when playing without AVB due to the fact that slot defaults could be used as infinite money exploit.

This feature is not recommended for casual players as it can make part edits more complex and confusing. For example, engine swaps can be frustrating because a single missing part can prevent your vehicle from moving. If this happens, make sure you added all drivetrain related parts (transmission, driveshaft, halfshafts, etc) some of which may not be located under the 'Engine' category of the part edit menu.

BeamNG is not built to fully handle this type of feature. Engines will still be running even when missing important parts like the oil pan, intake, exhaust manifold, long block or ECU. If you experience issues with vehicles missing parts in freeroam after force exiting from BeamLR, restarting the game should fix it.

## Advanced Repair Cost Calculation
### NOTE: Advanced repair cost calculation is turned off by default and can be enabled from the options menu. This setting does not require scenario reset and can be changed on the fly to see repair cost difference. 

Added in version 1.13, advanced repair cost calculation makes use of broken/deformed beams specific to each part on the vehicle to detect 'ruined' parts and add their actual cost to the repair value of the vehicle. This results in a more realistic and accurate representation of vehicle damage. 

Since repair cost becomes related to vehicle part value, repair costs will be higher especially for high end vehicles like the scintilla or vehicles using costly parts. Race wagers have been increased to help balance this change.

## GPS System
Added in version 1.13 is a new GPS system that allows you to find specific destinations or nearest destinations of certain types like gas stations, vehicle shops, repair garages, part shops, etc. By default, the GPS UI will only show when using a vehicle that has a GPS (BeamNavigator) installed. It is also possible to force enable or disable the GPS UI through the options menu. Regardless of chosen setting, the GPS UI will be disabled in some situations where groundmarkers are required, such as during delivery missions and daredevil challenges.

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
items=list_all
gmwp=DESTINATION_GPS_WAYPOINT
type=small
```

For trailer deliveries you don't need triggers. Drive up to the location where the trailer should be placed. In lua console use **extensions.blrutils.slotHelper()** to dump vehicle and camera positions in the **beamLR/slotHelper** file (which will be created if it doesn't exist yet). Some vehicles tend to have slight offset when using this code but the ETK 800 works well enough. File will look like this:

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
items=list_all
gmwp=DESTINATION_GPS_WAYPOINT
type=trailer
```

Then last step so your mission is available in game is to add it to a mission giver. As of version 1.12 mission givers use list files to make it easier to add new missions. For this example we'll take a look at the mission giver file **beamLR/missions/utah/utahGiver0**:

```
tspos=775.04846191406,-168.5132598877,144.50952148438
tsrot=0.0033254586916255,-0.0011244714208908,0.1608575760131,0.98697138617475
slist=list_small
tlist=list_trailer
```

The fields **tlist** and **slist** point to list files for trailer missions and small item missions respectively. The other two fields are the spawn position of trailers so should not be changed unless you're adding a new mission giver. Now taking a look at the file **list_small** you can see mission files are listed one by one:

```
caravanDelivery
airfieldDelivery
topshopDelivery
constructionDelivery
parkingLotDelivery
touristAreaDelivery
rangerCabinDelivery
```
Simply add your mission file to this file and your mission will now be available from the mission giver. To test your mission, create a temporary list file containing only your mission and use that list for a mission giver to force that mission to be offered immediately.


You can also add extra delivery items. Item files for small deliveries are very simple, only item name which will be used to replace $item in the mission description and a G force value where the mission fails, basically the fragility of the item being delivered. Mission reward bonus scales with fragility. Just copy a file and change the values. Trailer items have an extra parameter for what trailer config should spawn, usually it will be one of the crate trailers for generic items but specific configs are also be used.

```
name=a couch
failg=20.0
trailer=vehicles/tsfb/loaded_couch.pc
```

After adding an item file you need to point to it in the mission files. As of version 1.12 items are also stored in list files which can quickly be edited with new items. Below is the item list **beamLR/missions/items/small/list_all** which is used for most small item delivery missions.

```
beer
books
coffee_lid
coffee_nolid
fastfood
fishingequipment
gameconsoles
graphicscards
monitors
motoroil
mufflers
pistons
pizza
powertools
scrapmetal
soda
sparkplugs
tools
```
Simply add your item file to a list file to make it available in missions which use this list file. The **items** field of a mission file can be changed to point to different or more specific item list files such as the small item list **list_food** which only contains food items. Make sure not to use trailer item files/lists for small item deliveries.

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

The **randslots** line simply isn't there on new cars as they do not spawn with randomized parts. To use randomized parts use the following process:

First step is to get a list of vehicle slots to find all the slots for body panels: 

* Spawn the config in game
* In lua console use the line **extensions.blrutils.actualSlotDebug()**

This will dump the slots of that vehicle in the file **beamLR/actualSlotsDebug** so you can create the list of body panel slots. 

Here is one way to accomplish this:

* Look through the list to remove slots you don't want randomized (such as engine parts, wheels, other important parts)
* Use Notepad++ search and replace **extended mode** to replace **\n** with a **comma**
* Append that list to the **randslots** field.

Keep in mind if you hit enter when removing slots it might add **\r\n** so if the list isn't in a single line that's probably why.

Once you're done with the car file itself the next step is to make it available in shops. That's done within shop files in **beamLR/shops**.  As of version 1.12 list files are used to easily manage which vehicles are available in each shop. Shop files contain a link to the list file set using the **models** field. List files are stored in **beamLR/shop/car** and are simple one value per line files pointing to vehicle files. As an example here is the file **utahUsedCarShop** which uses the **list_used_all** list file:

```
name=Used Car Shop
slots=4
chance=0.9
rpchance=0.3
shopid=0
models=list_used_all
slotp0=824.29364013672,-0.1175025672017,147.83654785156
slotr0=0.0019109094749717,0.034539506349485,-0.82961584485164,0.55832066827696
slotp1=825.71472167969,-3.5963778495789,147.83418644531
slotr1=0.0033082890440838,0.0027348922892865,-0.82524905499833,0.56475266903957
slotp2=826.95849609375,-6.9461436271667,147.83628845215
slotr2=0.0027869357604591,0.0029588866532912,-0.82071921700846,0.57131728908887
slotp3=827.56097412109,-10.998514175415,147.83543395996
slotr3=0.0033683123225928,0.0022886268196966,-0.6751874490874,0.73763495392656
camp0=819.196,-0.168,149.798
camr0=0.070,-0.080,0.749,0.654
camp1=820.313,-4.253,149.607
camr1=0.069,-0.069,0.706,0.702
camp2=822.327,-7.880,149.303
camr2=0.057,-0.057,0.707,0.703
camp3=823.124,-11.839,149.786
camr3=0.125,-0.112,0.660,0.732
```
Part of the file **list_used_all** can be seen below. Each line must point to a vehicle files in **beamLR/shop/car**. Add your previously created vehicle file to the list file for the shop you want your vehicle to be available in.

```
coupe_baseM
coupe_malodorous
coupe_typeLSM
barstow_awful
barstow_232I6M
bluebuck_horrible
bluebuck_291V8
covet_pointless
covet_13SM
covet_typeLSM
vivace_100M_used
fullsize_miserable
fullsize_V8A
etki_2400M
...
```

Your car should now be spawning in shops you added it to. While by default list files are mostly shared between shops of a similar type (scrap,used,new) shops can also have their own specific list files which can used to create more specific shops, for instance brand or country specific shops.

With list files to test if your vehicle is working you can force it to spawn by creating a temporary list file containing only your vehicle and set a shop to use that list file. This will force the vehicle to spawn at that shop on the first attempt and will save you having to re-roll shops until your new vehicle spawns.


### Other modding
Start money can be customized, check the **beamLR/init** folder for the various start difficulties.

Mod vehicles *should* also work but beamstate loading is a very unstable feature so some may have issues and I will not focus on fixing issues related to other mods.

The flowgraph mission can also be tweaked, this is for advanced users only as it's very easy to break things.

Same things goes for LUA scripts.

As of version 1.12 pink slip races are now restricted for certain vehicle models listed in the file **beamLR/pinkslipsBlacklist**. Blacklisted (fancy) vehicles will only allow pink slips when player is also using a blacklisted vehicle. This list can be edited.

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


## Known Issues 

* As of BeamNG version 0.28 beamstate loading is broken. This is listed in known issues for the game and should hopefully be fixed soon.
* ~~Towing mechanic may repair your vehicle. This is due to problems with a teleport function that shouldn't cause a reset yet sometimes does.~~ Should be fixed as of version 1.10
* Some tuning configurations can cause unfair damage when a vehicle is loaded. A workaround is implemented but may fail to work in certain situations.
* ~~Various UI problems, input fields stop registering keystrokes, whole UI can refuse to work. Workaround is to keep cursor above input fields.~~ Seems fixed as of 1.11 if any issues arise try CTRL+F5.
* ~~Race checkpoints sometimes fail to trigger properly.~~ Should be fixed as of version 1.6
* ~~Beamstate file corruption breaking pristine vehicles. Workaround is implemented but may fail. Use world editor for repair or delete the corrupted beamstate file.~~ Seems fixed.
* Player can get stuck in place while walking and trying to take bus home. Currently investigating this issue. Reload the mission to get unstuck.
* Pausing the game during part edits will reset your vehicle odometer. Try to make sure the game isn't paused when interacting with BeamLR features to prevent issues.
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
