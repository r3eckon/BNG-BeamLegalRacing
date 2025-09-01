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
  cout = cout .. n.id .. "=" .. (extensions.blrpartmgmt.getFullSlotNameLibrary()[extensions.blrpartmgmt.getSlotIDFromPath(n.id)] or "!!! NO UI NAME !!!")
  print(cout)
  for k,v in ipairs(n.children) do
    treedump(v, depth+1)
  end
end

local config = {}
local cmodel = ""


local function recursiveChildLookup(p, n)
local cjbeam = extensions.blrpartmgmt.getJbeamFromFullMap(p)
local cslots = cjbeam["slots"] or cjbeam["slots2"]
local stdata = cjbeam["slotType"]
local cstype = ""
local cpart = ""
local cmap = {}
local cspath = ""
local tcheckpath = ""


-- 1.18.1 handle "slotType" that's a table instead of a single value, happens on new sunburst
-- since we're checking for child slots of a part, only the slot that actually contains the part 
-- matters, ignore other slots the part could fit in, this shouldn't affect the same part fitting
-- in other slots because path will be different
if type(stdata) == "table" then
	--print("JBEAM FIELD slotType IS A TABLE CONTAINING: " .. dumps(stdata))
	for _,t in pairs(stdata) do
		tcheckpath = n .. t .. "/"
		if config[tcheckpath] then 
			--print("FOUND SLOT " .. tcheckpath .. " IN CONFIG, IGNORING OTHER SLOTS FROM slotType TABLE")
			cstype = t
			break
		end
	end
	if cstype == "" then -- 1.18.1 fix for empty slot in part tree
		--print("DIDN'T FIND ANY SLOTS FROM slotType TABLE IN CONFIG (LIKELY CAUSED BY allowType TABLE)")
		return
	end
else
	cstype = stdata
end

if not cstype then -- 1.18.1, just adding a check to make sure process doesn't crash due to jbeam error
	--print("PART DID NOT HAVE A slotType DEFINED (LIKELY CAUSED BY INCORRECT JBEAM)")
	return
end


if n == "root" then
cspath = "/"
else
cspath = n .. cstype .. "/"
end

--print("CSPATH: " .. cspath)

-- create node for current slot (should only happen for first slot)
if not nodedict[cspath] then
node:new(n, cspath)
end


-- find child slots for currently attached part
if not cslots then 
--print("NO CHILD SLOTS FOUND FOR " .. p)
return 
end -- no child slots for part

-- parse jbeam slots table
cslots = extensions.blrpartmgmt.parseJbeamSlotsTable(cslots)
-- sort slots table by ui names, return ordered list of slots
-- 1.18 UPDATE, FUNCTION ALSO CONVERTS SLOTID INTO SLOT PATH
cslots = extensions.blrpartmgmt.getSortedJbeamSlotsTable(cslots, cspath)

for index,slotPath in pairs(cslots) do

if slotPath ~= ("/" .. cmodel .. "_mod/") then -- avoid "additional modification" slot which doesn't show up in vanilla tree

-- create node for child slot 
if not nodedict[slotPath] then
node:new(cspath, slotPath)
end

slotPath = string.gsub(slotPath, "/main", "")

-- find part attached to child slot
cpart = config[slotPath] or ""
--print("CPART FOR " .. slotPath .. " = " .. cpart)
if cpart ~= "" and cpart ~= "none" then
recursiveChildLookup(cpart, cspath)
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
model = extensions.blrpartmgmt.getMainPartName(vid) 
end

cmodel = model
nodedict = {}
tree = node:new(nil)
config = extensions.blrpartmgmt.getVehicleParts(vid)
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