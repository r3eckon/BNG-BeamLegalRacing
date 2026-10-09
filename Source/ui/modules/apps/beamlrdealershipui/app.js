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
.directive('beamlrdealershipui', ['$filter', function($filter){
  return {
    templateUrl: '/ui/modules/apps/beamlrdealershipui/app.html',
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
		  scope.setContainerZindex(30);
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
	  
	  //Interaction vars
	  scope.page = 0	  
	  scope.selectedSlot = 0
	  scope.buyoptions = {}
	  scope.buyoptions.delivery	= "delivery"
	  scope.buyoptions.tradein = false
	  scope.buyoptions.confirm = false
	  scope.showvehfax = true
	  scope.showvehfaxhelp = false
	  
	  //buy button double click protection
	  scope.buyButtonProtected = false
	  
	  //Data vars
	  scope.slotCount = 0
	  scope.vehdata = {}
	  scope.vehfax = {}
	  scope.extradata = {}
	  
	  //pass some math functions to scope for use in html code
	  scope.abs = Math.abs
	  scope.max = Math.max
	  
	  
	  
	  //UI caching system
	  scope.cachedVars = {
		buyopt_delivery : "buyoptions.delivery",
		buyopt_tradein : "buyoptions.tradein",
		buyopt_confirm : "buyoptions.confirm",
		selectedSlot : "selectedSlot",
		showvehfax : "showvehfax",
		showvehfaxhelp : "showvehfaxhelp",
		page : "page"
	  }
	  scope.getNestedValue = function(k)
	  {
		  var keyseq = k.split(".")
		  var current = scope[keyseq[0]]
		  for(i=1;i<keyseq.length; i++)
			{
			  current = current[keyseq[i]]
			}
		  return current
		}

	  scope.setNestedValue = function(k, v)
	  {
		  var keyseq = k.split(".")
		  var current = scope
		  for(i=0;i<keyseq.length-1; i++)
			{
			  current = current[keyseq[i]]
			}
		  current[keyseq[keyseq.length-1]] = v
	  }
	  scope.cache = function()
	  {
		  for(var k in scope.cachedVars)
		  {
			  var ckeyseq = scope.cachedVars[k]
			  var cval = scope.getNestedValue(ckeyseq)
			  var ctype = typeof(cval)
			  
			  if(ctype == "string")
				bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue('dealercache', '${k}', '${cval}')`)
			  else
				bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue('dealercache', '${k}', ${cval})`)
		  }

		  bngApi.engineLua(`extensions.customGuiCallbacks.exec('dealershipUICacheUpdate', 'dealercache')`)
	  }
	  scope.$on('beamlrDealershipUICacheRefresh', function (event, data) {
		  for(var k in data)
		  {
			  //console.log("SHOULD HAVE SET VAR " + k + " TO " + data[k])
			  scope.setNestedValue(scope.cachedVars[k], data[k])
		  }
	  })
	  
	  
	  //TODO: cache various UI only options when they change so they can be reloaded on ui init
	  
	  scope.$on('beamlrDealershipUIVehicleData', function (event, data) {
		  scope.vehdata = data
		  if(data != null)
			scope.slotCount = Object.keys(data).length
	  })
	  
	  scope.$on('beamlrDealershipUIVehfaxData', function (event, data) {
		  scope.vehfax = data
	  })
	  
	  scope.$on('beamlrDealershipUIExtraData', function (event, data) {
		  console.log("RECEIVED EXTRADATA:")
		  console.log(data)
		  scope.extradata = data
		  
		  //test values
		  //scope.extradata.tradeinval = 200000
		  //scope.extradata.playerMoney = 100000
		  //scope.extradata.garageSlots = 1
		  //scope.extradata.nocar = true
		  //scope.extradata.eventRestricted = true
		  //scope.extradata.trademin=10000
		  //scope.extradata.trademin=-1
		  //scope.extradata.boughtshop = -100
		  //scope.extradata.limitedSlots = false
		  
		  //console.log("SHOPID: " + scope.extradata.shopid)
		  //console.log("BOUGHTSHOP: " + scope.extradata.boughtshop)
	  })
	  
	  scope.$on('beamlrDealershipUIToggle', function (event, data) {
		  scope.enabled = data
		  
		  if(scope.enabled == true)
			  scope.buyButtonProtected = false
	  })
	  
	  scope.$on('beamlrDealershipUISelectedSlot', function (event, data) {
		  scope.selectedSlot = data
	  })
	  
	  scope.$on('beamlrDealershipUIPage', function (event, data) {
		  scope.page = data
	  })
	  
	  scope.$on('beamlrDealershipUIDayDataUpdate', function (event, data) {
		  scope.extradata.daydata = data
	  })
	  
	  scope.$on('beamlrDealershipUIPlayerMoneyUpdate', function (event, data) {
		  scope.extradata.playerMoney = data
	  })
	  
	  

	  
	  scope.toggleVehFaxHelp = function(toggle)
	  {
		  scope.showvehfaxhelp = toggle
	  }
	  
	  scope.selectNextSlot = function()
	  {
		  if(scope.selectedSlot < scope.slotCount - 1)
		  {
			  scope.selectedSlot = scope.selectedSlot+1
			  bngApi.engineLua(`extensions.customGuiCallbacks.flowgraphAppButtonCallback('dealership_slotChanged', ${scope.selectedSlot})`)
		  
			  scope.cache()
		  }
	  }
	  
	  scope.selectPreviousSlot = function()
	  {
		  if(scope.selectedSlot > 0)
		  {
			 scope.selectedSlot = scope.selectedSlot-1
			 bngApi.engineLua(`extensions.customGuiCallbacks.flowgraphAppButtonCallback('dealership_slotChanged', ${scope.selectedSlot})`)
		  
			 scope.cache()
		  }
	  }
	  
	  scope.exit = function()
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.flowgraphAppButtonCallback('dealership_exit')`)
		  scope.enabled = false
	  }
	  
	  scope.buyVehfaxReport = function()
	  {
		  console.log(scope.extradata)
		  console.log(scope.extradata.shopfile)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue('vehfaxdata', 'slot', ${scope.selectedSlot})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue('vehfaxdata', 'shopfile', '${scope.extradata.shopfile}')`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec('buyVehfaxReport', 'vehfaxdata')`)
	  }
	  
	  scope.vehfaxOwned = function(slot)
	  {
		  //console.log("A: " + scope.extradata.daydata != "none")
		  //console.log("SLOT: " + slot)
		  //console.log("B: " + scope.extradata.daydata["slot" + slot])
		  return scope.extradata.daydata.vehfax != "none" && scope.extradata.daydata.vehfax["slot" + slot] == true
	  }
	  
	  scope.moneyCheck = function(cost)
	  {
		  return scope.extradata.playerMoney > cost
	  }
	  
	  scope.slotsCheck = function()
	  {
		  if(scope.buyoptions.tradein == true)
			return true
		  
		  if(scope.extradata.limitedSlots != true)
			 return true
		
		  return (scope.extradata.garageSlots - scope.extradata.ownedCars) > 0
	  }
	  
	  scope.setPage = function(p)
	  {
		  scope.page = p
		  
		  //reset buy options when returning to main page
		  if(p == 0)
		  {
			  scope.buyoptions.confirm = false
			  scope.buyoptions.delivery = "delivery"
			  scope.buyoptions.tradein = false
		  }
		  
		  scope.cache()
	  }
	  
	  scope.onDeliveryMethodChanged = function()
	  {
		  scope.cache()
	  }
	  
	  scope.onTradeinToggleChanged = function()
	  {
		  scope.cache()
	  }
	  
	  scope.onBuyConfirmToggleChanged = function()
	  {
		  scope.cache()
	  }
	  
	  scope.getTransactionTotal = function()
	  {
		  var total = scope.vehdata[scope.selectedSlot].baseprice
		  
		  if(scope.buyoptions.tradein)
			total -= scope.extradata.tradeinval
		
		  //Add delivery/towing fee when applicable
		  if(scope.buyoptions.delivery == 'delivery' || (scope.buyoptions.delivery == 'driveout' && scope.buyoptions.tradein != true && scope.extradata.nocar != true))
			total += 50
		
		  return total
	  }
	  
	  scope.getTransactionTotalColor = function()
	  {
		  var cost = scope.getTransactionTotal()
		  var money = scope.extradata.playerMoney
		  
		  if(cost < 0)
			return {'color':'lime'}
		  
		  if(money >= cost)
			  return {'color':'yellow'}
		  else
			  return {'color':'red'}
	  }
	  
	  scope.sendBuyRequest = function()
	  {
		  if(scope.buyButtonProtected == true)
		  {
			  console.log("Buy button protection handled double click event")
			  return
		  }

		  var moneyChange = -scope.getTransactionTotal()
		  var slotsChange = (scope.buyoptions.tradein) ? 0 : 1;
		  
		  scope.buyButtonProtected = true

		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue('buyreq', 'slot', ${scope.selectedSlot})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue('buyreq', 'tradein', ${scope.buyoptions.tradein})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue('buyreq', 'delivery', '${scope.buyoptions.delivery}')`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue('buyreq', 'moneyChange', ${moneyChange})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue('buyreq', 'slotsChange', ${slotsChange})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue('buyreq', 'nocar', ${scope.extradata.nocar})`)
		  
		  //Reset input values for next time menu is opened
		  //doing this before sending purchase request command otherwise doesn't seem to apply values for next time
		  scope.buyoptions.tradein = false
		  scope.buyoptions.delivery = "delivery"
		  scope.buyoptions.confirm = false
		  scope.showvehfax = false
		  scope.showvehfaxhelp = false
		  scope.page = 0
		  scope.enabled = false
		  scope.selectedSlot = 0
		  scope.cache()
		  
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec('dealershipPurchaseRequest', 'buyreq')`)
	  }
	  
	  scope.tradeAllowed = function()
	  {
		  return scope.extradata.trademin >= 0 
			  && scope.extradata.tradeinval >= scope.extradata.trademin 
			  && scope.extradata.boughtshop != scope.extradata.shopid;
	  }
	  
	  scope.tradeDisallowedTooltipShow = function()
	  {
		  if(scope.extradata.eventRestricted == true)
			  return true
		  else if(scope.extradata.nocar == true)
			  return true
		  else if(scope.extradata.boughtshop == scope.extradata.shopid)
			  return true
		  else if(scope.extradata.trademin < 0)
			  return true
		  else if(scope.extradata.tradeinval < scope.extradata.trademin)
			  return true
		  else
			  return false
			  
		  return false
	  }
	  
	  scope.tradeDisallowedTooltip = function()
	  {
		  var tooltip = "error"
		  var trademin = $filter("number")(scope.extradata.trademin, 2)
		  
		  if(scope.extradata.eventRestricted == true)
			  tooltip = $filter('blrtranslate')("beamlr.dealershipui.buypage_tradetooltip1")
		  else if(scope.extradata.nocar == true)
			  tooltip = $filter('blrtranslate')("beamlr.dealershipui.buypage_tradetooltip2")
		  else if(scope.extradata.boughtshop == scope.extradata.shopid)
			  tooltip = $filter('blrtranslate')("beamlr.dealershipui.buypage_tradetooltip3")
		  else if(scope.extradata.trademin < 0)
			  tooltip = $filter('blrtranslate')("beamlr.dealershipui.buypage_tradetooltip4")
		  else if(scope.extradata.tradeinval < scope.extradata.trademin)
			  tooltip = $filter('blrtranslate')("beamlr.dealershipui.buypage_tradetooltip5") + " ($" + trademin + ")"
		  else
			  tooltip = "Unknown"
			  
		  return tooltip
	  }
	  
	  scope.getUnitConvertedValue = function(input)
	  {
		  if(scope.extradata.units == "imperial")
		  {
			  return input / 1.609344
		  }
		  return input
	  }
	  
	  
    }
  }
}]);