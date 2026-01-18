angular.module('beamng.apps')
.directive('beamlrui', ['$filter',function($filter) {
  return {
    templateUrl: '/ui/modules/apps/beamlrui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  translate = function(key)
	  {
		  return $filter('translate')(key)
	  }
	  scope.translate = translate
	  
	  
	  scope.testdata = 'Not Loaded';
	  scope.beamlrData = {};
	  scope.inputData = {};
	  scope.textBoxFocus = false;
	  scope.menuPage = 0;
	  scope.showMenu = false;
	  scope.partPrice = 0;
	  scope.initDone = false
	  scope.editMode = 0;
	  scope.slotNameMode = 0;
	  scope.visibleSlots = {};
	  scope.resetConfirm = false;
	  scope.partSellConfirm = {};
	  scope.partSellScale = 0.2;
	  scope.sortedItemInventoryKeys = {};
	  scope.templateFixMode = false;
	  scope.templateFixData = {}
	  scope.templateFixSelected = {}
	  scope.templateFixUsedIDs = {}
	  scope.templateFixTemplate = {}
	  scope.templateFixNeeded = false
	  scope.optshow = {}
	  scope.actualDamage = 0 //actual damage value, stored when bypass is enabled
	  scope.invmode = 0 //0 = item inventory, 1 = part inventory 
	  scope.expanded = {} // slot tree expanded states
	  scope.searching = false // for new tree view, revert to old layout while searching (this is what vanilla does)
	  
	  scope.shopExpanded = {}
	  scope.shopPartsHidden = {}
	  
	  scope.buylocked = false //locks buy action until result received
	  scope.lastbuyitem = ""
	  scope.lastbuyused = false // true if used part was bought, false if new part was bough
	  
	  scope.beamlrData["slotFavorites"] = {}
	  
	  scope.pathNameCache = {}
	  
	  scope.defaults = {}
	  scope.defaults['traffic'] = 8
	  scope.defaults['trucks'] = 1
	  scope.defaults['police'] = 1
	  scope.defaults['trisk'] = 0.2
	  scope.defaults['tsrate'] = 0.1
	  scope.defaults['atcount'] = 10
	  scope.defaults['copstrict'] = 0.08
	  scope.defaults['tsbias'] = 0.8
	  
	  scope.defaultFunctions = {}
	  scope.defaultFunctions["traffic"] = "setTrafficDensity"
	  scope.defaultFunctions["trucks"] = "setTruckDensity"
	  scope.defaultFunctions["police"] = "setPoliceDensity"
	  scope.defaultFunctions["trisk"] = "setTrafficRisk"
	  scope.defaultFunctions["tsrate"] = "setTrafficSpawnRate"
	  scope.defaultFunctions["atcount"] = "setActiveTrafficCount"
	  scope.defaultFunctions["copstrict"] = "setPoliceStrictness"
	  scope.defaultFunctions["tsbias"] = "setTrafficDirectionBias"
	  
	  scope.inputData.saveDeleteConfirm = {}
	  scope.inputData.saveLoadConfirm = {}
	  
	  
	  //helper function to trigger message in vanilla message app
	  scope.guiMessage = function(msg, ttl, icon, category)
	  {
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("messageData", "msg", "${msg}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("messageData", "category", "${category}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("messageData", "ttl", ${ttl})`)
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("messageData", "icon", "${icon}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("guiMessage", "messageData")`)
	  }
	  
	  
	  scope.toggleOptionShow = function(submenu)
	  {
		  if(scope.optshow[submenu] == null)
			  scope.optshow[submenu] = true
		  else
			scope.optshow[submenu] = !scope.optshow[submenu]
	  }
	  
	  if(!scope.initDone)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("uiinit")`);
		  scope.inputData.searchFilter = "";
		  scope.inputData.targetWager = 100;
		  scope.initDone=true;
		  scope.partSellConfirm = {};
	  }
	 
	  
	  scope.menuButtons = [
		{type: "home", svg:"homebutton.svg", id:0, name:"Main Menu"},
		{type: "options", svg:"gearbutton.svg", id:1, name:"Options"},
		{type: "buyparts", svg:"partshopbutton.svg", id:2, name:"Buy Parts"},
		{type: "editcar", svg:"editcarbutton.svg", id:3, name:"Edit Car"},
		{type: "tuning", svg:"tuningbutton.svg", id:4, name:"Tuning"},
		{type: "inventory", svg:"inventorybutton.svg", id:6, name:"Inventory"},
		{type: "events", svg:"eventbrowserbutton.svg", id:5, name:"Track Events"}
	  ];
	  
	  scope.menuClick = function(id){
		scope.menuPage = id;
		scope.resetConfirm = false;
		
		if(id == 3 || id == 4)
		{
			bngApi.engineLua(`extensions.customGuiCallbacks.setParam("perfuitoggle", "1")`);
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("togglePerfUI", "perfuitoggle")`);
			scope.templateFixMode = false
		}
		else
		{
			bngApi.engineLua(`extensions.customGuiCallbacks.setParam("perfuitoggle", "0")`);
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("togglePerfUI", "perfuitoggle")`);
		}
		
		if(id == 5)
		{
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("updateEventMenuPage")`);
		}
	  }
	  
	  scope.filter = function(m, f){
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("filter", "${f}")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("setFilter", "filter")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("menu", ${m})`);
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("partUICategory", "menu")`);
	  } 

	  scope.garagePartClick = function(slot, item){
		
		//Prevent double clicking on part edit buttons
		if(scope.beamlrData["partEditLock"])
		{
			return;
		} 
		scope.beamlrData["partEditLock"] = true
		 
		  
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("garageEdit", "slot", "${slot}")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("garageEdit", "item", "${item}")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("setPart", "garageEdit")`);
		//bngApi.engineLua(`extensions.customGuiCallbacks.exec("inventoryRefresh")`) //Needs to be called in post edit process to work properly
	  }
	  
	  
	  scope.shopPartClick = function(item){
		if(scope.buylocked)
			return
		  
		scope.partPrice = scope.beamlrData["partPrices"][item];
		if(scope.partPrice == null)
		{
			scope.partPrice = scope.beamlrData["partPrices"]["default"] * scope.beamlrData['shopPriceScale'];
		}
		else
		{
			scope.partPrice = scope.beamlrData["partPrices"][item] * scope.beamlrData['shopPriceScale'];
		}
	    bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("shopPurchase", "item", "${item}")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("shopPurchase", "used", false)`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("shopPurchase", "price", ${scope.partPrice})`);
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("buyPart", "shopPurchase")`);
		
		scope.buylocked = true
		scope.lastbuyitem = item
		scope.lastbuyused = false
	  }

	  scope.$on('beamlrData', function (event, data) {
          scope.beamlrData[data.key] = data.val;
		  if(data.key == "itemInventory")
		  {
			  scope.sortedItemInventoryKeys = Object.keys(scope.beamlrData['itemInventory']).sort()
		  }
		  //Damage Bypass Mode tricks UI into thinking player has no damage to get out of soft locks
		  if(data.key == "playerDamage" && scope.inputData['dbypass'] == 1)
		  {
			  scope.actualDamage = scope.beamlrData["playerDamage"]
			  scope.beamlrData["playerDamage"] = 0
			  //console.log("DAMAGE: " + scope.beamlrData['playerDamage'])
		  }
		  //1.17.5 slot tree search mode, to use old UI with search or category filters
		  if(data.key == "searching")
		  {
			  scope.searching = data.val;
		  }
		  
		  // 1.18.5 fix, forcing refresh of trees, otherwise UI doesn't update for some reason
		  if(data.key == "slotTree")
		  {
			  scope.beamlrData["slotTree"] = {}
			  scope.$apply()
			  scope.beamlrData["slotTree"] = data.val
			  scope.$apply()
		  }
		  if(data.key == "partShopTree")
		  {
			  scope.beamlrData["partShopTree"] = {}
			  scope.$apply()
			  scope.beamlrData["partShopTree"] = data.val
			  scope.$apply()
		  }
		 
      })
	  
	  scope.$on('beamlrOptions', function (event, data) {
          scope.inputData['name'] = data['playername'];
		  scope.inputData['vehname'] = data['vehname'];
		  scope.inputData['sleepTime'] = data['sleeptime'];
		  scope.inputData['targetWager'] = data['targetwager'];
		  scope.inputData['raceRandPaint'] = data['raceRandPaint'];
		  scope.inputData['timeScale'] = data['timescale'];
		  scope.inputData['gpsmode'] = data['gpsmode'];
		  scope.inputData['dragslowmo'] = data['dragslowmo'];
		  scope.inputData['seed'] = data['nseed'];
		  scope.inputData['autoseed'] = data['autoseed'];
		  scope.inputData['difficulty'] = data['difficulty'];
		  scope.inputData['imguiScale'] = data['imscale'];
		  scope.inputData['imautosave'] = data['imautosave'];
		  scope.inputData['traffic'] = data['traffic'];
		  scope.inputData['police'] = data['police'];
		  scope.inputData['trucks'] = data['trucks'];
		  scope.inputData['trisk'] = data['trisk'];
		  scope.inputData['copstrict'] = data['copstrict'];
		  scope.inputData['autoCopfix'] = data['autoCopfix'];
		  scope.inputData['bstoggle'] = data['bstoggle'];
		  scope.inputData['avbtoggle'] = data['avbtoggle'];
		  scope.inputData['advrepaircost'] = data['advrepaircost'];
		  scope.inputData['gmtoggle'] = data['gmtoggle'];
		  scope.inputData['rtmode'] = data['rtmode'];
		  scope.inputData['fmtoggle'] = data['fmtoggle'];
		  scope.inputData['useadvrepairui'] = data['useadvrepairui'] && data['advrepaircost'];
		  scope.inputData['tfasttoggle'] = data['tfasttoggle'];
		  scope.inputData['gsafemode'] = data['gsafemode'];
		  scope.inputData['imgmode'] = data['imgmode'];
		  scope.inputData['wagerscl'] = data['wagerscl'];
		  scope.inputData['repscl'] = data['repscl'];
		  scope.beamlrData['seed'] = data['sseed'];
		  scope.inputData['ccvar'] = data['ccvar'];
		  scope.inputData['wsvar'] = data['wsvar'];
		  scope.inputData['fdvar'] = data['fdvar'];
		  scope.inputData['dwtoggle'] = data['dwtoggle'];
		  scope.inputData['allowinjury'] = data['allowinjury'];
		  scope.inputData['lrestrict'] = data['lrestrict']
		  scope.inputData['rsraces'] = data['rsraces']
		  scope.inputData['dbypass'] = data['dbypass']
		  scope.inputData['lgslots'] = data['lgslots']
		  scope.inputData['allowtesmode'] = data['allowtesmode']
		  scope.inputData['lmtoggle'] = data['lmtoggle']
		  scope.inputData['edittreemode'] = data['edittreemode']
		  scope.inputData['pshopshowinc'] = data['pshopshowinc']
		  scope.inputData['atcount'] = data['atcount']
		  scope.inputData['tsrate'] = data['tsrate']
		  scope.inputData['tsbias'] = data['tsbias']
		  scope.inputData['odbufsize'] = data['odbufsize']
		  scope.inputData['odtoggle'] = data['odtoggle']
      })
	  
	  scope.setDefaultValue = function(param)
	  {
		  scope.inputData[param] = scope.defaults[param]
		  scope[scope.defaultFunctions[param]]()
	  }
	  
	  scope.setNameClick = function (name) {
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("playername", "${scope.inputData.name}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("playerRename", "playername")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setVehNameClick = function (name) {
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("vehname", "${scope.inputData.vehname}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("vehicleRename", "vehname")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.showMenuClick = function () {
		  scope.showMenu = !scope.showMenu;
		  scope.resetConfirm = false;
		  if(scope.menuPage == 3 && scope.showMenu)
		  {
			bngApi.engineLua(`extensions.customGuiCallbacks.setParam("perfuitoggle", "1")`)
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("togglePerfUI", "perfuitoggle")`)
		  }
		  else
		  {
			bngApi.engineLua(`extensions.customGuiCallbacks.setParam("perfuitoggle", "0")`)
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("togglePerfUI", "perfuitoggle")`)
		  }
	  }
	  
	  scope.textboxHover = function(){
		if (!scope.textBoxFocus) return
		bngApi.engineLua('setCEFFocus(true)')
	  }
	  
	  scope.textboxClick = function(){
		scope.textBoxFocus=true
		bngApi.engineLua('setCEFFocus(true)')
	  }
	  
	  
	  scope.tuneChanged = function(id)
	  {
		  scope.beamlrData["tuningValues"][id] = parseFloat(scope.beamlrData["tuningValues"][id])
	  }
	  
	  scope.getTuneData = function(id)
	  {
		  return Math.round(parseFloat(scope.beamlrData["tuningValues"][id]) * 1000) / 1000;
	  }

	  scope.applyTune = function()
	  {
		  
		//Prevent double clicking
		if(scope.beamlrData["partEditLock"])
		{
			return;
		} 
		scope.beamlrData["partEditLock"] = true
		  
		  
		  var ckey = "";
		  var cval = 0;
		  
		  Object.keys(scope.beamlrData['tuningValues']).forEach(key => {
			ckey = key;
			cval = scope.beamlrData['tuningValues'][key];
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("tuneData", "${ckey}", ${cval})`)
		  });
		  
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTune", "tuneData")`)
	  }
	  
	  scope.resetTune = function()
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("resetTune")`)
	  }
	  
	  scope.search = function(m)
	  {  
		if(scope.inputData.searchFilter == "")
		{
			scope.filter(m, "all")
			return
		}
	  
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("filter", "${scope.inputData.searchFilter}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("setFilter", "filter")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("menu", ${m})`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("partUISearch", "menu")`)
	  }
	  
	  scope.resetCareer = function()
	  {
		  if (scope.resetConfirm == true)
		  {
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("uiResetCareer")`)
		  }
		  else
		  {
			  scope.resetConfirm = true
		  }
	  }
	  
	  scope.applyPaint = function()
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("paintData", "paintA", "${scope.beamlrData["paint"]["paintA"]}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("paintData", "paintB", "${scope.beamlrData["paint"]["paintB"]}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("paintData", "paintC", "${scope.beamlrData["paint"]["paintC"]}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("applyPaint", "paintData")`)
	  }
	  
	  scope.reloadPaint = function()
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("reloadPaint")`)
	  }
	  
	  scope.setEditMode = function(m)
	  {
		  scope.editMode = m
	  }
	  
	  scope.setSlotNameMode = function(m)
	  {
		  scope.slotNameMode = m
	  }

	  scope.setAllDefaultValues = function()
	  {
		  for(param in scope.defaults)
		  {
			  scope.setDefaultValue(param)
		  }
	  }

	  scope.setActiveTrafficCount = function()
	  {
		  var val = scope.inputData.atcount
		  
		  if(val == null || val > scope.inputData.traffic + scope.inputData.police + scope.inputData.trucks)
		  {
			  scope.inputData.atcount = scope.inputData.traffic + scope.inputData.police + scope.inputData.trucks
			  val = scope.inputData.atcount
		  }
			  
		  
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("traffic", "${val}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setActiveTrafficCount", "traffic")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setTrafficSpawnRate = function()
	  {
		  var val = scope.inputData.tsrate
		  
		  if(val == null)
			  val = 0.1
		  
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("traffic", "${val}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTrafficSpawnRate", "traffic")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setTrafficDensity= function()
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("traffic", "${scope.inputData.traffic}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTrafficDensity", "traffic")`)
		  
		  if(scope.inputData.traffic + scope.inputData.police + scope.inputData.trucks < scope.inputData.atcount)
		  {
			  scope.inputData.atcount = scope.inputData.traffic + scope.inputData.police + scope.inputData.trucks
			  scope.setActiveTrafficCount()
		  }			  
		  else
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setPoliceDensity= function()
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("traffic", "${scope.inputData.police}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setPoliceDensity", "traffic")`)
		  if(scope.inputData.traffic + scope.inputData.police + scope.inputData.trucks < scope.inputData.atcount)
		  {
			  scope.inputData.atcount = scope.inputData.traffic + scope.inputData.police + scope.inputData.trucks
			  scope.setActiveTrafficCount()
		  }			  
		  else
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setTruckDensity= function()
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("traffic", "${scope.inputData.trucks}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTruckDensity", "traffic")`)
		  if(scope.inputData.traffic + scope.inputData.police + scope.inputData.trucks < scope.inputData.atcount)
		  {
			  scope.inputData.atcount = scope.inputData.traffic + scope.inputData.police + scope.inputData.trucks
			  scope.setActiveTrafficCount()
		  }			  
		  else
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setSeed = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("seed", "${scope.inputData.seed}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setSeed", "seed")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setAutoSeed = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("autoseed", ${d})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setAutoSeed", "autoseed")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setRandomSeed = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setRandomSeed")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setDifficulty = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("difficulty", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setDifficulty", "difficulty")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.backupCareer = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("backupCareer")`)
	  }
	  
	  scope.restoreBackup = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("restoreBackup")`)
	  }
	  
	  scope.setTrafficRisk= function()
	  {
		  var val = scope.inputData.trisk || 0.2
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("risk", "${val}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTrafficRisk", "risk")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setPoliceStrictness= function()
	  {
		  var val = scope.inputData.copstrict || 0.08
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("copstrict", "${val}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setPoliceStrictness", "copstrict")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setTrafficDirectionBias= function()
	  {
		  if(!scope.inputData.tsbias)
			  scope.inputData.tsbias = 0
		  
		  var val = scope.inputData.tsbias
		  
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("tsbias", "${val}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTrafficDirectionBias", "tsbias")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setSleepDuration= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("sleeptime", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setSleepDuration", "sleeptime")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setTimeScale= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("timescale", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTimeScale", "timescale")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }


	  scope.setOpponentRandomPaint = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("randpaint", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setOpponentRandomPaint", "randpaint")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.forcedCopfix = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("forcedCopfix")`)
	  }
	  
	  scope.autoCopfix = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("copfixToggle", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setAutoCopfix", "copfixToggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.beamstateToggle = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("beamstateToggle", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setBeamstateToggle", "beamstateToggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.resetCouplers = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("resetCouplers")`)
	  }
	  
	  scope.showEventBrowser = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("showEventBrowser")`)
		  scope.showMenu=false
	  }	  
	  
	  scope.showPastEvents = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("showPastEvents")`)
		  scope.showMenu=false
	  }
	  
	  scope.abandonEvent = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("abandonEvent")`)
	  }
	  
	  scope.setTargetWager = function()
	  {
		  var wager = parseFloat(scope.inputData.targetWager)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("pwager", ${wager})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setRaceWager", "pwager")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.slotToggle = function(slot, toggle)
	  {
		  scope.visibleSlots[slot] = toggle
	  }
	  
	  scope.deleteTemplate = function (template)
	  {
	      bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateName", "${template}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateFolder", "${scope.beamlrData["vehicleTemplateFolder"]}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("deleteTemplate", "templateData")`)
	  }
	  
	  scope.loadTemplate = function (template)
	  {
		  
		  //Prevent double clicking
		  if(scope.beamlrData["partEditLock"])
		  {
			  return;
		  } 
		  scope.beamlrData["partEditLock"] = true
		
		  
          bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateName", "${template}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateFolder", "${scope.beamlrData["vehicleTemplateFolder"]}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("loadTemplate", "templateData")`)
	  }
	  
	  scope.avbToggle = function(toggle)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("avbtoggle", "${toggle}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setAVBToggle", "avbtoggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  //advanced repair cost
	  scope.arcToggle = function(toggle)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("arctoggle", ${toggle})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setARCToggle", "arctoggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
		  if(!toggle)
		  {
			  scope.inputData["useadvrepairui"] = false
		  }
	  }
	  
	  scope.aruiToggle = function(toggle)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("aruitoggle", ${toggle})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setARUIToggle", "aruitoggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.toggleGroundmarkers = function(toggle)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("gmtoggle", ${toggle})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setGroundmarkersToggle", "gmtoggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.toggleMarkers = function(toggle)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("fmtoggle", ${toggle})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setMarkersToggle", "fmtoggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setGPSMode = function(mode)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("gpsmode", ${mode})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setGPSMode", "gpsmode")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setRaceTraffic = function(mode)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("rtmode", ${mode})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setRaceTrafficMode", "rtmode")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setIMGUIScale = function(scale)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("imscale", ${scale})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setIMGUIScale", "imscale")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.loadIMGUI = function()
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("loadIMGUI")`)
	  }
	  
	  scope.saveIMGUI = function()
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("saveIMGUI")`)
	  }
	  
	  scope.autosaveIMGUI = function(toggle)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("imautosave", ${toggle})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("autosaveIMGUI", "imautosave")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.garagePartSell = function(part, value)
	  {
		  if(scope.partSellConfirm[part] == true)
		  {
			  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("partToSell", "part", "${part}")`)
		      bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("partToSell", "value", "${value}")`)
			  bngApi.engineLua(`extensions.customGuiCallbacks.exec("garagePartSell", "partToSell")`)
			  scope.partSellConfirm[part] = false;
		  }
		  else
		  {
			  scope.partSellConfirm[part] = true;
		  }
		  
	  }
	  
	  scope.toggleDragSlowmo = function(toggle)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("dragslowmo", ${toggle})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setDragSlowmoToggle", "dragslowmo")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setTrafficFastToggle = function(toggle)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("tfasttoggle", ${toggle})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTrafficFastToggle", "tfasttoggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.trafficToggle = function(toggle)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("ttoggle", ${toggle})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("trafficToggle", "ttoggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.safeModeToggle = function(toggle)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("stoggle", ${toggle})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("safeModeToggle", "stoggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setImageUIMode = function(mode)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("imgmode", ${mode})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setImageUIMode", "imgmode")`);
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.imageClicked = function(file)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("imgfile", "${file}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("showImageUI", "imgfile")`);
	  }
	  
	  scope.setWagerScale = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("wagerscl", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setWagerScale", "wagerscl")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setRepScale = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("repscl", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setRepScale", "repscl")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.inventoryUse = function(id)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("itemid", "${id}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("itemUse", "itemid")`)
	  }
	  
	  scope.inventoryDiscard = function(id)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("itemid", "${id}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("itemDiscard", "itemid")`)
	  }
	  
	  scope.dwtoggle = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("dwtoggle", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("toggleDynamicWeather", "dwtoggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setCloudCoverVar = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("ccvar", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setCloudCoverVar", "ccvar")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setWindSpeedVar = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("wsvar", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setWindSpeedVar", "wsvar")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setFogDensityVar = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("fdvar", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setFogDensityVar", "fdvar")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.toggleHealth = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("togglehealth", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("toggleHealthSystem", "togglehealth")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.getUsedPartOdometer = function(pid)
	  {
		  var invodo = scope.beamlrData['advinvData'][pid][1]
		  var ilinkodo = scope.beamlrData["ilinkodo"][pid]
		  var vehodo = scope.beamlrData["vehicleOdometer"]
		  var total = invodo + (vehodo - ilinkodo)
		  return total
	  }
	  
	  scope.getUsedPartSellPrice = function(pid)
	  {
		var odometer = scope.getUsedPartOdometer(pid)
		var full = scope.beamlrData['partPrices'][scope.beamlrData['advinvData'][pid][0]]
		if(full == null)
			full = scope.beamlrData['partPrices']['default']
		var scale = 1.0 - (0.9 * (Math.min(1.0, odometer / 200000000)))
		return full * scale
	  }
	  
	  scope.getPartSellPrice = function(pid)
	  {
		var odometer = scope.beamlrData['advinvData'][pid][1]
	    var full = scope.beamlrData['partPrices'][scope.beamlrData['advinvData'][pid][0]]
		if(full == null)
			full = scope.beamlrData['partPrices']['default']
		var scale = 1.0 - (0.9 * (Math.min(1.0, odometer / 200000000)))
		return full * scale
	  }
	  

	  
	  scope.advancedPartSell = function(pid)
	  {
		if(!scope.partSellConfirm[pid])
		{
			scope.partSellConfirm[pid] = true
		}
		else
		{
			var value = scope.getPartSellPrice(pid)
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advPartSellData", "pid", ${pid})`)
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advPartSellData", "value", ${value})`)
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("advPartSell", "advPartSellData")`)
			scope.partSellConfirm[pid] = false
			
			//decrement owned part count on UI side to avoid having to reload full inventory part counts
			scope.beamlrData["advinvOwned"][scope.beamlrData['advinvData'][pid][0]] -= 1
		}
	  }
	  
	  scope.advancedPartSet = function(slot, pid, part)
	  {
		  
		  //Prevent double clicking
		  if(scope.beamlrData["partEditLock"])
		  {
			  return;
		  } 
		  scope.beamlrData["partEditLock"] = true
		  
		  var currentPID = scope.beamlrData["advinvUsed"][slot];
		  var currentPrice = (currentPID) ? scope.getPartSellPrice(currentPID) : 0;
		  var newPrice = (part == "") ? 0 : scope.getPartSellPrice(pid);
		  var price = newPrice - currentPrice;
		  
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advPartSetData", "pid", ${pid})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advPartSetData", "slot", "${slot}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advPartSetData", "part", "${part}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("advPartSetData", "price", ${price})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("advPartSet", "advPartSetData")`)
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
	  
	  
	  scope.shopUsedPartBuy = function(item){
		if(scope.buylocked)
			return
		
		  
		var odometer = scope.getShopUsedPartOdometer(item)
		var odoscale = scope.getShopUsedPartPriceScale(item)
		var total = scope.beamlrData["partPrices"][item];
		var shopID = scope.beamlrData["shopID"]
		  
		
		if(total == null)
		{
			total = scope.beamlrData["partPrices"]["default"] * scope.beamlrData['shopPriceScale'] * odoscale;
		}
		else
		{
			total = scope.beamlrData["partPrices"][item] * scope.beamlrData['shopPriceScale'] * odoscale;
		}
		
		
	    bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("shopPurchase", "item", "${item}")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("shopPurchase", "price", ${total})`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("shopPurchase", "used", true)`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("shopPurchase", "odo", ${odometer})`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("shopPurchase", "shopID", ${shopID})`);
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("buyPart", "shopPurchase")`);
		
		scope.buylocked = true
		scope.lastbuyitem = item
		scope.lastbuyused = true
	  }

	   scope.usedPartDayDataCheck = function(item)
	   {
		   return scope.beamlrData["advinvUPSDayData"][item]
	   }
	  
	   scope.adjustMirrors = function()
	   {
		   bngApi.engineLua(`extensions.customGuiCallbacks.exec("toggleMirrorsUI")`);
	   }
	  
		
	   scope.fixTemplateClicked = function(template)
	   {
		   scope.templateFixTemplate = template
		   bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateName", "${template}")`)
		   bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateFolder", "${scope.beamlrData["vehicleTemplateFolder"]}")`)
		   bngApi.engineLua(`extensions.customGuiCallbacks.exec("onFixTemplateClicked", "templateData")`);
	   }
	  
	   scope.$on('beamlrTemplateFix', function (event, data) 
	   {
		   scope.templateFixMode = true
		   scope.templateFixData = data
		   scope.templateFixSelected = {}
		   scope.templateFixUsedIDs = {}
		   scope.templateFixNeeded = Object.keys(data["missing"]).length > 0
	   })
	   
	   scope.unitConvertedOdometer = function(val)
	   {
		   var units = scope.beamlrData["advinvUnits"]
		   return (units=="imperial") ? val / 1.609344 : val;
	   }
	   
	   scope.onReplacementSelected = function(part,id)
	   {
		   var selected = scope.templateFixSelected[part][id] == true
		   scope.templateFixSelected[part] = null
		   if(selected)
		   {
			  scope.templateFixSelected[part] = {} 
			  scope.templateFixSelected[part][id] = true 
		   }
			
			scope.templateFixUsedIDs[id] = selected
	   }
	   
	   scope.cancelTemplateFix = function()
	   {
		   scope.templateFixSelected = {}
		   scope.templateFixUsedIDs = {}
		   scope.templateFixMode = false
	   }
	   
	   scope.applyTemplateFix = function()
	   {
		   bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateReplacements", "templateFolder", "${scope.beamlrData["vehicleTemplateFolder"]}")`)
		   bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateReplacements", "templateName", "${scope.templateFixTemplate}")`)
           
		   for(var part in scope.templateFixSelected)
		   {
			   for(var id in scope.templateFixSelected[part])
			   {
				   if(scope.templateFixSelected[part][id] == true)
						bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateReplacements", "fix_${part}", ${id})`)
			   }
				
		   }

		   bngApi.engineLua(`extensions.customGuiCallbacks.exec("applyTemplateFix", "templateReplacements")`);
		   scope.templateFixMode = false
		   scope.templateFixSelected = {}
	   }
	   
	   scope.$on('beamlrPartBuyResult', function (event, data) 
	   {
		    console.log("PART BUY RESULT: " + data)
		    
			var result = data
			if(scope.buylocked && result)
			{
				scope.buylocked = false
				
				//increment owned part count on UI side to avoid having to reload full inventory part counts
				if(scope.beamlrData["advinvOwned"][scope.lastbuyitem] == null)//check for null to avoid NaN value after increment
				{
					scope.beamlrData["advinvOwned"][scope.lastbuyitem] = 1
				}
				else
				{
					scope.beamlrData["advinvOwned"][scope.lastbuyitem] += 1
				}

				if(scope.lastbuyused)
				{
					//updated used shop day data on UI side to avoid having to reload table during inventory refresh
					scope.beamlrData["advinvUPSDayData"][scope.lastbuyitem] = true					
				}
			}
			else
			{
				scope.buylocked = false
			}
			
			
			
	   })
	   
	  scope.setLeagueRestriction = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("restrict", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setLeagueRestriction", "restrict")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setRandomRaceSeedMode = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("rsraces", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setRandomRaceSeedMode", "rsraces")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.preciseTuneDecrease = function(field, step)
	  {
		  scope.beamlrData['tuningValues'][field] = Math.max(scope.beamlrData['tuningData'][field]['minDis'],scope.beamlrData['tuningValues'][field] - step)
	  }
	  
	  scope.preciseTuneIncrease = function(field, step)
	  {
		  scope.beamlrData['tuningValues'][field] = Math.min(scope.beamlrData['tuningData'][field]['maxDis'],scope.beamlrData['tuningValues'][field] + step)
	  }
	  
	  scope.damageBypassToggle = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("dbypass", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setDamageBypassMode", "dbypass")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
		  
		  if(t==1)
		  {
			  scope.actualDamage = scope.beamlrData["playerDamage"]
			  scope.beamlrData["playerDamage"] = 0
		  }
		  else
		  {
			  scope.beamlrData["playerDamage"] = scope.actualDamage
		  }
		  
	  }
	  scope.limitedGarageToggle = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("lgslots", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setLimitedGarageSlotsMode", "lgslots")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);  
	  }
	  
	  scope.trackEventSlicksToggle = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("allowtesmode", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTrackEventSlicksMode", "allowtesmode")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);  
	  }
	  scope.setInventoryMode = function(m)
	  {
		  scope.invmode = m
	  }
	  
	  scope.startManualCache = function(m)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("startManualJbeamCache")`)
	  }
	  
	  scope.toggleLightManager = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("lmtoggle", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("toggleLightManager", "lmtoggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);  
	  }
	  
	  scope.expandSlotTree = function(id)
	  {
		  scope.expanded[id] =  !scope.expanded[id]
	  }
	  
	  scope.expandShopTree = function(id)
	  {
		  scope.shopExpanded[id] =  !scope.shopExpanded[id]
	  }
	  
	  scope.toggleShopTreePartsHidden = function(id)
	  {
		  scope.shopPartsHidden[id] =  !scope.shopPartsHidden[id]
	  }
	  
	  scope.idFromPath = function(path)
	  {
		  return scope.beamlrData['slotPathIDMap'][path] || path
	  }
	  
	  scope.getSlotName = function(slot)
	  {
		  var name = scope.beamlrData['slotNames'][scope.beamlrData['slotPathIDMap'][slot]]
		  
		  if(name == null)
		  {
			  name = scope.beamlrData['slotNames'][slot]
		  }
		  
		  if(name == null || scope.slotNameMode == 1)
		  {
			  if(scope.beamlrData['slotPathIDMap'][slot] != null)
				name = scope.beamlrData['slotPathIDMap'][slot]
			  else
				name = slot
		  }
		  
		  return name			  
	  } 
	  
	  scope.getPartDescription = function(part)
	  {
		  //beamlrData['vehInstParts'][part] == null && beamlrData['advinvOwned'][part] > 0
		  var name = (scope.slotNameMode == 0 && scope.beamlrData['partNames'][part]) || part
		  var suffix = ""
		  
		  if(scope.beamlrData['vehInstParts'][part])
		  {
			  suffix = "\n(" + translate("beamlr.mainui.page.partbuy.tags.installed") + ")"
		  }
		  else if(scope.beamlrData['advinvOwned'][part] > 0)
		  {
			  suffix = "\n(" + translate("beamlr.mainui.page.partbuy.tags.own") + " " + scope.beamlrData['advinvOwned'][part] + ")"
		  }
		  
		  
		  
		  return name + suffix
	  }
	  
	  scope.toggleSlotNameMode = function()
	  {
		  scope.slotNameMode = Math.abs(scope.slotNameMode - 1)
	  }
	  
	  scope.getSlotExpandButton = function(id)
	  {
		  return (scope.expanded[id]) ? "-" : "+";
	  }
	  
	  scope.getShopExpandButton = function(id)
	  {
		  return (scope.shopExpanded[id]) ? "-" : "+";
	  }
	  
	  scope.setEditTreeMode = function(mode)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("treemode", ${mode})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setEditTreeMode", "treemode")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);  
	  }
	  
	  scope.validName = function (testName) {
		if (!testName || testName == "" || /[<>:"/\\|?*]/.test(testName)) {
			return false
		}
		if (/^ +| +$/.test(testName)) {
			testName = testName.replace(/^ +| +$/g, "")
		}
		if (!testName) {
			return false
		}
		return true
	  }
	  
	  
	  scope.exportConfig = function(name)
	  {
		  if(scope.validName(name))
		  {
			bngApi.engineLua(`extensions.customGuiCallbacks.setParam("configName", "${name}")`)
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("exportConfig", "configName")`)
		  }
		  else
		  {
			  scope.guiMessage("beamlr.msgapp.cantexportname", 10, "warning", "configsaving")
		  } 
	  }
	  
	  scope.saveTemplate = function(template)
	  {
		  if(scope.validName(template))
		  {
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateName", "${template}")`)
			bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateFolder", "${scope.beamlrData["vehicleTemplateFolder"]}")`)
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("saveTemplate", "templateData")`)
		  }
		  else
		  {
			scope.guiMessage("beamlr.msgapp.cantsavename", 10, "warning", "configsaving")
		  }
	  }
	  
	  scope.getSlotFavoriteIcon = function(name)
	  {
		  var slot = scope.idFromPath(name)
		  return (scope.beamlrData["slotFavorites"][slot] == "true") ? "star_filled.svg" : "star_empty.svg";
	  }
	  
	  
	  scope.slotFavoriteToggle = function(slot)
	  {
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("favdata", "${slot}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("slotFavoriteToggle", "favdata")`) 
		//immediate update to data so we don't need to receive full favorites table again
		if(scope.beamlrData["slotFavorites"][slot] == "true")
		{
			scope.beamlrData["slotFavorites"][slot] = "false"
		}
		else
		{
			scope.beamlrData["slotFavorites"][slot] = "true"
		}
			
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
				console.log("MAIN UI STRING SPLIT ERROR FOR PATH:" + path)
				return "???"
			}
			
			scope.pathNameCache[path] = cname
			return cname
		  }
		
	  }
	  
	  scope.togglePartShopShowIncompatible = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("pshopshowinc", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("togglePartShopShowIncompatible", "pshopshowinc")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.showPartShopV2 = function()
	  {
		  scope.showMenu = false
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("showPartShopV2")`);
	  }
	  
	  scope.isSlotFilled = function(slot)
	  {
		  return !(scope.beamlrData['advinvUsed'][slot] == null || scope.beamlrData['advinvUsed'][slot] == "")
	  }
	  
	  scope.mainPartCheck = function(slot)
	  {
		  var mainPartID = scope.nameFromPath(scope.beamlrData['mainpart'])
		  var usedPartID = scope.beamlrData['advinvData'][scope.beamlrData['advinvUsed'][slot]][0]
		  return mainPartID == usedPartID
	  }
	  
	  scope.odtoggle = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("odtoggle", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("toggleOilLeakDecals", "odtoggle")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);  
	  }
	  
	  scope.setOilLeakDecalBuffer = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("odbufsize", ${t})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setOilLeakDecalBuffer", "odbufsize")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);  
	  }
	  
	  scope.clearDecals = function(t)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("clearDecals")`);  
	  }
	  
	  scope.loadSaveFile = function(name)
	  {
		  if(scope.inputData.saveLoadConfirm[name] == true)
		  {
		       bngApi.engineLua(`extensions.customGuiCallbacks.setParam("savefilename", "${name}")`)
		       bngApi.engineLua(`extensions.customGuiCallbacks.exec("loadSaveFile", "savefilename")`)
			   scope.inputData.saveLoadConfirm[name] = false
		  }
		  else
		  {
			  scope.inputData.saveLoadConfirm[name] = true
		  }
	  }
	  
	  scope.loadSaveFileCancel = function(name)
	  {
		  scope.inputData.saveLoadConfirm[name] = false
	  }
	  
	  scope.deleteSaveFile = function(name)
	  {
		  if(scope.inputData.saveDeleteConfirm[name] == true)
		  {
			  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("savefilename", "${name}")`)
			  bngApi.engineLua(`extensions.customGuiCallbacks.exec("deleteSaveFile", "savefilename")`)
			  scope.inputData.saveDeleteConfirm[name] = false
		  }
		  else
		  {
			   scope.inputData.saveDeleteConfirm[name] = true
		  }
		  
	  }
	  
	  scope.deleteSaveFileCancel = function(name)
	  {
		  scope.inputData.saveDeleteConfirm[name] = false
	  }
	  
	  
	  isNullOrEmpty = function(str)
	  {
		  return (str == null || str.toString() == "")
	  }
	  
	  validFilename = function(str)
	  {
		var rg1=/^[^\\/:\*\?\."<>\|\s]+$/; // forbidden characters \ / . : * ? " < > | WHITESPACE
		var rg2=/^\./; // cannot start with dot (.)
		var rg3=/^(nul|prn|con|lpt[0-9]|com[0-9])(\.|$)/i; // forbidden file names

		return rg1.test(str)&&!rg2.test(str)&&!rg3.test(str);
	  }
	  
	  scope.createSaveFile = function(name)
	  {
		  if(isNullOrEmpty(name))
		  {
			  scope.guiMessage("Save couldn't be created, name cannot be empty!", 10, "warning", "savesystem")
			  return
		  }
		  
		  if(!validFilename(name))
		  {
			  scope.guiMessage("Save couldn't be created, name contains invalid terms or characters!", 10, "warning", "savesystem")
			  return
		  }
		  
		  
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("savefilename", "${name}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("createSaveFile", "savefilename")`)
	  }
	  
	  
	  
    }
  }
}]);