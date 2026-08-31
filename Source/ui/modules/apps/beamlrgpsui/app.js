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
.directive('beamlrgpsui', ['$filter',function ($filter) {
  return {
    templateUrl: '/ui/modules/apps/beamlrgpsui/app.html',
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
		  scope.setContainerZindex(1000);
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
	  
	  

	  scope.page = 0
	  scope.destinations = {}
	  scope.currentDestination = ""
	  scope.currentDistance = 0
	  scope.distanceUnit = ""
	  
	  
	  
	  scope.$on('beamlrGPSDestinationList', function (event, data) {
          scope.destinations = data
      })
	  
	  scope.$on('beamlrGPSCurrentDestination', function (event, data) {
          scope.currentDestination = data
      })	
	  
	  scope.$on('beamlrGPSCurrentDistance', function (event, data) {
          scope.currentDistance = data
      })

	  scope.$on('beamlrGPSDistanceUnit', function (event, data) {
          scope.distanceUnit = data
      })

	  scope.$on('beamlrGPSPageReload', function (event, data) {
          scope.page = data
      })
	  
	  scope.$on('beamlrGPSToggleState', function (event, data) {
          scope.enabled = data
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()		  
      })
	  
	  scope.setPage = function(page)
	  {
		  scope.page = page
	  }
	  
	  scope.selectDestination = function(d){
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("destination", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("gpsSelectDestination", "destination")`)
		  scope.page = 3
	  }
	  
	  scope.findNearest = function(d){
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("nearest", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("gpsFindNearest", "nearest")`)
		  scope.page = 3
	  }
	  
	  scope.cancelRoute = function(){
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("gpsCancelRoute")`)
		  scope.page = 0
	  }	  
	  
    }
  }
}]);