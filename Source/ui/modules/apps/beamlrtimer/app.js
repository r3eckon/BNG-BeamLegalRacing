angular.module('beamng.apps')
.directive('beamlrtimer', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrtimer/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.enabled = true
	  scope.racemode = false
	  scope.totaltime = null
	  scope.laptime = null
	  scope.deltatime = null
	  scope.deltasymbol = ""
	  scope.deltacolor = "white"
	  scope.offset = 0
	  scope.newLap = false
	  scope.lastlap = null
	  scope.clap = 0
	  scope.updatedelta = false
	  scope.sentforlap = 0
	  scope.sendqueued = false
	  scope.initdone = false
	  scope.lastlastlap = null
	  
	  scope.$on('BeamLRTimerData', function(event, data){
		scope.offset = data.offset
		scope.lastlap = data.lastlap
		scope.clap = data.clap
		scope.deltatime = data.deltatime
		scope.sentforlap = data.sentforlap
		scope.deltacolor = data.deltacolor
		scope.deltasymbol = data.deltasymbol
		scope.initdone = true
		scope.lastlastlap = data.lastlastlap
	  })
	  
	  scope.$on('raceTime', function (event, data) {
		scope.racemode = data.racemode
		
		if(data.time < 0)
		{
			scope.laptime = null
			scope.totaltime = null
			scope.deltatime = null
			scope.deltacolor = "white"
			scope.deltasymbol = ""
			return
		}
		
		//console.log("RECEIVED TIME " + data.time * 1000.0 )
		
        if (scope.newLap) {
		  scope.laptime = Math.floor((data.time - scope.offset) * 1000)//FIXES ISSUE WITH INCORRECT DELTA, LAP TIME OFFSET WAS SET TO data.time FROM PREVIOUS CALL OF raceTime SO THIS UPDATES TO NEWEST VALUE
          scope.offset = Math.floor(data.time * 1000) / 1000//MATH.FLOOR NEEDED TO FIX SMALL INCONSISTENCIES WITH UI VALUE
		  scope.lastlastlap = scope.lastlap
		  scope.lastlap = scope.laptime
          scope.newLap = false
		  //console.log("NEW LAP CALLED, LAP TIME " + scope.laptime + " OFFSET " + scope.offset)
        }
		
		if(scope.updatedelta)
		{
			scope.updatedelta = false
			
			if(scope.clap > 1)
			{
			scope.deltatime = Math.floor(scope.lastlap - scope.lastlastlap)
			//console.log("CALCULATED DELTA " + scope.deltatime + "\nFROM LATEST LAP TIME " + scope.lastlap + "\nMINUS PREVIOUS LAP TIME " + scope.lastlastlap)
			if(scope.deltatime < 0){
				scope.deltasymbol = "-"
				scope.deltacolor = "lime"
			}
			else if(scope.deltatime > 0)
			{
				scope.deltasymbol = "+"
				scope.deltacolor = "red"
			}
			else
			{
				scope.deltasymbol = ""
				scope.deltacolor = "white"
				scope.deltatime = 0
			}
			
			
			scope.deltatime = Math.abs(scope.deltatime)
			

			}
		}
		
		scope.totaltime = Math.floor(data.time * 1000)
		scope.laptime = Math.floor((data.time - scope.offset) * 1000)
		
		//console.log("LAPTIME: " + scope.laptime)
		//console.log("TOTALTIME: " + scope.totaltime)
		
		if(scope.sendqueued){
			scope.sendqueued = false
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("timerdata", "offset", ${scope.offset})`);
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("timerdata", "lastlap", ${scope.lastlap})`);
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("timerdata", "lastlastlap", ${scope.lastlastlap})`);
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("timerdata", "clap", ${scope.clap})`);
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("timerdata", "deltatime", ${scope.deltatime})`);
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("timerdata", "deltacolor", "${scope.deltacolor}")`);
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("timerdata", "deltasymbol", "${scope.deltasymbol}")`);
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("timerdata", "sentforlap", ${scope.clap})`);
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("timerSavedData", "timerdata")`);
			//console.log("SENT DELTA COLOR " + scope.deltacolor + "\nSENT DELTA SYMBOL " + scope.deltasymbol)
		}
		
		//Need this to force timer app to update as fast as data is received
		//Wasn't an issue with race timer but happened with clock + increased time scale
		scope.$apply()
		
      })
	  
	  scope.$on('BeamLRRaceFinished', function(event, data){
		scope.updatedelta = true
		scope.sendqueued = true
		scope.lastlastlap = scope.lastlap
		scope.lastlap = scope.laptime
	  })

      scope.$on('ScenarioResetTimer', function(event, data){
		scope.offset = 0
		scope.newLap = false
		scope.laptime = null
		scope.totaltime = null
		scope.deltatime = null
		scope.deltasymbol = ""
		scope.deltacolor = "white"
		scope.clap = 0
		scope.updatedelta = false
	  })

      scope.$on('RaceLapChange', function (event, data) {
        if (data && data.current > 1 && scope.clap != data.current) {
          scope.newLap = true
		  scope.clap = data.current
		  if(scope.sentforlap < data.current && scope.initdone)
		  {
			scope.sendqueued = true
		  }
		  if(data.current > 2)//No delta on first lap completion
		  {
			scope.updatedelta = true
		  }
        }
		
      })
	  
	  
	  
    }
  }
}]);