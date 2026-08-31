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
.directive('beamlrtrackeventbrowser', ['$filter',function ($filter) {
  return {
    templateUrl: '/ui/modules/apps/beamlrtrackeventbrowser/app.html',
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
		  scope.setContainerZindex(10000);
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
	  
	  
	  scope.playerdata = {}
	  scope.cardata = {}
	  scope.garage = {}
	  scope.eventlist = {}
	  scope.eventdata = {}
	  scope.selected = false
	  scope.selectedID = 0
	  scope.vehdamage = 0
	  scope.inspection = false
	  scope.currentevent = {}
	  scope.mode = 0
	  scope.pastevents = {}
	  
	  
	  
	  scope.$on('beamlrEventBrowserPlayerData', function (event, data) {
          scope.playerdata = data
      })
	  
	  scope.$on('beamlrEventBrowserData', function (event, data) {
          scope.eventdata = data
		  scope.selected = true
      })
	  
	  scope.$on('beamlrEventBrowserList', function (event, data) {
          scope.eventlist = data
      })
	  
	  scope.$on('beamlrEventBrowserGarage', function (event, data) {
          scope.garage = data
      })
	  
	  scope.$on('beamlrEventBrowserCarData', function (event, data) {
          scope.cardata = data
      })
	  
	  scope.$on('beamlrToggleTrackEventBrowser', function (event, data) {
          scope.enabled = data
		  scope.mode = 0
		  
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()		  
      })
	  
	  scope.$on('beamlrEventBrowserVehicleDamage', function (event, data) {
          scope.vehdamage = data
      })
	  
	  scope.$on('beamlrEventBrowserInspectionStatus', function (event, data) {
          scope.inspection = data
      })
	  
	  scope.$on('beamlrEventBrowserCurrentEvent', function (event, data) {
          scope.currentevent = data
      })
	  
	  scope.$on('beamlrEventBrowserReloadUID', function (event, data) {
          scope.selectedID = data
      })

	  scope.$on('beamlrTogglePastEventsList', function (event, data) {
          scope.enabled = data
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()
		  scope.mode = 1
      })
	  
	  scope.$on('beamlrPastEventData', function (event, data) {
          scope.pastevents = data
      })  

	  scope.eventSelected = function(file, uid){
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("selectedEvent", "file", "${file}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("selectedEvent", "uid", "${uid}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("selectEventFile", "selectedEvent")`)
		  scope.selectedID = uid
	  }
	  
	  scope.joinEvent = function(file, uid){
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("joinedEvent", "file", "${file}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("joinedEvent", "uid", "${uid}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("joinEvent", "joinedEvent")`)
	  }
	  
	  scope.toggleui = function()
	  {
		  scope.enabled = !scope.enabled
		  if(!scope.enabled)
		  {
			  bngApi.engineLua(`extensions.customGuiCallbacks.exec("hideEventBrowser")`)
		  }
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()
	  }
	  
	  
	  
    }
  }
}]);