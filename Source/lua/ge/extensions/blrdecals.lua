local M = {}

local activeDecals = {}
local enabled = false

local function createDecal(id, texture, position, rot, scale, color, fvec, fadeStart, fadeEnd, area, chunk)

local col = ColorF(0,0,0,0)

if color then 
col = ColorF(unpack(color))
end

local decal = {
    texture = texture,
    position = position or vec3(0,0,0),
    forwardVec = fvec or (rot * vec3(0,1,0)) or vec3(0,1,0),
    color = col,
    scale = scale or vec3(1,1,1),
    fadeStart = fadeStart or 200,
    fadeEnd = fadeEnd or 250,
	id = id,
	puddle_area = area,
	chunk = chunk,
  }

return decal
end

local function spawnDecal(decal)
Engine.Render.DynamicDecalMgr.addDecal(decal)
end

local function setPermanentDecal(decal, pid)
activeDecals[pid] = decal
end

local function removePermanentDecal(pid)
activeDecals[pid] = nil
end

local function getPermanentDecal(pid)
return activeDecals[pid]
end

local leakNodes = {}

local oilLeakReady = false

local function receiveLeakNodes(serialized)
leakNodes = deserialize(serialized)
oilLeakReady = true
print("blrdecals received leak nodes:")
dump(leakNodes)
end

local function getLeakNodePosition(vehid)
local cpos = nil
local count = #leakNodes
local veh = scenetree.findObjectById(vehid)

if not veh or not veh.getNodeAbsPosition then return end

if count == 0 then
--print("Leak node error: didn't find any leak nodes, can't spawn decals")
return
end

local ax = 0
local ay = 0
local az = 0

for k,v in pairs(leakNodes) do
--cpos = vec3(veh:getNodePosition(v)) + vec3(veh:getPositionXYZ())
cpos = vec3(veh:getNodeAbsPosition(v))
ax = ax + cpos.x
ay = ay + cpos.y
az = az + cpos.z
end

ax = ax / count
ay = ay / count
az = az / count

return vec3(ax,ay,az)
end


local function getLeakDecalRotation(vehid)
local veh = scenetree.findObjectById(vehid)
if not veh or not veh.getRotation then return end
return quat(veh:getRotation():toTable())
end

-- rolling id buffer, recycles id values
-- cdid = latest decal id value
-- buffer = amount of decals ids kept active, ids outside buffer are removed
-- range = total range of id values
local cdid = 0
local buffer = 500
local range = 1000


local function nextID()
cdid = cdid + 1
if cdid > range then cdid = 1 end 
end

local function getBufferLocation()
local st = cdid - buffer + 1
if st < 1 then st = range + st end
local en = cdid
return st,en
end

local function inBuffer(check)
local st,en = getBufferLocation()
if st > en then
return check <= en or check >= st
else
return check <= en and check >= st
end
end




local function spawnOilLeakDecal(id, file, pos, rot, scl, col, fvec, fstart, fend, parea, chunk)

if not id then return end
if not pos then return end

local did = id
local dpos = pos
local dfile = file or "art/decals/color_base.png"
local drot = rot or quat(0,0,0,0)
local dscl = scl or vec3(.2,.2,10.0)
local dcol = col or {0.0,0.0,0.0,1.0}
local dfstart = fstart or 1000
local dfend = fend or 1200
local dfvec = fvec or vec3(0,1,0)
local dparea = parea or 1
local dchunk = chunk or vec3(0,0,0)

-- spawn actual decal 
local d = createDecal(did, dfile, dpos, drot, dscl, dcol, fvec, dfstart, dfend, dparea, dchunk)
setPermanentDecal(d, did)

return d
end


local csx = 0.25
local csy = 0.25

local chunkedDecals = {}

local function getChunkFromPos(pos)
local px = pos.x
local py = pos.y
local cx = math.floor(px / csx)
local cy = math.floor(py / csy)

--print("getChunkFromPos returning " .. cx .. "," .. cy)

return cx,cy
end

local function getChunkCenterPos(cx,cy)
local x = (cx * csx) + (csx / 2)
local y = (cy * csy) + (csy / 2)

--print("getChunkCenterPos returning " .. x .. "," .. y)

return x,y
end

local function getDecalForChunk(cx,cy)
if chunkedDecals[cx] then
--print("getDecalForChunk data:")
--dump(chunkedDecals[cx][cy])
return chunkedDecals[cx][cy]
else
--print("getDecalForChunk returning nil")
end
end

local function setDecalForChunk(cx,cy, decal)
if not chunkedDecals[cx] then chunkedDecals[cx] = {} end
chunkedDecals[cx][cy] = decal
end

local puddles = nil


local function addChunkedOilLeakDecal(vehid)

if not scenetree.findObjectById(vehid) then return end


local npos = getLeakNodePosition(vehid)

if not npos then return end

local chunkx,chunky = getChunkFromPos(npos)
local centerx, centery = getChunkCenterPos(chunkx,chunky)
--local centerz = core_terrain.getTerrainHeight(vec3(centerx,centery,0)) + 0.1
local raycastStart = vec3(centerx,centery,npos.z)
local raycastEnd = vec3(centerx,centery,npos.z-100)
local raycastResult = Engine.castRay(raycastStart, raycastEnd, true, false)

if not raycastResult then return end

local seed = chunkx * 1000 + chunky
math.randomseed(seed)
if not puddles then puddles = FS:findFiles("/art/decals/beamlr", "*.png", 1) end
local ppick = math.random(1,#puddles)
local pfile = puddles[ppick]
local roffsetx = math.random(-25,25)/100.0
local roffsety = math.random(-25,25)/100.0

--print("Raycast result:")
--dump(raycastResult)
--print("Raycast object name: " ..  raycastResult.obj:getName())
--print("Raycast object class: " .. raycastResult.obj:getClassName())

local centerz = raycastResult.pt.z
local cdecal = getDecalForChunk(chunkx,chunky)
local cid = -1
local carea = 0.01
local cscale = (math.sqrt(carea) / math.pi) * 2.0

local rot = getLeakDecalRotation(vehid)
local gnorm = vec3(raycastResult.norm.x, raycastResult.norm.z, raycastResult.norm.y)

local color = {0,0,0,0.8}

-- no existing decal on current chunk, need to use a new id or reuse oldest id if max decal count is reached
if not cdecal then
nextID() -- increment id value
cid = cdid
--print("Chunk did not contain any exising decals, new id value is " .. cid)

-- last check if active decal exists with this ID that hasn't been removed smoothly yet
-- just remove it instantly to avoid keeping old decal data on chunks
if activeDecals[cdid] then
--print("Removed existing decal using same ID before it was faded out due to hard decal limit reached")
--print("Removed decal data:")
--print(dumps(activeDecals[cdid]))
chunkedDecals[activeDecals[cdid].chunk.x][activeDecals[cdid].chunk.y] = nil
activeDecals[cdid] = nil
end


else
cdecal = cdecal
cid = cdecal.id
cscale = cdecal.scale.x
carea = cdecal.puddle_area
--print("Chunk contained exising decals, existing cid value is " .. cid)
-- linearly grow area of puddle rather than radius to have a more realistic increase in size
carea = carea + 0.025
cscale = (math.sqrt(carea) / math.pi) * 2.0
end




--print("New scale value for decal: " .. cscale)






-- spawn decal
local ndecal = spawnOilLeakDecal(cid, pfile, vec3(centerx+roffsetx, centery+roffsety, centerz), rot, vec3(cscale, cscale, 1.0), color, gnorm, nil, nil, carea, vec3(chunkx,chunky,0))
setDecalForChunk(chunkx,chunky, ndecal)
--print("Should have spawned decal")
end

local lastoilval = -1

local function leakDecalSpawner(vehid, oilval)

if not enabled then return end
if not oilLeakReady then return end
if not oilval then return end
if not scenetree.findObjectById(vehid) then return end


local scaledCurrent = math.floor(oilval * 100.0)

if lastoilval == -1 then -- init last oil val, don't spawn decal this time
lastoilval = oilval
return
end

if oilval > lastoilval then -- happens after refilling oil, increase last oil val to spawn decals from new higher value
lastoilval = oilval
return
end

local scaledLast = math.floor(lastoilval * 100.0)

if scaledCurrent < scaledLast then
addChunkedOilLeakDecal(vehid)
--print("Spawned oil decal due to vehicle oil value dropping from " .. (scaledLast/100.0) .. " to " ..  (scaledCurrent/100.0))
lastoilval = oilval
end 


end


local function resetDecalSystem()
oilLeakReady = false
leakNodes = {}
activeDecals = {}
cdid = 0
chunkedDecals = {}
lastoilval = -1
end

local function clearDecals()
activeDecals = {}
cdid = 0
chunkedDecals = {}
lastoilval = -1
end

local function removeChunkedOilLeakDecal(decal)

--print("Should have removed from activeDecals table at id: " .. decal.id)
--print("Should have removed from chunkedDecals table at x,y: " .. decal.chunk.x .. "," .. decal.chunk.y)
--print("Previous decal for that chunk:")
--print(dumps(chunkedDecals[decal.chunk.x][decal.chunk.y]))

activeDecals[decal.id] = nil
chunkedDecals[decal.chunk.x][decal.chunk.y] = nil
end

local function onPreRender(dtReal,dtSim,dtRaw)

if not enabled then return end

local index = -1

local toRemove = {}

for k,v in pairs(activeDecals) do
	if not inBuffer(v.id) then
		v.color.a = math.max(0,v.color.a - (0.1 * dtSim))
		--print("Fading out decal id " .. v.id .. " in preparation for removal, current alpha value: " .. v.color.a)
		if v.color.a <= 0 then 
			table.insert(toRemove, v)
		else	
			spawnDecal(v)
		end
		
	else
		spawnDecal(v)
	end
end

for _,d in pairs(toRemove) do
removeChunkedOilLeakDecal(d)
end

end


local function setBufferSize(size)
buffer = size
range = size + 200
--print("New buffer params: " .. buffer .. " / " .. range)
end

local function toggleOilLeakDecals(toggle)
if toggle then
enabled = true
--print("Oil leak decals have been toggled on")
else
enabled = false
clearDecals()
--print("Oil leak decals have been toggled off")
end
end



M.toggleOilLeakDecals = toggleOilLeakDecals
M.setBufferSize = setBufferSize

M.leakDecalSpawner = leakDecalSpawner

M.getChunkCenterPos = getChunkCenterPos
M.getChunkFromPos = getChunkFromPos
M.getDecalForChunk = getDecalForChunk
M.setDecalForChunk = setDecalForChunk
M.addChunkedOilLeakDecal = addChunkedOilLeakDecal
M.removeChunkedOilLeakDecal = removeChunkedOilLeakDecal

M.spawnOilLeakDecal = spawnOilLeakDecal
M.receiveLeakNodes = receiveLeakNodes
M.getLeakNodePosition = getLeakNodePosition

M.resetDecalSystem = resetDecalSystem
M.clearDecals = clearDecals


M.createDecal = createDecal
M.setPermanentDecal = setPermanentDecal
M.removePermanentDecal = removePermanentDecal
M.getPermanentDecal = getPermanentDecal

M.onPreRender = onPreRender

return M