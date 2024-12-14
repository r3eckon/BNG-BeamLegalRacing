local M = {}

-- BEAMLR EDIT START
local extensions = require("extensions")
-- END


local im = ui_imgui
local scoreExperiment = im.BoolPtr(false)
local imVec4Yellow = im.ImVec4(1,1,0,1)

local isBeingDebugged
local profiler = LuaProfiler("drift scoring profiler")
local gc
local driftDebugInfo = {
  default = true,
  canBeChanged = true
}

local scoreAddedThisFrame = 0

local scoreOptions = {
  careerRewards = {
    minScore = 300,
    scoreMulForXp = 0.0017
  },
  defaultPoints = {
    driftThrough = 1500,
    donut = 500,
    hitPole = 1000,
    nearPole = 1000,
  },
  minDriftAngleMulti = 1,
  maxDriftAngleMulti = 10,
  maxWallMulti = 3,
  maxSpeedMulti = 4,
  maxCombo = 5,
  wallTapScore = 200,
  continuousDriftPoints = 0.6,
  comboOptions = {
    stuntZone = {
      creepUp = 70,
    },
    oneSideDrift = {
      creepUp = 3.125,
      timeToCreepup = 0.05, -- has to drift x seconds to increase creep up.
      maxIncrements = 96 -- how many times can the creepup be increased is a single drift
    },
    driftTransition = {
      creepUp = 20,
      cooldownTime = 2, -- this is to avoid quick transitions
    },
    closeWall = {
      creepUp = 25
    },
    increment = 0.2,
    maxCombo = 5,
  }
}
local driftScore = {}

local driftActiveData = {}
local driftOptions = {}

--
local currDriftTimeToCombo = 0
local currDriftIncrement = 0

local lastDriftInitiationTimer = 0

local function resetCachedScore()
  driftScore.cachedScore = 0
  driftScore.combo = 1
  driftScore.comboCreepup = 0 -- 0 - 100, when we go over 100, the combo is incremented
  extensions.hook("onDriftCachedScoreReset")
end

local function reset()
  driftScore = {
    score = 0,
  }
  resetCachedScore()
  lastDriftInitiationTimer = 0
end

local function addComboCreepUp(value)
  local tempCreepUp = driftScore.comboCreepup + value
  local potentialCombo = driftScore.combo + scoreOptions.comboOptions.increment

  if potentialCombo <= scoreOptions.comboOptions.maxCombo + 0.01 then
    if tempCreepUp >= 100 then
      driftScore.combo = potentialCombo
      driftScore.comboCreepup = tempCreepUp - 100
    else
      driftScore.comboCreepup = tempCreepUp
    end
  end
end

local function resetOneSideDriftData()
  currDriftTimeToCombo = 0
  currDriftIncrement = 0
end

local function calculateOneSideDriftCreepUp(dtSim)
  currDriftTimeToCombo = currDriftTimeToCombo + dtSim
  if currDriftTimeToCombo >= scoreOptions.comboOptions.oneSideDrift.timeToCreepup and currDriftIncrement < scoreOptions.comboOptions.oneSideDrift.maxIncrements then
    addComboCreepUp(scoreOptions.comboOptions.oneSideDrift.creepUp)
    currDriftTimeToCombo = 0
    currDriftIncrement = currDriftIncrement + 1
  end
end

local function addCachedScore(valueToAdd, useStallingSystem)
  if useStallingSystem == nil then
    useStallingSystem = false
  end
  if gameplay_drift_general.getFrozen() then return end

  if useStallingSystem and gameplay_drift_stallingSystem then
    valueToAdd = gameplay_drift_stallingSystem.calculateScore(valueToAdd)
  end
  driftScore.cachedScore = driftScore.cachedScore +  valueToAdd

  return valueToAdd
end

local minSpeed = 22 --min speed at which the speedMulti factor starts increasing
local maxSpeed = 200 --speed at which the speedMulti factor stops increasing
local wallMulti
local speedMulti
local angleMulti
local continuousScore
local function scoreContinuousDrift(distSinceLastFrame)
  wallMulti = 1 + linearScale(driftActiveData.closestWallDistanceFront, driftOptions.wallDetectionLength, 0, 0, scoreOptions.maxWallMulti) + linearScale(driftActiveData.closestWallDistanceRear, driftOptions.wallDetectionLength, 0, 0, scoreOptions.maxWallMulti)
  angleMulti = linearScale(driftActiveData.currDegAngle, driftOptions.minAngle, driftOptions.maxAngle, scoreOptions.minDriftAngleMulti, scoreOptions.maxDriftAngleMulti)
  speedMulti = math.min(math.max(1, linearScale(gameplay_drift_drift.getAirSpeed(), minSpeed, maxSpeed, 1, scoreOptions.maxSpeedMulti) ), scoreOptions.maxSpeedMulti)

  continuousScore = scoreOptions.continuousDriftPoints
  if gameplay_drift_stallingSystem then
    continuousScore = gameplay_drift_stallingSystem.calculateScore(continuousScore)
  end

  scoreAddedThisFrame = angleMulti * speedMulti * wallMulti * distSinceLastFrame * continuousScore
  addCachedScore(scoreAddedThisFrame)
end

local function imguiDebug()
  if isBeingDebugged then
    if im.Begin("Drift score") then
      im.Text(string.format("Score : %d", driftScore.score))
      im.Text(string.format("Cached score : %d", driftScore.cachedScore))
      im.Text(string.format("Combo : %0.2f Combo creep up : %d", driftScore.combo, driftScore.comboCreepup))

      im.Checkbox("Experiment with score multipliers", scoreExperiment)

      if scoreExperiment[0] then
        im.BeginChild1("change", im.ImVec2(0, 140), true)
        im.Text("Experiment (CTRL + L to reset):")
        local baseScoreP = im.FloatPtr(scoreOptions.continuousDriftPoints)
        if im.SliderFloat("Base score", baseScoreP, 0, 3, "%.2f") then
          scoreOptions.continuousDriftPoints = baseScoreP[0]
        end
        local maxSpeedMultiP = im.FloatPtr(scoreOptions.maxSpeedMulti)
        if im.SliderFloat("Max speed multi", maxSpeedMultiP, 1, 50, "%.1f") then
          scoreOptions.maxSpeedMulti = maxSpeedMultiP[0]
        end
        local maxWallMultiP = im.FloatPtr(scoreOptions.maxWallMulti)
        if im.SliderFloat("Max wall multi", maxWallMultiP, 1, 50, "%.1f") then
          scoreOptions.maxWallMulti = maxWallMultiP[0]
        end
        local maxDriftAngleMultiP = im.FloatPtr(scoreOptions.maxDriftAngleMulti)
        if im.SliderFloat("Max angle multi", maxDriftAngleMultiP, 1, 50, "%.1f") then
          scoreOptions.maxDriftAngleMulti = maxDriftAngleMultiP[0]
        end
        im.EndChild()
      end
      if gameplay_drift_drift.getIsDrifting() then
        if not gameplay_drift_general.getFrozen() then
          im.Text(string.format("Speed score multi : %0.2f (%i - %i)", speedMulti or -1, 1, scoreOptions.maxSpeedMulti))
          im.Text(string.format("Wall score multi : %0.2f (%i - %i)", wallMulti or -1, 1, scoreOptions.maxWallMulti))
          im.Text(string.format("Angle score multi : %0.2f (%i - %i)", angleMulti or -1, scoreOptions.minDriftAngleMulti, scoreOptions.maxDriftAngleMulti))
          im.Text(string.format("Score added this frame : %0.5f", scoreAddedThisFrame or -1))
        end
      else
        im.PushStyleColor2(im.Col_Text, imVec4Yellow)
        im.Text("Drift to see scoring information")
        im.PopStyleColor()
      end
    end
  end
end

local function onUpdate(dtReal, dtSim)

  -- BEAMLR EDIT START
  if extensions.blrglobals.blrFlagGet("legacyDriftScoring") then return end
  -- END


  lastDriftInitiationTimer = lastDriftInitiationTimer + dtSim

  isBeingDebugged = gameplay_drift_general.getExtensionDebug("gameplay_drift_scoring")
  imguiDebug()
  if gameplay_drift_general.getGeneralDebug() then profiler:start() end


  if gameplay_drift_general.getPaused() then return end

  driftActiveData = gameplay_drift_drift.getDriftActiveData()
  driftOptions = gameplay_drift_drift.getDriftOptions()

  if gameplay_drift_drift.getIsDrifting() then
    if not gameplay_drift_general.getFrozen() then
      calculateOneSideDriftCreepUp(dtSim)
      scoreContinuousDrift(gameplay_drift_drift.getDistSinceLastFrame())
    end
  else
    resetOneSideDriftData()
  end

  if gameplay_drift_general.getGeneralDebug() then
    profiler:add("Drift scoring")
    gc = profiler.sections[1].garbage
    profiler:finish(false)
  end
end

-- Drift stunts --
local function onAnyStuntZoneAccomplished()
  addComboCreepUp(scoreOptions.comboOptions.stuntZone.creepUp)
end

local function onDriftThroughAccomplished(data)
  local score = math.floor(linearScale(data.currDegAngle, 0, 90, 0, data.zoneData.points))
  score = addCachedScore(score, true)
  extensions.hook('onTightDriftScored', score)
end

local function onHitPoleAccomplished(data)
  local score = math.floor(linearScale(data.currDegAngle + data.currAirSpeed, 0, 250, 0, data.zoneData.points))
  score = addCachedScore(score, true)
  extensions.hook('onHitPoleScored', score)
end

local function onNearPoleAccomplished(data)
  local score = (data.currDegAngle * data.closeness / 90) ^ 1 * data.zoneData.points
  score = addCachedScore(score, true)
  extensions.hook("onNearPoleScored", score)
end

local function onDonutDriftAccomplished(data)
  local score = addCachedScore(data.zoneData.points, true)
  extensions.hook('onDonutDriftScored', score)
end

-- preemptively "confirm" cached score
local function wrapUp()
  local addedScore = math.floor(driftScore.cachedScore * driftScore.combo)
  if addedScore < 1 then return false end

  driftScore.score = driftScore.score + addedScore

  resetCachedScore()
  return addedScore
end

local function wrapUpWithText()
  local addedScore = wrapUp()
  if addedScore then
    extensions.hook("onDriftScoreWrappedUp", addedScore)
  end
  return addedScore
end

-- doesn't return anything if too small of a drift
local function getCareerRewardsForDriftScore(addedScore)
  if addedScore < scoreOptions.careerRewards.minScore then return end

  local beamXP = math.ceil(addedScore * scoreOptions.careerRewards.scoreMulForXp)
  return {
    beamXP = beamXP
  }
end

local function onDriftCompleted()
  local addedScore = wrapUp()
  if not addedScore then return end

  extensions.hook('onDriftCompletedScored',
    {
      addedScore = addedScore,
      cachedScore = math.floor(driftScore.cachedScore),
      combo = driftScore.combo,
      careerRewards = getCareerRewardsForDriftScore(addedScore)
    }
  )
end

local function onDriftStatusChanged(isDrifting)
  if isDrifting then
    if lastDriftInitiationTimer >= scoreOptions.comboOptions.driftTransition.cooldownTime then
      addComboCreepUp(scoreOptions.comboOptions.driftTransition.creepUp)
    end
    lastDriftInitiationTimer = 0
  end
end

local function onDriftFailed()
  resetCachedScore()
end

local function onDriftCrash(hasCachedScore)
  if hasCachedScore then
    onDriftFailed()
  end
end

local function onDriftSpinout()
  onDriftFailed()
end

local function getScore()
  return driftScore
end

local function getScoreAddedThisFrame()
  return scoreAddedThisFrame
end

local function getDriftDebugInfo()
  return driftDebugInfo
end

local function getGC()
  return gc
end

local function getScoreOptions()
  return scoreOptions
end

local function onDriftPlVehReset()
  reset()
end

local function onSerialize()
  return {
    scoreExperiment = scoreExperiment[0]
  }
end

local function onDeserialized(data)
  scoreExperiment = im.BoolPtr(data.scoreExperiment or false)
end

M.onDriftPlVehReset = onDriftPlVehReset
M.onUpdate = onUpdate
M.onSerialize = onSerialize
M.onDeserialized = onDeserialized

M.onDriftStatusChanged = onDriftStatusChanged
M.onAnyStuntZoneAccomplished = onAnyStuntZoneAccomplished
M.onDriftThroughAccomplished = onDriftThroughAccomplished
M.onHitPoleAccomplished = onHitPoleAccomplished
M.onDonutDriftAccomplished = onDonutDriftAccomplished
M.onDriftCompleted = onDriftCompleted
M.onNearPoleAccomplished = onNearPoleAccomplished

M.onDriftCrash = onDriftCrash
M.onDriftSpinout = onDriftSpinout

M.getScore = getScore
M.getScoreOptions = getScoreOptions
M.getScoreAddedThisFrame = getScoreAddedThisFrame
M.getDriftDebugInfo = getDriftDebugInfo
M.getGC = getGC

M.reset = reset
M.wrapUp = wrapUp
M.wrapUpWithText = wrapUpWithText
M.addCachedScore = addCachedScore

return M