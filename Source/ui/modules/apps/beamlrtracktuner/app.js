angular.module('beamng.apps')
.directive('beamlrtracktuner', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrtracktuner/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.enabled = false
	  scope.tuningData = {}
	  scope.tuningValues = {}
	  scope.textBoxFocus = false
	  scope.tuningFields = {}
	  scope.tuningCategories = {}

	  scope.$on('beamlrTrackTuningValues', function (event, data) {
          scope.tuningValues = data
      })

	  scope.$on('beamlrTrackTuningData', function (event, data) {
          scope.tuningData = data
      })
	  
	  scope.$on('beamlrTrackTuningFields', function (event, data) {
          scope.tuningFields = data
      })
	  
	  scope.$on('beamlrTrackTuningCategories', function (event, data) {
          scope.tuningCategories = data
      })

	  scope.$on('beamlrToggleTrackTuningUI', function (event, data) {
          scope.enabled = data
      })
	  
	  scope.toggleui = function()
	  {
		  scope.enabled = !scope.enabled
	  }
	  	  
	  scope.tuneChanged = function(id)
	  {
		  scope.tuningValues[id] = parseFloat(scope.tuningValues[id])
	  }
	  
	  scope.getTuneData = function(id)
	  {
		  return Math.round(parseFloat(scope.tuningValues[id]) * 1000) / 1000;
	  }

	  scope.applyTune = function()
	  {
		  var ckey = "";
		  var cval = 0;
		  
		  Object.keys(scope.tuningValues).forEach(key => {
			ckey = key;
			cval = scope.tuningValues[key];
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("tuneData", "${ckey}", ${cval})`)
		  });
		  
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTuneTrack", "tuneData")`)
	  }
	  
	  scope.resetTune = function()
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("resetTuneTrack")`)
	  }
	  
	  scope.textboxHover = function(){
		if (!scope.textBoxFocus) return
		bngApi.engineLua('setCEFFocus(true)')
	  }
	  
	  scope.textboxClick = function(){
		scope.textBoxFocus=true
		bngApi.engineLua('setCEFFocus(true)')
	  }
	  
	  scope.preciseTuneDecrease = function(field, step)
	  {
		  scope.tuningValues[field] = Math.max(scope.tuningData[field]['minDis'],scope.tuningValues[field] - step)
	  }
	  
	  scope.preciseTuneIncrease = function(field, step)
	  {
		  scope.tuningValues[field] = Math.min(scope.tuningData[field]['maxDis'],scope.tuningValues[field] + step)
	  }  
	  
	  
    }
  }
}]);