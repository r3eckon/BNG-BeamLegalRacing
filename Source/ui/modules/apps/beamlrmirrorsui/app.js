angular.module('beamng.apps')
.directive('beamlrmirrorsui', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrmirrorsui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.enabled = false
	  scope.mdata = {}
	  scope.sorted = {}
	  scope.selected = "none"
	  scope.cox = 0;
	  scope.coy = 0;
	  scope.max = 0;
	  scope.min = 0;
	  
	  scope.$on('beamlrToggleMirrorsUI', function (event, data) {
          scope.enabled = data;
      })
	  
	  scope.$on('beamlrMirrorsData', function (event, data) {
          scope.mdata = data;
		  scope.selected = "none" //to return to main menu when changing cars
      })
	 
	  scope.$on('beamlrSortedMirrors', function (event, data) {
          scope.sorted = data;
      })
	  
	  scope.close = function()
	  {
		  scope.enabled = false
	  }
	  
	  scope.selectMirror = function(mirror)
	  {
		  scope.selected = mirror
		  scope.cox = scope.mdata[mirror]["angle"]["x"]
		  scope.coy = scope.mdata[mirror]["angle"]["z"]
		  scope.min = scope.mdata[mirror]["clampX"][0]
		  scope.max = scope.mdata[mirror]["clampX"][1]
	  }
	  
	  scope.deselect = function()
	  {
		  scope.selected = "none"
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("mirrorUIUpdate")`);//request updated mirror data to reflect any changes
	  }
	  
	  scope.updateMirror = function(mirror, offsetX, offsetY)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("mirrorUpdate", "mirror", "${mirror}")`);
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("mirrorUpdate", "offsetX", ${offsetX})`);
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("mirrorUpdate", "offsetY", ${offsetY})`);
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("updateMirrorOffsets", "mirrorUpdate")`);
	  }
	  
    }
  }
}]);