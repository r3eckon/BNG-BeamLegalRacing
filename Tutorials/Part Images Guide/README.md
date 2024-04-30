# Part Images Guide
This guide will explain how to create part images for vehicles with minimal effort. Download the toolset.zip file listed above to get the scripts, edited gridmap and other utilities needed to follow along. This guide can be used for BeamLR part images or just to create part images for your own use.

### NOTE: This guide is unfinished/placeholder. Script utilities will be added soon.

## Step 1 - Setup
### Userfolder Setup
Look inside toolset.zip for the folder **ADD TO USERFOLDER**. Extract the contents of this folder directly inside your userfolder. This will add the **partImageGenerator.lua** script as well as the modified gridmap.

### Window Setup
As part images are square to work as thumbnails the game window should be in a 1:1 aspect ratio. To do this, set rendering mode to **windowed** in game. Then close the game and navigate to **userfolder/settings/settings.json** and open the file in notepad++ to make the following edits:

Set **GraphicsDisplayResolutions** to 800 800 (or any 1:1 aspect ratio resolution):
`
  "GraphicDisplayResolutions":"800 800",
`

Delete the **WindowPlacement** line:
`
"WindowPlacement":".....",
`

Save the edited file. Next time you run the game the window should be in 1:1 aspect ratio and ready to generate part images. Do not maximize the window. You can move it around the screen or to a different screen. If you resize the window you will need to do this process again.

### Graphic Setup
For best results the following graphic options should be used
* Mesh Quality, Texture Quality, Lighting Quality, Shader Quality: As high as your GPU can handle
* Shadows Visibility: None 
* Anisotropic Filtering: 16x
* Bloom, Light Rays, Depth of Field, Ambient Occlusion: OFF
* Anti-Aliasing: ON, SMAA

### Lighting Setup
Disable time of day "play" mode if it is enabled. Select a time of day that works for you (12:00 to 14:00 seems to work best in my experience) and stick with it as much as possible. This is to ensure the cropping script is able to detect a solid background color. For certain "vertical" parts (like wheels and brakes) you may need to change this value to get optimal lighting on the part. In this situation, a different "category" folder will be used to store the resulting images. More on this later.

### Game & UI Setup
Load the **Grid, Small, Pure** map. In the UI Apps menu select the "1st person" layout. This will remove all visible apps to ensure clean screenshots. After spawning the vehicle use world editor to set the position and rotation values to **0,0,0**.

### You are now ready to start taking screenshots.

## Step 2 - Creating part images

### Process overview
You are now ready to start creating part images. The process follows a repeating pattern:
1. Using old part editor, find the internal name for the slot to screenshot (**display names** toggled on)
2. Disable visibility for the entire vehicle except for this slot (eye icon)
3. Find a good camera angle using freecam (F8, use **core_camera.setSpeed(10)** for extra precision)
4. Execute the screenshot taking script

### Placing the camera
* Make sure the target part is contained within the game window
* Make sure only the white plane is visible in the background (no sky should be visible)
* If the sky must be visible (such as for upside down parts like some gas tanks) do not move the camera between screenshots and batch them in a different folder (batches will be explained below)
* For long parts, use a 45 degree angle to the part can take up as much space as possible
* The world editor scenetree contains "wall" objects that can be turned on and off as needed acting as solid color backgrounds for certain parts (like wheels and brakes)


### Screenshot taking command

After placing the camera at a good angle, make sure the part editor is closed and the only visible UI component on screen is the console and then execute the following command, replacing parameters as needed for the current part:

`
extensions.partScreenshotGenerator.start(SLOT, DELAY, RMODE, CMODE, PSLOT, KEYWORD, BATCH, FORCEVISIBLE, DELAYSS, NOHIDE, IGNITION, GPSLOT, GPKEYWORD)
`

This may seem like a lot to of parameters so let's go over them. The parameters in bold are required, the rest are optional.
* **SLOT**: The current slot to take part screenshots, in quotations since this is a string value (EX: "bx_body")
* **DELAY**: The delay between screenshot taking and next part being set (10 to 100 frames is usually enough)
* **RMODE**: Replace mode, can be **true** or **false** (false will skip existing files for same part, true will replace)
* **CMODE**: Child mode, can be **true** or **false** (true requires PSLOT and KEYWORD to be set)
* PSLOT: Parent slot for child mode (if parts for SLOT have run out, script will move to next part for PSLOT)
* KEYWORD: Keyword used to find child part (to filter parts that don't work with current camera angle)
* **BATCH**: Path relative to **userfolder/blrPartImages** that will be used to store generated images
* FORCEVISIBLE: List of slots that will still be visible during screenshot (useful for gauges, interior color, etc)
* DELAYSS: Delay the actual screenshot taking after part set (**true** or **false**, useful if loading textures/shaders)
* NOHIDE: Toggle to force visibility of entire vehicle (useful for paint design, branding, etc)
* IGNITION: Force set vehicle ignition mode (useful for electronic gauges/digital screens like those in Vivace)
* GPSLOT: Grandparent slot, extra layer of child mode looping. (See explanation below)
* GPKEYWORD: Grandparent keyword (See explanation below)

### Command examples:
The following command will take screenshots for the BX-Series rear bumper:
`
extensions.partScreenshotGenerator.start("bx_bumper_R", 100, false, false, nil, nil, "bx/main")
`

The **SLOT** parameter is set to "bx_bumper_R" which is the target slot. The **DELAY** used is of 100 frames. **RMODE** is set to false. Since **CMODE** is false the following **PSLOT** and **KEYWORD** parameters can be set to nil as they will be ignored. Finally, the **BATCH** value makes it so the screenshots are put in the userfolder/blrPartImages/**bx/main** folder. All other parameters are ignored as they are not necessary for this slot.

The following command will take screenshots for the BX-Series roof accessory:
`
extensions.partScreenshotGenerator.start("bx_roof_accessory_coupe", 100, false, true, "bx_body", "roof_accessory", "bx/main")
`

In this example, the main difference is that the car has different roof accessory slots for each body type (which can be seen by the _coupe ending for the slot) therefore **CMODE** is set to true and the **PSLOT** is set to "bx_body" which is the parent slot that will be changed once all coupe roof accessory parts have been screenshotted. The **KEYWORD** value is set to "roof_accessory" which will be used in string matching to find the slot "bx_roof_accessory_hatch" and start looping over its parts.  

**GPSLOT** and **GPKEYWORD** works in exactly the same way, it is an extra layer of looping for specific parts that can be automated. For instance, the pickup has different frames, which have different bodies, which have different beds. In this case the main slot would be the bed, the parent would be the body and the grandparent would be the frame. When used correctly the script will loop over the entire set of parts without user intervention.

The following command will take screenshots for the BX-Series paint designs:
`
extensions.partScreenshotGenerator.start("paint_design", 100, false, false, nil, nil, "bx/main", nil, true, true)
`

In this example, the main difference is that **DELAYSS** and **NOHIDE** are set to true. This will make it so the screenshot taking is delayed after part is set (to ensure paint design textures are loaded) and force the entire vehicle to stay visible (which will best show the paint design).

These 3 examples show the usage of this command for the vast majority of parts.


### Screenshot batching
The folder specified by the **BATCH** parameter contains a reference file named **BACKGROUND.png** which will be used for automated cropping of empty space around parts. This is the reason why images with different backgrounds must be placed in different batch folders. If you put all images in the same batch folder the cropping script will fail to crop images with pixel values different than the background reference.

Using the **NOHIDE** parameter will show the vehicle in the background reference. It is recommended not to use this parameter for the last part in a batch otherwise you will need to do an extra pass to recreate the correct background reference (or manually fix the background image in an image editor).

### Process monitoring
If you have a second monitor, I recommend you use it to monitor the process in two ways:

1. Open the current batch folder and sort files by date. The latest screenshot will be shown as the first file in the folder allowing you to quickly see if something went wrong.
2. Open the file **userfolder/blrPartImages/log.txt** in Notepad++ and toggle on monitoring (eye button).

The log file will contain important information regarding the process, what step it is currently performing, how many screenshots have been taken as well as the current time when a step is executed. Example output:

```
[17:24:41] Execution started
[17:24:41] Taking background screenshot
[17:24:41] Iteration for part: bx_lightbar_coupe_red
[17:24:41] Setting slot bx_roof_accessory_coupe to part bx_lightbar_coupe_red
[17:24:43] onVehicleResetted called
[17:24:43] Taking screenshot, path: blrPartImages/bx_lightbar_coupe_red
[17:24:43] cpart (1) was less than #parts (3) incrementing to next part
[17:24:44] Calling iteration from onPreRender
[17:24:44] Iteration for part: bx_lightbar_coupe
[17:24:44] Setting slot bx_roof_accessory_coupe to part bx_lightbar_coupe
[17:24:46] onVehicleResetted called
[17:24:46] Taking screenshot, path: blrPartImages/bx_lightbar_coupe
...
[17:25:00] cmode was false or parent list exhausted, finishing
[17:25:00] Resetting parent slot bx_body to initial chosen part bx_body_coupe
[17:25:00] Part screenshots finished!
[17:25:00] Took 6 new screenshots
[17:25:00] Skipped 0 screenshots due to existing part images
[17:25:02] onVehicleResetted called
```

### Problems to expect
While this script is quite helpful for the tedious repetitive nature of taking screenshots for thousands of parts it is nowhere near perfect (code is in fact a mess) and you will likely encounter some problems along the way. Here are some of them as well as solutions:

* Some slots have parts which aren't stable when used in this script, for instance the main "body" part of a lot of vanilla vehicles have "simple traffic" variants which don't usually play well with this script. This may cause the script to crash, then resume on its own after you manually change parts with the part editor.
* Some slots have names that make it impossible for string matching to work correctly. In this case the best solution is to avoid using **CMODE** and simply loop over the slot then manually change the parent slot.
* Some parts make use of shaders/textures that can take some time to load. Using **DELAYSS** can usually compensate for the loading time.
* Since vehicles spawn some height off the ground causing it to drop until the suspension takes effect, placing the camera very close to some parts may cause them to be outside the screenshot frame when the screenshot is taken. This can be an issue for very small parts such as branding logos and shift lights. Using **DELAYSS** may help counteract this issue.
* The **DELAYSS** feature does not work well with **CMODE** looping, can result in blank images and skipped screenshots. If you must use delayed mode due to texture issues, avoid using child part looping.

If you notice something wrong with camera placement mid process, open the console and execute the following command:
`
extensions.partScreenshotGenerator.cancel()
`

Unfortunately since this script is running on the game main thread it will delay key presses so you will be typing without seeing characters updating in the console immediately. Once the command is fully entered spam the enter key until the process has stopped. Depending on the amount of parts for a particular slot this may or may not be faster than letting it complete before starting over. 

## Step 3 - Cropping (and encoding) images
You should now have folders filled with raw part images. The final part of this process is to crop (and optionally re-encode) images. The toolset.zip archive contains a program that can do this automatically, granted you have correctly batched images with matching background reference files.

TODO: Finish & polish guide, add script utilities.