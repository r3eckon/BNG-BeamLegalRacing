angular.module('beamng.apps')
.directive('beamlrshopvehutil', [function () {
  return {
    templateUrl: '/ui/modules/apps/beamlrshopvehutil/app.html',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {

	  scope.init = false
	  
	  scope.walking = false
	  
	  scope.data = {}
	  
	  scope.page = 0
	  scope.page_main = 0
	  scope.page_load = 1
	  scope.page_save = 2
	  scope.page_editlists = 3
	  scope.page_editshops = 4
	  
	  scope.officialListNames = {}
	  scope.officialListNames["used_all"] = "Used Car Shops"
	  scope.officialListNames["new_all"] = "New Car Shops"
	  scope.officialListNames["mixed_all"] = "Mixed Car Shops"
	  scope.officialListNames["scrap_all"] = "Scrapyards"
	  

	  scope.saveParams = {}
	  scope.saveParams.selectedSlots = {}
	  scope.saveParams.selectedLists = {}
	  scope.saveParams.customListName = null
	  scope.saveParams.listAddonMode = true
	  scope.saveParams.selectedAddons = {}
	  scope.saveParams.customAddonName = {}
	  scope.saveParams.carFileName = null
	  
	  scope.carFileNameInvalidReason = ""
	  scope.selectedListsCount = 0
	  scope.selectedNeededAddons = false
	  
	 
	  scope.selectedCarFile = null
	  scope.deleteCarConfirm = false
	  scope.deleteListConfirm = false
	  
	  scope.listeditSelectedList = null
	  scope.listeditSelectedCars = {}
	  scope.listeditParams = {}
	  scope.listeditParams.customListName = null
	  scope.listeditParams.customAddonName = {}

	  scope.shopParams = {}
	  scope.shopEditSelectedShop = null
	  
	  
	  sanitize = function(v)
	  {
		  if(typeof v != "string")
			  return v
		  
		  var toRet = v
		  toRet = toRet.replaceAll("'", "\\'")
		  toRet = toRet.replaceAll('"', '\\"')
		  return toRet
	  }
	  
	  sendParamSanitized = function(key, val)
	  {
		  var s = sanitize(val)
		  if(typeof s == "string")
			bngApi.engineLua(`extensions.blrShopVehUtil.receiveParam('${key}', '${s}')`)
		  else
			bngApi.engineLua(`extensions.blrShopVehUtil.receiveParam('${key}', ${s})`)  
	  }
	  
	  sendParamTableSanitized = function(t, key, val)
	  {
		  var s = sanitize(val)
		  if(typeof s == "string")
			bngApi.engineLua(`extensions.blrShopVehUtil.receiveParamTableValue('${t}','${key}', '${s}')`)
		  else
			bngApi.engineLua(`extensions.blrShopVehUtil.receiveParamTableValue('${t}','${key}', ${s})`)
	  }
	  
	  sendCacheParamTableSanitized = function(t, key, val)
	  {
		  var s = sanitize(val)
		  if(typeof s == "string")
			bngApi.engineLua(`extensions.blrShopVehUtil.receiveCacheParamTableValue('${t}','${key}', '${s}')`)
		  else
			bngApi.engineLua(`extensions.blrShopVehUtil.receiveCacheParamTableValue('${t}','${key}', ${s})`)
	  }
	  
	  sendCacheParamSanitized = function(key, val)
	  {
		  var s = sanitize(val)
		  if(typeof s == "string")
			bngApi.engineLua(`extensions.blrShopVehUtil.receiveCacheParam('${key}', '${s}')`)
		  else
			bngApi.engineLua(`extensions.blrShopVehUtil.receiveCacheParam('${key}', ${s})`)  
	  }

	  
	  scope.cache = function()
	  {
		  var serialized = JSON.stringify(scope.saveParams)
		  
		  //main params
		  sendCacheParamSanitized('page',scope.page)
		  
		  //save params  
		  sendCacheParamSanitized('saveParams',serialized)
		  sendCacheParamSanitized('selectedNeededAddons',scope.selectedNeededAddons)
		  sendCacheParamSanitized('selectedListsCount',scope.selectedListsCount)
		  
		  //load params
		  sendCacheParamSanitized('selectedCarFile',scope.selectedCarFile)
		  sendCacheParamSanitized('deleteCarConfirm',scope.deleteCarConfirm)
		  
		  //list edit params
		  serialized = JSON.stringify(scope.listeditSelectedCars)
		  sendCacheParamSanitized('listeditSelectedList',scope.listeditSelectedList)
		  sendCacheParamSanitized('listeditSelectedCars',serialized)
		  sendCacheParamSanitized('deleteListConfirm',scope.deleteListConfirm)	 
		  serialized = JSON.stringify(scope.listeditParams)
		  sendCacheParamSanitized('listeditParams',serialized)	 
	  
		  //shop edit params
		  serialized = JSON.stringify(scope.shopParams)
		  sendCacheParamSanitized('shopParams',serialized)
		  sendCacheParamSanitized('shopEditSelectedShop',scope.shopEditSelectedShop)
	  }

	  if(!scope.init)
	  {
		 bngApi.engineLua(`extensions.blrShopVehUtil.sendUIData(true)`)
		 //scope.params["mincost"] = 1000
		 //scope.params["maxcost"] = 10000
		 //scope.params["minodo"] = 50000
		 //scope.params["maxodo"] = 200000
	  }
	  
	  scope.idFromPath = function(path)
	  {
		  var id = path.split("/")
		  return id[id.length-2]
	  }
	  
	  scope.filenameFromPath = function(path)
	  {
		  var id = path.split("/")
		  return id[id.length-1]
	  }

	  scope.$on('beamlrShopVehUtilData', function (event, data) {
          scope.data = data
		  scope.init=true
      })
	  
	  scope.$on('beamlrShopVehUtilWalking', function (event, data) {
          scope.walking = data
      })
	  
	  scope.reset = function()
	  {
		  scope.saveParams = {}
		  scope.saveParams.selectedSlots = {}
		  scope.saveParams.selectedLists = {}
		  scope.saveParams.customListName = null
		  scope.saveParams.listAddonMode = true
		  scope.saveParams.selectedAddons = {}
		  scope.saveParams.customAddonName = {}
		  scope.saveParams.carFileName = null
		  scope.carFileNameInvalidReason = ""
		  scope.selectedListsCount = 0
		  scope.selectedNeededAddons = false
		  scope.selectedCarFile = null
		  scope.deleteCarConfirm = false
		  scope.listeditSelectedList = null
		  scope.listeditSelectedCars = {}
		  scope.deleteListConfirm = false
		  scope.listeditParams = {}
		  scope.listeditParams.customListName = null
		  scope.listeditParams.customAddonName = {}
		  scope.shopParams = {}
		  scope.shopEditSelectedShop = null
		  bngApi.engineLua(`extensions.blrShopVehUtil.sendUIData()`)
	  }
	  
	  scope.$on('beamlrShopVehUtilCache', function (event, data) {
		  if(data && data.page != null)
		  {
			 //main params
			 scope.page = data.page
			 
			 //save params
			 if(data.saveParams != null)
				scope.saveParams = JSON.parse(data.saveParams)
			 if(data.selectedNeededAddons != null)
				scope.selectedNeededAddons = JSON.parse(data.selectedNeededAddons)
			 if(data.selectedListsCount != null)
				scope.selectedListsCount = JSON.parse(data.selectedListsCount)
			 
			 //load params
			 if(data.selectedCarFile != null)
				scope.selectedCarFile = data.selectedCarFile
			 if(data.deleteCarConfirm != null)
				scope.deleteCarConfirm = data.deleteCarConfirm
			 
			 //list edit params
			 if(data.listeditSelectedList != null)
				scope.listeditSelectedList = data.listeditSelectedList
			 if(data.listeditSelectedCars != null)
				scope.listeditSelectedCars = JSON.parse(data.listeditSelectedCars)
			 if(data.deleteListConfirm != null)
				scope.deleteListConfirm = data.deleteListConfirm
			 if(data.listeditParams != null)
				scope.listeditParams = JSON.parse(data.listeditParams)
			
			 //shop edit params
			 if(data.shopParams != null)
				 scope.shopParams = JSON.parse(data.shopParams)
			 if(data.shopEditSelectedShop != null)
				scope.shopEditSelectedShop = data.shopEditSelectedShop
			 
			
		  }
		  else
		  {
			  scope.reset()
			  scope.cache()
		  }
		  
      })
	  
	  
	  
	  scope.$on('beamlrShopLoadedCarParams', function (event, data) {
		  scope.saveParams.selectedSlots = {} //reset selected slots in case previous car had same paths selected (happens with /paint_design/)
          scope.saveParams.name = data.name
          scope.saveParams.mincost = data.mincost
          scope.saveParams.maxcost = data.maxcost
          scope.saveParams.minodo = data.minodo
          scope.saveParams.maxodo = data.maxodo
          scope.saveParams.scrapval = data.scrapval
		  
		  var cpath = ""
		  var cid = ""
		  for(index in scope.data.slots)
		  {
			  cpath = scope.data.slots[index]
			  cid = scope.idFromPath(cpath)
			  
			  if(data.randslots && data.randslots[cid])
			  {
				  scope.saveParams.selectedSlots[cpath] = true
			  }
				  
		  }
		  
		  scope.saveParams.carFileName = data.carfile
		  
		  scope.cache()
      })
	  
	  scope.$on('beamlrShopLoadedShopParams', function (event, data) {
		  scope.shopParams.name = data.name
		  scope.shopParams.chance = data.chance * 100
		  scope.shopParams.rpchance = data.rpchance * 100
		  scope.shopParams.dchance = data.dchance * 100
		  scope.shopParams.models = data.models
		  scope.cache()
      })

	  scope.resetSaveParams = function()
	  {
		scope.saveParams = {}
		scope.saveParams.selectedLists = {}
		scope.saveParams.customListName = null
		scope.saveParams.listAddonMode = true
		scope.saveParams.selectedAddons = {}
		scope.saveParams.customAddonName = {}
		scope.saveParams.carFileName = null
		scope.saveParams.selectedSlots = {}
	  }
	  
	  scope.updateRanges = function()
	  {
		  scope.$apply()
	  }
	  
	  
	  
	  showMessage = function(msg, icon, ttl, cat)
	  {
		  if(msg)
			sendParamSanitized('msg',msg)
		
		  if(icon)
			sendParamSanitized('icon',icon)
		
		  if(ttl)
			sendParamSanitized('ttl',ttl)
		
		  if(cat)
			sendParamSanitized('cat',cat)
		
		  bngApi.engineLua(`extensions.blrShopVehUtil.exec('showMessage')`)
	  }
	  
	  scope.setPage = function(page)
	  {
		  scope.page = page
		  scope.cache()
		  scope.deleteCarConfirm=false
		  scope.deleteListConfirm=false
	  }
	  
	  scope.removeListPrefix = function(name)
	  {
		  return name.replace("list_", "")
	  }
	  
	  scope.removeAddonPrefix = function(name)
	  {
		  return name.replace("addon_", "")
	  }
	  
	  scope.listNameFromPath = function(path)
	  {
		  var name = path.split("/")
		  return name[name.length-1].replace("list_", "")
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
	  
	  //returns null if no blacklisted words are found, otherwise returns found word
	  checkStringBlacklist = function(s, blist)
	  {
		  var str = s.toUpperCase()
		  
		  for(i in blist)
		  {
			  if(str.indexOf(blist[i]) >= 0)
				  return blist[i]
		  }
		  
		  return null
	  }
	  
	  scope.addCustomList = function()
	  {
		  var name = scope.saveParams.customListName
		  
		  
		  if(isNullOrEmpty(name))
		  {
			  return
		  }

		  if(!validFilename(name))
		  {
			  showMessage("Could not create list file, name contains invalid characters or terms.")
			  return
		  }
			
          var bterm = checkStringBlacklist(name, ["LIST","ADDON"])
		  if(bterm)
		  {
			  showMessage("Could not create list file, name contains blacklisted word \"" + bterm + "\".")
			  return
		  }
		  
		  
		  var path = "/beamLR/shop/car/list_" + name
		  if(!scope.data['listFiles'][path])
		  {
			  scope.data['listFiles'][path] = true
			  sendParamSanitized('path',path)
			  bngApi.engineLua(`extensions.blrShopVehUtil.exec('createList')`)
		  }
		  else
		  {
			  showMessage("Could not create list file, name already in use.")
		  }
	  }
	  
	  scope.listedit_addCustomList = function()
	  {
		  var name = scope.listeditParams.customListName
		  
		  if(isNullOrEmpty(name))
		  {
			  return
		  }

		  if(!validFilename(name))
		  {
			  showMessage("Could not create list file, name contains invalid characters or terms.")
			  return
		  }
			
          var bterm = checkStringBlacklist(name, ["LIST","ADDON"])
		  if(bterm)
		  {
			  showMessage("Could not create list file, name contains blacklisted word \"" + bterm + "\".")
			  return
		  }
		  
		  
		  var path = "/beamLR/shop/car/list_" + name
		  if(!scope.data['listFiles'][path])
		  {
			  scope.data['listFiles'][path] = true
			  sendParamSanitized('path',path)
			  bngApi.engineLua(`extensions.blrShopVehUtil.exec('createList')`)
		  }
		  else
		  {
			  showMessage("Could not create list file, name already in use.")
		  }
	  }
	  
	  scope.listAddonFolderFromFile = function(file)
	  {
		  var name = scope.listNameFromPath(file)
		  return "/beamLR/shop/car/addon_" + name
	  }
	  
	  scope.addonFolderNameFromPath = function(path)
	  {
		  var name = path.split("/")
		  return name[name.length-1].replace("addon_", "")
	  } 
	  
	  scope.addonFileNameFromPath = function(path)
	  {
		  var name = path.split("/")
		  return name[name.length-1]
	  } 
	  
	  scope.addCustomAddon = function(list, listedit)
	  {
		  var addonFolder = (listedit ? list : scope.listAddonFolderFromFile(list))
		  var name = scope.saveParams.customAddonName[list]
		  
		  if(isNullOrEmpty(name))
		  {
			  return
		  }
		  
		  if(!validFilename(name))
		  {
			  showMessage("Could not create addon file, name contains invalid characters or terms.")
			  return
		  }

		  var bterm = checkStringBlacklist(name, ["LIST"])
		  if(bterm)
		  {
			  showMessage("Could not create addon file, name contains blacklisted word \"" + bterm + "\".")
		  }
		  
		  
		  if(!scope.data['listAddonFiles'][addonFolder])
				  scope.data['listAddonFiles'][addonFolder] = {}
			  
		  var path = addonFolder + "/" + name
		  if(!scope.data['listAddonFiles'][addonFolder][path])
		  {
			  scope.data['listAddonFiles'][addonFolder][path] = true
			  sendParamSanitized('path',path)
			  bngApi.engineLua(`extensions.blrShopVehUtil.exec('createList')`)
		  }
		  else
		  {
			  showMessage("Could not create addon file, name already in use.")
		  }
		  
	  }
	  
	  scope.listedit_addCustomAddon = function(folder)
	  {
		  var addonFolder = folder
		  var name = scope.listeditParams.customAddonName[folder]
		  
		  if(isNullOrEmpty(name))
		  {
			  return
		  }
		  
		  if(!validFilename(name))
		  {
			  showMessage("Could not create addon file, name contains invalid characters or terms.")
			  return
		  }

		  var bterm = checkStringBlacklist(name, ["LIST"])
		  if(bterm)
		  {
			  showMessage("Could not create addon file, name contains blacklisted word \"" + bterm + "\".")
		  }
		  
		  
		  if(!scope.data['listAddonFiles'][addonFolder])
				  scope.data['listAddonFiles'][addonFolder] = {}
			  
		  var path = addonFolder + "/" + name
		  if(!scope.data['listAddonFiles'][addonFolder][path])
		  {
			  scope.data['listAddonFiles'][addonFolder][path] = true
			  sendParamSanitized('path',path)
			  bngApi.engineLua(`extensions.blrShopVehUtil.exec('createList')`)
		  }
		  else
		  {
			  showMessage("Could not create addon file, name already in use.")
		  }
		  
	  }
	  
	  scope.carShopFileNameExists = function(path)
	  {
		  if(scope.data['carFiles'][path])
		  {
			  return true
		  }
		  
		  return false
		  
	  }

	  scope.carShopFileNameValid = function(toConfirm)
	  {
		  
		  
		  if(isNullOrEmpty(scope.saveParams.carFileName) && !toConfirm)
			  return true
		  
		  if(isNullOrEmpty(scope.saveParams.carFileName) && toConfirm)
			  return false
		  
		  var path = "/beamLR/shop/car/" + scope.saveParams.carFileName
		  
		  if(scope.carShopFileNameExists(path) && !toConfirm)
		  {
			  scope.carFileNameInvalidReason = "Existing file will be overwritten!"
			  return false
		  }

		  if(!validFilename(scope.saveParams.carFileName))
		  {
			  scope.carFileNameInvalidReason = "Filename contains invalid strings or characters!"
			  return false
		  }
			  
		  
		  return true
	  }
	  
	  scope.selectedAddonsChange = function()
	  {
		  for(list in scope.saveParams.selectedLists)
		  {
			  if(scope.saveParams.selectedLists[list] && !scope.saveParams.selectedAddons[list])
			  {
				  scope.selectedNeededAddons = false
				  return
			  }
		  }
		  
		  scope.selectedNeededAddons = true
		  scope.cache()
	  }
	  
	  scope.selectedListsChange = function()
	  {
		  scope.selectedListsCount = 0
		  for(key in scope.saveParams.selectedLists)
		  {
			  if(scope.saveParams.selectedLists[key])
				  scope.selectedListsCount++;
		  }
		  
		  scope.selectedAddonsChange()
		  scope.cache()
	  }

	  scope.saveSelectedListAddonValid = function()
	  {
		  if(scope.selectedListsCount == 0)
			  return false
		  
		  if(scope.selectedAddonsCount == 0 && scope.saveParams.listAddonMode)
			  return false
		  
		  if(!scope.saveParams.listAddonMode)
			  return true
		  
		  if(!scope.selectedNeededAddons)
			  return false
		  
		  return true
	  }
	  
	  
	  scope.saveParamsValid = function()
	  {
		  return scope.carShopFileNameValid(true) && scope.saveSelectedListAddonValid()
	  }
	  
	  scope.selectCarFile = function(file, spawnNew)
	  {
		  if(scope.selectedCarFile == file)
		  {
			  scope.setPage(scope.page_main)
			  scope.cache()
			  sendParamSanitized('replace',!spawnNew)
			  sendParamSanitized('carfile',file)
			  bngApi.engineLua(`extensions.blrShopVehUtil.exec('loadCarFile')`)
		  }
		  else
		  {
			  scope.deleteCarConfirm = false
			  scope.selectedCarFile = file
		  }

		   scope.cache()
	  }
	  
	  scope.selectListFile = function(file, addon)
	  {
		  if(file != scope.listeditSelectedList)
			  scope.deleteListConfirm = false
		  
		  scope.listeditSelectedList = file
		  scope.listeditSelectedCars = {}
		  
		  var cpath = ""
		  
		  if(!addon)
		  {
			  for(car in scope.data['listFilesData'][file])
			  {
				  cpath = "/beamLR/shop/car/" + car
				  scope.listeditSelectedCars[cpath] = true
			  }
		  }
		  else
		  {
			  for(car in scope.data['addonFilesData'][file])
			  {
				  cpath = "/beamLR/shop/car/" + car
				  scope.listeditSelectedCars[cpath] = true
			  }
		  }
		  
		  
		  
		  scope.cache()
	  }
	  
	  scope.saveCarFile = function()
	  {
		  sendParamSanitized('filename',scope.saveParams.carFileName)
		  sendParamSanitized('name',scope.saveParams.name)
		  sendParamSanitized('type',scope.data['model'])
		  sendParamSanitized('config',scope.data['config'])
		  sendParamSanitized('maxcost',scope.saveParams.maxcost)
		  sendParamSanitized('mincost',scope.saveParams.mincost)
		  sendParamSanitized('maxodo',scope.saveParams.maxodo)
		  sendParamSanitized('minodo',scope.saveParams.minodo)
		  sendParamSanitized('scrapval',scope.saveParams.scrapval)
		  
		  var cid = ""
		  for(k in scope.saveParams.selectedSlots)
		  {
			  cid = scope.idFromPath(k)
			  sendParamTableSanitized('randslots',cid, true)
		  }
		  
		  
		  
		  bngApi.engineLua(`extensions.blrShopVehUtil.exec('saveCarFile')`)
	  }
	  
	  scope.saveCarFileAndAddToList = function()
	  {
		  scope.saveCarFile()
		  
		  sendParamSanitized('filename',scope.saveParams.carFileName)
		  sendParamSanitized('addonMode',scope.saveParams.listAddonMode)
		  
		  for(list in scope.saveParams.selectedLists)
		  {
			  if(scope.saveParams.selectedLists[list])
			  {
				  sendParamTableSanitized('selectedLists',list, true)
				  
				  if(scope.saveParams.selectedAddons[list])
					sendParamTableSanitized('selectedAddons',list, scope.saveParams.selectedAddons[list])
			  }
		  }

		  bngApi.engineLua(`extensions.blrShopVehUtil.exec('addToList')`)
	  }
	  
	
	  scope.editList = function()
	  {
		  if(isNullOrEmpty(scope.listeditSelectedList))
			  return
		  
		  
		  sendParamSanitized('list',scope.listeditSelectedList)
		  
		  var ccar = ""
		  for(path in scope.listeditSelectedCars)
		  {
			  
			  if(scope.listeditSelectedCars[path])
			  {
				 ccar = scope.filenameFromPath(path)
				 if(ccar != "")
					sendParamTableSanitized('selected',ccar, true)
			  }
		  }

		  bngApi.engineLua(`extensions.blrShopVehUtil.exec('editList')`)
	  }
	  
	  scope.deleteCar = function()
	  {
		  if(!scope.deleteCarConfirm)
			  scope.deleteCarConfirm = true
		  else
		  {
			  scope.deleteCarConfirm=false
			  sendParamSanitized('carfile',scope.selectedCarFile)
			  bngApi.engineLua(`extensions.blrShopVehUtil.exec('deleteCar')`)
			  scope.selectedCarFile = ""
		  }
		  scope.cache()
		  
		  
	  }
	  
	  scope.mainPageSaveParamsValid = function()
	  {
		  if(isNullOrEmpty(scope.saveParams.name))
			  return false
		  
		  if(isNullOrEmpty(scope.saveParams.mincost))
			  return false
		  
		  if(isNullOrEmpty(scope.saveParams.maxcost))
			  return false
		  
		  if(isNullOrEmpty(scope.saveParams.minodo))
			  return false
		  
		  if(isNullOrEmpty(scope.saveParams.maxodo))
			  return false
		  
		  if(isNullOrEmpty(scope.saveParams.scrapval))
			  return false
		  
		  return true
	  }
	  
	  scope.deleteList = function()
	  {
		  if(!scope.deleteListConfirm)
			  scope.deleteListConfirm = true
		  else
		  {
			  sendParamSanitized('path',scope.listeditSelectedList)
			  bngApi.engineLua(`extensions.blrShopVehUtil.exec('deleteList')`)
			  
			  bngApi.engineLua(`extensions.blrShopVehUtil.sendUIData()`)
			  
			  scope.deleteListConfirm = false
			  scope.listeditSelectedList=null
		  }
		  scope.cache()
	  }
	  
	  
	  scope.showRandomConfig = function()
	  {
		  for(k in scope.saveParams.selectedSlots)
		  {
			  cid = scope.idFromPath(k)
			  sendParamTableSanitized('randslots',cid, true)
		  }
		  bngApi.engineLua(`extensions.blrShopVehUtil.exec('spawnRandomConfig')`)
	  }
	  
	  scope.showOriginalConfig = function()
	  {
		  bngApi.engineLua(`extensions.blrShopVehUtil.exec('spawnOriginalConfig')`)
	  }
	  
	  scope.selectShopFile = function(shop)
	  {
		  scope.shopEditSelectedShop = shop
		  sendParamSanitized('shop',shop)
		  bngApi.engineLua(`extensions.blrShopVehUtil.exec('loadShop')`)
	  }
	  
	  scope.saveShopFile = function()
	  {
		  sendParamSanitized('shop',scope.shopEditSelectedShop)
		  
		  sendParamSanitized('name',scope.shopParams.name)
		  sendParamSanitized('chance',scope.shopParams.chance/100.0)
		  sendParamSanitized('rpchance',scope.shopParams.rpchance/100.0)
		  sendParamSanitized('dchance',scope.shopParams.dchance/100.0)
		  sendParamSanitized('models',scope.shopParams.models)

		  bngApi.engineLua(`extensions.blrShopVehUtil.exec('saveShop')`)
	  }
	  
    }
  }
}]);