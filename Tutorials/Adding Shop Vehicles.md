# Adding modded vehicles and custom configs to shops

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