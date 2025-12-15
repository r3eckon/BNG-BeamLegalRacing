angular.module('beamng.apps')
.directive('beamlrrepairui', ['$filter',function ($filter) {
  return {
    templateUrl: '/ui/modules/apps/beamlrrepairui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  translate = function(key)
	  {
		  return $filter('translate')(key)
	  }
	  scope.translate = translate
	  
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
	  scope.buttonlock = false
	  scope.pathNameCache = {}
	  scope.toggle = {}
	  
	  scope.extras = {}
	  scope.extras.engineSelected = false
	  
	  
	  
	  
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
		  
		  if(scope.extras.engineSelected)
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

		  if(scope.toggle["parentSelect"])
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

		  
		  //update select all checkbox state
		  var allselected = true
		  for(part in scope.damage)
		  {
			  if(scope.picks[part]!=true)
			  {
				  scope.toggle["selectAll"] = false
				  allselected=false
				  break
			  }
		  }
		  if(allselected && !scope.selectAllToggled)
		  {
			  scope.toggle["selectAll"]=true
		  }
		  
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
	  
	  scope.$on('beamlrRepairButtonLock', function (event, data) {
          scope.buttonlock = data
      })
	  
	  scope.$on('beamlrRepairSelectParents', function (event, data) {
          scope.toggle["parentSelect"] = data
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
			  
		  //prevent double click
		  if(scope.buttonlock)
		  {
			  return;
		  }
		  scope.buttonlock = true;		  
			  
			  
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advrepairdata", "cost", ${scope.formatNumber(scope.total * scope.mult)})`)
			for(k in scope.picks)
			{
			  if(scope.picks[k])
			  {
				  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advrepairdata", "${k}", ${scope.picks[k]})`)
			  }
			}
			
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advrepairdata", "engineCost", ${scope.engine})`)
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advrepairdata", "engineSelected", ${scope.extras.engineSelected})`)
			
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
			//prevent double click
			if(scope.buttonlock)
			{
			  return;
			}
			scope.buttonlock = true;				  
			  
			  
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
	  
	  
	  scope.engineToggleChanged = function()
	  {
		  scope.calculateTotal()
		  scope.calculateFull()
	  }
	  
	  //returns a part name from its path 
	  scope.nameFromPath = function(path)
	  {
		  //console.log(path)
		  if(scope.pathNameCache[path] != null)
		  {
			return scope.pathNameCache[path]
		  }
		  else
		  {
			var cname = path.split("/")
			cname = cname[cname.length-1]
			if(cname == null)
			{
				console.log("REPAIR UI STRING SPLIT ERROR FOR PATH:" + path)
				return "???"
			}
			if(scope.names[cname] != null)
			{
				scope.pathNameCache[path] = scope.names[cname]
				return scope.names[cname]
			}
			else
			{
				return cname
			}
		  }
		  
	  }
	  
	  scope.toggleParentSelect = function()
	  {
		  if(scope.toggle["parentSelect"])
		  {
			  for(pick in scope.picks)
			  {
				  if(scope.picks[pick])
					scope.linkedPartsUpdate(pick)
			  }
		  }
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("armparentselect", ${scope.toggle['parentSelect']})`);
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setRepairParentSelectToggle", "armparentselect")`);
		  
	  }
	  
	  scope.selectAll = function()
	  {
		  for(part in scope.damage)
		  {
			  if(part != scope.mainpart)
				scope.picks[part] = scope.toggle["selectAll"]		  
		  }
		  
		  scope.extras.engineSelected = scope.toggle["selectAll"]
		  scope.engineToggleChanged()
	  }
	  
	  
    }
  }
}]);