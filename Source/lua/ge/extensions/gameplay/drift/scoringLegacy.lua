local M = {}
local im = ui_imgui
local extensions = require("extensions")

-- BEAMLR LEGACY SCORING SCRIPT

local stallingOptions = {
  maxOneSideDriftIncrement = 3 -- how many times can the combo be increased is a single drift
}

local scoreOptions = {
  minDriftAngleMulti = 1,
  maxDriftAngleMulti = 3,
  minWallMulti = 1,
  maxWallMulti = 5,
  minSpeedMulti = 0.5,
  maxSpeedMulti = 2,
  maxCombo = 5,
  maxTightDriftScore = 1500,
  donutScore = 500,
  wallTapScore = 200,
  continuousDriftPoints = 10,
  comboOptions = {
    increment = 0.2,
    maxCombo = 5,
    driftTimeToCombo = 1.50 -- has to drift x seconds to increase combo.
  }
}
local driftScore = {}
local driftActiveData = {}
local driftOptions = {}

--
local currDriftTimeToCombo = 0
local currDriftIncrement = 0
local scoreAddedThisFrame = 0

local function resetCachedScore()
  driftScore.cachedScore = 0
  driftScore.combo = 1
  extensions.hook("onDriftCachedScoreReset")
end

local function resetScore()
  driftScore = {
    score = 0,
  }
  resetCachedScore()
end


local function resetSingleDriftData()
  currDriftTimeToCombo = 0
  currDriftIncrement = 0
end

local function calculateDriftCombo(dtSim)
  currDriftTimeToCombo = currDriftTimeToCombo + dtSim
  if currDriftTimeToCombo >= scoreOptions.comboOptions.driftTimeToCombo and currDriftIncrement < stallingOptions.maxOneSideDriftIncrement then
    local potentialScore = driftScore.combo + scoreOptions.comboOptions.increment
    if potentialScore <= scoreOptions.comboOptions.maxCombo + 0.01 then
      driftScore.combo = potentialScore
    end
    currDriftTimeToCombo = 0
    currDriftIncrement = currDriftIncrement + 1
  end
end

local function addCachedScore(valueToAdd)
  if gameplay_drift_general.getFrozen() then return end

  driftScore.cachedScore = driftScore.cachedScore +  valueToAdd
end

local minSpeed = 20 --min speed at which the speedMulti factor starts increasing
local maxSpeed = 200 --speed at which the speedMulti factor stops increasing
local wallMulti
local speedMulti
local driftAngleScore
local function scoreContinuousDrift(dtSim)
  wallMulti = 1 + linearScale(driftActiveData.closestWallDistanceFront, driftOptions.wallDetectionLength, 0, scoreOptions.minWallMulti, scoreOptions.maxWallMulti) + linearScale(driftActiveData.closestWallDistanceRear, driftOptions.wallDetectionLength, 0, scoreOptions.minWallMulti, scoreOptions.maxWallMulti)
  driftAngleScore = linearScale(driftActiveData.currDegAngle, driftOptions.minAngle, driftOptions.maxAngle, scoreOptions.minDriftAngleMulti, scoreOptions.maxDriftAngleMulti)
  speedMulti = math.min(math.max(1, linearScale(gameplay_drift_drift.getAirSpeed(), minSpeed, maxSpeed, scoreOptions.minSpeedMulti, scoreOptions.maxSpeedMulti) ), scoreOptions.maxSpeedMulti)

  scoreAddedThisFrame = driftAngleScore * speedMulti * wallMulti * dtSim * scoreOptions.continuousDriftPoints
  addCachedScore(scoreAddedThisFrame)
end

local function onUpdate(dtReal, dtSim)

  if not extensions.blrglobals.blrFlagGet("legacyDriftScoring") then return end
  
  if gameplay_drift_general.getContext() == "stopped" then return end

  driftActiveData = gameplay_drift_drift.getDriftActiveData()
  driftOptions = gameplay_drift_drift.getDriftOptions()

  if gameplay_drift_drift.getIsDrifting() then
    if not gameplay_drift_general.getFrozen() then
      calculateDriftCombo(dtSim)
      scoreContinuousDrift(dtSim)
    end
  else
    resetSingleDriftData()
  end
end

-- Drift stunts --

local function onDriftThroughDetected(degAngle)
  local score = math.floor(linearScale(degAngle, 0, 90, 0, scoreOptions.maxTightDriftScore))

  addCachedScore(score)
  extensions.hook('onTightDriftScored', score)

end

local function onDonutDriftDetected()
  addCachedScore(scoreOptions.donutScore)

  extensions.hook('onDonutDriftScore', scoreOptions.donutScore)
end

local function onDriftCompleted()
  local addedScore = math.floor(driftScore.cachedScore * driftScore.combo)
  driftScore.score = driftScore.score + addedScore
  
  -- 1.17.2 modified for compatibility with new drift scripts
  local data = {}
  data.addedScore = addedScore
  data.cachedScore = driftScore.cachedScore
  data.combo = driftScore.combo
  extensions.hook('onDriftCompletedScored', data)
  
  resetCachedScore()
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
  driftScore.comboCreepup = 0 -- Added in 1.17.2 for compatibility with new drift display script
  return driftScore
end

local function onDriftPlVehReset()
  resetScore()
end

-- Added in 1.17.2 for compatibility with new drift display script
local function getScoreOptions() 
return scoreOptions
end

-- Added in 1.17.2 for compatibility with new drift display script
local function getScoreAddedThisFrame()
return scoreAddedThisFrame
end

M.getScoreOptions = getScoreOptions
M.getScoreAddedThisFrame = getScoreAddedThisFrame


M.onDriftPlVehReset = onDriftPlVehReset
M.onUpdate = onUpdate
M.onDriftThroughDetected = onDriftThroughDetected
M.onDonutDriftDetected = onDonutDriftDetected
M.onDriftCompleted = onDriftCompleted
M.onDriftCrash = onDriftCrash
M.onDriftSpinout = onDriftSpinout

M.getScore = getScore
M.resetScore = resetScore
return M