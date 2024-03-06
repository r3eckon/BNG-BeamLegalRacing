angular.module('beamng.apps')
.directive('beamlrimageviewer', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrimageviewer/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.enabled = false
	  scope.mode = 0 //0=original size, 1=scale to fit
	  scope.file = "/ui/modules/apps/beamlrui/partimg/bolide_beaconlight_blue.png"
	  
	  scope.$on('beamlrToggleImageUI', function (event, data) {
          scope.enabled = data;
      })
	  
	  scope.$on('beamlrImageUIMode', function (event, data) {
          scope.mode = data;
      })
	  
	  scope.$on('beamlrImageUIFile', function (event, data) {
          scope.file = data;
      })

		
	  scope.clicked = function(){
		scope.enabled = false;
	  }
	  
    }
  }
}]);