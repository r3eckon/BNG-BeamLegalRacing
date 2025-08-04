-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
-- BEAMLR EDITED FOR OPTIMIZED DRAW MODE

local im = ui_imgui

local gridSize = 14
local xOffGrid, yOffGrid = 10, 8
local behaviourOrder = { 'once', 'duration', 'simple', 'singleActive', 'obsolete' }
local C = {}
local emptyPin = {
  thisIsEmptyPin = true,

}

-- hardcoded order for specific pins: name,direction,position
local pinOrder = {
  { 'flow', 'in', 1 },
  { 'flow', 'out', 2 },
  { 'reset', 'in', 3 },
  { 'incomplete', 'out', 4 },
  { 'complete', 'out', 5 },
  { 'completed', 'out', 6 },
}

setmetatable(emptyPin, {
  __newindex = function(tbl, key, value)
    print("Tried to set value of empty pin! Not allowed.")
    print(debug.tracesimple())
  end

})

function C:init(mgr, graph, forceId)
  self.mgr = mgr
  self.graph = graph
  self.graphName = im.ArrayChar(256,'New subGraph')
  self.id = forceId or self.mgr:getNextFreeGraphNodeId()
  if mgr.__safeIds then
    if mgr:checkDuplicateId(self.id) then
      log("E","","Duplicate ID error! Node")
      print(debug.tracesimple())
    end
  end


  self.name = 'unknown'
  self.description = 'No Description!'
  self.color = ui_flowgraph_editor.nodeColors.default
  self.iconColor = im.ImVec4(1, 1, 1, 0.8)
  self.durationState = 'inactive'
  self.type = 'node'
  self.tags = { 'base' }
  self.behaviour = {}
  self.triggerCount = 0
  self.workCount = 0
  self.data = {}
  self.clearOutPinsOnStart = true
  self.defaultTableElementBufferSize = 16
  self.dynamicMode = 'repeat' -- 'repeat' is the default mode, 'once' is the single-mode
  self.durationStateChanged = false

  -- named pin
  self.pinIn = {} -- TODO: __index, __newindex
  self.pinOut = {} -- TODO: __index, __newindex

  self.alignmentPin = require('/lua/ge/extensions/flowgraph/pin')(self.graph, self)
  self.alignmentPin.name = "ALIGNMENT PIN DO NOT USE"

  setmetatable(self.pinIn, {
    __index = function(self, key) return emptyPin end,
    __newindex = function(self, key, value) log('E', self.mgr.logTag, 'cannot write to input pin: ' .. tostring(key)) print(debug.tracesimple()) end,
  })
  self.pinInLocal = {}
  self.pinList = {} -- for the pin order only
  self._flowColors = {}
  self._flowLevel = 0
  self._flowInDeps = {}
  self._mInFlow = {}
  self._mInFlowPins = {}
  self._frameLastUsed = -1
end

function C:getData()
  return self.data
end

function C:setData(data)
  self.data = data
end

function C:getPinIn()
  return self.pinIn
end

function C:setPinIn(data)
  self.pinIn = data
end

function C:destroy()
end

function C:_destroy()
  self:destroy()
end

function C:addedToGraph(graph)end
function C:representsGraph() return nil end
C.canHaveGraph = false

function C:_preInit()
  if self.pinSchema then
    for _, v in pairs(self.pinSchema) do
      local dir = v.dir
      if not dir then
        log("E","Node Creation","Old Pin Schema no longer supported.")
      else
        if dir == 'out' then
          if v.default then
            log("W","Node Creation","Default values for output pins not supported. (".. self.name .. " / " .. v.name .. " / " .. dumps(v.default) ..")")
          end
          local pin = self:createPin(dir, v.type, v.name, nil, v.description, nil, nil, v.fixed)
          pin.hidden = v.hidden or false
          pin.impulse = v.impulse or nil
          pin.chainFlow = v.chainFlow or nil
          pin.tableType = v.tableType
        end
      end
    end
  end
end

function C:_postInit()
  if self.pinSchema then
    for _, v in pairs(self.pinSchema) do
      local dir = v.dir
      if not dir then
        log("E","Node Creation","Old Pin Schema no longer supported.")
      else
        if dir ~= 'out' then
          local pin = self:createPin(dir, v.type, v.name, v.default, v.description, nil, nil, v.fixed)
          pin.hidden = v.hidden or false
          pin.tableType = v.tableType
          pin.defaultHardCodeType = v.defaultHardCodeType
          if v.hardcoded then
            self:_setHardcodedDummyInputPin(pin,v.default)
          end
          pin.impulse = v.impulse or nil
          pin.chainFlow = v.chainFlow or nil
        end
      end
    end
  end
  -- check dynamic mode pin requirements
  if self.dynamicMode == 'once' then
    -- do we have a pin named reset?
    if self.pinInLocal.reset == nil then
      -- create a reset pin directly under the flow pin, also warning/error
      log("E", "", "Node is dynamic once, but has no reset pin!")
      self:createResetPin()
    end
  end
  self:handleNodeCategories()
  self:postInit()
end

function C:handleNodeCategories()
  if not self.category then
    self.dynamicMode = 'repeat'
    return
  end
  -- check if category exists
  if self.category then
    -- check if functional
    if ui_flowgraph_editor.isFunctionalNode(self.category) then

      -- check if simple
      if ui_flowgraph_editor.isSimpleNode(self.category) then
        if self:hasFlowPins() then
          log("E", "", "Node " .. self.name .. " is simple, but has flow pins!")
        end
        if self.category == 'provider' and self:hasInputPins() then
          log("E", "", "Node " .. self.name .. " is provider, but has input pins!")
        end
        self:addBehaviour('simple')
      else
        self:autoCreatePin('in', 'flow', 'flow', nil, 'Inflow for this node.', nil, true)
        self:autoCreatePin('out', 'flow', 'flow', nil, 'Outflow for this node.', nil, true)

        -- check if duration
        if ui_flowgraph_editor.isDurationNode(self.category) then
          self:addBehaviour('duration')

          -- check if f_duration
          if ui_flowgraph_editor.isF_DurationNode(self.category) then
            self:autoCreatePin('out', 'flow', 'incomplete', nil, "Puts out flow, while this node's functionality is not completed.", nil, true)
            self:autoCreatePin('out', 'flow', 'complete', nil, "Puts out flow continuously, after the node's functionality is complete.", nil, true)
            local completedPin = self:autoCreatePin('out', 'flow', 'completed', nil, "Puts out flow once, after the node's functionality is completed.", nil, true)
            if completedPin then
              completedPin.impulse = true
            end
          end
        end
        -- check if once
        if ui_flowgraph_editor.isOnceNode(self.category) then
          local resetPin = self:autoCreatePin('in', 'flow', 'reset', nil, "Resets the node.", nil, true)
          self.dynamicMode = 'once'
          if resetPin then
            resetPin.impulse = true
          end
          self:addBehaviour('once')
        end
        -- check if dynamic
        if ui_flowgraph_editor.isDynamicNode(self.category) then
          if self.dynamicMode == 'once' then
            self:createResetPin()
            self:addBehaviour('once')
          else
            self:removeResetPin()
            self:removeBehaviour('once')
          end
        end
      end
    end
  end

  if self.obsolete then
    self:addBehaviour('obsolete')
  end
end

function C:addBehaviour(behaviour)
  if self.behaviour == nil then
    self.behaviour = {}
  end
  if self.behaviour[behaviour] ~= true then
    self.behaviour[behaviour] = true
  end
end

function C:removeBehaviour(behaviour)
  if self.behaviour == nil or not self.behaviour[behaviour] then
    return
  end
  self.behaviour[behaviour] = false
end

-- used for automatically created
function C:autoCreatePin(direction, type, name, default, description, extra, fixed)
  -- only creates pin, if no pin with same name exists yet
  if not (direction == 'in' and self.pinInLocal[name]) and not (direction == 'out' and self.pinOut[name]) then
    local pin = self:createPin(direction, type, name, default, description,nil , extra, fixed)

    if self.category and ui_flowgraph_editor.isFunctionalNode(self.category) then
      local pos = 1
      -- finds pos
      for i = 1, #self.pinList do
        if self.pinList[i] == pin then
          pos = i
          break
        end
      end

      -- sorts pins
      for _, p in pairs(pinOrder) do
        if p[1] == pin.name and p[2] == pin.direction then
          table.remove(self.pinList, pos)
          table.insert(self.pinList, p[3], pin)
        end
      end
    end

    return pin
  end
end

function C:hasFlowPins()
  if self.pinSchema then
    for _, v in pairs(self.pinSchema) do
      if v.type == 'flow' then
        return true
      end
    end
  end
  return false
end

function C:hasInputPins()
  if self.pinSchema then
    for _, v in pairs(self.pinSchema) do
      if v.dir == 'in' then
        return true
      end
    end
  end
  return false
end

function C:createResetPin()
  if not self.pinInLocal.reset then
    local pin = self:autoCreatePin("in", "flow", "reset", nil, "Resets this node.", nil, nil)
    pin.impulse = true
    self:addBehaviour('once')
  end

end
function C:removeResetPin()
  if self.pinInLocal.reset then
    self:removePin(self.pinInLocal.reset)
    self:removeBehaviour('once')
  end
end

function C:postInit()end

function C:work(args)end

local status, err, res
function C:_workDynamicRepeat()
  self._frameLastUsed = self.graph.mgr.frameCount
  status, err, res = xpcall(self.work, debug.traceback, self)
  self:checkAutomatedFlow()
  self.workCount = self.workCount + 1
  if not status then
    log('E', 'node.work', tostring(err))
    self:__setNodeError('work', 'Error while executing node:work(): ' .. tostring(err))
    self.mgr:logEvent("Node Error in " .. dumps(self.name), "E", 'Error while executing node:work(): ' .. tostring(err), { type = "node", node = self })
  end
  --self:work(args)
end

function C:onNodeReset()
end
function C:_onNodeReset()
  status, err, res = xpcall(self.onNodeReset, debug.traceback, self)
  if not status then
    log('E', 'node.onNodeReset', tostring(err))
    self:__setNodeError('onNodeReset', 'Error while executing node:onNodeReset(): ' .. tostring(err))
    self.mgr:logEvent("Node Error in " .. dumps(self.name), "E", 'Error while executing node:onNodeReset(): ' .. tostring(err), { type = "node", node = self })
  end

  for _, p in pairs(self.pinOut) do
    p.value = nil
  end
end

function C:workOnce()
end
function C:_workDynamicOnce()
  self._frameLastUsed = self.graph.mgr.frameCount

  -- check reset
  if self._dynamicDone and self.pinIn.reset.value then
    self:_onNodeReset()
    self._dynamicDone = false
  end

  if self.pinIn.flow.value then

    -- call workOnce, if not dynamicDone
    if not self._dynamicDone then
      status, err, res = xpcall(self.workOnce, debug.traceback, self)
      self.workCount = self.workCount + 1
      if not status then
        log('E', 'node.workOnce', tostring(err))
        self:__setNodeError('work', 'Error while executing node:workOnce(): ' .. tostring(err))
        self.mgr:logEvent("Node Error in " .. dumps(self.name), "E", 'Error while executing node:workOnce(): ' .. tostring(err), { type = "node", node = self })
      end
      self._dynamicDone = true
    end

    -- call work, if dynamicDone already
    if self._dynamicDone then
      status, err, res = xpcall(self.work, debug.traceback, self)
      self:checkAutomatedFlow()
      self.workCount = self.workCount + 1
      if not status then
        log('E', 'node.work', tostring(err))
        self:__setNodeError('work', 'Error while executing node:work(): ' .. tostring(err))
        self.mgr:logEvent("Node Error in " .. dumps(self.name), "E", 'Error while executing node:work(): ' .. tostring(err), { type = "node", node = self })
      end
    end
  end
  self.workCount = self.workCount + 1
end

function C:setDurationState(state)
  if not self.category or not ui_flowgraph_editor.isF_DurationNode(self.category) or self.durationState == state then
    return
  end
  self.durationState = state
  self.durationStateChanged = true
end

function C:checkAutomatedFlow()

  -- handle automatic flow out on all functional (non-simple) nodes
  if ui_flowgraph_editor.isFunctionalNode(self.category) and not ui_flowgraph_editor.isSimpleNode(self.category) then
    self.pinOut.flow.value = self.pinIn.flow.value
  end

  -- handles f_duration nodes output pins depending on state
  if ui_flowgraph_editor.isF_DurationNode(self.category) then

    -- turns off completed pin after 1 frame (for impulse)
    if self.pinOut.completed.value then
      self.pinOut.completed.value = false
    end

    -- checks for durationState change
    if self.durationStateChanged then
      self.durationStateChanged = false
      if self.durationState == 'inactive' then
        self.pinOut.incomplete.value = false
        self.pinOut.complete.value = false
        self.pinOut.completed.value = false
        self:onDurationInactive()
      elseif self.durationState == 'started' then
        self.pinOut.incomplete.value = true
        self.pinOut.complete.value = false
        self.pinOut.completed.value = false
        self:onDurationStarted()
      elseif self.durationState == 'finished' then
        self.pinOut.incomplete.value = false
        self.pinOut.complete.value = true
        self.pinOut.completed.value = true
        self:onDurationFinished()
      end
    end
  end
end

function C:onDurationInactive()
end
function C:onDurationStarted()
end
function C:onDurationFinished()
end

function C:toggleDynamicMode()
  if not ui_flowgraph_editor.isDynamicNode(self.category) then
    return
  end
  if self.dynamicMode == 'once' then
    self:setDynamicMode('repeat')
  else
    self:setDynamicMode('once')
  end
end

function C:setDynamicMode(mode)
  if self.dynamicMode == mode then return end
  self.dynamicMode = mode
  if mode == 'once' then
    self:createResetPin()
  end
  if mode == 'repeat' then
    self:removeResetPin()
  end
end

local _createPin = require('/lua/ge/extensions/flowgraph/pin')
function C:createPin(direction, type, name, default, description, autoNumber, extra, fixed)
  if not name or name == '' then
    log('E', self.mgr.logTag, 'Empty pin name not allowed')
    return
  end
  if (direction == 'in' and self.pinInLocal[name]) or (direction == 'out' and self.pinOut[name]) then
    if autoNumber then
      local x = 1
      local newName
      local successful = false
      for i = 1, 100 do
        x = x + 1
        newName = name .. x
        if (direction == 'in' and not self.pinInLocal[newName]) or (direction == 'out' and not self.pinOut[newName]) then
          name = newName
          successful = true
          break
        end
      end
      if not successful then
        log('E', self.mgr.logTag, 'Duplicate pin names not allowed: ' .. tostring(name))
        return
      end
    else
      log('E', self.mgr.logTag, 'Duplicate pin names not allowed: ' .. tostring(name))
      return
    end
  end
  local pin = _createPin(self.graph, self, direction, type, name, default, description)
  pin.extraData = extra
  pin.fixed = fixed
  self[direction == 'in' and 'pinInLocal' or 'pinOut'][pin.name] = pin
  table.insert(self.pinList, pin)
  self.graph.pins[pin.id] = pin
  return pin
end

-- TODO: care about links, some other stuff i might have missed?
function C:removePin(pin)
  if not pin then return end
  -- remove links
  for _, lnk in pairs(self.graph.links) do
    if lnk.sourcePin == pin or lnk.targetPin == pin then
      self.graph:deleteLink(lnk)
    end
  end

  if pin.direction == 'in' then
    self.pinInLocal[pin.name] = nil
    rawset(self.pinIn,pin.name, nil)
  else
    self.pinOut[pin.name] = nil
  end
  self.graph.pins[pin.id] = nil

  for i=1,#self.pinList do
    if self.pinList[i].id == pin.id then
      table.remove(self.pinList, i)
      break
    end
  end
end

function C:renamePin(pin, newName)
  if self.pinInLocal[newName] ~= nil then
    if self.pinInLocal[newName].id ~= pin.id then
      log('W', 'baseNode', 'Pin rename failed - renaming pin '..tostring(pin.name) ..' to '..tostring(newName)..'. Pin Name: '..tostring(newName).. ' is already used!')
    end
    return
  end
  self.pinInLocal[pin.name] = nil
  pin.name = newName
  self.pinInLocal[newName] = pin
end

function C:shiftPin(idInList, direction)
  local newIndex = ((idInList + direction-1)% #self.pinList) +1
  log("D","","Shifting Pin: "..idInList .. " -> " .. newIndex)
  local a = self.pinList[idInList]
  local b = self.pinList[newIndex]
  self.pinList[idInList] = b
  self.pinList[newIndex] = a
end

function C:trigger()
  if self.mgr.runningState == "stopped" then
    return
  end
  self.triggerCount = self.triggerCount +1
  if self._trigger then
    self:_trigger()
  else
    print('empty trigger! ('..self.nodeType.. " - " .. self.id .. ")")
  end
  self._frameLastUsed = self.mgr.frameCount
end

function C:isFlowActive()
  for i = 1, #self._flowInDeps do
    if self._flowInDeps[i].value then
      return true
    end
  end
  return true
end

function C:showProperties() end
function C:hideProperties() end

function C:_doubleClicked()
  --print(self.id .. ' ' .. self.name .. ' double-clicked')
  if self.doubleClicked and type(self.doubleClicked) == 'function' then
    self:doubleClicked()
  end
end

function C:onLink(link)
end

function C:_onLink(link)
  self:onLink(link)
end

function C:onUnlink(link)
end

function C:_onUnlink(link)
  self:onUnlink(link)
end

function C:onSetHardcode(pin, value, forceType)
end

function C:_onSetHardcode(pin, value, forceType)
  self:onSetHardcode(pin, value, forceType)
end

function C:onUnsetHardcode(pin)
end

function C:_onUnsetHardcode(pin)
  self:onUnsetHardcode(pin)
end

function C:_onClear()
 --self:_executionStopped()
end

function C:_executionStopped()
end
function C:__executionStopped()
  self:_executionStopped()
  self._dynamicDone = false
  --self._trigger = nop
end
function C:_executionStarted()
end
function C:__executionStarted()
  self:__setNodeError(nil, nil)
  if self.clearOutPinsOnStart then
    for _, p in pairs(self.pinOut) do
      p.value = nil
    end
  end
  self._frameLastUsed = -1
  self._dynamicDone = false
  self:_executionStarted()
end

function C:getLinks()
  local sources = {}
  local targets = {}
  for lid, link in pairs(self.graph.links) do
    if link.sourceNode.id == self.id then
      table.insert(sources, link)
    elseif link.targetNode.id == self.id then
      table.insert(targets, link)
    end
  end
  return targets, sources
end

function C:HSVtoRGB(h,s,v)
  h = h - math.floor(h)
  return {HSVtoRGB(math.max(0, math.min(1, h)), math.max(0, math.min(1, s)), math.max(0, math.min(1, v)))}
end

local vec20x20 = im.ImVec2(22,22)
function C:drawHeader(builder, style)
  local icon = self.customIcon or self.icon
  local displayedName = self.customName or self.name
  local iconWidth = icon and 24 or 0
  if self.customName then
    displayedName = "["..displayedName.."]"
  end
  local headerColor = self.customColor or self.color
  if self._error then
    headerColor = im.ImVec4(1,0,0,1)
    displayedName = "[[ERROR]]" .. displayedName
  end
  if self.obsolete then
    headerColor = im.ImVec4(0,0,0,0.25)
  end
  if editor.getPreference("flowgraph.debug.displayIds") then
    displayedName = displayedName.." ["..self.id.."]"
  end
  local drawType = editor.getPreference("flowgraph.debug.viewMode")
  if self.type == 'simple' and self.__error == nil then
    return
  end
  if drawType == 'heatmap' then
    if self.mgr.runningState ~= 'stopped' then
      local oldness = math.min(( self.mgr.frameCount- self._frameLastUsed )/100, 5)
      if self._frameLastUsed == -1 then
        self._lastHeatmapColor = im.ImVec4(0.2,0.2,0.2, 1)
      else
        local c = self:HSVtoRGB(math.max(0.3-oldness*0.15,-0.3), math.min(1, 2/(( self.mgr.frameCount- self._frameLastUsed )/100+1)), 1)
        self._lastHeatmapColor = im.ImVec4(c[1],c[2],c[3],0.9)
      end

    end
    headerColor = self._lastHeatmapColor or im.ImVec4(0.2,0.2,0.2, 1)

  end
  builder:Header(headerColor)
  im.Dummy(im.ImVec2(1, 1))
  im.SameLine()
  if icon and editor.icons[icon] then
    editor.uiIconImage(editor.icons[icon], vec20x20, self.customIconColor or self.iconColor)
    im.SameLine()
  end
  im.TextUnformatted(displayedName)
  im.SameLine()
  im.Dummy(im.ImVec2(0, 28))

  if editor.getPreference("flowgraph.general.showNodeBehaviours") then
    for k, v in pairs(self.behaviour) do iconWidth = iconWidth + 24 end
  end

  builder:setExpectedHeaderSize(im.CalcTextSize(displayedName).x + 6 +iconWidth)

  builder:EndHeader()
end


function C:drawTooltip()
  if editor_flowgraphEditor.allowTooltip then

    -- modify style before opening
    im.PushStyleVar2(im.StyleVar_WindowPadding, im.ImVec2(5, 5))
    im.PushStyleColor2(im.Col_Separator, im.ImVec4(1.0, 1.0, 1.0, 0.175))
    if self.mgr.runningState ~= "running" then
      im.PushStyleColor2(im.Col_Border, im.ImVec4(1.0, 1.0, 1.0, 0.25))
    end
    im.BeginTooltip()
    im.PushTextWrapPos(200 * editor.getPreference("ui.general.scale"))
    if editor.getPreference("flowgraph.debug.viewMode") == 'heatmap' then
      editor.uiIconImage(editor.icons.timer, vec20x20)
      im.SameLine()
      if self._frameLastUsed ~= -1 then
        local dist = self.mgr.frameCount - self._frameLastUsed
        if dist == 0 then
          im.Text("Currently Active!")
        else
          im.Text(string.format("Last Activity: %d Frames ago.", dist))
        end
      else
        im.Text("No Activity yet.")
      end
      im.Separator()
    end

    -- Add icon and name
    local icon = self.customIcon or self.icon
    if icon then
      editor.uiIconImage(editor.icons[icon], im.ImVec2(22, 22))
      im.SameLine()
    end
    im.TextUnformatted(self.name)

    -- Check custom name
    if self.customName then
      im.Separator()
      im.TextUnformatted('Custom Name:')
      im.TextUnformatted(self.customName)
    end

    -- Add behaviours
    im.Separator()
    for _, b in ipairs(behaviourOrder) do
      if self.behaviour[b] then
        editor.uiIconImage(editor.icons[ui_flowgraph_editor.getBehaviourIcon(b)], im.ImVec2(22, 22))
        im.SameLine()
        im.Text(ui_flowgraph_editor.getBehaviourDescription(b))
      end
    end
    if self.behaviour and next(self.behaviour) ~= nil then
      im.Separator()
    end

    if self.obsolete then
      im.TextUnformatted("OBSOLETE: " .. tostring(self.obsolete))
    end
    -- now the description
    if self.description and self.description ~= "" then
      im.TextUnformatted(tostring(self.description))
    elseif self.nodeType == "macro/integrated" and self.targetGraph.description then
      im.TextUnformatted(self.targetGraph.description)
    --else
    --  im.Text('No description')
    end
    if self.todo then
      im.TextUnformatted("TODO: " .. tostring(self.todo))
    end

    if self._error then
      im.TextUnformatted('Errors:')
      for k, v in pairs(self._error) do
        im.TextUnformatted(v)
      end
    end

    --im.TextUnformatted('PIN ID: ' .. tostring(self.id))
    im.PopTextWrapPos()
    im.EndTooltip()

    -- pop style changes
    if self.mgr.runningState ~= "running" then
      im.PopStyleColor()
    end
    im.PopStyleColor()
    im.PopStyleVar()
  end
end

function C:overDraw()
  local icon = self.customIcon or self.icon
  if icon then
    local off = im.GetWindowPos()
    local pos = self.overDrawSize.top_left()
    local size = im.ImVec2(self.overDrawSize.w, self.overDrawSize.h)
    local pad = im.ImVec2(size.x/2, size.y/2)
    if size.x > size.y then size.x = size.y end
    if size.y > size.x then size.y = size.x end
    size.x = size.x * 0.75
    size.y = size.y * 0.75
    pad = im.ImVec2(pad.x - size.x/2, pad.y - size.y/2)

    im.SetCursorPos(im.ImVec2(-off.x + pos.x + pad.x, -off.y + pos.y + pad.y))
    local fgClr = self.customIconColor or self.iconColor
    fgClr = im.ImVec4(fgClr.x, fgClr.y, fgClr.z, fgClr.w * 0.25)
    local bgClr = self.customColor or self.color
    im.Text("ASDF")
    bgClr = im.ImVec4(bgClr.x*0.4, bgClr.y*0.4, bgClr.z*0.4, 1)
    im.ImDrawList_AddRectFilled(im.GetWindowDrawList(), self.overDrawSize.top_left(), self.overDrawSize.bottom_right(), im.GetColorU322(bgClr),8)
    editor.uiIconImage(editor.icons[icon], size, fgClr)
  end
end

function C:_drawMiddle(builder, style, drawType)
  if drawType == 'flowLevel' then
    builder:Middle()
    im.TextUnformatted(tostring(self._flowLevel))
  elseif drawType == 'simple' then
    builder:Middle()
    --im.TextUnformatted(self.name)
    local icon = self.customIcon or self.icon or "help"
    local fgClr = self.customIconColor or self.iconColor
    im.Dummy(im.ImVec2(math.max(1,builder.expectedHeaderWidth/2-64),0))
    im.SameLine()
    editor.uiIconImage(editor.icons[icon], im.ImVec2(64,64), fgClr)
  elseif drawType == 'debug' then
    builder:Middle()
    im.TextUnformatted(self.id .. " : " .. self.name)

    im.TextUnformatted("_trigger: " .. (self._trigger == nop and "nop" or "[func]") )
    --if self._trigger and self._triggerCode then
      if im.Button("Log trigger code") then
        print("Trigger Code for " .. self.id .. " : " ..self.name .. " is:")
        print(self._triggerCode)
      end
    --end
    im.TextUnformatted("Triggered: " .. self.triggerCount)
    --im.TextUnformatted("_work: " .. (self._work == nop and "nop" or "[func]") )
    im.TextUnformatted("Worked: " .. self.workCount)
    if im.Button("Colors") then
      dumpz(self._flowColors,2)
    end

  elseif drawType == 'default' or drawType == 'heatmap' then
    if not self.drawMiddle then
      if self.type == 'simple' or self.type == 'variable' then
        builder:Middle()
        im.TextUnformatted(self.name)
      end
    else
      self:drawMiddle(builder, style, drawType)
    end
  elseif drawType == 'geometry' then
    if not self.drawMiddle then
      if self.type == 'simple' or self.type == 'variable' then
        builder:Middle()
        im.TextUnformatted(self.name)
      end
    else
      self:drawMiddle(builder, style, drawType)
    end

  end

  --[[
  builder:Middle()
  for k, pin in pairs(self.pinIn) do
    im.TextUnformatted('> ' .. k .. '[' .. pin.type .. ']')
  end
  for k, pin in pairs(self.pinInLocal) do
    im.TextUnformatted('L> ' .. k .. '[' .. pin.type .. ']')
  end
  for k, pin in pairs(self.pinOut) do
    im.TextUnformatted(k .. '[' .. pin.type .. '] >')
  end
  --]]
end
function C:drawMiddle(builder, style)
  builder:Middle()
end

-- BEAMLR EDIT: PASSED DRAWTYPE FROM MAIN FLOWGRAPH SCRIPT 
-- TO TRICK DEFAULT DRAW TYPE IN OPTIMIZED MODE
function C:draw(builder, style, dType)
  local mgr = self.graph.mgr
  local isSimple = (self.type == 'simple')
  if self.type ~= 'node' and self.type ~= 'simple' and self.type ~= 'variable' then
    return
  end

  local drawType = dType or editor.getPreference("flowgraph.debug.viewMode")
  builder.drawDebug = drawType == 'geometry'
  if ui_flowgraph_editor.GetHotObjectId() == self.id then
    ui_flowgraph_editor.Suspend()
    self:drawTooltip()
    ui_flowgraph_editor.Resume()
  end

  local triggered = (self.mgr.runningState == "running") and (self._frameLastUsed > mgr.frameCount - 10)

  if self._error then
    -- this node has errors
    ui_flowgraph_editor.PushStyleColor(ui_flowgraph_editor.StyleColor_NodeBg, im.ImVec4(1, 0, 0, 0.5))
    ui_flowgraph_editor.PushStyleColor(ui_flowgraph_editor.StyleColor_NodeBorder, im.ImVec4(0.5, 0, 0, 0))
  else
    if triggered then
      ui_flowgraph_editor.PushStyleColor(ui_flowgraph_editor.StyleColor_NodeBorder, im.ImVec4(1, 0.5, 0, 1))
    end
  end

  local bgClr = self.customColor or self.color
  local bgStrength, bgOff  = 0.03, 0.09
  if drawType == 'simple' then
    bgStrength, bgOff  = 0.15, 0.01
  end
  bgClr = im.ImVec4(bgOff+bgClr.x*bgStrength,bgOff+ bgClr.y*bgStrength, bgOff+bgClr.z*bgStrength, 0.95)
  ui_flowgraph_editor.PushStyleColor(ui_flowgraph_editor.StyleColor_NodeBg, bgClr)
  builder:Begin(self.id)

  -- figure out if the node has any active pins at all
  local hasActivePins = false
  for _, pin in pairs(self.pinList) do
    if pin:isActive() then
      hasActivePins = true
      break
    end
  end

  if not hasActivePins then
    im.PushStyleVar1(im.StyleVar_Alpha, style.Alpha * 0.2)
  end


  self:drawHeader(builder, style)


  local outPinWidth = 0
  local inPinWidth = 0
  local hiddenCount = 0
  for _, pin in pairs(self.pinList) do
    local show = not pin.hidden
    if show then
      if editor.getPreference("flowgraph.general.hideUnusedPinsWhenRunning") and self.mgr.runningState ~= "stopped" then
        show = pin:isUsed()
      end
      if show then
        if pin.direction == 'out' and (isSimple or pin.type ~= 'delegate') then
          outPinWidth = math.max(outPinWidth, pin:_getCalculatedWidth(pin._hardcodedDummyPin))
        elseif pin.direction == 'in' then
          inPinWidth = math.max(inPinWidth, pin:_getCalculatedWidth(pin._hardcodedDummyPin))
        end
      end
    end
  end
  -- inputs
  local inCount = 0
  for _, pin in pairs(self.pinList) do
    if pin.direction == 'in' then
      local show = not pin.hidden
      if show then
        if editor.getPreference("flowgraph.general.hideUnusedPinsWhenRunning") and self.mgr.runningState ~= "stopped" then
          show = pin:isUsed()
        end
        if show then
          im.SetCursorPosY(im.GetCursorPosY()+1)
          pin:draw(builder, style, nil, self:getPinInConstValue(pin.name), inPinWidth)
          --im.NewLine()
          inCount = inCount +1
        end
      else
        hiddenCount = hiddenCount+1
      end
    end
  end
  if hiddenCount > 0 and editor.getPreference("flowgraph.general.showHiddenPinCount") then
    im.BeginDisabled()
    im.Text(string.format(" (+%d)",hiddenCount))
    --ui_flowgraph_editor.tooltip(hiddenCount .. " hidden pins")
    im.EndDisabled()
  end
  if inCount == 0 then
    builder:expectOutPinWidth(5)
    im.SetCursorPosY(im.GetCursorPosY()+1)
    --builder:SetStage('input')
    builder:makeAlignmentPin(self.alignmentPin)
    --im.Dummy(im.ImVec2(5,5))
  end


  --self:drawMiddle(builder, style)
  local status, err, res = xpcall(self._drawMiddle, debug.traceback, self, builder, style, drawType)
  if not status then
    log('E', 'node.'..tostring('_drawMiddle'), tostring(err))
    self:__setNodeError('work', 'Error while executing node:_drawMiddle(): ' .. tostring(err))
  end

  --for parentNode, _ in pairs(self._flowColors) do
  --  im.TextUnformatted(tostring(parentNode.id))
  --end

  hiddenCount = 0
  builder:expectOutPinWidth(outPinWidth)
  -- outputs
  for _, pin in pairs(self.pinList) do
    if pin.direction == 'out' and (isSimple or pin.type ~= 'delegate')  then
      local show = not pin.hidden
      if show then
        if editor.getPreference("flowgraph.general.hideUnusedPinsWhenRunning") and self.mgr.runningState ~= "stopped"  then
          show = pin:isUsed()
        end
        if show then
          im.SetCursorPosY(im.GetCursorPosY()+1)
          pin:draw(builder, style, nil, pin._hardcodedDummyPin, outPinWidth)
        end
      end
      if not show then
        hiddenCount = hiddenCount+1
      end
    end
  end
  if hiddenCount > 0 and editor.getPreference("flowgraph.general.showHiddenPinCount") then
    im.BeginDisabled()
    local txt = string.format("(+%d)",hiddenCount)
    local xOff = outPinWidth - im.CalcTextSize(txt).x - 3
    im.Dummy(im.ImVec2(xOff, 1)) im.SameLine()
    im.Text(txt)
    --ui_flowgraph_editor.tooltip(hiddenCount .. " hidden pins")
    im.EndDisabled()
  end
  if outPinWidth then
    -- dummy area for pins
    builder:expectOutPinWidth(5)
    builder:SetStage('output')
    im.Dummy(im.ImVec2(5,0))
  end


  builder:End(self)
  -- patch in behavior icons
  if editor.getPreference("flowgraph.general.showNodeBehaviours") and self.type ~= 'simple' then
    local iconCount = 0
    local off = im.GetWindowPos()
    for _, b in ipairs(behaviourOrder) do
      if self.behaviour[b] then
        im.SetCursorPos(im.ImVec2(-off.x + builder.NodeRect.x + builder.NodeRect.w - 24 * iconCount - 24, -off.y + builder.NodeRect.y))
        editor.uiIconImage(editor.icons[ui_flowgraph_editor.getBehaviourIcon(b)], im.ImVec2(22, 22), im.ImVec4(1, 1, 1, 0.25))
        iconCount = iconCount + 1
      end
    end
  end

  ui_flowgraph_editor.PopStyleColor(1)
  if not hasActivePins then
    im.PopStyleVar(1)
  end
  ui_flowgraph_editor.Suspend()
  for _, pin in pairs(self.pinList) do
    pin:hoverDraw(self.mgr)
  end
  ui_flowgraph_editor.Resume()
  self.overDrawSize = builder.ContentRect
  self.overDrawSize.x = self.overDrawSize.x - 3
  self.overDrawSize.w = self.overDrawSize.w + 6
  self.overDrawSize.h = self.overDrawSize.h + 18
  self.overDrawSize.y = self.overDrawSize.y - 12
  --self:overDraw()
  if self._error then
    ui_flowgraph_editor.PopStyleColor(2)
  else
    if triggered then
      ui_flowgraph_editor.PopStyleColor(1)
    end
  end
end



function C:getPinInConstValue(pinName)
  local constValue = nil
  if self.pinIn[pinName] then
    if self.pinIn[pinName]._hardcodedDummyPin then
      constValue = self.pinIn[pinName].value
    end
  end
  return constValue
end

function C:customContextMenu() end
function C:showContextMenu(menuPos)

  im.SetWindowFontScale(editor.getPreference("ui.general.scale"))
-- im.BeginChild1("ncm##"..self.id, im.ImVec2(150*editor.getPreference("ui.general.scale"), entries * im.GetTextLineHeightWithSpacing() * editor.getPreference("ui.general.scale")))

  local y = im.GetCursorPosY()
  self:customContextMenu()
  if y ~= im.GetCursorPosY() then im.Separator() end


  if self.mgr.allowEditing then
    if im.MenuItem1("Copy") then
      self.mgr:copyNodes()
    end
    if im.MenuItem1("Delete") then
      self.mgr:deleteSelection()
      editor_flowgraphEditor.addHistory("Deleted nodes")
    end

    if im.MenuItem1("Show all pins", nil, false, true) then
      for _, pin in ipairs(self.pinList) do
        pin.hidden = false
      end
    end

    if im.MenuItem1("Hide unused pins", nil, false, true) then
      for _, pin in ipairs(self.pinList) do
        pin.hidden = pin.hidden or not pin:isUsed()
      end
    end
    im.Separator()
    if self.graphType == "instance" then
      if im.MenuItem1('Revert to Subgraph') then
        self.mgr:createSubgraphFromMacroInstance()
        editor_flowgraphEditor.addHistory("Reverted instance back to subgraph")
        im.CloseCurrentPopup()
      end
    end
    if im.BeginMenu('Create Subgraph...') then
      im.SetWindowFontScale(1/editor.getPreference("ui.general.scale"))
      im.PushItemWidth(150 * editor.getPreference("ui.general.scale"))
      local accept = false
      accept = im.InputText('',self.graphName,128, im.InputTextFlags_EnterReturnsTrue)
      if accept or im.Button("Create", im.ImVec2(im.GetContentRegionAvailWidth(), 0)) then

        --self.graph.subGraphName = ffi.string(self.graphName)
        self.mgr:createSubgraphFromSelection(false)
        editor_flowgraphEditor.addHistory("Created subgraph " ..  ffi.string(self.graphName))
        im.CloseCurrentPopup()
        self.graphName = im.ArrayChar(256,"New Subgraph")
      end
      im.PopItemWidth()
      im.SetWindowFontScale(1)
      im.EndMenu()
    end
    if self:representsGraph() and self.mgr.selectedNodeCount == 1 and self.graph.isStateGraph == self:representsGraph().isStateGraph then
      if im.MenuItem1("Ungroup") then
        self.mgr.groupHelper:ungroupSelection()
      end
    end
    if im.BeginMenu('Comment...') then
      im.SetWindowFontScale(1/editor.getPreference("ui.general.scale"))
      im.PushItemWidth(150 * editor.getPreference("ui.general.scale"))
      local accept = false
      if self._commentInput == nil then self._commentInput = im.ArrayChar(256, "") end
      accept = im.InputText('',self._commentInput,128, im.InputTextFlags_EnterReturnsTrue)
      accept = accept or im.Button("Create", im.ImVec2(im.GetContentRegionAvailWidth(), 0))
      im.PushStyleVar2(im.StyleVar_ItemSpacing, im.ImVec2(0,0))
      local clr = nil
      for i = 1, 10 do
        local c = rainbowColor(10,11-i,1)
        im.PushStyleColor2(im.Col_Button, im.ImVec4(c[1],c[2],c[3],0.5))
        im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(c[1],c[2],c[3],0.9))
        im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(c[1],c[2],c[3],0.8))
        if im.Button("##"..i.."clr", im.ImVec2(15*editor.getPreference("ui.general.scale"), 15* editor.getPreference("ui.general.scale"))) then
          accept = true
          clr = i
        end
        im.PopStyleColor(3)
        if i < 10 then
          im.SameLine()
        end
      end
      im.PopStyleVar()
      if accept then
        local selectedNodes = {}
        for id, _ in pairs(self.mgr.selectedNodes) do
          table.insert(selectedNodes, self.graph.nodes[id])
        end
        local rect, center = self.mgr.groupHelper:getRectCenter(selectedNodes)
        local comment = self.graph:createNode('debug/comment')
        local pad = 40
        comment.nodePosition = {rect[1]-pad,rect[2]-1.5*pad}
        comment:updateEditorPosition()
        comment.commentTitle = ffi.string(self._commentInput)
        if comment.commentTitle == "" then comment.commentTitle = "Comment" end
        comment.commentSize = im.ImVec2(rect[3]-rect[1]+1.6*pad, rect[4]-rect[2]+1.5*pad)
        if clr then
          local c = rainbowColor(10,11-clr,1)
          comment.backgroundColor[0] = im.Float(0.125+c[1]*0.75)
          comment.backgroundColor[1] = im.Float(0.125+c[2]*0.75)
          comment.backgroundColor[2] = im.Float(0.125+c[3]*0.75)
          comment.borderColor[0] = im.Float(0.75+c[1]*0.25)
          comment.borderColor[1] = im.Float(0.75+c[2]*0.25)
          comment.borderColor[2] = im.Float(0.75+c[3]*0.25)
          comment:refreshColors()
        end
        self.mgr:unselectAll()
        ui_flowgraph_editor.SelectNode(comment.id, false)
        --e.meta.node.graph.focusSelection = true
        --e.meta.node.graph.focusDelay = 1
        im.CloseCurrentPopup()
        self._commentInput = nil
      end
      im.PopItemWidth()
      im.SetWindowFontScale(1)
      im.EndMenu()
    end

  end
  if editor.getPreference("flowgraph.debug.editorDebug") then
    --im.Separator()
    if im.BeginMenu('Dev tools') then
      im.SetWindowFontScale(1/editor.getPreference("ui.general.scale"))
      if im.MenuItem1("Open Source File") then
        Engine.Platform.openFile(self.sourcePath)
      end
      if im.MenuItem1("Show File Location") then
        Engine.Platform.exploreFolder(self.sourcePath)
      end
      if im.MenuItem1("Show References") then
        editor_flowgraphEditor.showNodeReferences(self)
      end
      if im.BeginMenu('Dumpz Node') then
        im.SetWindowFontScale(editor.getPreference("ui.general.scale"))
        for i = 1, 5 do
          if im.MenuItem1("Depth " .. i) then
            dumpz(self, i)
          end
        end
        im.SetWindowFontScale(1)
        im.EndMenu()
      end
      im.SetWindowFontScale(1)
      im.EndMenu()
    end
    if not self.mgr.allowEditing then
      im.Separator()
      im.Text("Triggered: " .. tonumber(self.triggerCount))
      im.Text("Worked: " .. tonumber(self.workCount))
    end
  end
  if editor.getPreference("flowgraph.debug.displayIds") then
    im.Text("id: %s", tostring(self.id))
  end
  if editor.getPreference("flowgraph.debug.editorDebug") then
    im.Text("Type: %s", self.type)
    im.Text("File: %s", self.nodeType..'.lua')
    if self.nodePosition then
      im.Text(string.format("Pos: %d / %d  | %0.1f / %0.1f", self.nodePosition[1] , self.nodePosition[2], (self.nodePosition[1]-xOffGrid)/gridSize, (self.nodePosition[2]-yOffGrid)/gridSize ))
    end
    local nSize = ui_flowgraph_editor.GetNodeSize(self.id)
    im.Text(string.format("Size: %d / %d", nSize.x, nSize.y))

  end
  im.SetWindowFontScale(1)
end

function C:_setHardcodedDummyInputPin(pin, val, forceType)
  if val ~= nil then
    local t = forceType or pin.type
    if type(t) == 'table' then
      t = pin.defaultHardCodeType or t[1]
    end
    if t == 'any' then
      t = pin.defaultHardCodeType or 'number'
    end
    pin.pinMode = 'hardcoded'
    rawset(self.pinIn, pin.name, {
      _hardcodedDummyPin = true,
      direction = pin.direction,
      hardCodeType = t,
      name = pin.name,
      value = val,
    })
    if self._cdata then
      self._cdata = nil
    end
    self:_onSetHardcode(pin, val, forceType)
    return t
  else
    pin.pinMode = 'normal'
    rawset(self.pinIn, pin.name, nil)
    if self._cdata then
      self._cdata = nil
    end
    self:_onUnsetHardcode(pin)
  end
end

function C:_setupTimeline(beginTime, endTime)
  self.timeline = {
    beginTime = beginTime,
    endTime = endTime,
    lane = 0
  }
  if not self.onTimelineBegin then self.onTimelineBegin = nop end
  if not self.onTimelineEnd then self.onTimelineEnd = nop end
  if not self.onTimelineTrigger then self.onTimelineTrigger = nop end

end

function C:_onSerialize(res)
end

function C:__onSerialize()
  local res = {}
  res.data = {}
  res.customName = self.customName or nil
  res.customColor = self.customColor and {self.customColor.x, self.customColor.y, self.customColor.z, self.customColor.w} or nil
  res.customIcon = self.customIcon or  nil
  res.customIconColor = self.customIconColor and { self.customIconColor.x, self.customIconColor.y, self.customIconColor.z, self.customIconColor.w } or nil
  res.dynamicMode = self.dynamicMode
  -- serialize data/values
  if self.data.identifier and self.data.identifier ~= '' then
    res.identifier = self.data.identifier
  end

  for k, v in pairs(self.data) do

    -- cdata
    if type(v) == 'cdata' then

    -- lua type
    else
      res.data[k] = v
    end
  end
  res.type = self.nodeType
  -- Todo: node state e.g. variable names etc.
  --self:updateNodePosition()
  local pos =  self.nodePosition--ui_flowgraph_editor.GetNodePosition(self.id)
  res.pos = pos
  if self.savePins then
    res.pins = {}
    for _, pin in ipairs(self.pinList) do
      table.insert(res.pins, {pin.direction, pin.type, pin.name, pin.default or nil, pin.description, pin.fixed, pin.tableType or nil})
    end
  end

  for _, pin in pairs(self.pinIn) do
    if pin._hardcodedDummyPin then
      if not res.hardcodedPins then res.hardcodedPins = {} end
      res.hardcodedPins[pin.name] = {value = pin.value, type = pin.hardCodeType}
    end
  end
  for _, pin in pairs(self.pinList) do
    if pin.quickAccess then
      if not res.quickAccess then res.quickAccess = {p_in = {}, p_out = {}} end
      res.quickAccess['p_'..pin.direction][pin.name] = pin.accessName
    end
    if pin.hidden ~= nil then
      if not res.hiddenPins then res.hiddenPins = {p_in = {}, p_out = {}} end
      res.hiddenPins['p_'..pin.direction][pin.name] = pin.hidden
    end
  end
  res.timeline = self.timeline

  self:_onSerialize(res)
  return res
end

function C:updateNodePosition()
  if ui_flowgraph_editor.GetCurrentEditor() ~= nil then
    local pos = ui_flowgraph_editor.GetNodePosition(self.id)
    -- sanity check since GetNodePosition sometimes gives whacky results?
    if pos.x > -2e8 and pos.y > -2e8 and pos.x < 2e8 and pos.y < 2e8 then
      self.nodePosition = {pos.x, pos.y}
    end
  end
end

-- updating the node position should only happen when you open the manager in the editor.
function C:updateEditorPosition()
  if self.nodePosition and (ui_flowgraph_editor.GetCurrentEditor() ~= nil) then
    if    self.nodePosition[1] > -2e8 and self.nodePosition[2] > -2e8
      and self.nodePosition[1] <  2e8 and self.nodePosition[2] <  2e8 then
      ui_flowgraph_editor.SetNodePosition(self.id, im.ImVec2(self.nodePosition[1], self.nodePosition[2]))
    end
  end
end




function C:_onDeserialized(nodeData)
end

function C:__onDeserialized(nodeData)
  if nodeData.pos then
    self.nodePosition = { nodeData.pos[1], nodeData.pos[2] }
  else
    self.nodePosition = {0,0}
  end
  self:updateEditorPosition()
  self.customName = nodeData.customName
  self.customColor = nodeData.customColor and im.ImVec4(nodeData.customColor[1], nodeData.customColor[2], nodeData.customColor[3], nodeData.customColor[4])
  self.customIcon = nodeData.customIcon
  self.customIconColor = nodeData.customIconColor and im.ImVec4(nodeData.customIconColor[1], nodeData.customIconColor[2], nodeData.customIconColor[3], nodeData.customIconColor[4])
  if nodeData.identifier then
    self.data.identifier = nodeData.identifier
  end
  self.timeline = nodeData.timeline or nil
  if self.timeline and not self.timeline.lane then self.timeline.lane = 1 end
  -- deserialize data/values
  for k, v in pairs(nodeData.data) do
    if self.data[k] ~= nil then
      -- Cdata
      if type(data) == 'cdata' then
      -- lua type
      else
        self.data[k] = v
      end
    else
      if self.nodeType == 'util/ghost' then
        if not self.data then self.data = {} end
        self.data[k] = v
      else
        log('D',self.mgr.logTag,string.format("Property %s in Node %s does not exist.", k, self.name))
      end
    end
  end

  -- deserialize node before setting fixed pins
  self:_onDeserialized(nodeData)

  if self.nodeType == 'vehicle/special/customVlua' then
   -- print(debug.tracesimple())
   --dump(nodeData)
  end

  self.dynamicMode = nodeData.dynamicMode or 'repeat'
  self:handleNodeCategories()
  if nodeData.pins then
    table.clear(self.pinIn)
    table.clear(self.pinInLocal)
    table.clear(self.pinOut)
    table.clear(self.pinList)
    for _, pinData in ipairs(nodeData.pins) do
      local pin = self:createPin(
        pinData.dir or pinData[1] or pinData["1"],
        pinData.type or pinData[2] or pinData["2"],
        pinData.name or pinData[3]or pinData["3"],
        pinData.default or pinData[4] or pinData["4"],
        pinData.description or pinData[5] or pinData["5"],
        nil, nil,
        pinData.fixed or pinData[6] or pinData["6"])
      pin.tableType = pinData.tableType or pinData[7] or pinData["7"]
    end
  end

  if nodeData.hardcodedPins then
    for pinName, val in pairs(nodeData.hardcodedPins) do

      local updatedName  = self.legacyPins and self.legacyPins._in and self.legacyPins._in[pinName] or nil
      if self.pinInLocal[pinName] then
        self:_setHardcodedDummyInputPin(self.pinInLocal[pinName], val.value, val.type)
      elseif self.pinInLocal[updatedName] then
        self:_setHardcodedDummyInputPin(self.pinInLocal[updatedName], val.value, val.type)
      else
        log('W', self.mgr.logTag, 'Unable to set const value, pin not found: ' .. tostring(pinName) .. 'neither updated name: ' .. tostring(updatedName))
      end
    end
  end
  if nodeData.quickAccess then
    for pinName, val in pairs(nodeData.quickAccess.p_in) do
      if self.pinInLocal[pinName] then
        self.pinInLocal[pinName].quickAccess = true
        self.pinInLocal[pinName].accessName = val
      else
        log('W', self.mgr.logTag, 'Unable to set quickAccess value, in pin not found: ' .. tostring(pinName))
      end
    end
    for pinName, val in pairs(nodeData.quickAccess.p_out) do
      if self.pinOut[pinName] then
        self.pinOut[pinName].quickAccess = true
        self.pinOut[pinName].accessName = val
      else
        log('W', self.mgr.logTag, 'Unable to set quickAccess value, out pin not found: ' .. tostring(pinName))
      end
    end
  end
  if nodeData.hiddenPins then
    for pinName, val in pairs(nodeData.hiddenPins.p_in) do
      if val then
        if self.pinInLocal[pinName] then
          self.pinInLocal[pinName].hidden = val or false
        else
          log('W', self.mgr.logTag, 'Unable to hide pin, in pin not found: ' .. tostring(pinName))
        end
      end
    end
    for pinName, val in pairs(nodeData.hiddenPins.p_out) do
      if val then
        if self.pinOut[pinName] then
          self.pinOut[pinName].hidden = val or false
        else
          log('W', self.mgr.logTag, 'Unable to hide pin, out pin not found: ' .. tostring(pinName))
        end
      end
    end
  end
end

function C:__setNodeError(category, err)
  if not category then self._error = nil return end
  if err then
    log('E', self.name, tostring(err))
  end
  if not self._error then self._error = {} end
  self._error[category] = err
  if next(self._error) == nil then
    self._error = nil
  end
end

function C:__getNodeError(category)
  return (self._error or {})[category]
end

function C:toString() return self.name .. "( " ..self.nodeType .. " / " ..self.id .. ") in " .. self.graph:toString() end

function C:_postDeserialize() end

-- x=11 + 14n
-- y=5  + 14n

function C:alignToGrid(x,y)
  if not self.nodePosition or self.nodePosition == {} or force then
    self:updateNodePosition()
  end
  if x and y then self.nodePosition = {x,y} end
  local xn, yn = (self.nodePosition[1]-xOffGrid)/gridSize,  (self.nodePosition[2]-yOffGrid)/gridSize
  self.nodePosition = {xOffGrid+gridSize*round(xn), yOffGrid+gridSize*round(yn)}
  self:updateEditorPosition()
  --ui_flowgraph_editor.SetNodePosition(self.id, im.ImVec2(self.nodePosition[1], self.nodePosition[2]))
end

local M = {}

function M.createBase(...)
  local o = {}
  setmetatable(o, C)
  C.__index = C
  o:init(...)
  return o
end

function M.use(mgr, graph, forceId, derivedClass)
  local o = M.createBase(mgr, graph, forceId)
  -- override the things in the base node
  local baseInit = o.init
  for k, v in pairs(derivedClass) do
    --print('k = ' .. tostring(k) .. ' = '.. tostring(v) )
    o[k] = v
  end
  o:_preInit()
  if o.init ~= baseInit then
    o:init()
  end
  o:_postInit()
  return o
end

return M