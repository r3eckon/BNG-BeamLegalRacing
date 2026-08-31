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
.directive('beamlrperfui', ['$filter',function ($filter) {
  return {
    templateUrl: '/ui/modules/apps/beamlrperfui/app.html',
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
		  scope.setContainerZindex(40);
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
	  
	  
	  
	  scope.perfdata = {}
	  scope.perfmode = {}
	  scope.page = 0

	  scope.$on('beamlrPerfUIData', function (event, data) {
          scope.perfdata = data
      })
	  
	  scope.$on('beamlrTogglePerfUI', function (event, data) {
          scope.enabled = data;
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()		  
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