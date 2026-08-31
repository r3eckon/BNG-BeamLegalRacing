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
.directive('beamlrtrackeventui', ['$filter',function ($filter) {
  return {
    templateUrl: '/ui/modules/apps/beamlrtrackeventui/app.html',
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
		  scope.setContainerZindex(10000);
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
	  
	  
	  
	  scope.leaderboard = {}
	  scope.eventdata = {}
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
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()		  
      })
	  
	  scope.toggleui = function()
	  {
		  scope.enabled = !scope.enabled
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()		  
	  }
	  
    }
  }
}]);