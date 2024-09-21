local M = {}

local im = ui_imgui

-- BEAMLR EDIT START
local extensions = require("extensions")
-- END

local scoreOptions = {
  defaultPoints = {
    driftThrough = 1500,
    donut = 500,
    hitPole = 1000,
    nearPole = 1000,
  },
  minDriftAngleMulti = 1,
  maxDriftAngleMulti = 2.5,
  maxWallMulti = 4,
  maxSpeedMulti = 3,
  maxCombo = 5,
  wallTapScore = 200,
  continuousDriftPoints = 20,
  comboOptions = {
    stuntZone = {
      creepUp = 70,
    },
    oneSideDrift = {
      creepUp = 25,
      timeToCreepup = 0.4, -- has to drift x seconds to increase creep up.
      maxIncrements = 12 -- how many times can the combo be increased is a single drift
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
local driftScore = {

}
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

local function resetScore()
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

local minSpeed = 35 --min speed at which the speedMulti factor starts increasing
local maxSpeed = 200 --speed at which the speedMulti factor stops increasing
local wallMulti
local speedMulti
local angleMulti
local continuousScore
local function scoreContinuousDrift(dtSim)
  wallMulti = 1 + linearScale(driftActiveData.closestWallDistanceFront, driftOptions.wallDetectionLength, 0, 0, scoreOptions.maxWallMulti) + linearScale(driftActiveData.closestWallDistanceRear, driftOptions.wallDetectionLength, 0, 0, scoreOptions.maxWallMulti)
  angleMulti = linearScale(driftActiveData.currDegAngle, driftOptions.minAngle, driftOptions.maxAngle, scoreOptions.minDriftAngleMulti, scoreOptions.maxDriftAngleMulti)
  speedMulti = math.min(math.max(1, linearScale(gameplay_drift_drift.getAirSpeed(), minSpeed, maxSpeed, 1, scoreOptions.maxSpeedMulti) ), scoreOptions.maxSpeedMulti)

  continuousScore = scoreOptions.continuousDriftPoints
  if gameplay_drift_stallingSystem then
    continuousScore = gameplay_drift_stallingSystem.calculateScore(continuousScore)
  end

  addCachedScore(angleMulti * speedMulti * wallMulti * dtSim * continuousScore)
end

local function imguiDebug()
  if gameplay_drift_general.getDebug() then
    if im.Begin("Drift score") then
      im.Text(string.format("Score : %d", driftScore.score))
      im.Text(string.format("Cached score : %d", driftScore.cachedScore))
      im.Text(string.format("Combo : %0.2f", driftScore.combo))
      im.Text(string.format("Combo creep up : %d", driftScore.comboCreepup))

      if gameplay_drift_drift.getIsDrifting() then
        if not gameplay_drift_general.getFrozen() then
          im.Text(string.format("Speed score multi : %0.2f", speedMulti or -1))
          im.Text(string.format("Wall score multi : %0.2f", wallMulti or -1))
          im.Text(string.format("Angle score multi : %0.2f", angleMulti or -1))
        end
      end
    end
  end
end

local function onUpdate(dtReal, dtSim)

  -- BEAMLR EDIT START
  if extensions.blrglobals.blrFlagGet("legacyDriftScoring") then return end
  -- END
 
  lastDriftInitiationTimer = lastDriftInitiationTimer + dtSim

  imguiDebug()

  if gameplay_drift_general.getContext() == "stopped" then return end

  driftActiveData = gameplay_drift_drift.getDriftActiveData()
  driftOptions = gameplay_drift_drift.getDriftOptions()

  if gameplay_drift_drift.getIsDrifting() then
    if not gameplay_drift_general.getFrozen() then
      calculateOneSideDriftCreepUp(dtSim)
      scoreContinuousDrift(dtSim)
    end
  else
    resetOneSideDriftData()
  end
end

-- Drift stunts --
local function onAnyStuntZoneScored()
  addComboCreepUp(scoreOptions.comboOptions.stuntZone.creepUp)
end

local function onDriftThroughDetected(data)
  local score = math.floor(linearScale(data.currDegAngle, 0, 90, 0, data.zoneData.points))
  score = addCachedScore(score, true)
  extensions.hook('onTightDriftScored', score)
end

local function onHitPoleDetected(data)
  local score = math.floor(linearScale(data.currDegAngle + data.currAirSpeed, 0, 250, 0, data.zoneData.points))
  score = addCachedScore(score, true)
  extensions.hook('onHitPoleScored', score)
end

local function onNearPoleDetected(data)
  local score = (data.currDegAngle * data.closeness / 90) ^ 1 * data.zoneData.points
  score = addCachedScore(score, true)
  extensions.hook("onNearPoleScored", score)
end

local function onDonutDriftDetected(data)
  local score = addCachedScore(data.zoneData.points, true)
  extensions.hook('onDonutDriftScored', score)
end

local function onDriftCompleted()
  local addedScore = math.floor(driftScore.cachedScore * driftScore.combo)
  driftScore.score = driftScore.score + addedScore

  extensions.hook('onDriftCompletedScored', addedScore, math.floor(driftScore.cachedScore), driftScore.combo)
  resetCachedScore()
end

local function onDriftStatusChanged(status)
  if status then
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

local function getScoreOptions()
  return scoreOptions
end

local function onDriftPlVehReset()
  resetScore()
end

M.onDriftPlVehReset = onDriftPlVehReset
M.onUpdate = onUpdate

M.onDriftStatusChanged = onDriftStatusChanged
M.onAnyStuntZoneScored = onAnyStuntZoneScored
M.onDriftThroughDetected = onDriftThroughDetected
M.onHitPoleDetected = onHitPoleDetected
M.onDonutDriftDetected = onDonutDriftDetected
M.onDriftCompleted = onDriftCompleted
M.onNearPoleDetected = onNearPoleDetected

M.onDriftCrash = onDriftCrash
M.onDriftSpinout = onDriftSpinout

M.getScore = getScore
M.getScoreOptions = getScoreOptions

M.resetScore = resetScore
return M