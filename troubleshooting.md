# Troubleshooting
If you are experiencing issues with the mod please follow these steps before reporting them to confirm the bug is with BeamLR.

## Step 1 - Update Game & Mod
Make sure that you are on the latest version of the game and BeamLR. Even though the mod may not be compatible with the latest game version bug reports relating to compatibility with new BeamNG updates are useful and such bugs are usually addressed in quickly released hotfixes.

Also try verifying integrity of game files through Steam in case some corrupt game files might be to blame. Some players have mistakenly installed mods or otherwise messed with the game install folder. If you suspect your game install folder contains such files, the easiest way to fix it is to uninstall the game, delete any remaining files and reinstall the game.

## Step 2 - Careful Reinstall
A lot of problems can be caused by incorrect installation. Back up your career files before reinstalling to ensure you don't lose any progress. Make sure to carefully follow the install instructions. You should then be able to restore your backup using the in game options menu or, if this fails to work, by manually overwritting the fresh BeamLR folder with your backup.

## Step 3 - Clean Userfolder

Installing the mod in a clean [userfolder](https://documentation.beamng.com/support/userfolder/) can solve most issues caused by incorrect installation or conflicting mods.

Following the below process correctly will generate a brand new userfolder in a new location to perform a clean install. **Your current userfolder will not be affected**. Pay close attention and do not skip any step. If you want to be extra safe feel free to backup your current userfolder.

1. Open the BeamNG Launcher
2. Click **"Manage User Folder"**
3. Uncheck the **"Move user data"** checkbox as shown below (**IMPORTANT to avoid moving userfolder files to new location!**)
4. Click **"Choose a new location"**
5. Select a different folder than the current userfolder
6. Start BeamNG to generate base files inside the new userfolder
7. Close BeamNG
8. Install BeamLR in the newly created userfolder **carefully following the instructions**

![checkbox](https://i.imgur.com/H822pm6.png)

If this process fixes your issue this means you either installed incorrectly the first time or something in your userfolder was conflicting with the mod. 

If you absolutely must play with other mods, add them one at a time and test to make sure there are no conflicts. 

Also, consider using separate userfolders to create "modpacks" or collections of compatible mods. Using the launcher's userfolder moving function with the "move user data" button unchecked you can create and select different userfolders. You can use this to keep BeamLR and compatible mods in a separate userfolder to other mods that cause conflicts without having to manually backup or delete files.

## Still having issues? 

If your issue can be reliably reproduced, take note of steps needed to recreate the problem and mention them in your bug report. 

Attach your log files (found inside the userfolder) to your bug report. Do not post screenshots of error pop-ups in game, this error message is useless most of the time. 

![logs](https://i.imgur.com/6BDvi7C.png)

Once again to remove unrelated output, delete these files before the error happens. The "beamng-launcher" log files are unrelated and don't need to be attached to your bug report.

Finally, please attach to your bug report any screenshots, videos or information you think could help fix the issue. List any steps you took to try to fix the issue. 

The more comprehensive your bug report is, the faster the bug will be fixed.

## Userfolder Structure Dump

In some cases I may request a dump of the userfolder structure to confirm everything is installed correctly. 

Follow this process to generate the tree file:

1. Navigate to the userfolder
2. Hold down the SHIFT key > Right click in the folder empty space > "Open PowerShell window here"
3. Type this line and hit enter

`tree > tree.txt /a /f`

This will create a text file called tree.txt in your userfolder which contains the folder structure. 

Attach this to your bug report or post it on the forum as requested.


## Viewing Jbeam Caching Progress

When caching jbeam files with a lot of mods the game may appear to be frozen. This process will usually take a few minutes depending on hardware and installed mods. 

To make sure the process isn't frozen you can tail the beamlr.log file (command works on Windows, Linux also has equivalents):

1. Open windows powershell 
2. Type the following line (replace path to log file with correct path for your userfolder) and hit enter

`Get-Content C:\Users\r3eck\AppData\Local\BeamNG.drive\current\beamlr.log  -Wait -Tail 1`

The powershell window will now display jbeam caching progress in percent as well as remaining steps and files left to process. You can use this to ensure the process isn't frozen and also to estimate how long it will take to complete.

