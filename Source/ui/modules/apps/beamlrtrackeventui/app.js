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
	  scope.initDone = false
	  
	  //1.15.3 fix, makes sure UI init is called in track event even though this
	  //specific app doesn't use it, will call ui init for timer which needs it
	  if(!scope.initDone)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("uiinit")`);
		  scope.initDone = true
	  }
	  
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