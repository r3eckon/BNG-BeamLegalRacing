angular.module('beamng.apps')
.directive('beamlrgpsui', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrgpsui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.enabled = false
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