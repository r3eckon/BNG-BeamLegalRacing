# Adding New Missions

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