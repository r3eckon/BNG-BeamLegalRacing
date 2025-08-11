




[latest]: https://github.com/r3eckon/BNG-BeamLegalRacing/releases/download/1.18.1/beamLegalRacing1.18.1.zip
[userfolder]: https://documentation.beamng.com/support/userfolder/

# Beam Legal Racing 1.18.1
BeamLR is a persistent career BeamNG mod inspired by SLRR aiming to bring hardcore game mechanics to BeamNG such as external and mechanical damage persistence, money, paying for repairs, player health and injuries with fatal crashes resetting your save file, etc. The mod adds interaction to the sandbox with gas stations, repair shops, in world vehicle store system, dynamic race events, enabled traffic and more to achieve a sandbox career experience. 

Perform missions, races and challenges to earn money to buy vehicles and parts. Drive carefully as repairs can be quite costly and a hard enough crash could mean game over!

## Quick Links
### More Info | [Forum thread](https://www.beamng.com/threads/87394/) 

### Career Maps | [Utah](utahmap.md) | [East Coast](eastcoastmap.md) | [Italy](italymap.md) | [West Coast](westcoastmap.md) | [Valo City](valocitymap.md)

### Track Event Maps | [Hirochi Raceway](hirochimap.md) | [Automation Test Track](automationmap.md) | [Johnson Valley](map_johnson.md) | [Nordschleife](map_ks_nord.md)

### Download Extra Content | [Addons](Addons) 

### Enjoying the mod and looking to support the project? [Donate here!](https://www.paypal.com/donate/?hosted_button_id=QQ7SKC6XK7PAE)

### Having issues with the mod? [Please follow this troubleshooting guide.](troubleshooting.md)

## Install Instructions ([Video](https://www.youtube.com/watch?v=iKZckDVPjR4))
**BeamLR cannot be installed like a normal mod due to data persistence issues when zipped**. 

Carefully follow the instructions to ensure all features are working properly:
1. [Download the latest release][latest].
2. Extract zip file contents directly to your [BeamNG userfolder][userfolder].
3. Tell your operating system to replace existing files if asked.

**After installing check the *[Read Before Playing](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#read-before-playing)* section of this readme for important information and a quick overview of major update features.**

**Installing BeamLR may overwrite custom changes made to levels.** 
Modders should back up the userfolder before installing.

## Update Instructions ([Video](https://www.youtube.com/watch?v=iKZckDVPjR4))
**BEFORE UPDATING**:  Back up the userfolder/beamLR folder to archive your career

**IMPORTANT NOTE**: Version 1.18 and above are not compatible with previous version backups

1. [Download the latest release][latest].
2. Extract updated mod zip contents to the [BeamNG userfolder][userfolder].
3. Tell OS to replace existing files when asked. **This will apply the update.**
4. Use the BeamLR options menu to restore your backup. 

**Remember to update your addons if you have any installed!**

If the backup system fails to work properly you can manually replace the files/folders using your backed up beamLR folder. Ask on the forum if you need help knowing which files to paste over. 

**After updating check the *[Read Before Playing](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#read-before-playing)* section of this readme for important information and a quick overview of major update features**

If you are experiencing issues after updating the mod, try a **clean** userfolder install and copy over your backup.

## BeamNG Major Updates
### The mod will most likely not be compatible with a new major version of BeamNG. 
### Do not create issues telling me to update the mod during major version updates. 

With major updates to BeamNG a new userfolder is created. Not all BeamLR files are automatically migrated. It is recommended to do a fresh install of BeamLR in the new userfolder before moving your career files:

1. Start BeamNG after updating to complete the userfolder migration process
2. Do a fresh install of BeamLR into the new userfolder (once a compatible version has been released)
3. Copy the contents of **beamLR/backup** from the old userfolder into **beamLR/backup** in the new userfolder
4. Use the options menu to restore your backup

The game will give you a chance to view the contents of your old userfolder containing career files on first launch after updating so don't worry about steam update deleting your save. The BeamLR folder will not be migrated to the new userfolder so your career files will be kept in the old userfolder.


## Read Before Playing

**IMPORTANT**: **Do not change the settings shown below while playing BeamLR**. The settings should be automatically restored to your previous values when you abandon the scenario. Keep in mind game crashes and other forceful exit from the scenario may prevent your old setting from being restored.

![settings](https://i.imgur.com/4bm3moL.png)

**IMPORTANT**: **You must abandon the scenario to properly save your progress**. Do not exit the game from main menu until you have abandonned the scenario and are back in freeroam. ALT-F4 or other forceful exit from the game are likely to cause lost progress and/or corrupted save files. Copy the **userfolder/beamLR** folder somewhere if you want to manually backup your career files.

**IMPORTANT**: **Do not pause the game when interacting with mod menus**. Doing so will cause issues.

**First time players**: The imgui unit detection feature may fail to properly register your unit setting causing a mismatch in displayed units. Switching between metric and imperial fixes this issue. The UI will then show correct units.

The "BeamLR" layout will be loaded on scenario start. Any changes made to this UI layout will be reflected when playing BeamLR in case the default layout doesn't fit on your screen.

## Major Feature Update Overview

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

Version 1.16 completely revamps the part inventory system allowing each individual part to have specific odometer and integrity values. It also adds the ability to buy used parts (reduced cost for higher odometer) and implements dynamic mirror offsets saved to vehicle configs. This new version is not compatible career files from previous versions and will require starting from scratch. See [advanced part inventory](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#advanced-part-inventory) for more information.

Version 1.16.1 adds part integrity decrease at high odometer which means more idle play and less performance on high odometer engines.

Version 1.16.4 adds performance class restrictions for race club leagues and the ability to skip leagues up to gold league.  Bronze league requires a vehicle below C class, silver league requires a vehicle below S class. Night only race clubs don't have this restriction. This feature can be turned off in options.

Version 1.16.7 improves mod compatibility for car shops with additive list files. See the [updated tutorial](https://github.com/r3eckon/BNG-BeamLegalRacing/blob/main/Tutorials/Adding%20Shop%20Vehicles.md) to learn more.

Version 1.17 adds new interactive areas ([car meets](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#car-meets) & [properties](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#garage-slots-and-properties)), daily seeded race clubs and a [new part inventory menu](https://github.com/r3eckon/BNG-BeamLegalRacing/tree/main#part-inventory-menu). Daily seeded race clubs prevent reroll abuse and is the intended way to play (can be turned off in options). 

Version 1.17.2 adds new track events on West Coast USA, track event prefabs and an option to give all track event opponents slick tires to improve their racing ability. This version of the mod also adds content from the 0.34 update of BeamNG including the new Bruckell Nine and updated level files.

Version 1.17.4 adds the Valo City addon, defective vehicles to used car shops (SLRR like, missing engine, wheels, etc), shared race club progress files (for Valo City, same drag club progress at multiple locations) and gearbox damage persistence (grinding gears damaged saved, must pay to repair). This update also slightly tweaked the odometer based integrity decrease to improve scaling, the effect should be overall a bit lessened for most cars.

Version 1.17.5 adds nested tree part edit menu similar to vanilla part edit menu (can be toggled in UI options), a button to export your current config to freeroam (done from the config page of part edit), buttons to add slots to a list of favorites accessible in part edit and part buying menu and a UI to view history of past track event results. Part specific repair costs are now linked to part odometer so older parts and vehicles are cheaper to repair.

Version 1.18 brings compatibility for BeamNG version 0.36 and adds content from 0.35 and 0.36 to the mod. This version also adds the ability to selectively repair child parts of a broken parent without repairing the parent part (repaired part will be sent to inventory).

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

Chosen difficulty will affect the amount of money and garage slots you get at the start of your career:
* Easy: $5000, 5 slots
* Medium: $1000, 3 slots
* Hard: $20, 2 slots


Purchased or won vehicles are sent to your player garage. You can also scrap vehicles for some money using the player garage menu.

Depending on your chosen difficulty setting (default is medium) you may need to perform delivery missions from part shops before you have enough money to wager in races or challenges. 

Version 1.11 updated delivery mission system works using a set of items and destinations. Each destination has a base reward that is scaled to give up to 100% bonus depending on item fragility. Experiencing more Gs than the item can endure will fail the mission. If your vehicle has a tow hitch you can accept trailer delivery missions. 

The main gameplay for this mod is available at various race clubs where you can wager money in races.

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
Added in version 1.14 part specific repairs adds a menu allowing players to choose which parts to repair. Damaged parts that aren't repaired will be removed from the vehicle config and **will not be added to inventory**. Some parts must be repaired such as mechanical damage and the vehicle 'main' part and cannot be deselected. 

Since 1.18 you can now repair damaged sub-parts without repairing a damaged parent. Undamaged or repaired sub-parts removed when you choose not to repair a damaged parent part will be returned to the part inventory. When repairing your vehicle from the player garage an on-site mechanic fee is added to the repair cost.

## GPS System
Added in version 1.13 is a new GPS system that allows you to find specific destinations or nearest destinations of certain types like gas stations, vehicle shops, repair garages, part shops, etc. By default, the GPS UI will only show when using a vehicle that has a GPS (BeamNavigator) installed. It is also possible to force enable or disable the GPS UI through the options menu. Regardless of chosen setting, the GPS UI will be disabled in some situations where groundmarkers are required, such as during delivery missions and daredevil challenges.

## Improved Fuel System
Added in version 1.14.2 the improved fuel system now features diesel fuel and gasoline tiers which give slight performance boost to vehicles. Diesel fuel must now be used with diesel engines. Using the incorrect fuel type will disable the engine until the tank is drained. Draining the tank will allow you to add the correct fuel and start the engine again. Gasoline quality is calculated based on ratio of each fuel tier in the tank, higher quality will slightly increase the vehicle output torque. The maximum increase for each tier (for a fuel tank containing only this tier) is as follows:

* Premium: 5%
* Mid-Grade: 2.5%
* Regular: 0%

For example, if a fuel tank contains a 50/50 mix of premium and mid-grade the increase is 3.75%. For a mix of regular and mid-grade, the increase is 1.25%. If a fuel tank contains only premium grade, the increase is 5%. While not realistic, BeamNG does not have fuel octane ratings for engines and side effects of incorrect fuel being used, so this is a compromise to give a purpose to higher fuel tiers that makes sense for a racing game. If BeamNG eventually adds this feature the fuel system will be changed to implement fuel tiers in a more realistic way.

## Part Edit Safe Mode
Added in version 1.14.2 part edit safe mode is a new advanced option used to help prevent damage during part edits. Certain parts may cause damage when removed, for instance wheels, which cause the vehicle to fall and damage the bumper. This option will temporarily increase beam strength to help prevent taking damage. While in safe mode, the vehicle will be frozen in place. To unfreeze the vehicle you must exit safe mode, at which point the game will reload the normal beam strength values. This option can be kept off for the vast majority of part edits but should help with certain edits that tend to cause damage.

## Walk Mode Integration
Walk mode is now integrated with certain mod features as of version 1.15 allowing you to exit your own vehicle, to interact with the controls of gooseneck trailers, to interact with shop vehicles (which will properly reflect currently entered vehicle details in UI) and to access a new consumable item shop at gas stations.

## Consumable Item Inventory
Added in version 1.15 is a new inventory system for "consumable" type items. The first iteration of this system comes with two consumable items: fuel canisters and oil bottles. Both can be used to refill your vehicle in an emergency. Items can be purchased by walking at a gas station ("convenience store" menu). Gas canisters can contain gasoline or diesel and like regular gas station refuelling using the incorrect fuel type will disable the engine. 

## Improved Oil System
Added in version 1.15 is an improved oil system that now saves oil value for your vehicles.  Breaking the oil pan will now require refilling the oil as the emptied out value is restored even after repairing. Refill bottles can be purchased at gas stations with the walk mode menu.

As of version 1.16 the oil leak mechanic is tied to the advanced inventory system explained below.  Oil now leaks from the engine and oil pan parts separately, meaning if you replace an old oil pan with a new one it will drastically reduce the oil leak rate. Some vehicles in BeamNG have no separate oil pan part so in this situation 100% of the leak rate comes from the engine. For most other vehicles, 70% of the leak rate comes from the oil pan and 30% comes from the engine. 

The relation between leak rate and part odometer is still the same as in previous versions, however it is now calculated separately for each part. The base leak rate is designed to leak out all the oil in 2 hours at 100,000km, 1 hour at 200,000 km and down to 30 minutes at 400,000 km which is the worst possible leak rate.

Removing the oil pan from your vehicle will quickly leak out all the oil. Remember to refill the oil after re-installing a new oil pan to avoid engine damage!

## Advanced Part Inventory
Added in version 1.16, the advanced part inventory system completely revamps the part inventory. While the previous inventory system was only keeping a count of each part owned by the player, this new system essentially makes each part a unique element that can have specific odometer and integrity values.

The vehicle part condition system is now tied to part specific odometer values meaning changing old parts for brand new parts will, in some situations, improve your vehicle's performance. This depends on whether or not BeamNG simulates performance degradation for that part based on the odometer value, which I've confirmed to be the case for the engine (more friction so less performance & more idle play) and brakes (wears quicker at high odometer). This will likely influence other parts as BeamNG's part condition system is updated.

To go along with this new system used parts can now be bought from part shops. Each shop will offer one used part of each type per day. Odometer values are randomly generated and used part stocks are refreshed daily. Buy price is linked to odometer value, meaning you can get replacement parts for your old or less performance oriented cars for cheaper. Part sell price and the vehicles full sell price are also tied to part specific odometer values. 

Keep in mind this feature is still early days and may be prone to bugs due to the fact that it replaced almost all of  the existing part inventory related code. The need to link inventory parts with vehicle configs, two different files that need to be in sync, means that game crashes and other forceful exit from the game can easily result in corruption of your part inventory or vehicle configs. This new feature is also incompatible with save files from previous versions. You will need to start from scratch for this version.

As of version 1.16.1 high odometer parts now have decreased integrity values when attached to your car. The decrease is linear, begins at 100,000km (5% decrease) and maxes out at 300,000km (15% decrease). This results in lower performance for certain parts such as the engine which will have more idle play and friction.

## Car Meets
Added in 1.17, car meets are a new type of interactive area where the player vehicle is compared to a randomly picked selection of vehicles and rated for "coolness". An above average coolness score will increase your rep while a below average score will decrease it. Having the best/worst score of the meet will double the rep change. Coolness score is calculated using raw performance value but also parts such as underglow, spoilers, carbon fiber parts, paint designs and more. Basically, having a riced out car will increase coolness rating.

## Garage Slots and Properties
Since 1.17 the amount of free slots for vehicles in your garage is now limited. The starting amount of slots is determined by the difficulty setting. Having no free slot in your garage will prevent you from buying cars, participating in pink slips races or joining track events that have a vehicle reward. Joining such an event will also reserve a free slot in your garage for the duration of the event, essentially filling that slot temporarily. Note that while this feature can be turned off in options, limited garage slots are the intended way to play.

To purchase more garage slots, various properties are now available to purchase. The more expensive the property, the more slots it will add to your garage. Some levels have more properties than others. Properties are not shown on GPS or maps and thus must be found by exploring each level.

## Part Inventory Menu
Added in 1.17, this new menu will show all unused parts in your inventory, including parts for vehicles you no longer own. This menu is used to sell parts that don't show up in the part edit menu, such as subparts of an engine that has been removed from your vehicle. This menu improves the part-out process for vehicles.

This menu requires the game to cache jbeam file data upon first start. This process takes about a minute for a vanilla install and could take longer depending on how many vehicle and part mods you have installed. This process will be started automatically when you start the scenario if the game detects new mods. If you are a mod developer making your own jbeam parts you can start this process manually from the options menu to cache any new jbeam file that isn't stored in a mod zip. 

Version 1.17.1 will now skip broken jbeam files during the caching process. The process has also been optimized to use less RAM as it caused crashes on some systems.

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
* Soolek
* Lorenzo Boccaccia (LoSboccacc)
* Fernando Serafim Marcello
* Andrew Barbot
* Joe Franco
* Zbignev Ulevic
* Nuno Medeiros
* Preston Knapp

## Known Issues 

* As of BeamNG version 0.28 beamstate loading is broken. This is listed in known issues for the game and should hopefully be fixed soon.
* ~~Towing mechanic may repair your vehicle. This is due to problems with a teleport function that shouldn't cause a reset yet sometimes does.~~ Should be fixed as of version 1.10
* Some tuning configurations can cause unfair damage when a vehicle is loaded. A workaround is implemented but may fail to work in certain situations.
* ~~Various UI problems, input fields stop registering keystrokes, whole UI can refuse to work. Workaround is to keep cursor above input fields.~~ Seems fixed as of 1.11 if any issues arise try CTRL+F5.
* ~~Race checkpoints sometimes fail to trigger properly.~~ Should be fixed as of version 1.6
* ~~Beamstate file corruption breaking pristine vehicles. Workaround is implemented but may fail. Use world editor for repair or delete the corrupted beamstate file.~~ Seems fixed.
* ~~Player can get stuck in place while walking and trying to take bus home. Currently investigating this issue. Reload the mission to get unstuck.~~ Seems fixed.
* Pausing the game during part edits may reset your vehicle odometer. Do not pause the game when interacting with BeamLR features to prevent issues.
* ~~Health mechanic is temporarily removed due to vehicle "wiggle" after crashes causing erroneous high enough G forces to injure the player. Fatal crashes from a single high G impact are still enabled like track events.~~ As of version 1.15.4 the health mechanic has been re-introduced into the mod. This feature is disabled by default as G force sensors are still buggy and may lead to unfair deaths. Use at your own risk!
* Advanced Vehicle Building may not work with certain part mods. If you absolutely want to use part mods, cheat yourself money and test them before using in a real career.
* Car shop may bug while on foot for some players, requiring forced exit which loses progress. A potential fix has been added in 1.16.1 but before using this feature in a real career test to see if it works properly on your computer.
* UI apps may fail to show up after initially loading. Use CTRL+F5 to fix.

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

### 1.16
* Added Advanced Part Inventory (allows part specific odometer & integrity values)
* Added used part buying in part shop (lower prices for higher odometer parts)
* Added dynamic mirrors implementation (saved to car config, edit from options menu)
* Added race clubs and daredevil challenge destinations to GPS
* Vehicle integrity now linked to advanced inventory part specific odometer values
* Oil leak rate now linked to engine and oil pan odometers (use new parts to fix leak)
* Advanced repair UI now shows warning regarding selective repair
* Replaced frame delay vlua with flow blocking calls to fix potential race conditions 
* Fix same shopID values used on different maps resulting in same RNG rolls
* Fixed gas stations displays not updating to new values after sleep to next day
* Removed car shop frame delay (trying fix for some players not seeing shop menu)
* Vehicle sell price now tied to part specific odometer values
* Removing oil pan now increases oil leak rate to 1000% (empty within 3 seconds)
* Engine mechanical damage is now selectable in repair UI (removed if not selected)
* Updated part rewards to work with new inventory system
* Increased damage threshold for part edit restriction
* Fixed track event timer flickering between 00:00:000 and --:--:--- after round ended
* Increased wager and rep rewards for most daredevil challenges
* Updated West Coast USA level files to fix floating gas station objects
* Fixed East Coast USA small item deliveries not showing correct items in description
* Increased base rewards for trailer and gooseneck deliveries on West Coast USA
* Fixed traffic pooling breaking lights at night (thanks to LoSboccacc for the fix!)
* Trying fix for vanilla traffic.lua script allowing traffic on gated roads
* Disabled autoJunction for West Coast USA dragstrip to prevent traffic driving on it

### 1.16.1
* Added integrity decrease for high odometer parts (adds idle play, not saved to inv)
* Fixed VLUA crash when turning off car without exhaust (cooling metal SFX bug)
* Fixed hazards indicator turning itself on in certain situation (bug with traffic/vehicle.lua)
* Trying another fix for car shop menu bug while on foot
* Unicycle now frozen in place while in car shop (prevents exiting trigger)

### 1.16.2
* Fixed old "coupe" model in police spawngroups (replaced with BX-Series)
* Fixed fallback part price not used causing null sell/buy prices
* Fixed part buy layout bug with fallback value (missing line break)
* Fixed AVB bug when exiting Part Edit Safe Mode (game breaking inventory bug)
* Fixed engine immediately melting when added with no oil (bug in combustionEngineThermals.lua)
* Fixed race start markers staying active after giving up (allowed starting race in loss state)
* Increased base odometer value for starter cars to 300,000 km
* Tweaked odometer based part integrity decrease (starts at 150,000 km, maxes out at 450,000 km)
* Tweaked low end used cars odometer & price (decreased min value, increased max odometer)
* Removed option to disable Advanced Vehicle Building (necessary for new part inventory)

### 1.16.3
* Added toggles to show/hide option categories 
* Fixed selective repair issue with new inventory system
* Fixed Italy traffic spawns blocking player home entrance
* Fixed onVehicleResetted hook error when traffic is reset while player has no car
* Missing partConditions table now loads fallback (can't recreate bug, this will reset part odometer values but should avoid breaking save files)

### 1.16.4
* Added performance class restrictions for race leagues (bronze below C, silver below S)
* Added button to skip bronze and silver race leagues (if car is above class restriction)
* Fixed incorrect BX-series config files in drag race clubs (bugged when won in pink slips)
* Missing config files for pink slips rewards are now avoided (message will be displayed)
* Scrapyard cars now have odometer and price ranges (200,000km to 400,000km for $200 to $400)
* Fixed parts that can fit in multiple slots causing missing slots in edit menu
* Updated drift scoring app to show current combo multiplier
* Fixed jbeam cache related issue causing AVB data to be used for non AVB cars
* Fixed dragstrip slow mo triggering after race complete when driving through finish again
* Slightly increased length of race start markers to fit longer vehicles
* (0.33) Updated West Coast USA level files for new game version
* (0.33) Updated modified lua scripts for new game version
* (0.33) Updated traffic spawngroups with new configs using shared "simple_traffic" model
* (0.33) Fixed West Coast USA island part shop trigger inside building due to map changes
* (0.33) Fixed West Coast USA race waypoints outside aiRoads due to map changes
* (0.33) Implemented legacy drift scoring system (doesn't affect game outside BeamLR)
* (0.33) Fixed missing West Coast USA dragstrip triggers and waypoints
* (0.33) Implemented changes for new drag system compatiblity (deactivates "practice" drag in scenario)

### 1.16.5
* Fixed West Coast USA broken waypoints and AI roads causing race opponents to stay in place
* Reduced torque increase from mid-grade and premium fuel (2.5% for mid-grade, 5% for premium)

### 1.16.6
* Fixed missing GPS waypoint on West Coast USA
* Fixed West Coast USA dock warehouse delivery spot inside containers
* Replaced delayed ilinks init with call in onVehicleResetted hook (potential fix for ilinks init bug)
* Fixed broken race waypoints on every map (waypoints probably changed in 0.33)
* Fixed West Coast USA island trailer spawn point inside building
* Fixed used part value changing when removed from vehicle when using imperial units
* Improved precision of kilometers to miles conversion

### 1.16.7
* Added car shop list addon system (additive list system for multiple mod compatibility)
* Part Edit Safe Mode now used when repairing vehicles to avoid soft lock
* Fixed midsize_18dxM car shop file incorrect odometer values
* Changed car shop list file refs to remove "list_" prefix (automatically added to path when loading)
* Fixed missing autoJunction/gatedRoad changes on West Coast USA dragstrip (causing traffic on dragstrip)
* Fixed West Coast USA left hand turn where AI crashes into wall (highway exit near race track)

### 1.16.8
* Fixed West Coast USA dragstrip AI pathing (needs autoJunction enabled for some reason)

### 1.17
* Added Car Meets interactive area (car rated by "coolness", bad cars lose rep, good cars win rep)
* Added + and - buttons to tuning UI sliders for more precise edits
* Added daily seeded race clubs (more SLRR like progression, can't re-roll for pink slips & max wagers)
* Added Damage Bypass Mode (used to get out of soft lock situations when safe mode doesn't help)
* Added "Properties" interactive areas (gives extra garage slots when bought, many for sale on each map)
* Added Part Inventory menu (shows all unused parts for all vehicles, can sell parts with removed parent)
* Daredevil challenges now sorted by category (can pick challenge type)
* Fixed tune apply not enabling AVB flag causing default parts to spawn (tune set reloads jbeam)
* Disabled towing/sleeping while safe mode is active to prevent issues
* Updated drag/general.lua script with 0.33.3 changes (fixes lua error with old script version)
* Fixed lua error in performance class check node after entering trigger with "none" as triggerDataPath
* Optimized IMGUI menu selection flowgraph (also makes it easier to add new interactive areas)
* Garage slots are now limited & must be purchased (can be turned off in options)
* Fixed Moonhawk ROH config blowing up at race start due to overtorque
* Vehicle main part can now be swapped in part edit menu (ex: changing pickup frame type)
* Lowered rep unlock requirement for class D track events
* Improved track even part rewards (gives random part within set value range that fits current vehicle)
* Game will now be force unpaused during part edits to prevent issues
* Fixed part edit & buying menu layout breaking with slots name taking more than one line
* Fixed part edit menu issue for slots that have exact same name

### 1.17.1
* Fixed Bolide ROH config blowing up due to overtorque
* Fixed part edits before odometer reload permanently resetting odometer value
* Tweaked trackS performance class config list
* Fixed high RAM usage during jbeam cache process causing a game crash for some users
* Fixed UI Init Request flowgraph error during jbeam cache generation process
* Broken jbeam files are now avoided by jbeam cache process (allows good files to get cached anyway)
* Fixed garage slot count not saving properly when using a save file from previous versions
* Fixed missing west coast USA level missiongroups

### 1.17.2
* Added Track Event Slicks Mode (track event opponents get slick tire grip values to help handling)
* Added Track Events to West Coast USA (3 race track layouts, 2 dirt oval layouts)
* Track event files can now define a list of prefabs to load during event
* Fixed jbeam caching using nil gcinterval preventing the saving of cached mods file
* (0.34) Added Bruckell Nine drag config to drag race clubs
* (0.34) Added Bruckell Nine and Soliad Lansdale starter configs
* (0.34) Added Bruckell Nine ROH config
* (0.34) Added Bruckell Nine used shop config
* (0.34) Updated level files for new game version
* (0.34) Updated modified lua scripts for new game version
* (0.34) Removed some modified lua scripts due to being made obsolete by vanilla script updates
* (0.34) Freeroam drag disabling now done through game option
* (0.34) Updated traffic spawngroups with new simple_traffic configs

### 1.17.3
* Fixed broken race waypoints on West Coast USA, East Coast USA, Italy and Utah
* Fixed incorrect gooseneck delivery destination on West Coast USA
* Updated West Coast USA level with 0.34.2 changes
* Fixed missing track event level objects on West Coast USA

### 1.17.4
* Added manual gearbox synchro wear persistence and repair cost (grinding gears will add repair cost)
* Added edited manualGearbox.lua script (uncommented worn gear pop out code, tweaked pop out chance)
* Added Light Manager script (Added for Valo City optimized night lighting)
* Added defective vehicles to used car shops (can be missing engine, tires, wheels or suspension)
* Race clubs can now use shared progress files (Added for Valo City, same club at multiple locations)
* Removed quarterpanels from used sunburst randomized slots list (visible backface issue when removed)
* Tweaked used car shop randomized vehicle spawn chances (to work with new defective vehicles)
* Jbeam caching process will now be started after game updates (to load potential jbeam file changes)
* Tweaked odometer based integrity decrease (starts at 200kkm, better scaling)
* Fixed bad race waypoint on East Coast USA

### 1.17.5 
* Added nested tree view in part edit UI (similar behavior to vanilla part edit menu)
* Added tracking of approximate total of money spent on car (repairs, added or removed parts)
* Added button to export current config for use in freeroam (button in config page of part edit menu)
* Added button to add slots to a list of favorites in part edit and buying menu
* Added UI to view track event history (accessed through the Track Events page of the main menu)
* Fixed West Coast USA AI not racing on derby track events 
* Garage UI can now show extra details on cars (repair cost, fuel in tank, approximate total spent)
* Advanced Repair Cost & Advanced Repair UI now force enabled to prevent potential inventory issues
* Potential fix for multiple oil leak messages getting spammed in some situations
* Slots under wheel category now listed inside suspension category (to make room for favorites)
* Fixed vanilla waypoints breaking West Coast USA track event pathing
* Repair cost now linked to part odometer (same price as used part of same odo at a 100% scale part shop)
* Fixed incorrect orientation for some track event start teleport points
* Fixed track event "teleport to start" placing player vehicle partly underground on some tracks
* Fixed vehicle frozen when giving up race before countdown is finished

### 1.18
* Added ability to repair subparts of a damaged part without repairing parent (subparts go back to inv)
* Added select all checkbox to advanced repair menu
* Added different marker icons for each type of interactive area
* Fixed missing favorite button svg files in part edit menu
* Moved lua files from scripts folder to lua/ge/extensions
* Renamed betterpartmgmt.lua to blrpartmgmt.lua
* Fixed config fixing allowing multiple replacement parts to be selected
* (0.36) Updated ilinks system to new slot tree system using slot/part path references
* (0.36) Updated part edit UI to work with slot paths
* (0.36) Updated vanilla scripts for new game version
* (0.36) Updated code using vehicleCertifications.lua to vehiclePerformanceData.lua
* (0.36) Updated traffic spawngroups with new simple traffic variants and vehicles
* (0.36) Updated legacy drift scoring script to include missing functions needed in drift.lua
* (0.36) Updated Burnside configs in shops and races
* (0.36) Updated Sunburst configs in shops and races
* (0.36) Updated blrdragdisplay.lua script to use new drag strip object names on WCUSA
* (0.36) Fixed delivery mission G force and damage UI app to work with updated meter component
* (0.36) Updated advanced repair UI & system to work with slot/part paths
* (0.36) Fixed broken race waypoints (using automated script, some may remain that tscript can't detect)
* (0.36) Fixed GPS detection broken by slot path system
* (0.36) Fixed car shop random configs broken by slot path system
* (0.36) Fixed car config saving and loading broken by slot path system
* (0.36) Fixed track event N2O detection broken by slot path system

### 1.18.1
* Fixed "slot2" jbeam format not properly handled breaking part edit UI for some cars
* Fixed "slotType" jbeam field being a table instead of a single value causing part edit UI issues
* Fixed sorting issues with part edit & part buying menus
* Jbeam caching process should now avoid incorrectly formatted jbeam files and prevent errors
* Fixed gearbox synchro wear setting function error with cars that don't have gearbox installed
* Fixed allowType jbeam data causing various issues with part edit & buy menu (both regular and tree)
* Fixed empty name fields for certain parts in the full part inventory menu
* Fixed missing "installed" indicator in part shop when using internal slot names