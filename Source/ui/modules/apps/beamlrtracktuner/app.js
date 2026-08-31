angular.module('beamng.apps')
.filter("blrtranslate", ["translateService", function(translateService){
	return function(input)
	{
	  var first = input.substring(0,1)
	  var last = input.substring(input.length-1,input.length)
	  var translated = ""
	  
	  if(first == "{" && last == "}")
	  {
		//Changing context tables name, in lua called "ctx" but has to be "context" in js
		//for contextTranslate to find it (at least as of BeamNG 0.39.0)
		var tdata = JSON.parse(input.replaceAll('\"ctx\":', '\"context\":'))
		translated = translateService.contextTranslate(tdata, true)
	  }
	  else
	  {
		translated = translateService.contextTranslate(input)
	  }

	  return translated
	}
}])
.directive('beamlrtracktuner', ['$filter',function ($filter) {
  return {
    templateUrl: '/ui/modules/apps/beamlrtracktuner/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.enabled = false
	  
	  //Universal app code start
	  //Layering code
	  var appcontainer = element[0].parentElement.parentElement.parentElement.parentElement
	  var appname = element[0].className.replace("bngApp ", "")
	  scope.setContainerZindex = function(index)
	  {
		  appcontainer.style["z-index"] = index.toString();
	  }
	  scope.moveToFront = function()
	  {
		  scope.setContainerZindex(20000);
	  }
	  scope.moveToBack = function()
	  {
		  scope.setContainerZindex(-9999);
	  }
	  scope.moveToCustom = function(layer)
	  {
		  scope.setContainerZindex(layer)
	  }
	  scope.$on('beamlrAppLayerChange', function (event, data) {
		  if(data.target == appname)
		  {
			  scope.setContainerZindex(data.layer)
		  }
	  })
	  //Default layering behavior depending on initial UI enable state
	  if(scope.enabled)
		  scope.moveToFront()
	  else
		  scope.moveToBack()
	  
	  //Translation code
	  translate = function(key)
	  {
		  return $filter('blrtranslate')(key)
	  }
	  scope.translate = translate
	  //Universal app code end
	  
	  
	  
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
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()		  
      })
	  
	  scope.toggleui = function()
	  {
		  scope.enabled = !scope.enabled
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()
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