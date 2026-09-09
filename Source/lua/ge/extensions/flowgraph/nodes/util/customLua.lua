-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- BEAMLR MODIFIED TO ADD blrlogs.lua FUNCTIONS TO ENVIRONMENT GLOBALS

local im  = ui_imgui

local ffi = require('ffi')

local C = {}

C.name = 'Custom Lua '
C.description = "Create a custom lua node in the editor."
C.category = 'repeat_instant'

C.pinSchema = {}
C.color = ui_flowgraph_editor.nodeColors.debug
C.icon = ui_flowgraph_editor.nodeIcons.debug
C.tags = {}

local codeNames = {'work','_executionStarted', '_executionStopped', 'onPreRender'}
local codeDescription = {
  work = "This function is called every frame when the node has at least one active flow input.",
  _executionStarted = "This function is called when the project is started. Use it to set up initial values for stuff.",
  _executionStopped = "This function is called after the project is stopped. Use it to clean up and remove unnecesary variables.",
  onPreRender = "This function is called before rendering."
}
local bufLen = 2048*16

function C:init()
  self.clearOutPinsOnStart = false
  self.code = {
    work = "",
    _executionStarted = "",
    _executionStopped = "",
    onPreRender = "",
  }
  self.compiled = {}
  self.status = {}
  self.allowCustomOutPins = true
  self.allowCustomInPins = true
  self.savePins = true
end

function C:compile(code)
  local exprFunc, message = load(self.code[code] or "",nil, nil, self:buildBaseEnv())
  self.status[code] = message
  if not message then
    self.compiled[code] = exprFunc
  else
    self.compiled[code] = nop
  end
end

function C:drawCustomProperties()
  local change = false
  local editEnded = im.BoolPtr(false)
  local customNodes = editor.getPreference('flowgraph.general.customLuaNodes')


  im.PushItemWidth(im.GetContentRegionAvailWidth())
  if im.BeginCombo("##loadNode", "Load from library...") then
    local sortedNames = tableKeys(customNodes)
    table.sort(sortedNames)
    for _, name in ipairs(sortedNames) do
      if im.Selectable1(name, name == self.name) then
        local data = deepcopy(customNodes[name])
        data.pos = self.nodePosition
        self:__onDeserialized(data)
      end
    end
    if #sortedNames == 0 then
      im.BeginDisabled()
      im.Text("No nodes saved yet!")
      im.EndDisabled()
    end
    im.EndCombo()

  end

  local name = im.ArrayChar(256, self.name)
  im.PushItemWidth(im.GetContentRegionAvailWidth() - 24 * im.uiscale[0])
  editor.uiInputText("##name"..self.id, name, 256, nil, nil, nil, editEnded)
  if editEnded[0] then
    self.name = ffi.string(name)
    change = "Changed name for custom lua node to " ..self.name
  end
  im.SameLine()


  if editor.uiIconImageButton(editor.icons.save, im.ImVec2(20, 20), customNodes[self.name] and im.ImVec4(1,0.6,0.6,1)) then
    local data = self:__onSerialize()
    data.pos = nil
    dump(data)
    customNodes[self.name] = data
    editor.setPreference('flowgraph.general.customLuaNodes', customNodes)
  end
  ui_flowgraph_editor.tooltip(customNodes[self.name] and "OVERWRITE existing node in library" or "Save node to library")


  for _, code in ipairs(codeNames) do
    if self.status[code] == nil then
      self:compile(code)
    end
    if self.status[code] then
      editor.uiIconImage(editor.icons.error, im.ImVec2(20, 20), im.ImVec4(1,0,0,1))
      ui_flowgraph_editor.tooltip(self.status[code])
    else
      editor.uiIconImage(editor.icons.check, im.ImVec2(20, 20), im.ImVec4(0,1,0,1))
      ui_flowgraph_editor.tooltip("All good!")
    end
    im.SameLine()
    im.Text(code)
    ui_flowgraph_editor.tooltip(codeDescription[code])
    local buff = im.ArrayChar(bufLen, self.code[code] or "")
    if editor.uiInputTextMultiline("##"..code..self.id.."/"..self.mgr.id, buff, bufLen, im.ImVec2(im.GetContentRegionAvailWidth(),150), im.InputTextFlags_Multiline, nil, nil, editEnded) then
      self.code[code] = ffi.string(buff)
      self.status[code] = nil
      self:compile(code)
    end
    if editEnded[0] then
      self.code[code] = ffi.string(buff)
      self.status[code] = nil
      self:compile(code)
      change = 'Changed Code for ' .. code
    end
    im.Separator()
  end
  return change
end

function C:_executionStarted()
  for _, code in ipairs(codeNames) do
    self:compile(code)
  end
  self:exec('_executionStarted')
end
function C:_executionStopped()
  self:exec('_executionStopped')
  self.__env = nil
end
function C:onPreRender(dt, dtSim)
  self:exec('onPreRender')
end

function C:exec(code)
  if self.compiled[code] then
    local status, err, res = pcall(self.compiled[code], debug.traceback)
    if not status then
      log('E', 'Custom Lua Node: " .. code', tostring(err))
      self:__setNodeError('work', 'Error while executing custom lua: '..code..' ' .. tostring(err))
      self.mgr:logEvent("Node Error in " .. dumps(self.name),"E", 'Error while executing custom lua: '..code..' ' .. tostring(err), {type = "node", node = self})
    end
  end
end

function C:work()
  self:exec('work')
end

function C:_onDeserialized(data)
  self.name = deepcopy(data.name or self.name)
  self.code = deepcopy(data.code or self.code)
  for _, code in ipairs(codeNames) do
    self:compile(code)
  end
end

function C:_onSerialize(data)
  data.name = deepcopy(self.name)
  data.code = deepcopy(self.code)
end

function C:buildBaseEnv()
  if self.__env == nil then
    local env = {}
	
	-- BEAMLR EDIT START
	env.lvl_err = lvl_err
	env.lvl_warn = lvl_warn
	env.lvl_info = lvl_info
	env.blrlog = blrlog
	-- BEAMLR EDIT END


     -- include various libs and global vars
    env.self = self
    env.map = map
    env.be = be
    env.FS = FS
    env.path = path
    env.math = math
    env.pairs = pairs
    env.ipairs = ipairs
    env.string = string
    env.table = table
    env.debug = debug
    env.io = io
    env.os = os
    env.spawn = spawn
    env.translateLanguage = function(key, fallback, silent)
      return _tr(key, fallback)
    end
    env._tr = _tr

    env.scenetree = scenetree
    env.Engine = Engine
    env.guihooks = guihooks
    env.settings = settings
    env.debugDrawer = debugDrawer
    env.String = String
    env.ColorF = ColorF
    env.ColorI = ColorI
    env.QuatF = QuatF
    env.Point3F = vec3
    env.extensions = extensions
    env.vec3 = vec3
    env.createObject = createObject
    env.worldEditorCppApi = worldEditorCppApi
    env.rainbowColor = rainbowColor
    env.readJsonFile = jsonReadFile
    env.getPlayerVehicle = getPlayerVehicle
    env.RenderViewManagerInstance = RenderViewManagerInstance
    env.Frustum = Frustum
    env.newTemporalSmoothingNonLinear = newTemporalSmoothingNonLinear
    env.getObjectByID = getObjectByID

    -- env.extension = extensions
    -- add all non-virtual extensions from the global table to the env
    for _, extName in ipairs(extensions.getLoadedExtensionsNames(true) or {}) do
      env[extName] = _G[extName]
    end

    env.refreshExtensions = function()
      for _, extName in ipairs(extensions.getLoadedExtensionsNames(true) or {}) do
        env[extName] = _G[extName]
      end
    end
    env.loadExtension = function(...)
      extensions.load(...)
      for _, extName in ipairs(extensions.getLoadedExtensionsNames(true) or {}) do
        env[extName] = _G[extName]
      end
    end
    env.unloadExtension = function(...)
      extensions.unload(...)
      for _, extName in ipairs(extensions.getLoadedExtensionsNames(true) or {}) do
        env[extName] = _G[extName]
      end
    end

    -- various functions
    env.print = print
    env.dump = dump
    env.dumps = dumps
    env.dumpz = dumpz
    env.error = error
    env.tostring = tostring
    env.tonumber = tonumber
    env.require = require
    env.pcall = pcall
    env.type = type
    env.next = next
    env.dofile = dofile
    env.loadfile = loadfile
    env.load = load
    env.tableKeys = tableKeys
    env.tableFindKey = tableFindKey
    env.tableContains = tableContains
    env.shallowcopy = shallowcopy
    env.deepcopy = deepcopy
    env.readFile = readFile
    env.writeFile = writeFile
    env.serialize = serialize
    env.deserialize = deserialize

    -- json stuff
    env.jsonEncode = jsonEncode
    env.jsonEncodePretty = jsonEncodePretty
    env.jsonDecode = jsonDecode
    env.jsonWriteFile = jsonWriteFile
    env.jsonReadFile = jsonReadFile

    --also include a few of our own math functions
    env.clamp = clamp
    env.round = round
    env.sign = sign
    env.quatFromDir = quatFromDir
    env.smoothstep = smoothstep
    env.smootherstep = smootherstep
    env.smoothmin = smoothmin
    env.case = case
    env.sqrt = math.sqrt

    env.vec3 = vec3
    env.quat = quat
    env.euler = quatFromEuler
    env.quatFromEuler = quatFromEuler

    env.RectI = RectI
    env.Point2I = Point2I

    env.im = ui_imgui
    env.square = square
    env.lerp = lerp
    env.inverseLerp = function(min, max, value)
      if math.abs(max - min) < 1e-30 then return min end
      return (value - min) / (max - min)
    end

    env.log = function(type,origin,value)
      self.mgr:logEvent(value, type, value, {type = "node", node = self})
      log(type, origin, value)
    end

    env.tableConcat = function(dst, src)
      for i=1,#src do
        dst[#dst+1] = src[i]
      end
      return dst
    end

    self.__env = env
  end
  return self.__env
end

return _flowgraph_createNode(C)
