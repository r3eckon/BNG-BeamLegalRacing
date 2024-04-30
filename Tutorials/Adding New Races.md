# Adding new races

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

Since version 1.14 the **traffic** parameter works as a random chance to use traffic in a certain race.

Also new in 1.14 is the ability to define looping subsections with **lstrig** and **lswp**. For example setting lstrig to 2 and lswp to 3 would mean the looping part of this race begins at checkpoint 2, with waypoint 3 used as the start of the looping path for the AI. This allows for a starting area that doesn't need to be traversed to complete extra laps.