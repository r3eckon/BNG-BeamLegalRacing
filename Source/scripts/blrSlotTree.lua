local M = {}

local nodedict = {}
local node = {parent=nil,id = "root", children={}}
local tree = {}

function node:new(p, i)
  local n = {parent=p or "none", id=i or "root", children={}}
  setmetatable(n, self)
  self.__index = self
  nodedict[n.id] = n
  if nodedict[n.parent] then
    nodedict[n.parent]:add(n)
  end
  return n
end

function node:add(n)
  table.insert(self.children, n)
end

local function treedump(n, d)
  local depth = d or 0
  local cout = ""
  for i=1,depth do
    cout = cout .. "   "
  end
  cout = cout .. n.id .. "=" .. (extensions.betterpartmgmt.getFullSlotNameLibrary()[n.id] or "!!! NO UI NAME !!!")
  print(cout)
  for k,v in ipairs(n.children) do
    treedump(v, depth+1)
  end
end

local config = {}
local cmodel = ""


local function recursiveChildLookup(p, n)
local cjbeam = extensions.betterpartmgmt.getJbeamFromFullMap(p)
local cslots = cjbeam["slots"] or cjbeam["slots2"]
local cstype = cjbeam["slotType"]
local cpart = ""
local cmap = {}

-- create node for current slot (should only happen for first slot)
if not nodedict[cstype] then
node:new(n, cstype)
end


-- find child slots for currently attached part
if not cslots then 
--print("NO CHILD SLOTS FOUND FOR " .. p)
return 
end -- no child slots for part

-- parse jbeam slots table
cslots = extensions.betterpartmgmt.parseJbeamSlotsTable(cslots)
-- sort slots table by ui names, return ordered list of slots
cslots = extensions.betterpartmgmt.getSortedJbeamSlotsTable(cslots)

for k,v in pairs(cslots) do

if v ~= cmodel .. "_mod" then -- avoid "additional modification" slot which doesn't show up in vanilla tree

-- create node for child slot 
if not nodedict[v] then
node:new(cstype, v)
end

-- find part attached to child slot
cpart = config[v] or ""
--print("CPART FOR " .. v .. " = " .. cpart)
if cpart ~= "" and cpart ~= "none" then
recursiveChildLookup(cpart, cstype)
end

end

end


end

-- reorganize tree to match vanilla part tree (no subpart slots go first)
local function reorganize(node)

local first = {}
local second = {}


for k,v in ipairs(node.children) do
if #v.children > 0 then
table.insert(second, v)
reorganize(v)
else
table.insert(first, v)
end
end

node.children = {}

for k,v in ipairs(first) do
table.insert(node.children, v)
end

for k,v in ipairs(second) do
table.insert(node.children, v)
end


end

local function buildSlotTree(model, vid)
if not vid then vid = be:getPlayerVehicle(0):getId() end
if not model then 
io.write("NOTE TO SELF: if errors appears below after CTRL+L you also need to hit CTRL+R")
model = extensions.betterpartmgmt.getMainPartName(vid) 
end

cmodel = model
nodedict = {}
tree = node:new(nil)
config = extensions.betterpartmgmt.getVehicleParts(vid)
recursiveChildLookup(model, "root")
reorganize(tree)
end






local function getTree()
return tree
end


--[[

local rootNode = node:new(nil)
local firstLayer = node:new("root", "layer1")
local secondLayer = node:new("layer1", "layer2")
local thirdLayer = node:new("layer2", "layer3")
local firstLayerA = node:new("root", "layer1A")
local firstLayerB = node:new("root", "layer1B")
local firstLayerC = node:new("root", "layer1C")
local firstLayerC2 = node:new("layer1C", "layer1C2")


treedump(rootNode)

for k,v in pairs(nodedict) do
  print(k .. "=" .. v.id) 
end


--]]

M.treedump = treedump
M.buildSlotTree = buildSlotTree
M.getTree = getTree

return M