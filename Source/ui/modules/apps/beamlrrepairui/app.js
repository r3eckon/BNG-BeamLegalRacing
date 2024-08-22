angular.module('beamng.apps')
.directive('beamlrrepairui', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrrepairui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.enabled = false
	  scope.picks = {}
	  scope.damage = {}
	  scope.names = {}
	  scope.mechanical = 0
	  scope.minimum = 0
	  scope.total = 0
	  scope.full = 0
	  scope.ready = false
	  scope.childmap = {}
	  scope.parentmap = {}
	  scope.mainpart = ""
	  scope.mult = 1
	  scope.money = 0
	  scope.totalConfirm = false
	  scope.fullConfirm = false
	  scope.totalBeforeMin = 0
	  scope.warnack = false
	  scope.engine = 0
	  scope.engineSelected = false
	  
	  scope.calculateTotal = function()
	  {
		  scope.total = 0
		  for(k in scope.damage)
		  {
			  if(scope.picks[k])
			  {
				  scope.total+=scope.damage[k]
			  }
		  }
		  scope.total += scope.mechanical
		  
		  if(scope.engineSelected)
			  scope.total += scope.engine
		  
		  scope.totalBeforeMin = scope.total
		  scope.total = Math.max(scope.total, scope.minimum)
	  }
	  
	  scope.calculateFull = function()
	  {
		  scope.full = 0
		  for(k in scope.damage)
		  {
			 scope.full+=scope.damage[k]
		  }
		  scope.full += scope.mechanical
		  scope.full += scope.engine
		  scope.full = Math.max(scope.full, scope.minimum)
	  }
	  
	  scope.linkedPartsUpdate = function(root)
	  {
		  if(scope.picks[root])
		  {
			for(k in scope.parentmap[root])
			{
				scope.picks[scope.parentmap[root][k]] = true
			}
		  }
		  else
		  {
			for(k in scope.childmap[root])
			{
				scope.picks[scope.childmap[root][k]] = false
			}
		  }
		  scope.calculateTotal()
		  scope.totalConfirm = false
	  }
	  
	  scope.formatNumber = function(num){
	      return Math.round(parseFloat(num) * 100) / 100
	  }
	  
	  scope.$on('beamlrRepairUIToggle', function (event, data) {
          scope.enabled = data
		  if(!scope.enabled)
		  {
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("advancedRepairUIClosed")`)			  
		  }
		  scope.totalConfirm = false
		  scope.fullConfirm = false
      })
	  
	  scope.$on('beamlrRepairWarnAck', function (event, data) {
          scope.warnack = data
      })

	  scope.$on('beamlrRepairUIDamageList', function (event, data) {
          scope.damage = data
		  scope.ready = true
      })
	  
	  scope.$on('beamlrRepairUIPartNames', function (event, data) {
          scope.names = data
      })
	  
	  scope.$on('beamlrRepairUIMechanicalDamage', function (event, data) {
          scope.mechanical = data
		  scope.calculateTotal()
		  scope.calculateFull()
      })
	  
	  scope.$on('beamlrRepairUIEngineDamage', function (event, data) {
          scope.engine = data
		  scope.calculateTotal()
		  scope.calculateFull()
      })
	  
	  scope.$on('beamlrRepairUIMinimumDamage', function (event, data) {
          scope.minimum = data
		  scope.calculateTotal()
		  scope.calculateFull()
      })
	  
	  scope.$on('beamlrRepairUIParentMap', function (event, data) {
          scope.parentmap = data
      })
	  
	  scope.$on('beamlrRepairUIChildMap', function (event, data) {
          scope.childmap = data
      })
	  
	  scope.$on('beamlrRepairUIMainPart', function (event, data) {
          scope.mainpart = data
		  scope.picks[data] = true
      })
	  
	  scope.$on('beamlrRepairUIMultiplier', function (event, data) {
          scope.mult = data
      })
	  
	  scope.$on('beamlrRepairUIMoney', function (event, data) {
          scope.money = data
      })
	  
	  scope.$on('beamlrRepairResetPicks', function (event, data) {
          scope.picks = {}
		  scope.picks[scope.mainpart] = true
      })
	  
	  scope.toggleui = function(value)
	  {
		  scope.enabled = value
		  scope.totalConfirm = false
		  scope.fullConfirm = false
		  if(!scope.enabled)
		  {
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("advancedRepairUIClosed")`)			  
		  }
	  }
	  
	  scope.repairSelected = function()
	  {
		  if(scope.totalConfirm)
		  {
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advrepairdata", "cost", ${scope.formatNumber(scope.total * scope.mult)})`)
			for(k in scope.picks)
			{
			  if(scope.picks[k])
			  {
				  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advrepairdata", "${k}", ${scope.picks[k]})`)
			  }
			}
			
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advrepairdata", "engineCost", ${scope.engine})`)
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advrepairdata", "engineSelected", ${scope.engineSelected})`)
			
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("advancedRepairSelected", "advrepairdata")`)
			scope.totalConfirm = false			
		  }
		  else
		  {
			  scope.totalConfirm = true
		  }

	  }
	  
	  scope.repairAll = function()
	  {
		  if(scope.fullConfirm)
		  {
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advrepairdata", "cost", ${scope.formatNumber(scope.full * scope.mult)})`)
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("advancedRepairAll", "advrepairdata")`)	
			scope.fullConfirm = false
		  }
		  else
		  {
			scope.fullConfirm = true
		  }
	  

	  }
	  
	  scope.warnclick = function()
	  {
		scope.warnack=true;
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("advancedRepairWarnAck")`)	
	  }
	  
	  
	  scope.selectEngine = function()
	  {
		  scope.engineSelected = !scope.engineSelected
		  scope.calculateTotal()
		  scope.calculateFull()
	  }
	  
	  
	  
	  
	  
	  
	  
    }
  }
}]);