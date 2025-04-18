
# Addon: Nürburgring Nordschleife (ks_nord)
Adds compatibility for the Nürburgring Nordschleife mod level which can be found in the description of [this youtube video](https://www.youtube.com/watch?v=bBluGKs1wjs) alongside install instructions for the map itself. 

## Contents

* Map mission loader
* Tweaks for the AI roads
* Waypoints and triggers for the track event

## Tips

Use the **Touristenfahrten** spawn to be close to mission loader.

GP circuit events start is near the GP starting line/pits.

## Version Information
This addon is currently built for map version **v20231124_v2** (ks_nord_v20231124_v2.zip).

## Changelog
### BeamLR 1.12
* Initial Release
### BeamLR 1.12.1
* Added GP circuit layout events
### BeamLR 1.13
* Fixed mission UI abandon not ending current round
### BeamLR 1.14.1
* Updated base map version to v20231124_v2
### BeamLR 1.14.3
* Fixed event loading issue caused by removed playerName file
### BeamLR 1.15
* Added "Teleport To Start" button in track event UI
* Updated track event system to work with point system
### BeamLR 1.15.3
* Replaced timer UI with custom version (shows lap time & previous lap delta)
### BeamLR 1.16
* Fixed custom timer flickering between 00:00:000 and --:--:--- after round completed
### BeamLR 1.17.2
* Added prefab barriers to block off parts of the track depending on event layout
* Fixed broken waypoints preventing AI from racing on both layouts
### BeamLR 1.17.5
* Added flowgraph for track event history UI
