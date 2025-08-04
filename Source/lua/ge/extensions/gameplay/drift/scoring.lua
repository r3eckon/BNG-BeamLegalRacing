-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
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
local dtSim
local driftDebugInfo = {
  default = true,
  canBeChanged = true
}

local scoreAddedThisFrameBeforeTier = 0
local scoreAddedThisFrame = 0

local scoreOptions = {
  stuntZones = {
    driftThrough = {basePoints = 300},
    donut = {basePoints = 100},
    hitPole = {basePoints = 300},
    nearPole = {basePoints = 300},
  },
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
  wallTapScore = 200,
  continuousDriftPoints = 0.6,
  comboOptions = {
    stuntZone = {
      creepUp = 140,
      creepLow = 20,
    },
    oneSideDrift = {
      minAngle = 25,
      creepUp = 10,
      creepLow = 5,
      timeToCreepup = 0.1, -- has to drift x seconds to increase creep up.
      maxIncrements = 100  -- how many times can the creepup be increased in a single drift
      --maxIncrements = math.huge -- how many times can the creepup be increased is a single drift
    },
    driftTransition = {
      minTransitionSpeed = 25, -- Below this speed, not earning any combo for transition between drifts
      cooldownTime = 2, -- this is to avoid quick transitions and earn combo too fast
      comboSpeeds = {
        {
          minSpeed = 30,
          maxSpeed = 60,
          creepUp = 100
        },
        {
          minSpeed = 60,
          maxSpeed = 90,
          creepUp = 200
        },
        {
          minSpeed = 90,
          maxSpeed = 120,
          creepUp = 300
        },
        {
          minSpeed = 120,
          maxSpeed = 150,
          creepUp = 400
        },
        {
          minSpeed = 150,
          creepUp = 500
        },
      }
    },
    closeWall = {
      creepUp = 50,
      creepLow = 5,
    },
    increment = 0.1,
    incrementLow = 0.01,
    comboSoftCap = 10,
    comboHardCap = 25,
  }
}

-- tier stuff
local currentTier = 1
local tierTranslationPrefix = "missions.drift.tiers."
local driftTiers = {
  { minScore =     0, continuousScore = 10, id = "drift", order = 1 },
  { minScore =   250, continuousScore = 20, id = "greatDrift" , order = 2},
  { minScore =   750, continuousScore = 30, id = "awesomeDrift" , order = 3},
  { minScore =  2000, continuousScore = 40, id = "superiorDrift" , order = 4},
  { minScore =  5000, continuousScore = 50, id = "epicDrift" , order = 5},
  { minScore =  9000, continuousScore = 60, id = "apexDrift" , order = 6},
  { minScore =  15000, continuousScore = 75, id = "legendaryDrift" , order = 7},
}

local driftScore = {
  score = 0,
  combo = 1,
}

local driftActiveData = {}
local driftOptions = {}

--
local currDriftTimeToCombo = 0
local currDriftIncrement = 0

local lastDriftInitiationTimer = 0
local firstUpdate = true

-- debug score history
local historicScoreTimer = 0
local historicScoresPerSecond = 5
local maxHistory = 50
local historicScore = {}
local plotHelperUtil

-- performance factor stuff
local goodDriftData = {
  closestWallDistanceFront = math.huge,
  closestWallDistanceRear = 1.8,
  currDegAngle = 80,
  airSpeed = 70
}
local driftScoringData = {
  closestWallDistanceFront = 0,
  closestWallDistanceRear = 0,
  currDegAngle = 0,
  airSpeed = 0
}
local veryGoodScore
local performanceFactor = 0 -- 0 - 1
local steppedPerformanceFactor -- from 1 to 4, 1 being a bad drift, 4 being a very good drift


local timeAtPerformance4 = 0
local timeBelowPerformance4 = 0
local hystersisTime = 0.3

-- Add these new variables near the other performance factor variables
local smoothedSteppedPerformanceFactor = 0
local performanceSmoother = newTemporalSmoothing(8, 8) -- Adjust these values to control smoothing speed


local function translateTierNames()
  for id, data in pairs(driftTiers) do
    driftTiers[id].name = translateLanguage(tierTranslationPrefix..data.id, tierTranslationPrefix..data.id, true)
  end
end

local function resetCachedScore()
  driftScore.potentialScore = 0
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
  historicScore = {}
end


local tempArgsTable = {newCombo = 0, comboChange = 0}
local function addComboCreepUp(value, valueLow)
  driftScore.comboCreepup = driftScore.comboCreepup +
    (driftScore.combo < scoreOptions.comboOptions.comboSoftCap and value or valueLow)

  local newCombo = driftScore.combo + math.floor(driftScore.comboCreepup / 100) * scoreOptions.comboOptions.increment
  local newCreepup = driftScore.comboCreepup % 100

  if newCombo <= scoreOptions.comboOptions.comboHardCap then
    if newCombo > driftScore.combo then

      -- FOR GC
      tempArgsTable.newCombo = newCombo
      tempArgsTable.comboChange = newCombo - driftScore.combo
      extensions.hook("onDriftNewCombo", tempArgsTable)
    end
    driftScore.combo = newCombo
    driftScore.comboCreepup = newCreepup
  elseif driftScore.combo < scoreOptions.comboOptions.comboHardCap then
    driftScore.combo = scoreOptions.comboOptions.comboHardCap
    driftScore.comboCreepup = 0
  end
end

local function resetOneSideDriftData()
  currDriftTimeToCombo = 0
  currDriftIncrement = 0
end

local function calculateOneSideDriftCreepUp()
  currDriftTimeToCombo = currDriftTimeToCombo + dtSim
  if currDriftTimeToCombo >= scoreOptions.comboOptions.oneSideDrift.timeToCreepup and currDriftIncrement < scoreOptions.comboOptions.oneSideDrift.maxIncrements and math.abs(gameplay_drift_drift.getCurrDegAngleSigned()) >= scoreOptions.comboOptions.oneSideDrift.minAngle then
    addComboCreepUp(scoreOptions.comboOptions.oneSideDrift.creepUp, scoreOptions.comboOptions.oneSideDrift.creepLow)
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

local scoreRangeResult = {0, 0}
local function getContinuousScore(distSinceLastFrame, driftData)
  driftOptions = gameplay_drift_drift.getDriftOptions()

  wallMulti = 1 + linearScale(driftData.closestWallDistanceFront, driftOptions.wallDetectionLength, 0, 0, scoreOptions.maxWallMulti) + linearScale(driftData.closestWallDistanceRear, driftOptions.wallDetectionLength, 0, 0, scoreOptions.maxWallMulti)
  angleMulti = linearScale(driftData.currDegAngle, driftOptions.minAngle, driftOptions.maxAngle, scoreOptions.minDriftAngleMulti, scoreOptions.maxDriftAngleMulti)
  speedMulti = math.min(math.max(1, linearScale(driftData.airSpeed, minSpeed, maxSpeed, 1, scoreOptions.maxSpeedMulti) ), scoreOptions.maxSpeedMulti)

  continuousScore = scoreOptions.continuousDriftPoints
  if gameplay_drift_stallingSystem then
    continuousScore = gameplay_drift_stallingSystem.calculateScore(continuousScore)
  end

  local scoreBeforeTier = angleMulti * speedMulti * wallMulti * distSinceLastFrame * continuousScore

  scoreRangeResult[1] = scoreBeforeTier
  scoreRangeResult[2] = scoreBeforeTier + driftTiers[currentTier].continuousScore * dtSim
  return scoreRangeResult
end

local tempScore
local function scoreContinuousDrift(distSinceLastFrame, driftData)
  tempScore = getContinuousScore(distSinceLastFrame, driftData)
  scoreAddedThisFrameBeforeTier = tempScore[1]
  scoreAddedThisFrame = tempScore[2]

  addCachedScore(scoreAddedThisFrame)
end

local function imguiDebug(dtReal)
  if isBeingDebugged then
    if im.Begin("Drift score") then
      im.Text(string.format("Score : %i", driftScore.score))
      im.Text(string.format("Cached score : %i", driftScore.cachedScore))
      im.Text(string.format("Potential score : %i", driftScore.potentialScore))
      im.Text(string.format("Combo : %0.2f Combo creep up : %d", driftScore.combo, driftScore.comboCreepup))
      im.Text(string.format("Current perfomance factor : %0.2f (%i) | Very good drift score : %0.2f", performanceFactor, steppedPerformanceFactor, veryGoodScore))

      if driftTiers[currentTier] then
        local nextTierScore = "None"
        if currentTier + 1 <= #driftTiers then
          nextTierScore = driftTiers[currentTier + 1].minScore
        end
        im.Text("Tier : " .. driftTiers[currentTier].name .. " ("..(currentTier)..") Next : " .. nextTierScore .. " points")
      end
      im.BeginChild1("Data", im.ImVec2(im.GetContentRegionAvailWidth() / 100 * 65, 300), true)
        -- debug graph
        plotHelperUtil = plotHelperUtil or require('/lua/ge/extensions/editor/util/plotHelperUtil')()
        local data = {{},{},{},{}}
        for i = 1, #historicScore do
          data[1][i], data[2][i], data[3][i], data[4][i] = {i,historicScore[i][1]},{i, historicScore[i][2]}, {i, historicScore[i][3]}, {i, historicScore[i][4]}
        end
        plotHelperUtil:setDataMulti(data)
        plotHelperUtil:scaleToFitData()
        plotHelperUtil:setScale(nil, nil, 0, nil)
        plotHelperUtil:draw(im.GetContentRegionAvailWidth(), im.GetContentRegionAvail().y, 400)
      im.EndChild()
      im.SameLine()
      im.BeginChild1("Legend", im.ImVec2(im.GetContentRegionAvailWidth(), 300), true)
      im.PushStyleColor2(im.Col_Text, im.ImVec4(1, 1, 0.1, 1))
        im.TextWrapped("-Combo")
      im.PopStyleColor()
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.2, 1, 0.1, 1))
        im.TextWrapped("-Curr. tier bonus score x10")
      im.PopStyleColor()
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.1, 0.3, 1, 1))
        im.TextWrapped("-Score per frame without tier x10")
      im.PopStyleColor()
      im.PushStyleColor2(im.Col_Text, im.ImVec4(1, 0.1, 0.1, 1))
        im.TextWrapped("-Score per frame with tier x10")
      im.PopStyleColor()
      im.EndChild()

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
          historicScoreTimer = historicScoreTimer + dtSim * historicScoresPerSecond
          if historicScoreTimer > 1 then
            table.insert(historicScore, 1, {scoreAddedThisFrameBeforeTier * 10, driftTiers[currentTier].continuousScore * dtSim * 10, driftScore.combo, scoreAddedThisFrame * 10})
            historicScore[maxHistory] = nil
            historicScoreTimer = historicScoreTimer - 1
          end
        end

        im.Text(string.format("Score added this frame : %0.2f", scoreAddedThisFrame))
        im.Text(string.format("Wall multi this frame : %0.2f", wallMulti))
        im.Text(string.format("Speed multi this frame : %0.2f", speedMulti))
        im.Text(string.format("Angle multi this frame : %0.2f", angleMulti))
      else
        im.PushStyleColor2(im.Col_Text, imVec4Yellow)
        im.Text("Drift to see scoring information")
        im.PopStyleColor()
      end
    end
  end
end

local function calculateBasePerformanceFactor()
  tempScore = getContinuousScore(0.15, goodDriftData) -- here we simulate a good drift score
  veryGoodScore = tempScore[2]
end

local function calculatePerformanceFactor()
  performanceFactor = scoreAddedThisFrameBeforeTier / veryGoodScore

  if not gameplay_drift_drift.getIsDrifting() then
    steppedPerformanceFactor = 0
    smoothedSteppedPerformanceFactor = 0
    timeAtPerformance4 = 0
    timeBelowPerformance4 = 0
  else
    if performanceFactor >= 1 then
      timeAtPerformance4 = timeAtPerformance4 + dtSim
      timeBelowPerformance4 = 0
      if timeAtPerformance4 >= hystersisTime then
        steppedPerformanceFactor = 4
      end
    else
      if steppedPerformanceFactor == 4 then
        timeBelowPerformance4 = timeBelowPerformance4 + dtSim
        if timeBelowPerformance4 >= hystersisTime then
          timeAtPerformance4 = 0
        else
          return
        end
      end

      -- Normal calculation
      if performanceFactor >= 2/3 then
        steppedPerformanceFactor = 3
      elseif performanceFactor >= 1/3 then
        steppedPerformanceFactor = 2
      else
        steppedPerformanceFactor = 1
      end
    end

    -- Apply smoothing
    smoothedSteppedPerformanceFactor = performanceSmoother:get(steppedPerformanceFactor, dtSim)
  end
end

local function calculateTier()
  local newTier = 1
  if driftScore.cachedScore and driftScore.cachedScore > 0 then
    for i, t in ipairs(driftTiers) do
      if driftScore.cachedScore >= t.minScore then
        newTier = i
      end
    end
  end

  -- when reaching a new tier ..
  if newTier == currentTier + 1 then
    local tierName = tierTranslationPrefix..tostring(newTier)
    extensions.hook("onNewDriftTierReached",driftTiers[newTier])
  end

  currentTier = newTier
end

local function onUpdate(dtReal, _dtSim)

  -- BEAMLR EDIT START
  if extensions.blrglobals.blrFlagGet("legacyDriftScoring") then return end
  -- END


  dtSim = _dtSim

  if driftScore.cachedScore then
    driftScore.potentialScore = math.floor(driftScore.cachedScore * driftScore.combo)
  end

  if firstUpdate then
    translateTierNames()
    calculateBasePerformanceFactor()
    firstUpdate = false
  end
  lastDriftInitiationTimer = lastDriftInitiationTimer + dtSim

  isBeingDebugged = gameplay_drift_general.getExtensionDebug("gameplay_drift_scoring")
  imguiDebug(dtReal)
  if gameplay_drift_general.getGeneralDebug() then profiler:start() end

  calculateTier()
  calculatePerformanceFactor()

  if gameplay_drift_general.getPaused() then return end

  driftActiveData = gameplay_drift_drift.getDriftActiveData()

  if gameplay_drift_drift.getIsDrifting() then
    if not gameplay_drift_general.getFrozen() then
      calculateOneSideDriftCreepUp()
      driftScoringData.closestWallDistanceFront = driftActiveData.closestWallDistanceFront
      driftScoringData.closestWallDistanceRear = driftActiveData.closestWallDistanceRear
      driftScoringData.currDegAngle = driftActiveData.currDegAngle
      driftScoringData.airSpeed = gameplay_drift_drift.getAirSpeed()
      scoreContinuousDrift(gameplay_drift_drift.getDistSinceLastFrame(), driftScoringData)
    end
  else
    resetOneSideDriftData()
    scoreAddedThisFrameBeforeTier = 0
    scoreAddedThisFrame = 0
  end

  if gameplay_drift_general.getGeneralDebug() then
    profiler:add("Drift scoring")
    gc = profiler.sections[1].garbage
    profiler:finish(false)
  end
end

-- Drift stunts --
local function onAnyStuntZoneAccomplished()
  addComboCreepUp(scoreOptions.comboOptions.stuntZone.creepUp, scoreOptions.comboOptions.stuntZone.creepLow)
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
  -- todo: remove beamXP
  local beamXP = math.ceil(addedScore * scoreOptions.careerRewards.scoreMulForXp)
  return {
    --beamXP = beamXP
  }
end

-- finished a whole drift chain
local function onDriftCompleted()
  local combo = driftScore.combo
  local addedScore = wrapUp()
  if not addedScore then return end

  extensions.hook('onDriftCompletedScored',
    {
      addedScore = addedScore,
      combo = combo,
      careerRewards = getCareerRewardsForDriftScore(addedScore),
      tier = driftTiers[currentTier]
    }
  )
end

local function getComboCreepupSpeedValue(speed, comboSpeeds)
  if not comboSpeeds or #comboSpeeds == 0 then return 0 end

  -- If speed is above last entry, return last value
  if speed >= comboSpeeds[#comboSpeeds].minSpeed then
    return comboSpeeds[#comboSpeeds].creepUp
  end

  -- Find the matching speed bracket and return its value
  for i = 1, #comboSpeeds - 1 do
    if speed >= comboSpeeds[i].minSpeed and speed < comboSpeeds[i + 1].minSpeed then
      return comboSpeeds[i].creepUp
    end
  end

  return 0
end

-- this is combo when doing drift transitions
local function onDriftTransition()
  if gameplay_drift_drift.getAirSpeed() > scoreOptions.comboOptions.driftTransition.minTransitionSpeed and lastDriftInitiationTimer >= scoreOptions.comboOptions.driftTransition.cooldownTime then
    local speed = gameplay_drift_drift.getAirSpeed()
    local creepUp = getComboCreepupSpeedValue(speed, scoreOptions.comboOptions.driftTransition.comboSpeeds)
    local creepLow = creepUp / 2
    addComboCreepUp(creepUp, creepLow)
  end
  lastDriftInitiationTimer = 0
end

local function onDriftFailed()
  resetCachedScore()
end

local function onDriftCrash()
  onDriftFailed()
end

local function onDriftSpinout()
  onDriftFailed()
end

local function getScore()
  return driftScore
end

local function getPotentialScore()
  return driftScore.potentialScore
end

local function getDriftPerformanceFactor()
  return performanceFactor
end

local function getScoreAddedThisFrame()
  return scoreAddedThisFrame
end

local function getDriftDebugInfo()
  return driftDebugInfo
end

local function getDriftTiers()
  return driftTiers
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

local function onDriftChainStarted()
  extensions.hook("onNewDriftTierReached",driftTiers[1])
end

local function getCurrentDriftTier()
  return driftTiers[currentTier]
end

local function getStuntZoneBasePoints(stuntZoneType)
  return scoreOptions.stuntZones[stuntZoneType].basePoints
end

local function onDeserialized(data)
  scoreExperiment = im.BoolPtr(data.scoreExperiment or false)
end


local function getSteppedDriftPerformanceFactor()
  return smoothedSteppedPerformanceFactor
end

M.onDriftPlVehReset = onDriftPlVehReset
M.onUpdate = onUpdate
M.onSerialize = onSerialize
M.onDeserialized = onDeserialized

M.onDriftTransition = onDriftTransition
M.onAnyStuntZoneAccomplished = onAnyStuntZoneAccomplished
M.onDriftThroughAccomplished = onDriftThroughAccomplished
M.onHitPoleAccomplished = onHitPoleAccomplished
M.onDonutDriftAccomplished = onDonutDriftAccomplished
M.onDriftCompleted = onDriftCompleted
M.onNearPoleAccomplished = onNearPoleAccomplished
M.onDriftChainStarted = onDriftChainStarted

M.onDriftCrash = onDriftCrash
M.onDriftSpinout = onDriftSpinout

M.getScore = getScore
M.getScoreOptions = getScoreOptions
M.getPotentialScore = getPotentialScore
M.getScoreAddedThisFrame = getScoreAddedThisFrame
M.getStuntZoneBasePoints = getStuntZoneBasePoints
M.getDriftDebugInfo = getDriftDebugInfo
M.getGC = getGC
M.getDriftTiers = getDriftTiers
M.getDriftPerformanceFactor = getDriftPerformanceFactor
M.getSteppedDriftPerformanceFactor = getSteppedDriftPerformanceFactor
M.getCurrentDriftTier = getCurrentDriftTier

M.reset = reset
M.wrapUp = wrapUp
M.wrapUpWithText = wrapUpWithText
M.addCachedScore = addCachedScore

return M