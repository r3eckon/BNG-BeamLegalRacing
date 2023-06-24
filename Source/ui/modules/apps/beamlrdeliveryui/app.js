angular.module('beamng.apps')
.directive('beamlrdeliveryui', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrdeliveryui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.mforce = 0
	  scope.cforce = 0
	  scope.enabled = false
	  
	  scope.$on('beamlrDeliveryMaxForce', function (event, data) {
          scope.mforce = data
      })
	  
	  scope.$on('beamlrDeliveryCurrentForce', function (event, data) {
          scope.cforce = data
      })
	  
	  scope.$on('beamlrToggleDeliveryUI', function (event, data) {
          scope.enabled = data;
      })
	  
	  scope.formatValue = function(value)
	  {
		  return Math.round(value * 100) / 100;
	  }
	  
	  
    }
  }
}]);