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
.directive('beamlrdeliveryui', ['$filter',function ($filter) {
  return {
    templateUrl: '/ui/modules/apps/beamlrdeliveryui/app.html',
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
		  scope.setContainerZindex(20);
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
	  
	  
	  
	  scope.mforce = 0
	  scope.cforce = 0
	  scope.cdmg = 0
	  scope.damage = false
	  
	  scope.$on('beamlrDeliveryMaxForce', function (event, data) {
          scope.mforce = data
      })
	  
	  scope.$on('beamlrDeliveryCurrentForce', function (event, data) {
          scope.cforce = data
      })
	  
	  scope.$on('beamlrDeliveryCurrentDamage', function (event, data) {
          scope.cdmg = data
      })
	  
	  scope.$on('beamlrToggleDeliveryUI', function (event, data) {
          scope.enabled = data;
		  if(scope.enabled)
			  scope.moveToFront()
		  else
			  scope.moveToBack()
      })
	  
	  scope.$on('beamlrToggleDeliveryDamage', function (event, data) {
          scope.damage = data;
      })
	  
	  scope.formatValue = function(value)
	  {
		  return Math.round(value * 100) / 100;
	  }
	  
	  
    }
  }
}]);