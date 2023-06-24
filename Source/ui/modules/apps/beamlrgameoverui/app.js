angular.module('beamng.apps')
.directive('beamlrgameoverui', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrgameoverui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.enabled = false
	  scope.confirmload = false
	  scope.confirmreset = false
	  scope.backopacity = 0.0
	  scope.textopacity = 0.0
	  scope.playermoney = 'Not Loaded'
	  scope.playerrep = 'Not Loaded'
	  scope.playercars = 'Not Loaded'
	  scope.initDone = false

	  scope.invlerp = function(val, min, max)
	  {
		  return Math.max(0.0, Math.min(1.0, (val - min) / (max - min)));
	  }
	  
	  scope.topoffset = Math.floor(20.0 + 30.0 * scope.invlerp(window.innerHeight, 720.0, 1080.0))
	  
	  
	  if(!scope.initDone)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("uiinit")`);
		  console.log("HEIGHT / OFFSET: " + window.innerHeight + " / " + scope.topoffset);
	  }
	  
	  scope.$on('beamlrToggleGameOverUI', function (event, data) {
		  scope.enabled = data
		  scope.$apply()
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