$currentDirectory = Get-Location
Get-Content "$currentDirectory\beamlr.log"  -Wait -Tail 1