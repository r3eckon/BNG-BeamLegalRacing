angular.module('beamng.apps')
.directive('beamlrtowui', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrtowui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.cscore = 'Not Loaded'
	  scope.tscore = 'Not Loaded'
	  scope.enabled = false
	  
	  scope.$on('beamlrToggleTowUI', function (event, data) {
          scope.enabled = data;
      })
	  
	  scope.cancel = function(){
		scope.enabled = false;
	  }
	  
	  scope.select = function(d){
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("towdest", "${d}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("towSelectDestination", "towdest")`)
	  }
	  
	  
    }
  }
}]);