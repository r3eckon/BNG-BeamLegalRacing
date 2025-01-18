-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.outputPorts = {[1] = true}
M.deviceCategories = {gearbox = true}
M.requiredExternalInertiaOutputs = {1}

local max = math.max
local min = math.min
local abs = math.abs
local clamp = clamp

local rpmToAV = 0.104719755
local avToRPM = 9.549296596425384

local function updateSounds(device, dt)
  local gearWhineCoefInput = device.gearWhineCoefsInput[device.gearIndex] or 0
  local gearWhineCoefOutput = device.gearWhineCoefsOutput[device.gearIndex] or 0

  local gearWhineDynamicsCoef = 0.05
  local fixedVolumePartOutput = device.gearWhineOutputAV * device.invMaxExpectedOutputAV --normalized AV
  local powerVolumePartOutput = device.gearWhineOutputAV * device.gearWhineOutputTorque * device.invMaxExpectedPower --normalized power
  local volumeOutput = clamp(gearWhineCoefOutput + ((abs(fixedVolumePartOutput) + abs(powerVolumePartOutput)) * gearWhineDynamicsCoef), 0, 10)

  local fixedVolumePartInput = device.gearWhineInputAV * device.invMaxExpectedInputAV --normalized AV
  local powerVolumePartInput = device.gearWhineInputAV * device.gearWhineInputTorque * device.invMaxExpectedPower --normalized power
  local volumeInput = clamp(gearWhineCoefInput + ((abs(fixedVolumePartInput) + abs(powerVolumePartInput)) * gearWhineDynamicsCoef), 0, 10)

  local inputPitchCoef = device.gearRatio >= 0 and device.forwardInputPitchCoef or device.reverseInputPitchCoef
  local outputPitchCoef = device.gearRatio >= 0 and device.forwardOutputPitchCoef or device.reverseOutputPitchCoef
  local pitchInput = clamp(abs(device.gearWhineInputAV) * avToRPM * inputPitchCoef, 0, 10000000)
  local pitchOutput = clamp(abs(device.gearWhineOutputAV) * avToRPM * outputPitchCoef, 0, 10000000)

  local inputLoad = device.gearWhineInputTorque * device.invMaxExpectedInputTorque
  local outputLoad = device.gearWhineOutputTorque * device.invMaxExpectedOutputTorque
  local outputRPMSign = sign(device.gearWhineOutputAV)

  device.gearWhineOutputLoop:setVolumePitch(volumeOutput, pitchOutput, outputLoad, outputRPMSign)
  device.gearWhineInputLoop:setVolumePitch(volumeInput, pitchInput, inputLoad, outputRPMSign)

  -- print(string.format("volIn - %0.2f / volOut - %0.2f / ptchIn - %0.2f / ptchOut - %0.2f / inLoad - %0.2f / outLoad - %0.2f", volumeInput, volumeOutput, pitchInput, pitchOutput, inputLoad, outputLoad))
end

local function updateVelocity(device, dt)
  device.inputAV = device.outputAV1 * device.gearRatio * device.lockCoef
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function updateTorque(device)
  local inputTorque = device.parent[device.parentOutputTorqueName]
  device.inputTorque = inputTorque
  local inputAV = device.inputAV
  local friction = (device.friction * clamp(inputAV, -1, 1) + device.dynamicFriction * inputAV + device.torqueLossCoef * inputTorque) * device.wearFrictionCoef * device.damageFrictionCoef
  local outputTorque = (inputTorque - friction) * device.gearRatio * device.lockCoef
  device.outputTorque1 = outputTorque

  device.gearWhineInputTorque = device.gearWhineInputTorqueSmoother:get(inputTorque)
  device.gearWhineOutputTorque = device.gearWhineOutputTorqueSmoother:get(outputTorque)
  device.gearWhineInputAV = device.gearWhineInputAVSmoother:get(inputAV)
  device.gearWhineOutputAV = device.gearWhineOutputAVSmoother:get(device.outputAV1)
end

local function neutralUpdateVelocity(device, dt)
  device.inputAV = device.virtualMassAV
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function neutralUpdateTorque(device, dt)
  device:updateGrinding(dt)

  local inputAV = device.inputAV
  local friction = (device.neutralFriction * clamp(inputAV, -1, 1) + device.neutralDynamicFriction * inputAV) * device.wearFrictionCoef * device.damageFrictionCoef
  device.inputTorque = device.parent[device.parentOutputTorqueName]
  local outputTorque = device.inputTorque - friction + device.grindingTorque * device.grindingTorqueSign
  device.virtualMassAV = device.virtualMassAV + outputTorque * device.invCumulativeInertia * dt
  device.outputTorque1 = -device.grindingTorque * device.grindingTorqueReactionSign

  device.gearWhineInputTorque = device.gearWhineInputTorqueSmoother:get(device.parent[device.parentOutputTorqueName])
  device.gearWhineOutputTorque = device.gearWhineOutputTorqueSmoother:get(0)
  device.gearWhineInputAV = device.gearWhineInputAVSmoother:get(inputAV)
  device.gearWhineOutputAV = device.gearWhineOutputAVSmoother:get(device.outputAV1)
end

local function selectUpdates(device)
  device.velocityUpdate = updateVelocity
  device.torqueUpdate = updateTorque

  if device.isBroken or device.gearRatio == 0 then
    device.velocityUpdate = neutralUpdateVelocity
    device.torqueUpdate = neutralUpdateTorque
    --make sure the virtual mass has the right AV
    device.virtualMassAV = device.inputAV
  end
end

local function updateGrinding(device, dt)
  if device.isGrindingShift then
    local gearIndex = device.grindingShiftTargetIndex
    local avDifference = (device.outputAV1 * device.gearRatios[gearIndex]) - device.inputAV
    device.grindingTorque = linearScale(avDifference, 1, 1000, device.maxGrindingTorque, device.maxGrindingTorque * 0.1)
    device.grindingTorqueSign = sign(avDifference)
    device.grindingTorqueReactionSign = sign(avDifference) * sign(device.gearRatios[gearIndex])
    local synchroWear = abs(avDifference * device.grindingTorque * device.synchroWearCoef[gearIndex] * dt)
    --print("gearIndex="..gearIndex)
	--print("device.synchroWear[gearIndex]=" .. device.synchroWear[gearIndex])
	--print("synchroWear=" .. synchroWear)
	
	device.synchroWear[gearIndex] = clamp(device.synchroWear[gearIndex] + synchroWear, 0, 1)

    --when we reach 100% synchro wear, disable this specific gear by setting its gear ratio to 0
    if device.synchroWear[gearIndex] >= 1 then
      device.gearRatios[gearIndex] = 0
	  --print("SET GEAR RATIO TO 0 FOR GEAR INDEX: " .. gearIndex)
      --set the av diff to 0 as well, so that in the next step it goes "into" gear rather than keep grinding (there's nothing left to grind)
      avDifference = 0
    end

    --if we reached a small enough AV difference, go into gear
    if abs(avDifference) < 20 then
      device.gearIndex = gearIndex
      device.gearRatio = device.gearRatios[device.gearIndex]
      device:setGearGrinding(false)
      local maxExpectedOutputTorque = device.maxExpectedInputTorque * device.gearRatio
      device.invMaxExpectedOutputTorque = 1 / maxExpectedOutputTorque

      if device.gearRatio ~= 0 then
        powertrain.calculateTreeInertia()
      end

      selectUpdates(device)
    end
    device.gearGrindLoop:setVolumePitch(1, abs(avDifference) * avToRPM, 1, 1)

    local wornGearIndex = gearIndex
    --we always want to display the UI message the first time damage happens
    local isFirstDamage = device.synchroWear[wornGearIndex] > 0 and device.previouslyReportedSynchroWear[wornGearIndex] <= 0
    --we also want to display it for every further %
    local isSignificantlyMoreDamage = (device.synchroWear[wornGearIndex] - device.previouslyReportedSynchroWear[wornGearIndex]) >= 0.01
    local hasReachedMaximumDamage = device.synchroWear[wornGearIndex] >= 1 and (device.synchroWear[wornGearIndex] - device.previouslyReportedSynchroWear[wornGearIndex]) > 0
    local doDisplayDamageMessage = isFirstDamage or isSignificantlyMoreDamage or hasReachedMaximumDamage
    if doDisplayDamageMessage then
      guihooks.message({txt = string.format("Synchronizer damage (Gear %g): %d%%", wornGearIndex, clamp(device.synchroWear[wornGearIndex] * 100, 1, 100)), context = {}}, 5, "vehicle.damage.synchros")
      device.previouslyReportedSynchroWear[wornGearIndex] = device.synchroWear[wornGearIndex]
    end

    if device.synchroWear[gearIndex] > 0 and not damageTracker.getDamage("gearbox", "synchroWear") then
      damageTracker.setDamageTemporary("gearbox", "synchroWear", true, false, 2)
    end
  end
end

local function setGearGrinding(device, active, targetGearIndex, maxGrindingTorque)
  if active then
    --expose the current grinding to the outside world
    device.isGrindingShift = active
    --save our target gear index for when grinding finished
    device.grindingShiftTargetIndex = targetGearIndex
    --activate the synchro/grinding torque
    device.grindingTorque = 0
    device.maxGrindingTorque = maxGrindingTorque
    if device.gearGrindLoop then
      --start the grinding sound, but keep it silent for now (params are then set from the update logic of the grinding)
      device.gearGrindLoop:setVolumePitch(0, 0, 0, 0)
      obj:playSFX(device.gearGrindLoop.obj)
    end
  else
    device.isGrindingShift = false
    device.grindingShiftTargetIndex = nil
    device.grindingTorque = 0
    device.maxGrindingTorque = 0
    device.grindingTorqueSign = 0
    device.grindingTorqueReactionSign = 0
    if device.gearGrindLoop then
      device.gearGrindLoop:setVolumePitch(0, 0, 0, 0)
      obj:stopSFX(device.gearGrindLoop.obj)
    end
  end
end

-- BEAMLR EDITED FUNCTION, RESTORED GEAR POP OUT BEHAVIOR, FIXED ERROR, INCREASED CHANCE
local function updateGFX(device, dt)
  local gearIndex = device.grindingShiftTargetIndex or device.gearIndex
  local roll = math.random()
  local avDifference = (device.outputAV1 * device.gearRatios[gearIndex]) - device.inputAV
  guihooks.graph({"RPM difference", avDifference * avToRPM, 7000, "", false}, {"Input RPM", device.inputAV * avToRPM, 7000, "", false}, {"Output RPM", device.outputAV1 * device.gearRatios[gearIndex] * avToRPM, 7000, "", false})
   local gearPopoutMinDamage = 0.25
   if device.gearIndex ~= 0 and device.synchroWear[device.gearIndex] >= gearPopoutMinDamage then
     device.gearPopOutTimer = device.gearPopOutTimer - dt
     if device.gearPopOutTimer <= 0 then
       local gearPopOutChance = linearScale(device.synchroWear[device.gearIndex], 0.25, 1, 0.995, 0.85) --0.5% chance at 25% damage, 15% chance at 100% damage
       --print(roll .. " VS " .. gearPopOutChance)
	   if roll > gearPopOutChance then
         device:setGearIndex(0)
         guihooks.message({txt = string.format("Gear popped out due to transmission damage"), context = {}}, 5, "vehicle.damage.synchros")
       end
       device.gearPopOutTimer = device.gearPopOutTimer + 1 --1s delay until the next check
     end
   end
end

local function setGearIndex(device, index, availableSyncTime)
  local oldIndex = device.gearIndex
  local newDesiredIndex = clamp(index, device.minGearIndex, device.maxGearIndex)
  local isSuccessfulShift = true
  local isGrindingShift = false
  local maxGrindingTorque = 0
  --assume lots of time when no time is provided, this helps staying backwards compatible
  local ignoreSynchroHandling = not availableSyncTime
  availableSyncTime = availableSyncTime or math.huge

  local avDifference = (device.outputAV1 * device.gearRatios[newDesiredIndex]) - device.inputAV
  --only use this logic if are changing away from neutral and indeed changing into a different gear
  if newDesiredIndex ~= 0 and newDesiredIndex ~= oldIndex then
    local absAVDifference = abs(avDifference)
    --print(string.format("AV difference: %.2f", avDifference))
    local synchroWearCoef = linearScale(device.synchroWear[newDesiredIndex], 0.1, 1, 1, 0.4)

    --check if our AV difference is below a certain threshold where we allow shifting without clutch usage
    if absAVDifference <= device.shiftAllowedNonClutchAVDifference[newDesiredIndex] * synchroWearCoef or ignoreSynchroHandling then
      --shift succeeded without using the clutch
      --print(string.format("AV difference is minimal, shift succeeded without clutch usage. Allowed AV difference: %.2f", device.shiftAllowedNonClutchAVDifference[newDesiredIndex]))
    else
      --check if the current AV difference _can_ be synced away, this threshold is very low with non-synchromesh transmissions
      if absAVDifference > device.shiftMaxSynchroAVCapability[newDesiredIndex] * synchroWearCoef then
        --print(string.format("AV difference too high to sync. Max: %.2f, actual: %.2f", device.shiftMaxSynchroAVCapability[newDesiredIndex], avDifference))
        isSuccessfulShift = false
        isGrindingShift = true
        maxGrindingTorque = 50
      else
        --check if the clutch is pressed enough to allow for shifting, ideally this would be solved via a torque check instead, but that's difficult with the current way the clutch works
        local clutchPressedEnough = device.parent.clutchRatio and (1 - device.parent.clutchRatio) >= device.shiftRequiredClutchInput[newDesiredIndex]
        if not clutchPressedEnough then
          --print(string.format("Not enough clutch input. Required: %.2f, actual: ", device.shiftRequiredClutchInput[newDesiredIndex], (1 - device.parent.clutchRatio)))
          isSuccessfulShift = false
          isGrindingShift = true
          maxGrindingTorque = 50
        else
          local maxSyncSpeed = device.shiftMaxSynchroRate[newDesiredIndex] * synchroWearCoef
          --check if our actual hardware shiftime was long enough to hypotheitcally complete synchro use. Only act if it's _not_ enough.
          --We need to do it in this "backwards" way so that we don't introduce additional lag upon shifting
          --since the first time we are notified about "user shifted into gear" is when the gearstick already finished moving.
          if availableSyncTime * maxSyncSpeed < absAVDifference then
            --print(string.format("Available sync time too small. Required: %.4fs, actual: %.4fs", absAVDifference / maxSyncSpeed, availableSyncTime))
            --print(string.format("Hypothetical sync rate required for this shift: %.2f rad/s", (absAVDifference / availableSyncTime)))
            isSuccessfulShift = false
            isGrindingShift = true
            maxGrindingTorque = 50
          else
            --print(string.format("Good shift, perfection: %.1f%%", (absAVDifference / maxSyncSpeed) / availableSyncTime * 100))
          end
        end
      end
    end
  elseif newDesiredIndex == 0 then
    --if we are shifting into neutral, stop any possible grinding logic
    device:setGearGrinding(false)
  end

  if isSuccessfulShift then
    device.gearIndex = newDesiredIndex
    device.gearRatio = device.gearRatios[device.gearIndex]
    --safe guard in case there somehow was still grinding active
    device:setGearGrinding(false)
  end

  if isGrindingShift then
    --we have a grinding shift, enable the grinding logic
    device:setGearGrinding(true, newDesiredIndex, maxGrindingTorque)
  end

  --update our powertrain stats for the possibly new gear
  local maxExpectedOutputTorque = device.maxExpectedInputTorque * device.gearRatio
  device.invMaxExpectedOutputTorque = 1 / maxExpectedOutputTorque

  if device.gearRatio ~= 0 then
    powertrain.calculateTreeInertia()
  end

  selectUpdates(device)
end

local function onBreak(device)
  device.isBroken = true
  selectUpdates(device)
end

local function setLock(device, enabled)
  device.lockCoef = enabled and 0 or 1
  if device.parent and device.parent.setLock then
    device.parent:setLock(enabled)
  end
end

local function applyDeformGroupDamage(device, damageAmount)
  device.damageFrictionCoef = device.damageFrictionCoef + linearScale(damageAmount, 0, 0.01, 0, 0.1)
end

local function setPartCondition(device, subSystem, odometer, integrity, visual)
  device.wearFrictionCoef = linearScale(odometer, 30000000, 1000000000, 1, 2)
  local integrityState = integrity
  if type(integrity) == "number" then
    local integrityValue = integrity
    integrityState = {
      damageFrictionCoef = linearScale(integrityValue, 1, 0, 1, 50),
      synchroWear = {},
      isBroken = false
    }
    for gearIndex, _ in pairs(device.gearRatios) do
      integrityState.synchroWear[gearIndex] = 0
    end
  end

  device.damageFrictionCoef = integrityState.damageFrictionCoef or 1
  device.synchroWear = integrityState.synchroWear

  if integrityState.isBroken then
    device:onBreak()
  end
end

local function getPartCondition(device)
  local integrityState = {
    damageFrictionCoef = device.damageFrictionCoef,
    synchroWear = device.synchroWear,
    isBroken = device.isBroken
  }
  local integrityValue = linearScale(device.damageFrictionCoef, 1, 50, 1, 0)
  if device.isBroken then
    integrityValue = 0
  end
  return integrityValue, integrityState
end

local function validate(device)
  if device.parent and not device.parent.deviceCategories.clutch and not device.parent.isFake then
    log("E", "manualGearbox.validate", "Parent device is not a clutch device...")
    log("E", "manualGearbox.validate", "Actual parent:")
    log("E", "manualGearbox.validate", powertrain.dumpsDeviceData(device.parent))
    return false
  end

  if not device.transmissionNodeID then
    local engine = device.parent and device.parent.parent or nil
    local engineNodeID = engine and engine.engineNodeID or nil
    device.transmissionNodeID = engineNodeID or sounds.engineNode
  end

  if type(device.transmissionNodeID) ~= "number" then
    device.transmissionNodeID = nil
  end

  local maxEngineTorque
  local maxEngineAV

  if device.parent.parent and device.parent.parent.deviceCategories.engine then
    local engine = device.parent.parent
    local torqueData = engine:getTorqueData()
    maxEngineTorque = torqueData.maxTorque
    maxEngineAV = engine.maxAV
  else
    maxEngineTorque = 100
    maxEngineAV = 6000 * rpmToAV
  end

  device.maxExpectedInputTorque = maxEngineTorque
  device.invMaxExpectedInputTorque = 1 / maxEngineTorque
  device.invMaxExpectedOutputTorque = 0
  device.maxExpectedPower = maxEngineAV * device.maxExpectedInputTorque
  device.invMaxExpectedPower = 1 / device.maxExpectedPower
  device.maxExpectedOutputAV = maxEngineAV / device.minGearRatio
  device.invMaxExpectedOutputAV = 1 / device.maxExpectedOutputAV
  device.invMaxExpectedInputAV = 1 / maxEngineAV

  return true
end

local function calculateInertia(device)
  local outputInertia = 0
  local cumulativeGearRatio = 1
  local maxCumulativeGearRatio = 1
  if device.children and #device.children > 0 then
    local child = device.children[1]
    outputInertia = child.cumulativeInertia
    cumulativeGearRatio = child.cumulativeGearRatio
    maxCumulativeGearRatio = child.maxCumulativeGearRatio
  end

  local gearRatio = device.gearRatio ~= 0 and abs(device.gearRatio) or (device.maxGearRatio * 2)
  device.cumulativeInertia = outputInertia / gearRatio / gearRatio
  device.invCumulativeInertia = 1 / device.cumulativeInertia

  device.cumulativeGearRatio = cumulativeGearRatio * device.gearRatio
  device.maxCumulativeGearRatio = maxCumulativeGearRatio * device.maxGearRatio
end

local function resetSounds(device)
  device.gearWhineInputTorqueSmoother:reset()
  device.gearWhineOutputTorqueSmoother:reset()
  device.gearWhineInputAVSmoother:reset()
  device.gearWhineOutputAVSmoother:reset()

  device.gearWhineInputAV = 0
  device.gearWhineOutputAV = 0
  device.gearWhineInputTorque = 0
  device.gearWhineOutputTorque = 0
end

local function initSounds(device, jbeamData)
  device.gearGrindSoundFile = jbeamData.gearGrindSoundFile or "event:>Vehicle>Transmission>grind>transmissionGrind_01"
  local gearGrindSample = jbeamData.gearGrindEvent or "event:>Vehicle>Transmission>grind>transmissionGrindTest"
  device.gearGrindLoop = sounds.createSoundObj(gearGrindSample, "AudioDefaultLoop3D", "GearGrind", device.transmissionNodeID or sounds.engineNode)

  local gearWhineOutputSample = jbeamData.gearWhineOutputEvent or "event:>Vehicle>Transmission>helical_01>twine_out"
  device.gearWhineOutputLoop = sounds.createSoundObj(gearWhineOutputSample, "AudioDefaultLoop3D", "GearWhineOut", device.transmissionNodeID or sounds.engineNode)

  local gearWhineInputSample = jbeamData.gearWhineInputEvent or "event:>Vehicle>Transmission>helical_01>twine_in"
  device.gearWhineInputLoop = sounds.createSoundObj(gearWhineInputSample, "AudioDefaultLoop3D", "GearWhineIn", device.transmissionNodeID or sounds.engineNode)

  bdebug.setNodeDebugText("Powertrain", device.transmissionNodeID or sounds.engineNode, device.name .. ": " .. gearWhineOutputSample)
  bdebug.setNodeDebugText("Powertrain", device.transmissionNodeID or sounds.engineNode, device.name .. ": " .. gearWhineInputSample)

  device.forwardInputPitchCoef = jbeamData.forwardInputPitchCoef or 1
  device.forwardOutputPitchCoef = jbeamData.forwardOutputPitchCoef or 1
  device.reverseInputPitchCoef = jbeamData.reverseInputPitchCoef or 0.7
  device.reverseOutputPitchCoef = jbeamData.reverseOutputPitchCoef or 0.7

  local inputAVSmoothing = jbeamData.gearWhineInputPitchCoefSmoothing or 50
  local outputAVSmoothing = jbeamData.gearWhineOutputPitchCoefSmoothing or 50
  local inputTorqueSmoothing = jbeamData.gearWhineInputVolumeCoefSmoothing or 10
  local outputTorqueSmoothing = jbeamData.gearWhineOutputVolumeCoefSmoothing or 10

  device.gearWhineInputTorqueSmoother = newExponentialSmoothing(inputTorqueSmoothing)
  device.gearWhineOutputTorqueSmoother = newExponentialSmoothing(outputTorqueSmoothing)
  device.gearWhineInputAVSmoother = newExponentialSmoothing(inputAVSmoothing)
  device.gearWhineOutputAVSmoother = newExponentialSmoothing(outputAVSmoothing)

  device.gearWhineInputAV = 0
  device.gearWhineOutputAV = 0
  device.gearWhineInputTorque = 0
  device.gearWhineOutputTorque = 0

  device.gearWhineFixedCoefOutput = jbeamData.gearWhineFixedCoefOutput or 0.7
  device.gearWhinePowerCoefOutput = 1 - device.gearWhineFixedCoefOutput
  device.gearWhineFixedCoefInput = jbeamData.gearWhineFixedCoefInput or 0.4
  device.gearWhinePowerCoefInput = 1 - device.gearWhineFixedCoefInput

  device.gearWhineOutputLoop:setParameter("c_gearboxMaxPower", device.maxExpectedPower * 0.001)
  device.gearWhineInputLoop:setParameter("c_gearboxMaxPower", device.maxExpectedPower * 0.001)
end

local function reset(device, jbeamData)
  device.gearRatio = jbeamData.gearRatio or 1
  device.friction = jbeamData.friction or 0
  device.cumulativeInertia = 1
  device.cumulativeGearRatio = 1
  device.maxCumulativeGearRatio = 1
  device.grindingTorque = 0
  device.maxGrindingTorque = 0
  device.grindingTorqueSign = 0
  device.grindingTorqueReactionSign = 0

  device.outputAV1 = 0
  device.inputAV = 0
  device.outputTorque1 = 0
  device.virtualMassAV = 0
  device.isBroken = false

  device.lockCoef = 1
  device.misShiftPenaltyTimer = 0

  device.gearIndex = 1
  device.isShiftGrinding = false
  device.gearPopOutTimer = 0

  for k, v in pairs(device.initialGearRatios) do
    device.gearRatios[k] = v
    device.synchroWear[k] = 0
    device.previouslyReportedSynchroWear[k] = 0
  end

  device.wearFrictionCoef = 1
  device.damageFrictionCoef = 1

  damageTracker.setDamage("gearbox", "synchroWear", false)

  device:setGearIndex(0)

  selectUpdates(device)
end

local function new(jbeamData)
  local device = {
    deviceCategories = shallowcopy(M.deviceCategories),
    requiredExternalInertiaOutputs = shallowcopy(M.requiredExternalInertiaOutputs),
    outputPorts = shallowcopy(M.outputPorts),
    name = jbeamData.name,
    type = jbeamData.type,
    inputName = jbeamData.inputName,
    inputIndex = jbeamData.inputIndex,
    gearRatio = jbeamData.gearRatio or 1,
    friction = jbeamData.friction or 0,
    dynamicFriction = jbeamData.dynamicFriction or 0,
    torqueLossCoef = jbeamData.torqueLossCoef or 0,
    wearFrictionCoef = 1,
    damageFrictionCoef = 1,
    cumulativeInertia = 1,
    cumulativeGearRatio = 1,
    maxCumulativeGearRatio = 1,
    isPhysicallyDisconnected = true,
    outputAV1 = 0,
    inputAV = 0,
    outputTorque1 = 0,
    virtualMassAV = 0,
    isBroken = false,
    lockCoef = 1,
    misShiftPenaltyTimer = 0,
    grindingTorque = 0,
    maxGrindingTorque = 0,
    grindingTorqueSign = 0,
    grindingTorqueReactionSign = 0,
    isShiftGrinding = false,
    gearPopOutTimer = 0,
    gearIndex = 1,
    gearRatios = {},
    gearDamageThreshold = jbeamData.gearDamageThreshold or 3000,
    maxExpectedInputAV = 0,
    maxExpectedOutputAV = 0,
    maxExpectedInputTorque = 0,
    invMaxExpectedOutputTorque = 0,
    invMaxExpectedInputTorque = 0,
    invMaxExpectedPower = 0,
    reset = reset,
    updateGFX = updateGFX,
    initSounds = initSounds,
    resetSounds = resetSounds,
    updateSounds = updateSounds,
    onBreak = onBreak,
    validate = validate,
    setLock = setLock,
    calculateInertia = calculateInertia,
    updateGrinding = updateGrinding,
    setGearIndex = setGearIndex,
    setGearGrinding = setGearGrinding,
    applyDeformGroupDamage = applyDeformGroupDamage,
    setPartCondition = setPartCondition,
    getPartCondition = getPartCondition
  }

  device.torqueLossCoef = clamp(device.torqueLossCoef, 0, 1)
  device.neutralFriction = jbeamData.neutralFriction or device.friction
  device.neutralDynamicFriction = jbeamData.neutralDynamicFriction or device.dynamicFriction

  local forwardGears = {}
  local reverseGears = {}
  for _, v in pairs(jbeamData.gearRatios) do
    table.insert(v >= 0 and forwardGears or reverseGears, v)
  end

  device.maxGearIndex = 0
  device.minGearIndex = 0
  device.maxGearRatio = 0
  device.minGearRatio = 999999
  for i = 0, tableSize(forwardGears) - 1, 1 do
    device.gearRatios[i] = forwardGears[i + 1]
    device.maxGearIndex = max(device.maxGearIndex, i)
    device.maxGearRatio = max(device.maxGearRatio, abs(device.gearRatios[i]))
    if device.gearRatios[i] ~= 0 then
      device.minGearRatio = min(device.minGearRatio, abs(device.gearRatios[i]))
    end
  end
  local reverseGearCount = tableSize(reverseGears)
  for i = -reverseGearCount, -1, 1 do
    local index = -reverseGearCount - i - 1
    device.gearRatios[i] = reverseGears[abs(index)]
    device.minGearIndex = min(device.minGearIndex, index)
    device.maxGearRatio = max(device.maxGearRatio, abs(device.gearRatios[i]))
    if device.gearRatios[i] ~= 0 then
      device.minGearRatio = min(device.minGearRatio, abs(device.gearRatios[i]))
    end
  end
  device.gearCount = abs(device.maxGearIndex) + abs(device.minGearIndex)

  device.initialGearRatios = shallowcopy(device.gearRatios)

  device.gearWhineCoefsOutput = {}
  local gearWhineCoefsOutput = jbeamData.gearWhineCoefsOutput or jbeamData.gearWhineCoefs
  if gearWhineCoefsOutput and type(gearWhineCoefsOutput) == "table" then
    local gearIndex = device.minGearIndex
    for _, v in pairs(gearWhineCoefsOutput) do
      device.gearWhineCoefsOutput[gearIndex] = v
      gearIndex = gearIndex + 1
    end
  else
    for i = device.minGearIndex, device.maxGearIndex, 1 do
      device.gearWhineCoefsOutput[i] = 0
    end
  end

  device.gearWhineCoefsInput = {}
  local gearWhineCoefsInput = jbeamData.gearWhineCoefsInput or jbeamData.gearWhineCoefs
  if gearWhineCoefsInput and type(gearWhineCoefsInput) == "table" then
    local gearIndex = device.minGearIndex
    for _, v in pairs(gearWhineCoefsInput) do
      device.gearWhineCoefsInput[gearIndex] = v
      gearIndex = gearIndex + 1
    end
  else
    for i = device.minGearIndex, device.maxGearIndex, 1 do
      device.gearWhineCoefsInput[i] = i < 0 and 0.3 or 0
    end
  end

  local synchroSettings = tableFromHeaderTable(jbeamData.synchronizerSettings or {})
  local synchroSettingLookup = {}
  for _, settings in pairs(synchroSettings) do
    if settings.gearIndex then
      synchroSettingLookup[settings.gearIndex] = settings
    end
  end
  device.synchroWear = {}
  device.previouslyReportedSynchroWear = {}
  device.shiftAllowedNonClutchAVDifference = {}
  device.shiftRequiredClutchInput = {}
  device.shiftMaxSynchroAVCapability = {}
  device.shiftMaxSynchroRate = {}
  device.synchroWearCoef = {}
  for i, _ in pairs(device.gearRatios) do
    local gearSettings = synchroSettingLookup[i] or {}
    device.synchroWear[i] = 0
    device.previouslyReportedSynchroWear[i] = 0
    device.shiftAllowedNonClutchAVDifference[i] = (gearSettings.maxClutchRPMDifference or 50) * rpmToAV
    device.shiftRequiredClutchInput[i] = gearSettings.requiredClutchInput or 0.8
    device.shiftMaxSynchroAVCapability[i] = (gearSettings.maxSynchroRPMDifference or math.huge) * rpmToAV
    device.shiftMaxSynchroRate[i] = gearSettings.maxSynchroRate or 5000
    device.synchroWearCoef[i] = gearSettings.synchroWearCoef or 0.000005
  end

  --if no synchro settings are provided, use a default of a non-synchro reverse gear
  if not jbeamData.synchronizerSettings then
    for i, _ in pairs(device.gearRatios) do
      if i >= 0 then
        device.shiftMaxSynchroAVCapability[i] = math.huge
      else
        device.shiftMaxSynchroAVCapability[i] = 100
      end
    end
  end

  if jbeamData.gearboxNode_nodes and type(jbeamData.gearboxNode_nodes) == "table" then
    device.transmissionNodeID = jbeamData.gearboxNode_nodes[1]
  end

  if type(device.transmissionNodeID) ~= "number" then
    device.transmissionNodeID = nil
  end

  device:setGearIndex(0)

  device.breakTriggerBeam = jbeamData.breakTriggerBeam
  if device.breakTriggerBeam and device.breakTriggerBeam == "" then
    --get rid of the break beam if it's just an empty string (cancellation)
    device.breakTriggerBeam = nil
  end

  selectUpdates(device)

  --print("experimental gearbox device")

  return device
end

M.new = new

return M
