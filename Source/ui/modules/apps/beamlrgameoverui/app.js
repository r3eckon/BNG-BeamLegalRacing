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
.directive('beamlrgameoverui', ['$filter',function ($filter) {
  return {
    templateUrl: '/ui/modules/apps/beamlrgameoverui/app.html',
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
		  scope.setContainerZindex(100000);
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

	  
	  scope.confirmload = false
	  scope.confirmreset = false
	  scope.backopacity = 0.0
	  scope.textopacity = 0.0
	  scope.playermoney = 'Not Loaded'
	  scope.playerrep = 'Not Loaded'
	  scope.playercars = 'Not Loaded'

	  scope.invlerp = function(val, min, max)
	  {
		  return Math.max(0.0, Math.min(1.0, (val - min) / (max - min)));
	  }
	  
	  scope.topoffset = Math.floor(20.0 + 30.0 * scope.invlerp(window.innerHeight, 720.0, 1080.0))
	  
	  scope.$on('beamlrToggleGameOverUI', function (event, data) {
		  scope.enabled = data	 
		  scope.$apply()
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()
      })
	  
	  scope.$on('beamlrGameOverBackOpacity', function (event, data) {
		  scope.backopacity = parseFloat(data)
		  scope.$apply()
      })
	  
	  scope.$on('beamlrGameOverTextOpacity', function (event, data) {
		  scope.textopacity = parseFloat(data)
		  scope.$apply()
      })
	  
	  scope.$on('beamlrGameOverStats', function (event, data) {
		  scope.playermoney = data['money']
		  scope.playerrep = data['reputation']
	      scope.playercars = data['cars']
		  scope.$apply()
      })
	 
	  scope.loadSave = function(){
	     if(!scope.confirmload)
		 {
			 scope.confirmload = true
		 }
		 else
		 {
			 bngApi.engineLua(`extensions.customGuiCallbacks.exec("restoreBackup")`)
		 }
	  }
	  
	  scope.resetCareer = function(){
		 if(!scope.confirmreset)
		 {
			 scope.confirmreset = true
		 }
		 else
		 {
			 bngApi.engineLua(`extensions.customGuiCallbacks.exec("uiResetCareer")`)
		 }
	  }
	  
	  scope.cancelReset = function()
	  {
		  scope.confirmreset=false;
	  }
	  
	  scope.cancelLoad = function()
	  {
		  scope.confirmload=false;
	  }
	  
	  scope.formatNumber = function(num){
	      return Math.round(parseFloat(num) * 100) / 100
	  }
	  
    }
  }
}]);