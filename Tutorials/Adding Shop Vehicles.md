# Adding modded vehicles and custom configs to shops

## NOTE THAT THIS GUIDE IS OBSOLETE

A new UI app has been added to add vehicles to dealerships. 
[See this video for an overview on how to use it](https://www.youtube.com/watch?v=1_O6-1_FsVk).

The below guide can still be a good read for users that wish to understand how dealerships work behind the scenes.

## Step 1: Creating a car shop file

Copy a file in the **beamLR/shop/car** folder so you have a new car file ready to replace values. Rename it to a unique file name. Opening that file you then replace the fields for your modded cars or custom configs. For this example the file used is **autobello_110AM**.

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

### Optional Step: Randomized Slots

The **randslots** line simply isn't there on new cars as they do not spawn with randomized parts. If you don't want randomized parts, remove that line. To use randomized parts use the following process:

Get a list of vehicle slots to find all the slots for body panels: 

1. Spawn the config in game
2. In lua console use the line **extensions.blrutils.actualSlotDebug()**

This will dump the slots of that vehicle in the file **beamLR/actualSlotsDebug** so you can create the list of body panel slots. To create the list use the following process:

1. Look through the list to remove slots you don't want randomized (such as engine parts, wheels, other important parts)
2. Use Notepad++ search and replace **extended mode** to replace **\n** with a **comma**
3. Append that list to the **randslots** field.

Make sure the list is on a single line and each item separated by a comma before appending to **randslots**. Keep in mind if you hit enter when removing slots it might add **\r\n** so if the list isn't in a single line that's probably why. 

## Step 2: Adding the car file to a shop list

Once you're done with the car file itself the next step is to make it available in shops. This process has been improved in version 1.12 to use list files. To find out which list file a particular shop uses, open the respective shop file stored in **beamLR/shop** for example the file **utahUsedCarShop**. This file points to a list file using the **models** field:

```
name=Used Car Shop
slots=4
chance=0.9
rpchance=0.3
shopid=0
models=used_all
slotp0=824.29364013672,-0.1175025672017,147.83654785156
slotr0=0.0019109094749717,0.034539506349485,-0.82961584485164,0.55832066827696
...
```
The value **used_all** points to the file **beamLR/shop/car/list_used_all**. Keep in mind that the **list_** prefix is added programatically to the path when loading the file. As of version 1.16.7 car shops share the same few list files though this may change at some point to create more region specific shops depending on map. For now you can use the following reference:

* Used Car Shop: **used_all**
* New Car Shop: **new_all**
* Scrapyard: **scrap_all**
* Mixed Car Shop: **mixed_all**


Part of the **used_all** list can be seen below. Each line must point to a vehicle files in **beamLR/shop/car**. 

```
coupe_baseM
coupe_malodorous
coupe_typeLSM
barstow_awful
barstow_232I6M
bluebuck_horrible
...
```
Since version 1.16.7 the addon compatibility has been improved for shop list files. This allows modders to create additive lists that don't affect the original list, meaning BeamLR can now work with multiple car shop addons. To create a car list addon, create a folder with the name of the list inside **beamLR/shop/car** replacing the **list_** prefix with **addon_** like so:

![](https://i.imgur.com/qixE0oi.png)

Inside that folder, create a file and give it a unique enough name to avoid potential conflicts with other addons. 

![](https://i.imgur.com/PDnUozh.png)

Following the same format as vanilla list files (one item per line), add your car files to the list.

![](https://i.imgur.com/2FIreTv.png)

Your addon list files will now be dynamically added to the regular list files allowing custom cars to spawn in shops that use this list. The below screenshot shows the list **testbug** (usually used to spawn a single car when debugging) before and after creating addon files in the folder **beamLR/shop/car/addon_testbug**:

![](https://i.imgur.com/Xt7spex.png)

The vanilla **testbug** list only contains **moonhawk_i6M**, the first addon file adds **bx_old_A** and **bx_old_B** while the second addon file adds **bx_old_C** and **bx_old_D**. If you want to make sure that your addons are properly loading, use the following command in console (replacing **testbug** with the name of the list you are adding to.

`
for k,v in pairs(extensions.blrutils.loadCarShopList("testbug")) do print(v) end
`

This will dump a more easily readable list of all car files that are loaded in shops that use this list file:

![](https://i.imgur.com/OZLIvJu.png)

## Step 3: Testing
To make sure your vehicle spawns in game the easiest way is to add it to the **testbug** list and temporarily change the list file for a particular shop to use that list. I usually do this with the used car shop on Utah because of its close proximity to the spawn point. This will force the shop to only spawn that car and will quickly allow you to find out if the car file is valid. 

If the car doesn't spawn or other errors occur, verify that your got the config path correct. Make sure that all non optional fields have been properly added to the car file. Make sure that the **randslots** field list is properly formatted. You can remove it temporarily to see if this allows the car to spawn.

## Step 4: Packaging your addon as a zip file mod
The regular BeamNG mod packaging guidelines apply here. The zip file for your car shop addon **should only contain only the files being added**, placed within the zip file at the **same relative location as inside the userfolder**. As a reference, a zip file that adds a single car should at minimum contain the following items at their respective locations:

* Car file: **beamLR/shop/car/myCar**
* Config file: **vehicles/model/config.pc**
* List addon: **beamLR/shop/car/addon_used_all/myListAddon**

A good way to do this is to create the folder structure first, making sure to double check so the paths are exactly the same. Then copy the needed files at their respective locations before archiving everything.

Thanks to the new addon loading system added in 1.16.7 no BeamLR files will be overwritten, meaning your addon can be used alongside other addons. Keep in mind that this system is not immune to potential conflicts caused by the same file names being used for car files, configs or list addons. In such a situation, the vanilla mod loading order (which is alphabetical) may prevent your mod from loading. This is why it is recommended to use file names that are as unique as possible, for instance by adding your username to files.