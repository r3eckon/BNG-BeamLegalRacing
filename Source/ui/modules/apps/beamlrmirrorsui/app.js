angular.module('beamng.apps')
.filter("blrtranslate", ["translateService", function(translateService){
	return function(input)
	{
	  var first = input.substring(0,1)
	  var last = input.substring(input.length-1,input.length)
	  var translated = ""
	  
	  if(first == "{" && last == "}")
	  {
		//Changing context tables name, in lua called "ctx" but has to be "context" in js
		//for contextTranslate to find it (at least as of BeamNG 0.39.0)
		var tdata = JSON.parse(input.replaceAll('\"ctx\":', '\"context\":'))
		translated = translateService.contextTranslate(tdata, true)
	  }
	  else
	  {
		translated = translateService.contextTranslate(input)
	  }

	  return translated
	}
}])
.directive('beamlrmirrorsui', ['$filter',function ($filter) {
  return {
    templateUrl: '/ui/modules/apps/beamlrmirrorsui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.enabled = false
	  
	  //Universal app code start
	  //Layering code
	  var appcontainer = element[0].parentElement.parentElement.parentElement.parentElement
	  var appname = element[0].className.replace("bngApp ", "")
	  scope.setContainerZindex = function(index)
	  {
		  appcontainer.style["z-index"] = index.toString();
	  }
	  scope.moveToFront = function()
	  {
		  scope.setContainerZindex(3000);
	  }
	  scope.moveToBack = function()
	  {
		  scope.setContainerZindex(-9999);
	  }
	  scope.moveToCustom = function(layer)
	  {
		  scope.setContainerZindex(layer)
	  }
	  scope.$on('beamlrAppLayerChange', function (event, data) {
		  if(data.target == appname)
		  {
			  scope.setContainerZindex(data.layer)
		  }
	  })
	  //Default layering behavior depending on initial UI enable state
	  if(scope.enabled)
		  scope.moveToFront()
	  else
		  scope.moveToBack()
	  
	  //Translation code
	  translate = function(key)
	  {
		  return $filter('blrtranslate')(key)
	  }
	  scope.translate = translate
	  //Universal app code end
	  
	  
	  scope.mdata = {}
	  scope.sorted = {}
	  scope.selected = "none"
	  scope.cox = 0;
	  scope.coy = 0;
	  scope.max = 0;
	  scope.min = 0;
	  
	  
	  
	  scope.$on('beamlrToggleMirrorsUI', function (event, data) {
          scope.enabled = data;
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()		  
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
		  scope.moveToBack()
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