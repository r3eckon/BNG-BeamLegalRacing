# UI Modding
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