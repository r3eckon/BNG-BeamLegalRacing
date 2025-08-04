local M = {}
local extensions = require("extensions")

local lights = {}
local mapxmin = 0
local mapymin = 0
local mapxmax = 0
local mapymax = 0
local mapwidth = 0
local mapheight = 0
local ccountx = 0
local ccounty = 0
local cwidth = 0
local cheight = 0

local chunks = {}
local chunkstate = {}

local playerObjectID = -100

local ready = false
local enabled = false
local tdetect = false

local starthour = 0
local endhour = 0

local shadegroup = {}

local function getLights()
return lights
end

local function loadLightData(path)
lights = {}
local ldata = extensions.blrutils.loadDataTable(path)


-- loading light objects
local gstr = ldata["lightgroup"]
local csplit = extensions.blrutils.ssplit(gstr, "/")
local cobj = nil
for i=1,#csplit do 
if not cobj then
cobj = scenetree.findObject(csplit[i])
else
cobj = cobj:findObject(csplit[i])
end
end
lights = cobj:getObjects()

-- loading shade group
if ldata["shadegroup"] then
gstr = ldata["shadegroup"]
csplit = extensions.blrutils.ssplit(gstr, "/")
shadegroup = nil
for i=1,#csplit do 
if not shadegroup then
shadegroup = scenetree.findObject(csplit[i])
else
shadegroup = shadegroup:findObject(csplit[i])
end
end
end

-- loading map bounds for chunking
csplit = extensions.blrutils.ssplit(ldata["mapbounds"], ",")
mapxmin = tonumber(csplit[1])
mapymin = tonumber(csplit[2])
mapxmax = tonumber(csplit[3])
mapymax = tonumber(csplit[4])
mapwidth = math.abs(mapxmin) + math.abs(mapxmax) 
mapheight = math.abs(mapymin) + math.abs(mapymax)

-- loading chunk counts
csplit = extensions.blrutils.ssplit(ldata["chunks"], ",")
ccountx = tonumber(csplit[1])
ccounty = tonumber(csplit[2])
cwidth = math.floor(mapwidth / ccountx)
cheight = math.floor(mapheight / ccounty)

-- loading hours
csplit = extensions.blrutils.ssplit(ldata["hours"], ",")
starthour = tonumber(csplit[1])
endhour = tonumber(csplit[2])


end

-- recursive set hidden
local function setHiddenRec(object, hidden)
  object:setHidden(hidden)
  if object:isSubClassOf("SimSet") then
  for k,v in pairs(object:getObjects()) do
	setHiddenRec(scenetree.findObject(v), hidden)
  end
  end
end

local function toggleAllLights(toggle)
for k,v in pairs(lights) do
scenetree.findObject(v):setHidden(not toggle)
end
end

local function toggleShading(toggle)
setHiddenRec(shadegroup, not toggle)
end

local function worldPosToChunkID(x,y)
local apx = x + math.abs(mapxmin)
local apy = y + math.abs(mapymin)

local cx = math.min(ccountx, math.max(0, math.floor(apx / cwidth)))
local cy = math.min(ccounty, math.max(0, math.floor(apy / cheight)))

return cx,cy
end

local function getChunkIndex(x,y)
return ccountx * y + x
end

local function generateChunks()
-- clear and init chunk list
chunks = {}
for i=0,(ccountx + 1)*(ccounty+1) do
chunks[i] = {}
end

local cobj = {}
local cpos = {}
local cidx, cidy 
local cid = -1
-- loop over all lights on level adding them to chunks
for k,v in pairs(lights) do
cobj = scenetree.findObject(v)
cpos = cobj:getPosition()
cidx, cidy = worldPosToChunkID(cpos.x,cpos.y)
cid = getChunkIndex(cidx,cidy)
table.insert(chunks[cid], cobj)
end

ready = true
end

local function getChunkAtPos(x,y)
local idx,idy = worldPosToChunkID(x,y)
local cid = getChunkIndex(idx,idy)
return chunks[cid]
end


local function setPlayerObjectID(id)
playerObjectID = id
end

local function toggleChunk(id, toggle)
if chunks[id] and chunkstate[id] ~= toggle then
chunkstate[id] = toggle
for k,v in pairs(chunks[id]) do
v:setHidden(not toggle)
end
end
end

local function toggleAllChunks(toggle)
for k,v in pairs(chunks) do
toggleChunk(k, toggle)
end
end


local pidx, pidy
local lchunk = -1
local cchunk = -1

-- cached player position to keep lights in same position during veh switch
local ppos = {}

local neededChunks = {}
local usedChunks = {}




local function onPreRender(dtReal,dtSim,dtRaw)
if not ready then return end

-- check if lights should be enabled at current hour
tdetect = extensions.blrutils.timeDetector(starthour,endhour)
if (enabled and not tdetect) then
toggleShading(false)
toggleAllChunks(false)
enabled = false
elseif ((not enabled) and tdetect) then
toggleShading(true)
enabled = true
lchunk = -1
end
if not enabled then return end

-- if no player object, use last known pos
if scenetree.objectExistsById(playerObjectID) then
ppos = scenetree.findObjectById(playerObjectID):getPosition()
end


pidx, pidy = worldPosToChunkID(ppos.x,ppos.y)
cchunk = getChunkIndex(pidx,pidy)

if lchunk ~= cchunk then
neededChunks = {}
neededChunks[getChunkIndex(pidx, pidy)] = true
neededChunks[getChunkIndex(pidx - 1, pidy)] = true
neededChunks[getChunkIndex(pidx + 1, pidy)] = true
neededChunks[getChunkIndex(pidx, pidy - 1)] = true
neededChunks[getChunkIndex(pidx - 1, pidy - 1)] = true
neededChunks[getChunkIndex(pidx + 1, pidy - 1)] = true
neededChunks[getChunkIndex(pidx, pidy + 1)] = true
neededChunks[getChunkIndex(pidx - 1, pidy + 1)] = true
neededChunks[getChunkIndex(pidx + 1, pidy + 1)] = true


for k,v in pairs(usedChunks) do
if not neededChunks[k] then
toggleChunk(k, false)
end
end

usedChunks = {}

for k,v in pairs(neededChunks) do
toggleChunk(k, true)
usedChunks[k] = true
end



lchunk = cchunk
end
end

local function reset()
if not ready then return end
toggleAllChunks(false)
toggleShading(false)
ready = false
enabled = false
playerObjectID = -100
lights = {}
chunks = {}
chunkstate = {}
end

local function isReady()
return ready
end

M.isReady = isReady
M.reset = reset
M.toggleChunk = toggleChunk
M.setPlayerObjectID = setPlayerObjectID
M.onPreRender = onPreRender
M.generateChunks = generateChunks
M.getChunkIndex = getChunkIndex
M.worldPosToChunkID = worldPosToChunkID
M.getLights = getLights
M.loadLightData = loadLightData
M.toggleAllLights = toggleAllLights


return M