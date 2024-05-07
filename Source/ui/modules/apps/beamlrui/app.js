angular.module('beamng.apps')
.directive('beamlrui', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
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
		{type: "inventory", svg:"inventorybutton.svg", id:6, name:"Items"},
		{type: "events", svg:"eventbrowserbutton.svg", id:5, name:"Track Events"}
	  ];
	  
	  scope.menuClick = function(id){
		scope.menuPage = id;
		scope.resetConfirm = false;
		
		if(id == 3)
		{
			bngApi.engineLua(`extensions.customGuiCallbacks.setParam("perfuitoggle", "1")`);
			bngApi.engineLua(`extensions.customGuiCallbacks.exec("togglePerfUI", "perfuitoggle")`);
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
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("garageEdit", "slot", "${slot}")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("garageEdit", "item", "${item}")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("setPart", "garageEdit")`);
		//bngApi.engineLua(`extensions.customGuiCallbacks.exec("inventoryRefresh")`) //Needs to be called in post edit process to work properly
	  }
	  
	  scope.shopPartClick = function(item){
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
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("shopPurchase", "price", ${scope.partPrice})`);
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("buyPart", "shopPurchase")`);
	  }

	  scope.$on('beamlrData', function (event, data) {
          scope.beamlrData[data.key] = data.val;
		  if(data.key == "itemInventory")
		  {
			  scope.sortedItemInventoryKeys = Object.keys(scope.beamlrData['itemInventory']).sort()
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
		  scope.inputData['wagerscl'] = data['wagerscl']
		  scope.inputData['repscl'] = data['repscl']
		  scope.beamlrData['seed'] = data['sseed']
      })
	  
	  
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
	  
	  scope.setTrafficDensity= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("traffic", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTrafficDensity", "traffic")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setPoliceDensity= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("traffic", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setPoliceDensity", "traffic")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setTruckDensity= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("traffic", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTruckDensity", "traffic")`)
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
	  
	  scope.setTrafficRisk= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("risk", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTrafficRisk", "risk")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("optionsUIReload")`);
	  }
	  
	  scope.setPoliceStrictness= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("copstrict", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setPoliceStrictness", "copstrict")`)
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
	  
	  scope.saveTemplate = function (template)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateName", "${template}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateFolder", "${scope.beamlrData["vehicleTemplateFolder"]}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("saveTemplate", "templateData")`)
	  }
	  
	  scope.deleteTemplate = function (template)
	  {
	      bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateName", "${template}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("templateData", "templateFolder", "${scope.beamlrData["vehicleTemplateFolder"]}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("deleteTemplate", "templateData")`)
	  }
	  
	  scope.loadTemplate = function (template)
	  {
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
	  
	  
    }
  }
}]);