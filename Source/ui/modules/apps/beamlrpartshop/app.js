angular.module('beamng.apps')
.directive('beamlrpartshop', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrpartshop/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.enabled = false
	  
	  scope.beamlrData = {}
	  scope.slotExpanded = {}
	  
	  scope.params = {}
	  scope.params.showInternalNames = false
	  scope.params.showIncompatible = true
	  scope.params.searchFilter = ""
	  scope.params.disableBuyButton = false
	  
	  scope.selectedSlot = ""
	  scope.searching = false
	  
	  scope.cartmetadata = {}
	  
	  
	  scope.params.page_current = 0
	  
	  scope.params.maxrows = 8
	  
	  scope.grid_x = 4
	  scope.grid_y = function()
	  {
		  if(scope.selectedSlot == "")
			  return 0
		  
		  if(scope.beamlrData['sortedShopParts'][scope.selectedSlot] == null)
			  return 0
		  
		  return Math.min(scope.params.maxrows,Math.max(2,Math.ceil(scope.beamlrData['sortedShopParts'][scope.selectedSlot].length / scope.grid_x)))
	  }
	  
	  scope.page_total = function()
	  {
		  return Math.ceil((scope.beamlrData['sortedShopParts'][scope.selectedSlot].length / scope.grid_x) / scope.params.maxrows)
	  }
	  
	  scope.page_offset = function()
	  {
		  return scope.params.page_current * scope.grid_x * scope.params.maxrows
	  }
	  
	  scope.changePage = function(move)
	  {
		  document.getElementById("catalog").scrollTop = 0
		  scope.params.page_current = Math.min(scope.page_total()-1, Math.max(0, scope.params.page_current+move))
	  }
	  
	  scope.closeMenu = function()
	  {
		  scope.enabled = false
	  }
	  

	  scope.range = function(l)
	  {
		  var toRet = []
		  for(i=0; i < l; i++)
		  {
			  toRet[i] = i
		  }
		  return toRet
	  }
	  
	  scope.usedPartDayDataCheck = function(item)
	  {
		return scope.beamlrData["advinvUPSDayData"][item]
	  }
	  
	  //splitmix32 seeded random function, need this since js has no seeded RNG
	  scope.seededrandom = function(a) 
	  {
		a |= 0;
		a = a + 0x9e3779b9 | 0;
		let t = a ^ a >>> 16;
		t = Math.imul(t, 0x21f0aaad);
		t = t ^ t >>> 15;
		t = Math.imul(t, 0x735a2d97);
		return ((t = t ^ t >>> 15) >>> 0) / 4294967296;
	  }
	  
	  
	  scope.getShopUsedPartOdometer = function(part, displaymode)
	  {
		 //First convert part name into number to get somewhat random hash  
		 var hash = 0
		 for(let i=0; i < part.length; i++)
		 {
			 hash += part.charCodeAt(i)
		 }
		 
		 //Get random value for part 
		 var rval = scope.seededrandom(scope.beamlrData["shopseed"] + hash)
		 var toRet = 30000000 + (rval * 270000000)
		 
		
		 //Next generate odometer value for part, minimum odo is 30kkm, maximum is 300kkm
		 //Display mode is only true in HTML, will convert to correct unit for UI display
		 return (scope.beamlrData["advinvUnits"] == "imperial" && displaymode) ? toRet / 1.609344: toRet; 
	  }
	  
	  //Basically, at 30kkm (minimum used part odometer) price scale is about 90%
	  //then worst scale of 10% is achieved at 250kkm
	  scope.getShopUsedPartPriceScale = function(part)
	  {
		  var odo = scope.getShopUsedPartOdometer(part)
		  return .9 - (0.8 * (Math.min(1.0, odo / 250000000)))
	  }
	  
	  scope.getPartPrice = function(part,used)
	  {
		  var baseprice = scope.beamlrData['partPrices'][part] || scope.beamlrData['partPrices']['default']
		  var toRet = baseprice * scope.beamlrData['shopPriceScale']
		  if(used)
		  {
			  toRet *= scope.getShopUsedPartPriceScale(part)
		  }
		  return toRet
	  }
	  
	  var updateCartMetadata = function()
	  {
		  if(!scope.beamlrData['pui2_cart'])
			  return
		  
		  var total = 0
		  var pdata = {}

		  for(var pid = 0; pid < scope.beamlrData['pui2_cart'].length; pid++)
		  {
			  pdata = scope.beamlrData['pui2_cart'][pid]
			  total += scope.getPartPrice(pdata.part, pdata.used, true)
		  }
		  
		  scope.cartmetadata.total = total
		  scope.cartmetadata.offset = Math.abs(total - total / scope.beamlrData['shopPriceScale'])
		  scope.cartmetadata.rawtotal = total / scope.beamlrData['shopPriceScale']
	  }

	  scope.$on('beamlrData', function (event, data) {
          scope.beamlrData[data.key] = data.val;
		  
		  if(data.key == "searching")
		  {
			  scope.searching = data.val;
		  }
		  
		  if(data.key == "pui2_cart" || data.key == "shopPriceScale" || data.key == "shopseed")
		  {
			  updateCartMetadata()
		  }
		  
		  // 1.18.5 fix, force view refresh after receiving tree data
		  if(data.key == "partShopTree")
		  {
			  scope.beamlrData["partShopTree"] = {}
			  scope.$apply()
			  scope.beamlrData["partShopTree"] = data.val
			  scope.$apply()
		  }
      })
	  
	  scope.$on('beamlrPartBuyResult', function (event, data) {
          scope.params.disableBuyButton = false
      })
	  
	  scope.$on('beamlrPartShopV2Show', function (event, data) {
          scope.enabled = data
      })
	  
	  
	  scope.getSlotName = function(slot)
	  {
		  var name = scope.beamlrData['slotNames'][scope.beamlrData['slotPathIDMap'][slot]]
		  
		  if(name == null)
		  {
			  name = scope.beamlrData['slotNames'][slot]
		  }
		  
		  if(name == null || scope.params.showInternalNames)
		  {
			  if(scope.beamlrData['slotPathIDMap'][slot] != null)
				name = scope.beamlrData['slotPathIDMap'][slot]
			  else
				name = slot
		  }
		  
		  return name			  
	  } 
	  
	  scope.getPartName = function(part)
	  {
		  var name = scope.beamlrData['partNames'][part]
		  
		  if(name == null || scope.params.showInternalNames)
		  {
			 name = part
		  }
		  
		  return name			  
	  } 
	  
	  
	  scope.getSlotExpandButton = function(slot)
	  {
		  if(scope.slotExpanded[slot])
			  return '-'
		  
		  return '+'
	  }
	  
	  scope.expandSlot = function(slot)
	  {
		  scope.slotExpanded[slot] = !scope.slotExpanded[slot]
	  }
	  
	  scope.selectSlot = function(slot)
	  {
		  scope.params.page_current = 0
		  document.getElementById("catalog").scrollTop = 0
		  scope.selectedSlot = slot
	  }

	  
	  
	  scope.filter = function(m, f){
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("filter", "${f}")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("setFilter", "filter")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("menu", ${m})`);
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("partUICategory", "menu")`);
	  } 
	  
	  scope.search = function()
	  {  
		if(scope.params.searchFilter == "")
		{
			scope.filter(0, "all")
			return
		}
	  
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("filter", "${scope.params.searchFilter}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("setFilter", "filter")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("menu", 0)`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("partUISearch", "menu")`)
	  }
	  
	  scope.searchReset = function()
	  {
		  scope.params.searchFilter = ""
		  scope.filter(0, "all")
	  }
	  
	  scope.addToCart = function(part, used)
	  {
		 bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("pdata", "part", "${part}")`)
		 bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("pdata", "used", ${used})`)
		 bngApi.engineLua(`extensions.customGuiCallbacks.exec("pui2_addToCart", "pdata")`)
	  }
	  
	  scope.removeFromCart = function(id)
	  {
		 bngApi.engineLua(`extensions.customGuiCallbacks.setParam("index", ${id+1})`)
		 bngApi.engineLua(`extensions.customGuiCallbacks.exec("pui2_removeFromCart", "index")`)
	  }
	  
	  scope.checkout = function()
	  {
		  if(scope.params.disableBuyButton)
			  return

		  var data = {}
		  var pid = 0
		  var pdata = {}
		  data.total = scope.cartmetadata.total
		  data.shopid = scope.beamlrData['shopID']
		  data.items = []
		  
		  for(var i = 0; i < scope.beamlrData['pui2_cart'].length; i++)
		  {
			 pid = i
			 pdata = scope.beamlrData['pui2_cart'][i]
			 data.items[pid] = {}
			 data.items[pid].part = pdata['part']
			 data.items[pid].used = pdata['used']
			 data.items[pid].odometer = pdata['used'] && scope.getShopUsedPartOdometer(pdata['part']) || 0
			 data.items[pid].price = scope.getPartPrice(pdata['part'], pdata['used'])
		  }
		  
		  var serialized = JSON.stringify(data)
		  
		  scope.params.disableBuyButton = true
		  
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("cdata", '${serialized}')`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("pui2_checkout", "cdata")`)
	  }
	  
	  scope.clearCart = function()
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("pui2_clearCart")`)
	  }
	  
	  scope.canAddUsedPart = function(part)
	  {
		  if(scope.usedPartDayDataCheck(part))
			  return false
		  
		  return !scope.beamlrData['pui2_usedmap'][part]
	  }
	  
	  scope.getStringSize = function(id)
	  {
		  var toRet = {}
		  var test = document.getElementById(id)
		  toRet.width = (test.clientWidth + 1)
		  toRet.height = (test.clientHeight + 1)
		  return toRet
	  }
	  
	  scope.getDynamicFontSize = function(id)
	  {
		  var container = 206
		  var size = scope.getStringSize(id)
		  return Math.max(12,Math.min(16,Math.floor(16 * (container / size.width))))
	  }
	  
	  scope.getPartNameExtras = function(part)
	  {
		  var toRet = {}
		  var owned = scope.beamlrData['advinvOwned'][part]
		  var installed = scope.beamlrData['vehInstParts'][part]
		  
		  var text = ""
		  var color = ""
		  
		  if(installed)
		  {
			  toRet.text = "(INSTALLED)"
			  toRet.color = "lime"
			  return toRet
		  }
		  if(owned > 0)
		  {
			  toRet.text = "(OWN " + owned + ")"
			  toRet.color = "orange"
			  return toRet
		  }
		  
		  return null
	  }

	  scope.canUseMenu = function()
	  {
		  return scope.beamlrData['triggerState'] >= 1
		  //return (scope.beamlrData['triggerState'] >= 1) && (scope.beamlrData['playerWalking'] == 0)
	  }
	  
		

    }
  }
}]);