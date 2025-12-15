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
		//1.19.2 fix for UI init restoring incorrect state after cancelling
		//go through customGuiStream lua script to toggle off UI to save correct state
		scope.enabled = false;//Keeping this one in to have faster button response
		bngApi.engineLua(`extensions.customGuiStream.towingUIToggle(false)`)
	  }
	  
	  scope.select = function(d){
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("towdest", "${d}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("towSelectDestination", "towdest")`)
	  }
	  
	  
    }
  }
}]);