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
local debugToggleSmothnessGraph = im.BoolPtr(false)
local isBeingDebugged

local profiler = LuaProfiler("drift scoring profiler")
local gc
local dtSim
local driftDebugInfo = {
  default = true,
  canBeChanged = true
}

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
      timeToCreepup = 0.1,
      maxIncrements = 100
    },
    driftTransition = {
      minTransitionSpeed = 25,
      cooldownTime = 2,
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

-- performance factor reference data
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

-- debug score history
local historicScoreTimer = 0
local historicScoresPerSecond = 5
local maxHistory = 50
local historicScore = {}
local plotHelperUtil

local firstUpdate = true

local minSpeed = 22
local maxSpeed = 200

local scoreStates = {} -- keyed by vehId
local frozenVehicles = {} -- vehId -> true when that vehicle's scoring is individually frozen

local function newVehicleScoreState(vehId)
  return {
    vehId = vehId,
    driftScore = {
      score = 0,
      combo = 1,
      cachedScore = 0,
      potentialScore = 0,
      comboCreepup = 0,
    },
    currentTier = 1,
    performanceFactor = 0,
    steppedPerformanceFactor = 0,
    smoothedSteppedPerformanceFactor = 0,
    performanceSmoother = newTemporalSmoothing(8, 8),
    timeAtPerformance4 = 0,
    timeBelowPerformance4 = 0,
    scoreAddedThisFrameBeforeTier = 0,
    scoreAddedThisFrame = 0,
    currDriftTimeToCombo = 0,
    currDriftIncrement = 0,
    lastDriftInitiationTimer = 0,
    lastScoreState = {score = 0, potentialScore = 0, combo = 1},
  }
end

local function getScoreState(vehId)
  if vehId and scoreStates[vehId] then return scoreStates[vehId] end
  -- default: player 0
  local plVehId = be:getPlayerVehicleID(0)
  if plVehId and scoreStates[plVehId] then return scoreStates[plVehId] end
  -- fallback: return any
  for _, state in pairs(scoreStates) do return state end
  return nil
end

local function ensureScoreState(vehId)
  if not vehId then return nil end
  if not scoreStates[vehId] then
    scoreStates[vehId] = newVehicleScoreState(vehId)
  end
  return scoreStates[vehId]
end

--------------------------------------------------

local hystersisTime = 0.3

local function translateTierNames()
  for id, data in pairs(driftTiers) do
    driftTiers[id].name = _tr(tierTranslationPrefix..data.id, tierTranslationPrefix..data.id, true)
  end
end

local function resetCachedScore(ss)
  ss.driftScore.potentialScore = 0
  ss.driftScore.cachedScore = 0
  ss.driftScore.combo = 1
  ss.driftScore.comboCreepup = 0
  extensions.hook("onDriftCachedScoreReset", ss.vehId)
end

local function resetScoreState(ss)
  ss.driftScore = {
    score = 0,
    combo = 1,
    cachedScore = 0,
    potentialScore = 0,
    comboCreepup = 0,
  }
  ss.lastDriftInitiationTimer = 0
  ss.lastScoreState = {score = 0, potentialScore = 0, combo = 1}
  ss.currentTier = 1
  ss.performanceFactor = 0
  ss.steppedPerformanceFactor = 0
  ss.smoothedSteppedPerformanceFactor = 0
  ss.timeAtPerformance4 = 0
  ss.timeBelowPerformance4 = 0
  ss.scoreAddedThisFrameBeforeTier = 0
  ss.scoreAddedThisFrame = 0
  ss.currDriftTimeToCombo = 0
  ss.currDriftIncrement = 0
end

local function reset(vehId)
  if vehId then
    local ss = scoreStates[vehId]
    if ss then resetScoreState(ss) end
  else
    for _, ss in pairs(scoreStates) do
      resetScoreState(ss)
    end
  end
  historicScore = {}
end

local function onVehicleDestroyed(vehId)
  scoreStates[vehId] = nil
  frozenVehicles[vehId] = nil
end

local function onClientEndMission()
  table.clear(scoreStates)
  table.clear(frozenVehicles)
end

local tempArgsTable = {newCombo = 0, comboChange = 0}
local function addComboCreepUp(ss, value, valueLow)
  ss.driftScore.comboCreepup = ss.driftScore.comboCreepup +
    (ss.driftScore.combo < scoreOptions.comboOptions.comboSoftCap and value or valueLow)

  local newCombo = ss.driftScore.combo + math.floor(ss.driftScore.comboCreepup / 100) * scoreOptions.comboOptions.increment
  local newCreepup = ss.driftScore.comboCreepup % 100

  if newCombo <= scoreOptions.comboOptions.comboHardCap then
    if newCombo > ss.driftScore.combo then
      tempArgsTable.newCombo = newCombo
      tempArgsTable.comboChange = newCombo - ss.driftScore.combo
      extensions.hook("onDriftNewCombo", tempArgsTable, ss.vehId)
    end
    ss.driftScore.combo = newCombo
    ss.driftScore.comboCreepup = newCreepup
  elseif ss.driftScore.combo < scoreOptions.comboOptions.comboHardCap then
    ss.driftScore.combo = scoreOptions.comboOptions.comboHardCap
    ss.driftScore.comboCreepup = 0
  end
end

local function resetOneSideDriftData(ss)
  ss.currDriftTimeToCombo = 0
  ss.currDriftIncrement = 0
end

local function calculateOneSideDriftCreepUp(ss)
  ss.currDriftTimeToCombo = ss.currDriftTimeToCombo + dtSim
  if ss.currDriftTimeToCombo >= scoreOptions.comboOptions.oneSideDrift.timeToCreepup and ss.currDriftIncrement < scoreOptions.comboOptions.oneSideDrift.maxIncrements and math.abs(gameplay_drift_drift.getCurrDegAngleSigned(ss.vehId)) >= scoreOptions.comboOptions.oneSideDrift.minAngle then
    addComboCreepUp(ss, scoreOptions.comboOptions.oneSideDrift.creepUp, scoreOptions.comboOptions.oneSideDrift.creepLow)
    ss.currDriftTimeToCombo = 0
    ss.currDriftIncrement = ss.currDriftIncrement + 1
  end
end

local function addCachedScore(valueToAdd, useStallingSystem, vehId)
  local ss = getScoreState(vehId)
  if not ss then return 0 end

  if useStallingSystem == nil then
    useStallingSystem = false
  end
  if gameplay_drift_general.getFrozen() then return 0 end
  if frozenVehicles[vehId or (ss and ss.vehId)] then return 0 end

  if useStallingSystem then
    if gameplay_drift_stallingSystem then
      valueToAdd = gameplay_drift_stallingSystem.calculateScore(valueToAdd)
    end
    valueToAdd = math.floor(valueToAdd)
  end
  ss.driftScore.cachedScore = ss.driftScore.cachedScore + valueToAdd

  return valueToAdd
end

local wallMulti
local speedMulti
local angleMulti
local continuousScore

local scoreRangeResult = {0, 0}
local function getContinuousScore(distSinceLastFrame, driftData)
  local driftOptions = gameplay_drift_drift.getDriftOptions()

  wallMulti = 1 + linearScale(driftData.closestWallDistanceFront, driftOptions.wallDetectionLength, 0, 0, scoreOptions.maxWallMulti) + linearScale(driftData.closestWallDistanceRear, driftOptions.wallDetectionLength, 0, 0, scoreOptions.maxWallMulti)
  angleMulti = linearScale(driftData.currDegAngle, driftOptions.minAngle, driftOptions.maxAngle, scoreOptions.minDriftAngleMulti, scoreOptions.maxDriftAngleMulti)
  speedMulti = math.min(math.max(1, linearScale(driftData.airSpeed, minSpeed, maxSpeed, 1, scoreOptions.maxSpeedMulti) ), scoreOptions.maxSpeedMulti)

  continuousScore = scoreOptions.continuousDriftPoints
  if gameplay_drift_stallingSystem then
    continuousScore = gameplay_drift_stallingSystem.calculateScore(continuousScore)
  end

  local scoreBeforeTier = angleMulti * speedMulti * wallMulti * distSinceLastFrame * continuousScore

  scoreRangeResult[1] = scoreBeforeTier
  -- tier bonus uses the active vehicle's current tier
  return scoreRangeResult
end

local function scoreContinuousDrift(ss, distSinceLastFrame, driftData)
  local tempScore = getContinuousScore(distSinceLastFrame, driftData)
  ss.scoreAddedThisFrameBeforeTier = tempScore[1]
  ss.scoreAddedThisFrame = tempScore[1] + driftTiers[ss.currentTier].continuousScore * dtSim

  ss.driftScore.cachedScore = ss.driftScore.cachedScore + ss.scoreAddedThisFrame
end

local function calculateBasePerformanceFactor()
  local tempScore = getContinuousScore(0.15, goodDriftData)
  veryGoodScore = tempScore[1] + driftTiers[1].continuousScore * dtSim
end

local function calculatePerformanceFactor(ss)
  ss.performanceFactor = ss.scoreAddedThisFrameBeforeTier / veryGoodScore

  if not gameplay_drift_drift.getIsDrifting(ss.vehId) then
    ss.steppedPerformanceFactor = 0
    ss.performanceFactor = 0
    ss.smoothedSteppedPerformanceFactor = 0
    ss.timeAtPerformance4 = 0
    ss.timeBelowPerformance4 = 0
  else
    if ss.performanceFactor >= 1 then
      ss.timeAtPerformance4 = ss.timeAtPerformance4 + dtSim
      ss.timeBelowPerformance4 = 0
      if ss.timeAtPerformance4 >= hystersisTime then
        ss.steppedPerformanceFactor = 4
      end
    else
      if ss.steppedPerformanceFactor == 4 then
        ss.timeBelowPerformance4 = ss.timeBelowPerformance4 + dtSim
        if ss.timeBelowPerformance4 >= hystersisTime then
          ss.timeAtPerformance4 = 0
        else
          return
        end
      end

      if ss.performanceFactor >= 2/3 then
        ss.steppedPerformanceFactor = 3
      elseif ss.performanceFactor >= 1/3 then
        ss.steppedPerformanceFactor = 2
      else
        ss.steppedPerformanceFactor = 1
      end
    end

    ss.smoothedSteppedPerformanceFactor = ss.performanceSmoother:get(ss.steppedPerformanceFactor, dtSim)
  end
end

local function calculateTier(ss)
  local newTier = 1
  if ss.driftScore.cachedScore and ss.driftScore.cachedScore > 0 then
    for i, t in ipairs(driftTiers) do
      if ss.driftScore.cachedScore >= t.minScore then
        newTier = i
      end
    end
  end

  if newTier == ss.currentTier + 1 then
    extensions.hook("onNewDriftTierReached", driftTiers[newTier], ss.vehId)
  end

  ss.currentTier = newTier
end

local function checkIfScoreChanged(ss)
  if ss.driftScore.score ~= ss.lastScoreState.score or
    ss.driftScore.potentialScore ~= ss.lastScoreState.potentialScore or
    ss.driftScore.combo ~= ss.lastScoreState.combo then
    ss.lastScoreState.score = ss.driftScore.score
    ss.lastScoreState.potentialScore = ss.driftScore.potentialScore
    ss.lastScoreState.combo = ss.driftScore.combo
    extensions.hook("onDriftScoreChanged", ss.driftScore, ss.vehId)
  end
end

local function imguiDebug(dtReal)
  if not isBeingDebugged then return end
  local ss = getScoreState()
  if not ss then return end

  if im.Begin("Drift score") then
    im.Text(string.format("Score : %i", ss.driftScore.score))
    im.Text(string.format("Cached score : %i", ss.driftScore.cachedScore))
    im.Text(string.format("Potential score : %i", ss.driftScore.potentialScore))
    im.Text(string.format("Combo : %0.2f Combo creep up : %d", ss.driftScore.combo, ss.driftScore.comboCreepup))
    im.Text(string.format("Current perfomance factor : %0.2f (%i) | Very good drift score : %0.2f", ss.performanceFactor, ss.steppedPerformanceFactor, veryGoodScore or 0))
    im.Text(string.format("Score states count : %d", tableSize(scoreStates)))

    if driftTiers[ss.currentTier] then
      local nextTierScore = "None"
      if ss.currentTier + 1 <= #driftTiers then
        nextTierScore = driftTiers[ss.currentTier + 1].minScore
      end
      im.Text("Tier : " .. driftTiers[ss.currentTier].name .. " ("..(ss.currentTier)..") Next : " .. nextTierScore .. " points")
    end
    im.Checkbox("Toggle Score Graph", debugToggleSmothnessGraph)
    if debugToggleSmothnessGraph[0] then
    im.BeginChild1("Data", im.ImVec2(im.GetContentRegionAvailWidth() / 100 * 65, 300), true)
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
    end

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
    if gameplay_drift_drift.getIsDrifting(ss.vehId) then
      if not gameplay_drift_general.getFrozen() then
        historicScoreTimer = historicScoreTimer + dtSim * historicScoresPerSecond
        if historicScoreTimer > 1 then
          table.insert(historicScore, 1, {ss.scoreAddedThisFrameBeforeTier * 10, driftTiers[ss.currentTier].continuousScore * dtSim * 10, ss.driftScore.combo, ss.scoreAddedThisFrame * 10})
          historicScore[maxHistory] = nil
          historicScoreTimer = historicScoreTimer - 1
        end
      end

      im.Text(string.format("Score added this frame : %0.2f", ss.scoreAddedThisFrame))
      im.Text(string.format("Wall multi this frame : %0.2f", wallMulti or 0))
      im.Text(string.format("Speed multi this frame : %0.2f", speedMulti or 0))
      im.Text(string.format("Angle multi this frame : %0.2f", angleMulti or 0))
    else
      im.PushStyleColor2(im.Col_Text, imVec4Yellow)
      im.Text("Drift to see scoring information")
      im.PopStyleColor()
    end
  end
  im.End()
end

local function updateScoreState(ss, dtReal)
  if ss.driftScore.cachedScore then
    ss.driftScore.potentialScore = math.floor(ss.driftScore.cachedScore * ss.driftScore.combo)
  end

  checkIfScoreChanged(ss)
  ss.lastDriftInitiationTimer = ss.lastDriftInitiationTimer + dtSim

  calculateTier(ss)
  calculatePerformanceFactor(ss)

  if gameplay_drift_general.getPaused() or dtSim <= 0 then return end

  local driftActiveData = gameplay_drift_drift.getDriftActiveData(ss.vehId)

  if gameplay_drift_drift.getIsDrifting(ss.vehId) then
    if not gameplay_drift_general.getFrozen() and not frozenVehicles[ss.vehId] then
      calculateOneSideDriftCreepUp(ss)
      driftScoringData.closestWallDistanceFront = driftActiveData.closestWallDistanceFront
      driftScoringData.closestWallDistanceRear = driftActiveData.closestWallDistanceRear
      driftScoringData.currDegAngle = driftActiveData.currDegAngle
      driftScoringData.airSpeed = gameplay_drift_drift.getAirSpeed(ss.vehId)
      scoreContinuousDrift(ss, gameplay_drift_drift.getDistSinceLastFrame(ss.vehId), driftScoringData)
    end
  else
    resetOneSideDriftData(ss)
    ss.scoreAddedThisFrameBeforeTier = 0
    ss.scoreAddedThisFrame = 0
  end
end

local function onUpdate(dtReal, _dtSim)

  -- BEAMLR EDIT START
  if extensions.blrglobals.blrFlagGet("legacyDriftScoring") then return end
  -- END

  dtSim = _dtSim

  if firstUpdate then
    translateTierNames()
    -- dtSim may be 0 on very first frame; use a safe default for base perf calc
    if dtSim <= 0 then dtSim = 1/60 end
    calculateBasePerformanceFactor()
    firstUpdate = false
  end

  isBeingDebugged = gameplay_drift_general.getExtensionDebug("gameplay_drift_scoring")
  imguiDebug(dtReal)
  if gameplay_drift_general.getGeneralDebug() then profiler:start() end

  -- ensure score states exist for all tracked vehicles
  local tracked = gameplay_drift_drift.getTrackedVehicles()
  if tracked then
    for vehId, _ in pairs(tracked) do
      ensureScoreState(vehId)
    end
  end

  for _, ss in pairs(scoreStates) do
    updateScoreState(ss, dtReal)
  end

  if gameplay_drift_general.getGeneralDebug() then
    profiler:add("Drift scoring")
    gc = profiler.sections[1].garbage
    profiler:finish(false)
  end
end

-- Drift stunts --
local function onAnyStuntZoneAccomplished(vehId)
  local ss = getScoreState(vehId)
  if ss then
    addComboCreepUp(ss, scoreOptions.comboOptions.stuntZone.creepUp, scoreOptions.comboOptions.stuntZone.creepLow)
  end
end

local function onDriftThroughAccomplished(data)
  local vehId = data.vehId
  local score = math.floor(linearScale(data.currDegAngle, 0, 90, 0, data.zoneData.points))
  score = addCachedScore(score, true, vehId)
  extensions.hook('onTightDriftScored', score, vehId)
end

local function onHitPoleAccomplished(data)
  local vehId = data.vehId
  local score = math.floor(linearScale(data.currDegAngle + data.currAirSpeed, 0, 250, 0, data.zoneData.points))
  score = addCachedScore(score, true, vehId)
  extensions.hook('onHitPoleScored', score, vehId)
end

local function onNearPoleAccomplished(data)
  local vehId = data.vehId
  local score = math.floor((data.currDegAngle * data.closeness / 90) ^ 1 * data.zoneData.points)
  score = addCachedScore(score, true, vehId)
  extensions.hook("onNearPoleScored", score, vehId)
end

local function onDonutDriftAccomplished(data)
  local vehId = data.vehId
  local score = addCachedScore(data.zoneData.points, true, vehId)
  extensions.hook('onDonutDriftScored', score, vehId)
end

local function wrapUp(vehId)
  local ss = getScoreState(vehId)
  if not ss then return false end

  local addedScore = math.floor(ss.driftScore.cachedScore * ss.driftScore.combo)
  if addedScore < 1 then return false end

  ss.driftScore.score = ss.driftScore.score + addedScore
  resetCachedScore(ss)
  return addedScore
end

local function wrapUpWithText(vehId)
  -- callers may omit vehId (single player), so resolve it before announcing: consumers
  -- key their own per-vehicle state off it and can't re-resolve a nil
  local ss = getScoreState(vehId)
  local addedScore = wrapUp(vehId)
  if addedScore then
    extensions.hook("onDriftScoreWrappedUp", addedScore, ss and ss.vehId or vehId)
  end
  return addedScore
end

local function getCareerRewardsForDriftScore(addedScore)
  if addedScore < scoreOptions.careerRewards.minScore then return end
  local beamXP = math.ceil(addedScore * scoreOptions.careerRewards.scoreMulForXp)
  return {}
end

local function onDriftCompleted(data)
  local vehId = data and data.vehId
  local ss = getScoreState(vehId)
  if not ss then return end

  local combo = ss.driftScore.combo
  local addedScore = wrapUp(vehId)
  if not addedScore then return end

  extensions.hook('onDriftCompletedScored',
    {
      addedScore = addedScore,
      combo = combo,
      careerRewards = getCareerRewardsForDriftScore(addedScore),
      tier = driftTiers[ss.currentTier],
      vehId = vehId
    }
  )
end

local function getComboCreepupSpeedValue(speed, comboSpeeds)
  if not comboSpeeds or #comboSpeeds == 0 then return 0 end

  if speed >= comboSpeeds[#comboSpeeds].minSpeed then
    return comboSpeeds[#comboSpeeds].creepUp
  end

  for i = 1, #comboSpeeds - 1 do
    if speed >= comboSpeeds[i].minSpeed and speed < comboSpeeds[i + 1].minSpeed then
      return comboSpeeds[i].creepUp
    end
  end

  return 0
end

local function onDriftTransition(vehId)
  local ss = getScoreState(vehId)
  if not ss then return end

  if gameplay_drift_drift.getAirSpeed(vehId) > scoreOptions.comboOptions.driftTransition.minTransitionSpeed and ss.lastDriftInitiationTimer >= scoreOptions.comboOptions.driftTransition.cooldownTime then
    local speed = gameplay_drift_drift.getAirSpeed(vehId)
    local creepUp = getComboCreepupSpeedValue(speed, scoreOptions.comboOptions.driftTransition.comboSpeeds)
    local creepLow = creepUp / 2
    addComboCreepUp(ss, creepUp, creepLow)
  end
  ss.lastDriftInitiationTimer = 0
end

local function onDriftFailed(vehId)
  local ss = getScoreState(vehId)
  if ss then resetCachedScore(ss) end
end

local function onDriftCrash(vehId)
  onDriftFailed(vehId)
end

local function onDriftSpinout(vehId)
  onDriftFailed(vehId)
end

local function getScore(vehId)
  -- when a specific vehicle is asked for, never fall back to another vehicle's score
  local ss
  if vehId then
    ss = scoreStates[vehId]
  else
    ss = getScoreState()
  end
  return ss and ss.driftScore or {score = 0, combo = 1, cachedScore = 0, potentialScore = 0, comboCreepup = 0}
end

local function getPotentialScore(vehId)
  local ss = getScoreState(vehId)
  return ss and ss.driftScore.potentialScore or 0
end

local function getDriftPerformanceFactor(vehId)
  local ss = getScoreState(vehId)
  return ss and ss.performanceFactor or 0
end

local function getSteppedDriftPerformanceFactor(vehId)
  local ss = getScoreState(vehId)
  return ss and ss.smoothedSteppedPerformanceFactor or 0
end

local function getScoreAddedThisFrame(vehId)
  local ss = getScoreState(vehId)
  return ss and ss.scoreAddedThisFrame or 0
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

local function getCurrentDriftTier(vehId)
  local ss = getScoreState(vehId)
  return ss and driftTiers[ss.currentTier] or driftTiers[1]
end

local function getStuntZoneBasePoints(stuntZoneType)
  return scoreOptions.stuntZones[stuntZoneType].basePoints
end

local function setVehicleFrozen(vehId, isFrozen)
  frozenVehicles[vehId] = isFrozen or nil
end

local function isVehicleFrozen(vehId)
  return frozenVehicles[vehId] == true
end

local function onDriftPlVehReset(vehId)
  reset(vehId)
end

local function onDriftChainStarted(vehId)
  extensions.hook("onNewDriftTierReached", driftTiers[1], vehId)
end

local function onDriftFreeroamCruisingStarted()
  for _, ss in pairs(scoreStates) do
    ss.driftScore.score = 0
  end
end

local function onSerialize()
  return {
    scoreExperiment = scoreExperiment[0],
    debugToggleSmothnessGraph = debugToggleSmothnessGraph[0],
  }
end

local function onDeserialized(data)
  scoreExperiment = im.BoolPtr(data.scoreExperiment or false)
  debugToggleSmothnessGraph = im.BoolPtr(data.debugToggleSmothnessGraph or false)
end

M.onDriftPlVehReset = onDriftPlVehReset
M.onUpdate = onUpdate
M.onSerialize = onSerialize
M.onDeserialized = onDeserialized
M.onVehicleDestroyed = onVehicleDestroyed
M.onClientEndMission = onClientEndMission

M.onDriftTransition = onDriftTransition
M.onAnyStuntZoneAccomplished = onAnyStuntZoneAccomplished
M.onDriftThroughAccomplished = onDriftThroughAccomplished
M.onHitPoleAccomplished = onHitPoleAccomplished
M.onDonutDriftAccomplished = onDonutDriftAccomplished
M.onDriftCompleted = onDriftCompleted
M.onNearPoleAccomplished = onNearPoleAccomplished
M.onDriftChainStarted = onDriftChainStarted
M.onDriftFreeroamCruisingStarted = onDriftFreeroamCruisingStarted

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
M.setVehicleFrozen = setVehicleFrozen
M.isVehicleFrozen = isVehicleFrozen

return M
