angular.module('beamng.apps')
.directive('beamlrui', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrui/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
	  
	  scope.testdata = 'Not Loaded'
	  scope.beamlrData = {}
	  scope.inputData = {}
	  scope.textBoxFocus = false
	  scope.menuPage = 0 
	  scope.showMenu = false
	  scope.partPrice = 0
	  scope.initDone = false
	  scope.editMode = 0
	  scope.slotNameMode = 0
	  
	  

	  if(!scope.initDone)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("uiinit")`);
		  scope.inputData.searchFilter = ""
		  scope.initDone=true;
	  }
	  
	  
	  scope.menuButtons = [
		{type: "home", svg:"homebutton.svg", id:0, name:"Main Menu"},
		{type: "options", svg:"gearbutton.svg", id:1, name:"Options"},
		{type: "buyparts", svg:"partshopbutton.svg", id:2, name:"Buy Parts"},
		{type: "editcar", svg:"editcarbutton.svg", id:3, name:"Edit Car"},
		{type: "tuning", svg:"tuningbutton.svg", id:4, name:"Tuning"}
	  ];
	  
	  scope.menuClick = function(id){
		scope.menuPage = id
	  }
	  
	  scope.filter = function(m, f){
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("filter", "${f}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("setFilter", "filter")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("menu", ${m})`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("partUICategory", "menu")`)
	  } 

	  scope.garagePartClick = function(slot, item){
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("garageEdit", "slot", "${slot}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("garageEdit", "item", "${item}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("setPart", "garageEdit")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("inventoryRefresh")`)
	  }
	  
	  scope.shopPartClick = function(item){
		scope.partPrice = scope.beamlrData["partPrices"][item];
		if(scope.partPrice == null)
		{
			scope.partPrice = scope.beamlrData["partPrices"]["default"];
		}
	    bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("shopPurchase", "item", "${item}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("shopPurchase", "price", ${scope.partPrice})`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("buyPart", "shopPurchase")`)
	  }

	  scope.$on('beamlrData', function (event, data) {
          scope.beamlrData[data.key] = data.val;
      })
	  
	  
	  scope.setNameClick = function () {
		bngApi.engineLua(`extensions.customGuiStream.sendDataToEngine("inputData","${scope.inputData.name}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("saveinfo", "filename", "beamLR/playername")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.setParamTableValue("saveinfo", "filedata", "playerName=${scope.inputData.name}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("writeFile", "saveinfo")`)
		
	  }
	  
	  scope.setVehNameClick = function () {
		bngApi.engineLua(`extensions.customGuiCallbacks.setParam("vehname", "${scope.inputData.vehname}")`)
		bngApi.engineLua(`extensions.customGuiCallbacks.exec("vehicleRename", "vehname")`)
	  }
	  
	  scope.showMenuClick = function () {
		  scope.showMenu = !scope.showMenu;
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
		  return parseFloat(scope.beamlrData["tuningValues"][id]);
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
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("uiResetCareer")`)
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
	  
	  scope.setRandomSeed = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setRandomSeed")`)
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

	  scope.setOpponentRandomPaint = function(d)
	  {
		  bngApi.engineLua(`extensions.customGuiCallbacks.setParam("randpaint", "${d}")`)
		  bngApi.engineLua(`extensions.customGuiCallbacks.exec("setOpponentRandomPaint", "randpaint")`)
	  }
	  
    }
  }
}]);