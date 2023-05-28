angular.module('beamng.apps')
.directive('beamlrperfui', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrperfui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.perfdata = {}
	  scope.perfmode = {}
	  scope.enabled = false
	  scope.page = 0
	  
	  scope.$on('beamlrPerfUIData', function (event, data) {
          scope.perfdata = data
      })
	  
	  scope.$on('beamlrTogglePerfUI', function (event, data) {
          scope.enabled = data;
      })
	  
	  scope.$on('beamlrPerfUIModes', function (event, data) {
          scope.perfmode = data
      })
	  
	  scope.formatNumber = function(num){
	      return Math.round(parseFloat(num) * 1000) / 1000
	  }
	  
	  scope.switchPage = function(page){
		  scope.page = page
	  }
	  
	  scope.modeChange = function(field){
		  if(field == "power")
		  {
			  scope.perfmode[field] = (scope.perfmode[field] + 1)%3
		  }
		  else
		  {
			  scope.perfmode[field] = (scope.perfmode[field] + 1)%2
		  }
		  
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("perfuiMode", "field", "${field}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("perfuiMode", "mode", "${scope.perfmode[field]}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("perfuiSetMode", "perfuiMode")`)

	  }
	  
    }
  }
}]);