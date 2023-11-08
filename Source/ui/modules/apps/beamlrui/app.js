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
	  scope.partSellScale = 0.5;

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
      })
	  
	  
	  scope.setNameClick = function () {
		bngApi.engineLua(`extensions.customGuiStream.sendDataToEngine("inputData","${scope.inputData.name}")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("saveinfo", "filename", "beamLR/playername")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("saveinfo", "filedata", "playerName=${scope.inputData.name}")`);
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("writeFile", "saveinfo")`);
		
	  }
	  
	  scope.setVehNameClick = function () {
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("vehname", "${scope.inputData.vehname}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("vehicleRename", "vehname")`)
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
	  }
	  
	  scope.setPoliceDensity= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("traffic", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setPoliceDensity", "traffic")`)
	  }
	  
	  scope.setTruckDensity= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("traffic", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTruckDensity", "traffic")`)
	  }
	  
	  scope.setSeed = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("seed", "${scope.inputData.seed}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setSeed", "seed")`)
	  }
	  
	  scope.setAutoSeed = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("autoseed", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setAutoSeed", "autoseed")`)
	  }
	  
	  scope.setRandomSeed = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setRandomSeed")`)
	  }
	  
	  scope.setDifficulty = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("difficulty", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setDifficulty", "difficulty")`)
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
	  }
	  
	  scope.setPoliceStrictness= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("copstrict", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setPoliceStrictness", "copstrict")`)
	  }
	  
	  scope.setSleepDuration= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("sleeptime", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setSleepDuration", "sleeptime")`)
	  }
	  
	  scope.setTimeScale= function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("timescale", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setTimeScale", "timescale")`)
	  }


	  scope.setOpponentRandomPaint = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("randpaint", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setOpponentRandomPaint", "randpaint")`)
	  }
	  
	  scope.forcedCopfix = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("forcedCopfix")`)
	  }
	  
	  scope.autoCopfix = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("copfixToggle", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setAutoCopfix", "copfixToggle")`)
	  }
	  
	  scope.beamstateToggle = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("beamstateToggle", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setBeamstateToggle", "beamstateToggle")`)
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
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("pwager", "${wager}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setRaceWager", "pwager")`)
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
	  }
	  //advanced repair cost
	  scope.arcToggle = function(toggle)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("arctoggle", ${toggle})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setARCToggle", "arctoggle")`)
	  }
	  
	  scope.setGPSMode = function(mode)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("gpsmode", ${mode})`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setGPSMode", "gpsmode")`)
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
	  
	  
	  
    }
  }
}]);