angular.module('beamng.apps')
.directive('beamlrtrackeventui', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrtrackeventui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.leaderboard = {}
	  scope.eventdata = {}
	  scope.enabled = false
	  scope.rewards = {}
	  
	  scope.$on('beamlrEventLeaderboard', function (event, data) {
          scope.leaderboard = data
      })
	  
	  scope.$on('beamlrEventRewards', function (event, data) {
          scope.rewards = data
      })
	  
	  scope.$on('beamlrEventData', function (event, data) {
          scope.eventdata = data
		  console.log(data["status"])
      })
	  
	  scope.$on('beamlrToggleTrackEventUI', function (event, data) {
          scope.enabled = data
      })
	  
	  scope.toggleui = function()
	  {
		  scope.enabled = !scope.enabled
	  }
	  
    }
  }
}]);