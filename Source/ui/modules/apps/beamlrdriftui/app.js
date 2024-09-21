angular.module('beamng.apps')
.directive('beamlrdriftui', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrdriftui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.cscore = 'Not Loaded'
	  scope.tscore = 'Not Loaded'
	  scope.combo = '0.0'
	  scope.enabled = false
	  
	  scope.$on('beamlrCurrentDrift', function (event, data) {
          scope.cscore = data
      })
	  
	  scope.$on('beamlrTotalDrift', function (event, data) {
          scope.tscore = data
      })
	  
	   scope.$on('beamlrDriftCombo', function (event, data) {
          scope.combo = data
      })
	  
	  scope.$on('beamlrToggleDriftUI', function (event, data) {
          scope.enabled = data;
      })
	  
    }
  }
}]);