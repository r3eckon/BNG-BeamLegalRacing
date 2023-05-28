angular.module('beamng.apps')
.directive('beamlrtrackeventbrowser', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrtrackeventbrowser/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.playerdata = {}
	  scope.cardata = {}
	  scope.garage = {}
	  scope.eventlist = {}
	  scope.eventdata = {}
	  scope.enabled = false
	  scope.selected = false
	  scope.selectedID = 0
	  scope.vehdamage = 0
	  scope.inspection = false
	  scope.currentevent = {}
	  
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
	  }
	  
    }
  }
}]);