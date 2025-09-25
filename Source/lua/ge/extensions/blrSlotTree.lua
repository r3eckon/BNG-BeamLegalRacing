local M = {}

local nodedict = {}
local node = {parent=nil,id = "root", children={}}

local tnodedict = {}
local tnode = {parent=nil,id = "root", children={}}


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

function tnode:new(p,i)
 local n = {parent=p or "none", id=i or "root", children={}, cmap={}}
 setmetatable(n, self)
 self.__index = self
 
 -- create node if it doesn't exist yet, update parent if it does
 if not tnodedict[n.id] then
	tnodedict[n.id] = n
 elseif n.parent ~= "none" then
	tnodedict[n.id].parent = n.parent
 end
 
 -- check if parent node exists, if it doesn't create it 
 if (n.parent ~= "none") and (not tnodedict[n.parent]) then
	tnode:new(nil, n.parent)
 end
 
 -- add self to children for parent node
 if n.parent ~= "none" then
	tnodedict[n.parent]:add(n.id)
 end
 
 return n
end

function tnode:add(id)
  if not self.cmap[id] then
  table.insert(self.children, id)
  self.cmap[id] = true
  end
end

local function treedump(n, d)
  local depth = d or 0
  local cout = ""
  for i=1,depth do
    cout = cout .. "   "
  end
  cout = cout .. n.id .. "=" .. (extensions.blrpartmgmt.getFullSlotNameLibrary()[extensions.blrpartmgmt.getSlotIDFromPath(n.id)] or "!!! NO UI NAME !!!")
  blrlog(cout)
  for k,v in ipairs(n.children) do
    treedump(v, depth+1)
  end
end

local function parttreedump(n, d)
local depth = d or 0
local cout = ""
for i=1,depth do
cout = cout .. "-"
end
cout = cout .. n.id .. "=" .. (extensions.blrpartmgmt.getFullSlotNameLibrary()[n.id] or "!!! NO UI NAME !!!")
blrlog(cout)
for k,v in ipairs(n.children) do
parttreedump(tnodedict[v], depth+1)
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

local function reorganizePartShopTree(node)
local first = {}
local second = {}
local cnode = tnodedict[node]

for _,child in ipairs(cnode.children) do
if #tnodedict[child].children > 0 then
table.insert(second, child)
reorganizePartShopTree(child)
else
table.insert(first, child)
end
end

cnode.children = {}

for k,v in ipairs(first) do
table.insert(cnode.children, v)
end
for k,v in ipairs(second) do
table.insert(cnode.children, v)
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

local function sortPartShopTree()
local sorted = {}
local map = {}
for _,node in pairs(tnodedict) do
sorted = {}
map = {}

for _,child in pairs(node.children) do
map[child] = extensions.blrpartmgmt.getFullSlotNameLibrary()[child] or child
end

for child,_ in valueSortedPairs(map) do
table.insert(sorted, child)
end
node.children = sorted
end
end


local shoptree = {}
local shopTreeCachedModel = ""

-- UI init calls to this function could be replaced with cached data as it loads jbeam files
-- to generate a part shop tree, so could be done during jbeam caching step and store the node 
-- dictionary for each vehicle as json tables for faster loading, but it's already quite fast as is
-- so only keep this in mind as a potential optimization 
local function buildPartShopTreeFromJbeam(vid, model, folders)

local cjbeam = {}
local stdata = {}
local cslots = {}
local cnode = {}
local cjdata = {}
local cstype = ""


if not vid then vid = be:getPlayerVehicle(0):getId() end

if not model then 
io.write("NOTE TO SELF: if errors appears below after CTRL+L you also need to hit CTRL+R")
model = extensions.blrpartmgmt.getMainPartName(true,vid) 
end

if model == shopTreeCachedModel then
print("Part shop tree generation skipped, already generated for this model")
return
end

if not folders then
folders = {"/vehicles/" .. model .. "/", "/vehicles/common/"}
end



shoptree = {}
tnodedict = {}
shoptree = tnode:new(nil,"root")
tnode:new("root", model)

for _,folder in pairs(folders) do
for _,file in pairs(FS:findFiles(folder, "*.jbeam", -1)) do
cjdata = jsonReadFile(file)
for part,cjbeam in pairs(cjdata) do
stdata = cjbeam["slotType"]
cslots = cjbeam["slots"] or cjbeam["slots2"]


if cslots then

cslots = extensions.blrpartmgmt.parseJbeamSlotsTable(cslots)
cslots = extensions.blrpartmgmt.getSortedJbeamSlotsTable(cslots)


for _,cslot in pairs(cslots) do	
	
	if cslot ~= (model .. "_mod") then -- avoids adding the "Additional Modification" slot 
	
		if type(stdata) == "table" then
			for _,ptype in pairs(stdata) do
				if ptype == "main" then
					ptype = model 
				end
				tnode:new(ptype, cslot)
			end
		else
			if stdata == "main" then 
				stdata = model 
			end
			tnode:new(stdata, cslot)
		end
	
	end
	
end

end


end
end
end

sortPartShopTree()
reorganizePartShopTree(model)

shopTreeCachedModel = model
end



local function getTNdict()
return tnodedict
end

local function getShopTree()
return shoptree
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
M.buildPartShopTree = buildPartShopTree
M.getTree = getTree
M.getShopTree = getShopTree
M.getTNdict = getTNdict
M.parttreedump = parttreedump
M.buildPartShopTreeFromJbeam = buildPartShopTreeFromJbeam

return M