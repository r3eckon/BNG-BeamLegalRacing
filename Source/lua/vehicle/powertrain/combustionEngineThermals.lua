-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- BEAMLR EDITED

local M = {}

local max = math.max
local min = math.min
local abs = math.abs
local random = math.random

local conversion = {
  kelvinToCelsius = -273.15,
  celsiusToKelvin = 273.15,
  avToRPM = 9.549296596425384
}

local parentEngine = nil
local tEnv = 0
--Thermal variables
M.engineBlockTemperature = 0
M.cylinderWallTemperature = 0
M.coolantTemperature = 0
M.oilTemperature = 0
M.exhaustTemperature = 0
M.radiatorFanSpin = 0
M.debugData = {}

M.exhaustEndNodes = {}

local energyCoef = {
  engineBlock = nil,
  cylinderWall = nil,
  oil = nil,
  coolant = nil,
  exhaust = nil
}

local thermalsEnabled = false

local engineBlockMeltingTemperature = 0
local cylinderWallMeltingTemperature = 0
local burnEfficiencyCoef = 0
local engineBlockAirCoolingEfficiency = nil
local engineBlockAirflowCoef = nil
local blockFanMaxAirSpeed = 0
local blockFanRPMCoef = 0

--Radiator
local radiatorFanType = nil
local radiatorFanMaxAirSpeed = 0
local radiatorFanTemperature = 0
local thermostatTemperature = 0
local oilThermostatTemperature = 0
local airRegulatorClosedCoef = 0
local fanAirSpeed = 0
local mechanicalRadiatorFanRPMCoef = 0
local radiatorCoef = 0
local oilRadiatorCoef = 0
local hasCoolantRadiator = false
local hasOilRadiator = false
local electricalRadiatorFanSmoother = nil
local mechanicalFanRPMCoef = 0
local electricRadiatorFanOverrideIgnitionLevel = -1

--Damage
local damageThreshold = {
  headGasket = 0,
  pistonRing = 0,
  connectingRod = 0,
  engineBlockTemperature = 0,
  cylinderWallTemperature = 0
}

M.engineBlockOverheatDamage = 0
M.oilOverheatDamage = 0
M.cylinderWallOverheatDamage = 0
M.headGasketBlown = false
M.pistonRingsDamaged = false
M.connectingRodBearingsDamaged = false
M.engineBlockMelted = false
M.cylinderWallsMelted = false

local fluidReservoirs = {
  coolant = {
    currentMass = 0,
    initialMass = 0,
    invInitialMass = 0
  },
  oil = {
    currentMass = 0,
    massInCylinders = 0,
    minimumSafeMass = 0,
    maximumSafeMass = 0,
    initialMass = 0
  }
}

local fluidLeakRates = {
  coolant = {
    overpressure = 0,
    headGasket = 0,
    radiator = 0,
    overall = 0,
    previousOverall = 0
  },
  oil = {
    oilpan = 0,
    radiator = 0,
    pistonRingDamage = 0,
    gravity = 0,
    combustionToExhaust = 0,
    overall = 0
  }
}

local radiatorDamageDeformGroup = nil
local radiatorDeformThreshold = 0
local radiatorDamage = 0
local lastRadiatorCompatibilityDamage = 0
local oilpanNodeBottom = -1
local oilpanNodeTop = -1
local oilpanMaximumSafeG = 0
local oilpanAccZSmoother = newTemporalSmoothing(10, 30)
local oilpanAccXYSmoother = newTemporalSmoothing(10, 10)
local oilStarvingTimer = 0
local oilStarvingTimerThreshold = 2
local missingOilDamage = 0
local hasOilStarvingDamage = false

--Particles & Sound
local particleTicks = {
  engineSteamParticleTick = 0,
  exhaustSteamParticleTick = 0,
  exhaustOilParticleTick = 0,
  exhaustSmokeParticleTick = 0,
  radiatorSteamParticleTick = 0
}
local knockSoundTick = 0
local particulates = 0
local idleParticulates = 0
local radiatorHissSound = nil
local radiatorFanSound = nil
local radiatorFanVolume = 0
local radiatorFanElectricSoundPlaying = false
local startPreHeated = true

--Thermal constants
local constants = {
  preHeatTemperature = 80,
  oilSpecHeat = 1800,
  coolantSpecHeat = 4000,
  exhaustSpecHeat = 500,
  minimumCoolantMass = 1.5,
  minimumOilMass = 0.25 * 0.87, --L to kg
  coolantTemperatureDamageThreshold = 120,
  maxCoolantTemperature = 130,
  oilTemperatureDamageThreshold = 150,
  exhaustCondensationThresholdEnvTemp = 10,
  exhaustCondensationThresholdBlockTemp = 150
}

--Nodes
local nodes = {
  coolantCap = {},
  radiator = {},
  engine = {},
  exhaust = {},
  exhaustEnds = {}
}
--local invExhaustNodeCount = 0
local exhaustStartNodes = {}
local exhaustBeams = nil
local exhaustTrees = {}

local afterFire = nil

local updateCoolingGFXMethod = nop
local updateExhaustGFXMethod = nop
local updateMechanicsGFXMethod = nop

local heatTickData = {
  debugEnabled = false,
  engineTickPeriodGain = 0,
  engineTickMinRate = 0,
  engineTickMaxRate = 0,
  engineTickMinTemperature = 0,
  engineTickPitch = 0.5,
  engineTickSizeBias = 0,
  engineTickVolume = 0,
  engineTickStartDelay = 3,
  engineTickDelay = 3,
  engineTickBucket = 0,
  engineTickBucketThreshold = 0,
  engineTickEventName = nil,
  lastEngineBlockTemperature = 0,
  engineDeltaTempSmoother = newTemporalSmoothing(10, 10),
  engineNodes = {},
  exhaustTickPeriodGain = 0,
  exhaustTickMinRate = 0,
  exhaustTickMaxRate = 0,
  exhaustTickMinTemperature = 0,
  exhaustTickPitch = 0.5,
  exhaustTickSizeBias = 3,
  exhaustTickVolume = 0,
  exhaustTickStartDelay = 3,
  exhaustTickDelay = 3,
  exhaustTickBucket = 0,
  exhaustTickBucketThreshold = 0,
  exhaustTickEventName = nil,
  lastExhaustTemperature = 0,
  exhaustDeltaTempSmoother = newTemporalSmoothing(10, 10),
  exhaustNodes = {},
  turboTickBucket = 0,
  turboTickBucketThreshold = 0,
  lastTurboTemperature = 0,
  turboNodes = {}
}

local engineThermalData = {
  coolantTemperature = 0,
  --this is to make the tacho display work, oil temp is the best measure of engine temp
  oilTemperature = 0,
  engineBlockTemperature = 0,
  cylinderWallTemperature = 0,
  exhaustTemperature = 0,
  radiatorAirSpeed = 0,
  radiatorAirSpeedEfficiency = 0,
  fanActive = 0,
  thermostatStatus = 0,
  airRegulatorStatus = 0,
  oilThermostatStatus = 0,
  coolantLeakRateOverpressure = 0,
  coolantLeakRateHeadGasket = 0,
  coolantLeakRateRadiator = 0,
  coolantLeakRateOverall = 0,
  coolantMass = 0,
  oilMass = 0,
  miniumSafeOilMass = 0,
  maximumSafeOilMass = 0,
  oilLeakRateOilpan = 0,
  oilLeakRateRadiator = 0,
  oilLeakRateGravity = 0,
  oilLeakRatePistonRingDamage = 0,
  oilLeakRateOverall = 0,
  oilLubricationCoef = 0,
  coolantEfficiency = 0,
  engineEfficiency = 0,
  energyToCylinderWall = 0,
  energyToOil = 0,
  energyToExhaust = 0,
  energyCoolantToAir = 0,
  energyCylinderWallToCoolant = 0,
  energyCoolantToBlock = 0,
  energyCylinderWallToBlock = 0,
  energyCylinderWallToOil = 0,
  energyOilToAir = 0,
  energyOilToBlock = 0,
  energyOilSumpToAir = 0,
  energyBlockToAir = 0,
  energyExhaustToAir = 0,
  engineBlockOverheatDamage = 0,
  oilOverheatDamage = 0,
  cylinderWallOverheatDamage = 0,
  headGasketBlown = 0,
  pistonRingsDamaged = 0,
  connectingRodBearingsDamaged = 0,
  engineBlockMelted = 0,
  cylinderWallsMelted = 0,
  thermostatTemperature = 0,
  oilThermostatTemperature = 0
}
M.debugData.engineThermalData = engineThermalData

local function applyDeformGroupDamageRadiator(damageAmount)
  radiatorDamage = radiatorDamage + damageAmount
end

local function applyDeformGroupDamageOilpan(damageAmount)
  fluidLeakRates.oil.oilpan = min(fluidLeakRates.oil.oilpan + damageAmount * 10, 1) --kg/s
  damageTracker.setDamage("engine", "oilpanLeak", true, true)
end

local function applyDeformGroupDamageOilRadiator(damageAmount)
  fluidLeakRates.oil.radiator = min(fluidLeakRates.oil.radiator + damageAmount * 0.1, 0.1) --kg/s
  damageTracker.setDamage("engine", "oilRadiatorLeak", true, true)
end

local function headGasketBlown()
  damageTracker.setDamage("engine", "headGasketDamaged", true, true)
  M.headGasketBlown = true
  --without a working headgasket we don't have full compression anymore -> less torque
  parentEngine:scaleOutputTorque(0.8)
  fluidLeakRates.coolant.headGasket = 0.1 --100g/s
end

local function pistonRingsDamaged()
  damageTracker.setDamage("engine", "pistonRingsDamaged", true, true)
  M.pistonRingsDamaged = true
  --Damaged piston rings cause a loss of compression and therefore less torque
  parentEngine:scaleOutputTorque(0.8)
  fluidLeakRates.oil.pistonRingDamage = 0.01
end

local function connectingRodBearingsDamaged()
  damageTracker.setDamage("engine", "rodBearingsDamaged", true, true)
  M.connectingRodBearingsDamaged = true
end

local function engineBlockMelted()
  parentEngine:scaleFriction(10000) --essentially kill the engine
  M.engineBlockMelted = true
  damageTracker.setDamage("engine", "blockMelted", true, true)
end

local function cylinderWallsMelted()
  parentEngine:scaleFriction(10000) --essentially kill the engine
  M.cylinderWallsMelted = true
  damageTracker.setDamage("engine", "cylinderWallsMelted", true, true)
end

local function setPartConditionRadiator(odometer, integrity, visual)
  
  local integrityState = integrity
  if type(integrity) == "number" then
    local integrityValue = integrity
    integrityState = {
      radiatorDamage = linearScale(integrityValue, 1, 0, 0, 0.1),
      coolantMass = linearScale(integrityValue, 1, 0, fluidReservoirs.coolant.initialMass, fluidReservoirs.coolant.initialMass * 0.1)
    }
  end
  radiatorDamage = integrityState.radiatorDamage or 0
  
  fluidReservoirs.coolant.currentMass = integrityState.coolantMass or fluidReservoirs.coolant.initialMass
end

local function setPartConditionExhaust(odometer, integrity, visual)
  local integrityState = integrity
  if type(integrity) == "number" then
    local integrityValue = integrity
    integrityState = {}
  end
end

local function setPartConditionThermals(odometer, integrity, visual)
  local integrityState = integrity
  if type(integrity) == "number" then
    local integrityValue = integrity
    integrityState = {
      headGasketBlown = integrityValue < 0.3,
      pistonRingsDamaged = integrityValue < 0.2,
      connectingRodBearingsDamaged = integrityValue < 0.1,
      engineBlockMelted = false,
      cylinderWallsMelted = false
    }
  end

  integrityState = integrityState or {} --make sure to have something if no data was passed
  if integrityState.headGasketBlown then
    headGasketBlown()
  end
  if integrityState.pistonRingsDamaged then
    pistonRingsDamaged()
  end
  if integrityState.connectingRodBearingsDamaged then
    connectingRodBearingsDamaged()
  end
  if integrityState.engineBlockMelted then
    engineBlockMelted()
  end
  if integrityState.cylinderWallsMelted then
    cylinderWallsMelted()
  end
end

local function getPartConditionRadiator()
  local integrityState = {
    radiatorDamage = radiatorDamage,
    coolantMass = fluidReservoirs.coolant.currentMass
  }

  local radiatorIntegrityValue = linearScale(radiatorDamage, 0, 0.1, 1, 0)
  
  -- 1.18.7 BEAMLR FIX START, RADIATOR WOULD GET DECREASED INTEGRITY BECAUSE OF LOW COOLANT VOLUME
  --local coolantIntegrityValue = linearScale(fluidReservoirs.coolant.currentMass, fluidReservoirs.coolant.initialMass, fluidReservoirs.coolant.initialMass * 0.1, 1, 0)
  local integrityValue = radiatorIntegrityValue
  -- BEAMLR FIX END
  
  return integrityValue, integrityState
end

local function getPartConditionExhaust()
  local integrityState = {}

  local integrityValue = min(1)
  return integrityValue, integrityState
end

local function getPartConditionThermals()
  local integrityState = {
    headGasketBlown = M.headGasketBlown,
    pistonRingsDamaged = M.pistonRingsDamaged,
    connectingRodBearingsDamaged = M.connectingRodBearingsDamaged,
    engineBlockMelted = M.engineBlockMelted,
    cylinderWallsMelted = M.cylinderWallsMelted
  }

  local headGasketBlownIntegrity = integrityState.headGasketBlown and 0.3 or 1
  local pistonRingsDamagedIntegrity = integrityState.pistonRingsDamaged and 0.2 or 1
  local connectingRodBearingsDamagedIntegrity = integrityState.connectingRodBearingsDamaged and 0.1 or 1
  local meltDamageIntegrity = (integrityState.engineBlockMelted or integrityState.cylinderWallsMelted) and 0.0 or 1
  local integrityValue = min(headGasketBlownIntegrity, pistonRingsDamagedIntegrity, connectingRodBearingsDamagedIntegrity, meltDamageIntegrity)
  return integrityValue, integrityState
end

local function emitBigAfterFireParticles(node1, node2, smokeParticleType)
  obj:addParticleByNodesRelative(node1, node2, -15, 61, 0, 1)
  obj:addParticleByNodesRelative(node1, node2, -10, 62, 0, 1)
  obj:addParticleByNodesRelative(node1, node2, -20, 63, 0, 1)
  obj:addParticleByNodesRelative(node1, node2, -8, 64, 0, 1)
  obj:addParticleByNodesRelative(node1, node2, -12, 65, 0, 1)

  obj:addParticleByNodesRelative(node1, node2, -5, smokeParticleType, 0, 1)
  obj:addParticleByNodesRelative(node1, node2, -3, smokeParticleType, 0, 1)
end

local function updateExhaustGFX(dt)
  local absEngineRPM = abs(parentEngine.outputAV1 * conversion.avToRPM)
  local particleAirspeed = electrics.values.airspeed
  local particulateEmission = (particulates * parentEngine.engineLoad) + idleParticulates
  local lightSmokeParticleType = particleAirspeed < 10 and 40 or 41
  local heavySmokeParticleType = particleAirspeed < 10 and 42 or 43
  local condensationParticleType = particleAirspeed < 10 and 46 or 47
  local exhaustGrayParticleType = particleAirspeed < 10 and 44 or 45
  local steamParticleType = particleAirspeed < 10 and 34 or 39

  --exhaust emission
  afterFire.afterFireSoundTimer = max(afterFire.afterFireSoundTimer - dt, 0)
  afterFire.instantAfterFireFuel = afterFire.instantAfterFireFuel + parentEngine.instantAfterFireFuelDelay:popSum(dt) * dt
  afterFire.sustainedAfterFireFuel = afterFire.sustainedAfterFireFuel + parentEngine.sustainedAfterFireFuelDelay:popSum(dt) * dt
  afterFire.shiftAfterFireFuel = afterFire.shiftAfterFireFuel + parentEngine.shiftAfterFireFuel --no * dt here, design already covers the timeframe

  local maxFuel = max(afterFire.instantAfterFireFuel, max(afterFire.sustainedAfterFireFuel, afterFire.shiftAfterFireFuel))
  local reason = maxFuel == afterFire.shiftAfterFireFuel and 2 or (maxFuel == afterFire.sustainedAfterFireFuel and 1 or 0)

  local tmpAfterFireTime = 0
  local emitSmallParticulates = particleTicks.exhaustSmokeParticleTick > 1 and particulateEmission > 0.05 and particulateEmission < 0.3
  local emitLargeParticulates = particleTicks.exhaustSmokeParticleTick > 1 and particulateEmission >= 0.3
  for _, n in pairs(nodes.exhaustEnds) do
    --regular exhaust smoke
    if emitSmallParticulates then
      obj:addParticleByNodesRelative(n.finish, n.start, absEngineRPM * -0.0004 - 3, lightSmokeParticleType, 0, 1)
    end
    if emitLargeParticulates then
      obj:addParticleByNodesRelative(n.finish, n.start, absEngineRPM * -0.0004 - 3, heavySmokeParticleType, 0, 1)
    end

    local exhaustAudioEndFuel = n.afterFireAudioCoef * maxFuel
    local exhaustVisualEndFuel = n.afterFireVisualCoef * maxFuel
    local exhaustNodeInWater = obj:inWater(n.finish)
    if (exhaustVisualEndFuel > 0 or exhaustAudioEndFuel > 0) and not exhaustNodeInWater then
      if afterFire.afterFireSoundTimer <= 0 then
        if reason == 0 then --Single bang
          if exhaustAudioEndFuel > afterFire.audibleThresholdInstant then --Single bang
            obj:playSFXOnceCT(afterFire.instantAudioSample, n.finish, n.afterFireVolumeCoef * afterFire.instantVolumeCoef, 1.0, 1 - n.afterFireMufflingCoef, 0)
          -- Audio Debug
          -- print (string.format(" AF Trig Insta %.3f/%.3f Eng InstVolCoef %.2f Exh VolCoef %.2f EngExh Vol TOTL %.2f Exh Color %.2f", parentEngine.instantAfterFireCoef, parentEngine.instantAfterFireCoef * n.afterFireAudioCoef, afterFire.instantVolumeCoef, n.afterFireVolumeCoef, afterFire.instantVolumeCoef * n.afterFireVolumeCoef, 1 - n.afterFireMufflingCoef))
          end

          if exhaustVisualEndFuel > afterFire.visualThresholdInstant then --Single bang
            emitBigAfterFireParticles(n.finish, n.start, exhaustGrayParticleType)
          end

          tmpAfterFireTime = max(tmpAfterFireTime, 0.01 + random(100) * 0.001)
        elseif reason == 2 then -- transmission ignition cut sounds
          if exhaustAudioEndFuel > afterFire.audibleThresholdShift then
            obj:playSFXOnceCT(afterFire.shiftAudioSample, n.finish, n.afterFireVolumeCoef * afterFire.shiftVolumeCoef, 1.0, 1 - n.afterFireMufflingCoef, 0)
          -- Audio Debug
          -- print (string.format(" AF Trig Shift %.3f/%.3f Eng InstVolCoef %.2f Exh VolCoef %.2f EngExh Vol TOTL %.2f Exh Color %.2f", parentEngine.shiftAfterFireCoef, parentEngine.shiftAfterFireCoef * n.afterFireAudioCoef, afterFire.shiftVolumeCoef, n.afterFireVolumeCoef, afterFire.shiftVolumeCoef * n.afterFireVolumeCoef, 1 - n.afterFireMufflingCoef))
          end

          if exhaustVisualEndFuel > afterFire.visualThresholdShift then
            emitBigAfterFireParticles(n.finish, n.start, exhaustGrayParticleType)
          end

          tmpAfterFireTime = max(tmpAfterFireTime, 0.5)
        elseif reason == 1 and parentEngine.instantEngineLoad <= 0 then --popcorn single bang
          if exhaustAudioEndFuel > afterFire.audibleThresholdSustained then --popcorn single bang
            obj:playSFXOnceCT(afterFire.sustainedAudioSample, n.finish, n.afterFireVolumeCoef * afterFire.sustainedVolumeCoef, 1.0, 1 - n.afterFireMufflingCoef, 0)
          --print (string.format(" AF Trig Sustd %.3f/%.3f Eng InstVolCoef %.2f Exh VolCoef %.2f EngExh Vol TOTL %.2f Exh Color %.2f", parentEngine.sustainedAfterFireCoef, parentEngine.sustainedAfterFireCoef * n.afterFireAudioCoef, afterFire.sustainedVolumeCoef, n.afterFireVolumeCoef, afterFire.sustainedVolumeCoef * n.afterFireVolumeCoef, 1 - n.afterFireMufflingCoef))
          end

          if exhaustVisualEndFuel > afterFire.visualThresholdSustained then --popcorn single bang
            emitBigAfterFireParticles(n.finish, n.start, exhaustGrayParticleType)
          end

          tmpAfterFireTime = max(tmpAfterFireTime, 0.05 + random(100) * 0.001)
        end
      end
    end

    if parentEngine.continuousAfterFireFuel > 0 and not exhaustNodeInWater then
      emitBigAfterFireParticles(n.finish, n.start, exhaustGrayParticleType)
    end

    --steam from broken head gasket
    if M.headGasketBlown and particleTicks.exhaustSteamParticleTick > 1 and fluidReservoirs.coolant.currentMass > constants.minimumCoolantMass and not (parentEngine.isDisabled or parentEngine.isStalled) and hasCoolantRadiator then
      --also emit steam from all exhaust ends because we are actually vaporizing coolant in the combustion chamber
      obj:addParticleByNodesRelative(n.finish, n.start, absEngineRPM * -0.0004 - 3, steamParticleType, 0, 1)
    end

    if tEnv <= constants.exhaustCondensationThresholdEnvTemp and M.exhaustTemperature <= constants.exhaustCondensationThresholdBlockTemp and particleTicks.exhaustSteamParticleTick > 1 then
      obj:addParticleByNodesRelative(n.finish, n.start, absEngineRPM * -0.0004 - 1.3, condensationParticleType, 0, 1)
    end
  end

  electrics.values.exhaustFlow = clamp(parentEngine.exhaustFlowDelay:popSum(dt) + clamp(maxFuel, 0, 1), 0, 1)

  afterFire.sustainedAfterFireFuel = max(afterFire.sustainedAfterFireFuel - 1000000 * dt, 0)

  if (afterFire.afterFireSoundTimer <= 0 and tmpAfterFireTime > 0) then
    afterFire.instantAfterFireFuel = 0
    afterFire.sustainedAfterFireFuel = 0
    afterFire.shiftAfterFireFuel = 0
  end
  afterFire.afterFireSoundTimer = tmpAfterFireTime > 0 and tmpAfterFireTime or afterFire.afterFireSoundTimer
end

local function updateAirCoolingGFX(dt)
  tEnv = obj:getEnvTemperature() + conversion.kelvinToCelsius
  --k "spring" values
  local kExhaustToAir = 0.000015
  local kCylinderWallToOil = 60
  local kOilSumpToAir = 200
  local kOilToBlock = 300
  local kCylinderWallToBlock = 2200
  local engineRPM = parentEngine.outputAV1 * conversion.avToRPM
  local absEngineRPM = abs(engineRPM)

  local airSpeedThroughVehicle = abs(obj:getFrontAirflowSpeed())
  local airRegulatorActive = min((M.engineBlockTemperature > thermostatTemperature and not parentEngine.isDisabled) and (M.engineBlockTemperature - thermostatTemperature) * 0.1 + airRegulatorClosedCoef or airRegulatorClosedCoef, 1)
  local oilRadiatorActive = min((hasOilRadiator and M.oilTemperature > oilThermostatTemperature and not parentEngine.isDisabled) and (M.oilTemperature - oilThermostatTemperature) or 0, 1)

  local underWaterBlockCoolingCoef = 1
  --if a node is underwater we want to increase the block to air cooling to simulate water cooling of the block
  for _, v in pairs(nodes.engine) do
    underWaterBlockCoolingCoef = underWaterBlockCoolingCoef + (obj:inWater(v) and 1000 or 0)
  end

  --Step 1: Calculate the "forces" with our "spring" k values
  local currentEngineEfficiency = burnEfficiencyCoef[math.floor(parentEngine.engineLoad * 100)]
  local burnEnergyPerUpdate = parentEngine.engineWorkPerUpdate * currentEngineEfficiency

  local energyToCylinderWall = 0.5 * burnEnergyPerUpdate + 0.5 * parentEngine.pumpingLossPerUpdate
  local energyToExhaust = 0.5 * burnEnergyPerUpdate + 0.5 * parentEngine.pumpingLossPerUpdate
  local energyToOil = parentEngine.frictionLossPerUpdate

  local coolingAirSpeed = airSpeedThroughVehicle * 0.7
  local coolingAirSpeedCoef = max(coolingAirSpeed / (10 + coolingAirSpeed), 0.1)

  local blockFanAirSpeedCoef = 1 + blockFanMaxAirSpeed * min(max(engineRPM * blockFanRPMCoef, 0), 1)
  local blockAirSpeedCoef = coolingAirSpeed * engineBlockAirflowCoef

  local energyOilToBlock = (M.oilTemperature - M.engineBlockTemperature) * kOilToBlock
  local energyOilToAir = (M.oilTemperature - tEnv) * oilRadiatorCoef * coolingAirSpeedCoef * oilRadiatorActive
  local energyOilSumpToAir = (M.oilTemperature - tEnv) * kOilSumpToAir * coolingAirSpeedCoef

  local energyCylinderWallToBlock = (M.cylinderWallTemperature - M.engineBlockTemperature) * kCylinderWallToBlock
  local energyCylinderWallToOil = (M.cylinderWallTemperature - M.oilTemperature) * kCylinderWallToOil

  local energyBlockToAir = (M.engineBlockTemperature - tEnv) * (blockFanAirSpeedCoef + blockAirSpeedCoef) * airRegulatorActive * engineBlockAirCoolingEfficiency * underWaterBlockCoolingCoef

  local exhaustTempDiff = M.exhaustTemperature - tEnv
  local exhaustTempSquared = exhaustTempDiff * exhaustTempDiff
  local energyExhaustToAir = exhaustTempSquared * exhaustTempSquared * kExhaustToAir
  local fireTemperature, fireDistance = fire.getClosestHotNodeTempDistance(parentEngine.engineNodeID)
  local energyFireToBlock = (fireTemperature - M.engineBlockTemperature) * 50 * max(10 - fireDistance, 0)

  --Step 2: The integrator
  M.cylinderWallTemperature = max(M.cylinderWallTemperature + (energyToCylinderWall - (energyCylinderWallToOil + energyCylinderWallToBlock) * dt) * energyCoef.cylinderWall, tEnv)
  M.oilTemperature = max(M.oilTemperature + (energyToOil + (energyCylinderWallToOil - energyOilToAir - energyOilSumpToAir - energyOilToBlock) * dt) * energyCoef.oil, tEnv)
  M.engineBlockTemperature = max(M.engineBlockTemperature + (energyCylinderWallToBlock - energyBlockToAir + energyOilToBlock + energyFireToBlock) * energyCoef.engineBlock * dt, tEnv)
  M.exhaustTemperature = max(M.exhaustTemperature + (energyToExhaust - energyExhaustToAir * dt) * energyCoef.exhaust, tEnv)
  M.coolantTemperature = nil

  local particleAirspeed = electrics.values.airspeed
  local engineRunning = (parentEngine.isDisabled or parentEngine.isStalled or parentEngine.ignitionCoef < 1) and 0 or 1
  particleTicks.exhaustOilParticleTick = particleTicks.exhaustOilParticleTick > 1 and 0 or particleTicks.exhaustOilParticleTick + dt * (0.01 * absEngineRPM + 0.1 * particleAirspeed) * engineRunning
  particleTicks.exhaustSmokeParticleTick = particleTicks.exhaustSmokeParticleTick > 1 and 0 or particleTicks.exhaustSmokeParticleTick + dt * (0.02 + (0.02 * absEngineRPM + 0.02 * particleAirspeed)) * engineRunning

  if M.engineBlockTemperature > damageThreshold.engineBlockTemperature then
    M.engineBlockOverheatDamage = min(M.engineBlockOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.headGasket)
    if M.engineBlockOverheatDamage >= damageThreshold.headGasket and not damageTracker.getDamage("engine", "headGasketDamaged") then
      headGasketBlown()
    end

    if M.engineBlockTemperature > engineBlockMeltingTemperature and not M.engineBlockMelted then
      engineBlockMelted()
    end
  end

  if M.oilTemperature > constants.oilTemperatureDamageThreshold then
    local diff = M.oilTemperature - constants.oilTemperatureDamageThreshold
    --increase engine friction relative to temperature of overheated oil
    local frictionCoef = 1 + diff * dt * 0.005
    parentEngine:scaleFriction(frictionCoef)
    M.oilOverheatDamage = min(M.oilOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.connectingRod)
    if M.oilOverheatDamage >= damageThreshold.connectingRod and not damageTracker.getDamage("engine", "rodBearingsDamaged") then
      connectingRodBearingsDamaged()
    end

    damageTracker.setDamage("engine", "oilOverheating", true, true)
  elseif damageTracker.getDamage("engine", "oilOverheating", true) then
    damageTracker.setDamage("engine", "oilOverheating", false)
  end

  if M.cylinderWallTemperature > damageThreshold.cylinderWallTemperature then
    M.cylinderWallOverheatDamage = min(M.cylinderWallOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.pistonRing)
    --if our cylinder wall gets too hot, the piston rings will be damaged eventually
    if M.cylinderWallOverheatDamage >= damageThreshold.pistonRing and not damageTracker.getDamage("engine", "pistonRingsDamaged") then
      pistonRingsDamaged()
    end

    if M.cylinderWallTemperature > cylinderWallMeltingTemperature and not M.cylinderWallsMelted then
      cylinderWallsMelted()
    end
  end

  if M.connectingRodBearingsDamaged then
    knockSoundTick = knockSoundTick > 1 and 0 or knockSoundTick + dt * absEngineRPM * 0.008333
    if knockSoundTick > 1 then
      --make a knocking sound if the bearings are damaged
      sounds.playSoundOnceFollowNode("event:>Vehicle>Failures>failure_engine_knock", nodes.engine[1], 1)
    end
  end
  engineThermalData.coolantTemperature = M.oilTemperature
  --this is to make the tacho display work, oil temp is the best measure of engine temp
  engineThermalData.oilTemperature = M.oilTemperature
  engineThermalData.engineBlockTemperature = M.engineBlockTemperature
  engineThermalData.cylinderWallTemperature = M.cylinderWallTemperature
  engineThermalData.exhaustTemperature = M.exhaustTemperature
  engineThermalData.radiatorAirSpeed = coolingAirSpeed
  engineThermalData.radiatorAirSpeedEfficiency = coolingAirSpeedCoef
  engineThermalData.fanActive = fanAirSpeed > 0
  engineThermalData.thermostatStatus = 0
  engineThermalData.airRegulatorStatus = airRegulatorActive
  engineThermalData.oilThermostatStatus = oilRadiatorActive
  engineThermalData.coolantMass = 0
  engineThermalData.coolantLeakRateOverpressure = 0
  engineThermalData.coolantLeakRateHeadGasket = 0
  engineThermalData.coolantLeakRateRadiator = 0
  engineThermalData.coolantLeakRateOverall = 0
  engineThermalData.coolantEfficiency = 0
  engineThermalData.engineEfficiency = 1 / (currentEngineEfficiency + 1)
  engineThermalData.energyToCylinderWall = energyToCylinderWall
  engineThermalData.energyToOil = energyToOil
  engineThermalData.energyToExhaust = energyToExhaust
  engineThermalData.energyCoolantToAir = 0
  engineThermalData.energyCylinderWallToCoolant = 0
  engineThermalData.energyCoolantToBlock = 0
  engineThermalData.energyCylinderWallToBlock = energyCylinderWallToBlock * dt
  engineThermalData.energyCylinderWallToOil = energyCylinderWallToOil * dt
  engineThermalData.energyOilToAir = energyOilToAir * dt
  engineThermalData.energyOilToBlock = energyOilToBlock * dt
  engineThermalData.energyOilSumpToAir = energyOilSumpToAir * dt
  engineThermalData.energyBlockToAir = energyBlockToAir * dt
  engineThermalData.energyExhaustToAir = energyExhaustToAir * dt
  engineThermalData.engineBlockOverheatDamage = M.engineBlockOverheatDamage
  engineThermalData.oilOverheatDamage = M.oilOverheatDamage
  engineThermalData.cylinderWallOverheatDamage = M.cylinderWallOverheatDamage
  engineThermalData.headGasketBlown = M.headGasketBlown
  engineThermalData.pistonRingsDamaged = M.pistonRingsDamaged
  engineThermalData.connectingRodBearingsDamaged = M.connectingRodBearingsDamaged
  engineThermalData.engineBlockMelted = M.engineBlockMelted
  engineThermalData.cylinderWallsMelted = M.cylinderWallsMelted
  engineThermalData.thermostatTemperature = thermostatTemperature
  engineThermalData.oilThermostatTemperature = oilThermostatTemperature
  if streams.willSend("engineThermalData") then
    gui.send("engineThermalData", engineThermalData)
  end
end

local function updateCoolantRadiatorDamage()
  --This is a compatibility mode for engines that do not have the updated deformgroup features
  if not parentEngine.deformGroupDamages.radiator then
    local currentRadiatorCompatibilityDamage = beamstate.deformGroupDamage[radiatorDamageDeformGroup] and beamstate.deformGroupDamage[radiatorDamageDeformGroup].damage or 0
    radiatorDamage = radiatorDamage + max(currentRadiatorCompatibilityDamage - lastRadiatorCompatibilityDamage, 0)
    lastRadiatorCompatibilityDamage = currentRadiatorCompatibilityDamage
  end
end

local function updateWaterCoolingGFX(dt)
  tEnv = obj:getEnvTemperature() + conversion.kelvinToCelsius
  --k "spring" values
  local kExhaustToAir = 0.00001
  local kCylinderWallToCoolant = 28000
  local kCylinderWallToOil = 100
  local kOilSumpToAir = 60
  local kOilToBlock = 300
  local kCoolantToBlock = 24000
  local kCylinderWallToBlock = 5000
  local engineRPM = parentEngine.outputAV1 * conversion.avToRPM
  local maxEngineRPM = parentEngine.maxRPM or 8000
  local absEngineRPM = abs(engineRPM)

  local adjustedRadiatorDamage = max(radiatorDamage - radiatorDeformThreshold, 0)

  if hasCoolantRadiator then
    --get radiator damage (if there is any) and calculate coolant leak rate based on that
    updateCoolantRadiatorDamage()

    if adjustedRadiatorDamage > 0 and not damageTracker.getDamage("engine", "radiatorLeak") then
      damageTracker.setDamage("engine", "radiatorLeak", true, true)
    end
	-- BEAMLR EDIT TO ALLOW SCRIPTED LEAKS OF COOLANT FROM RADIATOR
    fluidLeakRates.coolant.radiator = max(fluidLeakRates.coolant.radiator, adjustedRadiatorDamage * 10)
	-- BEAMLR EDIT END
  end

  local radiatorFanRPM = 0
  if radiatorFanType == "electric" then
    --eletric fans are either on or off, depending on coolant temperature
    local electricFanOverride = electricRadiatorFanOverrideIgnitionLevel >= 0 and electrics.values.ignitionLevel >= electricRadiatorFanOverrideIgnitionLevel
    if M.coolantTemperature >= radiatorFanTemperature or electricFanOverride then
      fanAirSpeed = radiatorFanMaxAirSpeed
      if radiatorFanSound and not radiatorFanElectricSoundPlaying then
        obj:setVolumePitch(radiatorFanSound, radiatorFanVolume, 1)
        obj:playSFX(radiatorFanSound)
        radiatorFanElectricSoundPlaying = true
      end
    elseif M.coolantTemperature <= thermostatTemperature * 1.05 then
      fanAirSpeed = 0
      if radiatorFanSound and radiatorFanElectricSoundPlaying then
        obj:stopSFX(radiatorFanSound)
        radiatorFanElectricSoundPlaying = false
      end
    end
    radiatorFanRPM = electricalRadiatorFanSmoother:getUncapped(fanAirSpeed > 0 and 2500 or 0, dt)
  elseif radiatorFanType == "mechanical" then
    --mechanical fans are tied to the RPM but at some point they won't go any faster (because they are linked with a clutch)
    radiatorFanRPM = engineRPM * mechanicalFanRPMCoef
    fanAirSpeed = radiatorFanMaxAirSpeed * min(max(engineRPM * mechanicalRadiatorFanRPMCoef, 0), 1)
    if radiatorFanSound then
      obj:setVolumePitch(radiatorFanSound, radiatorFanVolume, absEngineRPM / maxEngineRPM)
    end
  end
  M.radiatorFanSpin = (M.radiatorFanSpin + radiatorFanRPM * dt) % 360

  local airSpeedThroughVehicle = abs(obj:getFrontAirflowSpeed())

   --radiator is only actually used above a certain temperature
  local radiatorActive = min((hasCoolantRadiator and M.coolantTemperature > thermostatTemperature and not parentEngine.isDisabled) and M.coolantTemperature - thermostatTemperature or 0, 1)
  local oilRadiatorActive = min((hasOilRadiator and M.oilTemperature > oilThermostatTemperature and not parentEngine.isDisabled) and M.oilTemperature - oilThermostatTemperature or 0, 1)
  --Efficiency of the cooling system drops with decreasing coolant mass and raising temps above damage threshold
  local coolantEmpty = fluidReservoirs.coolant.currentMass <= constants.minimumCoolantMass
																				  
																	   
  local coolantEfficiency = (not coolantEmpty) and (fluidReservoirs.coolant.currentMass * fluidReservoirs.coolant.invInitialMass) or 0.01

  local underWaterBlockCoolingCoef = 1
  --if a node is underwater we want to increase the block to air cooling to simulate water cooling of the block
  for _, v in pairs(nodes.engine) do
    underWaterBlockCoolingCoef = underWaterBlockCoolingCoef + (obj:inWater(v) and 100 or 0)
  end

  --Step 1: Calculate the "forces" with our "spring" k values
  local currentEngineEfficiency = burnEfficiencyCoef[math.floor(parentEngine.engineLoad * 100)]
  local burnEnergyPerUpdate = parentEngine.engineWorkPerUpdate * currentEngineEfficiency

  local energyToCylinderWall = 0.5 * burnEnergyPerUpdate + 0.5 * parentEngine.pumpingLossPerUpdate
  local energyToExhaust = 0.5 * burnEnergyPerUpdate + 0.5 * parentEngine.pumpingLossPerUpdate
  local energyToOil = parentEngine.frictionLossPerUpdate

  local radiatorAirSpeed = max(airSpeedThroughVehicle * 0.8, fanAirSpeed) --reduce actual airspeed because the rad blocks part of the air
  local radiatorAirSpeedCoef = max(radiatorAirSpeed / (15 + radiatorAirSpeed), 0.1)

  local blockFanAirSpeedCoef = 1 + blockFanMaxAirSpeed * min(max(engineRPM * blockFanRPMCoef, 0), 1)
  local cylinderWallToCoolantAirCooledCoef = blockFanMaxAirSpeed > 0 and 0 or 1 --kill the energy transfer from wall to coolant on an air cooled engine (no coolant)

  local energyCylinderWallToCoolant = (M.cylinderWallTemperature - M.coolantTemperature) * kCylinderWallToCoolant * coolantEfficiency * cylinderWallToCoolantAirCooledCoef
  local energyCoolantToAir = (M.coolantTemperature - tEnv) * radiatorCoef * radiatorActive * radiatorAirSpeedCoef * coolantEfficiency
  local energyCoolantToBlock = (M.coolantTemperature - M.engineBlockTemperature) * kCoolantToBlock * coolantEfficiency * cylinderWallToCoolantAirCooledCoef
  local energyOilToBlock = (M.oilTemperature - M.engineBlockTemperature) * kOilToBlock
  local energyCylinderWallToBlock = (M.cylinderWallTemperature - M.engineBlockTemperature) * kCylinderWallToBlock

  local energyCylinderWallToOil = (M.cylinderWallTemperature - M.oilTemperature) * kCylinderWallToOil
  local energyOilSumpToAir = (M.oilTemperature - tEnv) * kOilSumpToAir * radiatorAirSpeedCoef
  local energyOilToAir = (M.oilTemperature - tEnv) * oilRadiatorCoef * radiatorAirSpeedCoef * oilRadiatorActive
  local energyBlockToAir = (M.engineBlockTemperature - tEnv) * blockFanAirSpeedCoef * engineBlockAirCoolingEfficiency * underWaterBlockCoolingCoef
  local exhaustTempDiff = M.exhaustTemperature - tEnv
  local exhaustTempSquared = exhaustTempDiff * exhaustTempDiff
  local energyExhaustToAir = exhaustTempSquared * exhaustTempSquared * kExhaustToAir
  local fireTemperature, fireDistance = fire.getClosestHotNodeTempDistance(parentEngine.engineNodeID)
  local energyFireToBlock = max((fireTemperature - M.engineBlockTemperature) * 50 * max(10 - fireDistance, 1), 0)

  --Step 2: The integrator
  M.cylinderWallTemperature = max(M.cylinderWallTemperature + (energyToCylinderWall - (energyCylinderWallToOil + energyCylinderWallToCoolant + energyCylinderWallToBlock) * dt) * energyCoef.cylinderWall, tEnv)
  M.coolantTemperature = min(max(M.coolantTemperature + (energyCylinderWallToCoolant - energyCoolantToAir - energyCoolantToBlock) * energyCoef.coolant * dt, tEnv), constants.maxCoolantTemperature)
  M.oilTemperature = max(M.oilTemperature + (energyToOil + (energyCylinderWallToOil - energyOilToAir - energyOilSumpToAir - energyOilToBlock) * dt) * energyCoef.oil, tEnv)
  M.engineBlockTemperature = max(M.engineBlockTemperature + (energyCoolantToBlock + energyCylinderWallToBlock - energyBlockToAir + energyOilToBlock + energyFireToBlock) * energyCoef.engineBlock * dt, tEnv)
  M.exhaustTemperature = max(M.exhaustTemperature + (energyToExhaust - energyExhaustToAir * dt) * energyCoef.exhaust, tEnv)

  local particleAirspeed = electrics.values.airspeed
  local engineRunning = (parentEngine.isDisabled or parentEngine.isStalled or parentEngine.ignitionCoef < 1) and 0 or 1
  particleTicks.engineSteamParticleTick = particleTicks.engineSteamParticleTick > 1 and 0 or particleTicks.engineSteamParticleTick + dt * 4
  particleTicks.radiatorSteamParticleTick = particleTicks.radiatorSteamParticleTick > 1 and 0 or particleTicks.radiatorSteamParticleTick + dt * (200 * adjustedRadiatorDamage + 2 * particleAirspeed)
  particleTicks.exhaustSteamParticleTick = particleTicks.exhaustSteamParticleTick > 1 and 0 or particleTicks.exhaustSteamParticleTick + dt * (0.01 * absEngineRPM + 0.2 * particleAirspeed) * engineRunning
  particleTicks.exhaustOilParticleTick = particleTicks.exhaustOilParticleTick > 1 and 0 or particleTicks.exhaustOilParticleTick + dt * (0.01 * absEngineRPM + 0.1 * particleAirspeed) * engineRunning
  particleTicks.exhaustSmokeParticleTick = particleTicks.exhaustSmokeParticleTick > 1 and 0 or particleTicks.exhaustSmokeParticleTick + dt * (0.02 + (0.02 * absEngineRPM + 0.02 * particleAirspeed)) * engineRunning

  --airspeed depending particle type selection
  local coolantHeavyParticleType = particleAirspeed < 10 and 35 or 37
  local coolantLightParticleType = particleAirspeed < 10 and 48 or 49

  if M.coolantTemperature > constants.coolantTemperatureDamageThreshold then
    --our coolant is too hot, so our radiator cap is releasing pressure/steam and therefore coolant mass
    fluidLeakRates.coolant.overpressure = 0.01 --10g/s

    if particleTicks.engineSteamParticleTick > 1 then
      --emit steam as long as there is still coolant left
      obj:addParticleByNodesRelative(nodes.coolantCap[1], nodes.coolantCap[2], 0, coolantHeavyParticleType, 0, 1)
    end

    damageTracker.setDamage("engine", "coolantOverheating", true, true)
  elseif damageTracker.getDamage("engine", "coolantOverheating") then
    --if the coolant cools down again, we don't leak anymore because of overpressure
    fluidLeakRates.coolant.overpressure = 0
    damageTracker.setDamage("engine", "coolantOverheating", false)
  end

  if M.engineBlockTemperature > damageThreshold.engineBlockTemperature then
    M.engineBlockOverheatDamage = min(M.engineBlockOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.headGasket)
    if M.engineBlockOverheatDamage >= damageThreshold.headGasket and not damageTracker.getDamage("engine", "headGasketDamaged") then
      headGasketBlown()
      --let's get rid of a bit of coolant immediately
      fluidReservoirs.coolant.currentMass = fluidReservoirs.coolant.currentMass * 0.9

      --implement nice steam "explosion" here
      if #parentEngine.engineBlockNodes >= 2 then
        for i = 1, 10 do
          local rnd = random()
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], i * rnd, 43, 0, 1)
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], i * rnd, 39, 0, 1)
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], -i * rnd, 43, 0, 1)
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], -i * rnd, 39, 0, 1)
        end
      end
    end

    if M.engineBlockTemperature > engineBlockMeltingTemperature and not M.engineBlockMelted then
      engineBlockMelted()
    end
  end

  if M.oilTemperature > constants.oilTemperatureDamageThreshold then
    local diff = M.oilTemperature - constants.oilTemperatureDamageThreshold
    --increase engine friction relative to temperature of overheated oil
    local frictionCoef = 1 + diff * dt * 0.005
    parentEngine:scaleFriction(frictionCoef)
    M.oilOverheatDamage = min(M.oilOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.connectingRod)
    if M.oilOverheatDamage >= damageThreshold.connectingRod and not damageTracker.getDamage("engine", "rodBearingsDamaged") then
      connectingRodBearingsDamaged()
    end

    damageTracker.setDamage("engine", "oilOverheating", true, true)
  elseif damageTracker.getDamage("engine", "oilOverheating", true) then
    damageTracker.setDamage("engine", "oilOverheating", false)
  end

  if M.cylinderWallTemperature > damageThreshold.cylinderWallTemperature then
    M.cylinderWallOverheatDamage = min(M.cylinderWallOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.pistonRing)
    --if our cylinder wall gets too hot, the piston rings will be damaged eventually
    if M.cylinderWallOverheatDamage >= damageThreshold.pistonRing and not damageTracker.getDamage("engine", "pistonRingsDamaged") then
      pistonRingsDamaged()
    end

    if M.cylinderWallTemperature > cylinderWallMeltingTemperature and not M.cylinderWallsMelted then
      cylinderWallsMelted()
    end
  end

  if adjustedRadiatorDamage > 0 and particleTicks.radiatorSteamParticleTick > 1 and M.coolantTemperature >= 70 and hasCoolantRadiator then
    --emit steam from the radiator if it's damaged and we have coolant left
    if #nodes.radiator >= 2 then
      local coolantLeakParticle = M.coolantTemperature > 95 and coolantHeavyParticleType or coolantLightParticleType
      obj:addParticleByNodesRelative(nodes.radiator[1], nodes.radiator[2], 0, coolantLeakParticle, 0, 1)
    end
  end

  if M.headGasketBlown then
    --emit steam from the engine since we can't keep the coolant under control anymore
    if particleTicks.engineSteamParticleTick > 1 and hasCoolantRadiator then
      obj:addParticleByNodesRelative(nodes.engine[2], nodes.engine[1], 0, coolantHeavyParticleType, 0, 1)
    end
  end

  if M.connectingRodBearingsDamaged then
    knockSoundTick = knockSoundTick > 1 and 0 or knockSoundTick + dt * absEngineRPM * 0.008333
    if knockSoundTick > 1 then
      --make a knocking sound if the bearings are damaged
      sounds.playSoundOnceFollowNode("event:>Vehicle>Failures>failure_engine_knock", nodes.engine[1], 1)
    end
  end

  --We can lose coolant in different places, sum up all the rates and calculate the new mass
  fluidLeakRates.coolant.overall = (fluidReservoirs.coolant.currentMass > constants.minimumCoolantMass) and (fluidLeakRates.coolant.overpressure + fluidLeakRates.coolant.headGasket + fluidLeakRates.coolant.radiator) or 0 -- max: 0.01 + 0.1 + 1

  fluidReservoirs.coolant.currentMass = max(fluidReservoirs.coolant.currentMass - fluidLeakRates.coolant.overall * dt, constants.minimumCoolantMass)

  -- BEAMLR FIX FOR ENGINE MELTING DUE TO DIVISION BY ZERO WHEN OIL/COOLANT MASS IS EMPTY
  -- Clamping to constants.minimumOilMass to avoid division by zero
  if fluidReservoirs.coolant.currentMass < fluidReservoirs.coolant.initialMass then
    energyCoef.coolant = 1 / (max(fluidReservoirs.coolant.currentMass, constants.minimumCoolantMass) * constants.coolantSpecHeat)
  end
  if fluidReservoirs.oil.currentMass < fluidReservoirs.oil.initialMass then
    energyCoef.oil = 1 / (max(fluidReservoirs.oil.currentMass, constants.minimumOilMass) * constants.oilSpecHeat)
  end
  -- BEAMLR FIX END

  if radiatorHissSound then
    obj:setVolumePitch(radiatorHissSound, fluidLeakRates.coolant.overall, M.coolantTemperature / constants.maxCoolantTemperature, 0, 0)
    if fluidLeakRates.coolant.previousOverall <= 0 and fluidLeakRates.coolant.overall > 0 then
      obj:playSFX(radiatorHissSound)
    end
  end

  fluidLeakRates.coolant.previousOverall = fluidLeakRates.coolant.overall

  engineThermalData.coolantTemperature = M.coolantTemperature
  engineThermalData.oilTemperature = M.oilTemperature
  engineThermalData.engineBlockTemperature = M.engineBlockTemperature
  engineThermalData.cylinderWallTemperature = M.cylinderWallTemperature
  engineThermalData.exhaustTemperature = M.exhaustTemperature
  engineThermalData.radiatorAirSpeed = radiatorAirSpeed
  engineThermalData.radiatorAirSpeedEfficiency = radiatorAirSpeedCoef
  engineThermalData.fanActive = fanAirSpeed > 0
  engineThermalData.thermostatStatus = radiatorActive
  engineThermalData.airRegulatorStatus = 0
  engineThermalData.oilThermostatStatus = oilRadiatorActive
  engineThermalData.coolantMass = fluidReservoirs.coolant.currentMass
  engineThermalData.coolantLeakRateOverpressure = fluidLeakRates.coolant.overpressure
  engineThermalData.coolantLeakRateHeadGasket = fluidLeakRates.coolant.headGasket
  engineThermalData.coolantLeakRateRadiator = fluidLeakRates.coolant.radiator
  engineThermalData.coolantLeakRateOverall = fluidLeakRates.coolant.overall
  engineThermalData.coolantEfficiency = coolantEfficiency
  engineThermalData.engineEfficiency = 1 / (currentEngineEfficiency + 1)
  engineThermalData.energyToCylinderWall = energyToCylinderWall
  engineThermalData.energyToOil = energyToOil
  engineThermalData.energyToExhaust = energyToExhaust
  engineThermalData.energyCoolantToAir = energyCoolantToAir * dt
  engineThermalData.energyCylinderWallToCoolant = energyCylinderWallToCoolant * dt
  engineThermalData.energyCoolantToBlock = energyCoolantToBlock * dt
  engineThermalData.energyCylinderWallToBlock = energyCylinderWallToBlock * dt
  engineThermalData.energyCylinderWallToOil = energyCylinderWallToOil * dt
  engineThermalData.energyOilToAir = energyOilToAir * dt
  engineThermalData.energyOilToBlock = energyOilToBlock * dt
  engineThermalData.energyOilSumpToAir = energyOilSumpToAir * dt
  engineThermalData.energyBlockToAir = energyBlockToAir * dt
  engineThermalData.energyExhaustToAir = energyExhaustToAir * dt
  engineThermalData.engineBlockOverheatDamage = M.engineBlockOverheatDamage
  engineThermalData.oilOverheatDamage = M.oilOverheatDamage
  engineThermalData.cylinderWallOverheatDamage = M.cylinderWallOverheatDamage
  engineThermalData.headGasketBlown = M.headGasketBlown
  engineThermalData.pistonRingsDamaged = M.pistonRingsDamaged
  engineThermalData.connectingRodBearingsDamaged = M.connectingRodBearingsDamaged
  engineThermalData.engineBlockMelted = M.engineBlockMelted
  engineThermalData.cylinderWallsMelted = M.cylinderWallsMelted
  engineThermalData.thermostatTemperature = thermostatTemperature
  engineThermalData.oilThermostatTemperature = oilThermostatTemperature
  if streams.willSend("engineThermalData") then
    gui.send("engineThermalData", engineThermalData)
  end
end

local function updateMechanicsGFX(dt)

  local oilLubricationCoef = 1
  local maximumSafeGVolumeCoef = 1
  --too little oil
  if fluidReservoirs.oil.currentMass < fluidReservoirs.oil.minimumSafeMass and fluidReservoirs.oil.minimumSafeMass > 0 then
    maximumSafeGVolumeCoef = 1 - (fluidReservoirs.oil.minimumSafeMass - fluidReservoirs.oil.currentMass) / fluidReservoirs.oil.minimumSafeMass
    if fluidReservoirs.oil.currentMass <= constants.minimumOilMass then
      oilLubricationCoef = 0
    end
    if not damageTracker.getDamage("engine", "oilLevelCritical") then
      damageTracker.setDamage("engine", "oilLevelCritical", true, true)
    end
  elseif damageTracker.getDamage("engine", "oilLevelCritical") then
    damageTracker.setDamage("engine", "oilLevelCritical", false)
  end

  local oilStarvingSevernessZ = sensors.gz2
  local oilStarvingSevernessXY = 0
  if hasOilStarvingDamage and oilpanNodeBottom > -1 and oilpanNodeTop > -1 then
    local oilpanForceZ, oilpanForceXY = obj:getNodeForceNonInertial(oilpanNodeBottom, oilpanNodeTop)
    local invNodeWeight = 1 / v.data.nodes[oilpanNodeBottom].nodeWeight
    local gravityLimit = 3 * abs(powertrain.currentGravity)
    local oilpanAccZ = clamp(-oilpanForceZ * invNodeWeight, -gravityLimit, gravityLimit)
    local oilpanAccXY = clamp(oilpanForceXY * invNodeWeight, -gravityLimit, gravityLimit)
    oilpanAccZ = oilpanAccZSmoother:getUncapped(oilpanAccZ, dt)
    oilpanAccXY = oilpanAccXYSmoother:getUncapped(oilpanAccXY, dt)
    oilStarvingSevernessZ = -oilpanAccZ -- use the more accurate oilpan Z acc rather than refnode acc if we have it
    local oilAccRatio = clamp(oilpanAccXY / oilpanAccZ, -10, 10)
    oilStarvingSevernessXY = max(oilAccRatio - oilpanMaximumSafeG * maximumSafeGVolumeCoef, 0) --adjust max safe G based on oil level
  end

  local oilStarvingSeverness = max(oilStarvingSevernessXY * 20, oilStarvingSevernessZ * 0.05)
  local oilStarvingTimerAdjust = oilStarvingSeverness > 0 and 1 or -10
  oilStarvingTimer = clamp(oilStarvingTimer + oilStarvingTimerAdjust * dt, 0, oilStarvingTimerThreshold)

  if oilStarvingTimer >= oilStarvingTimerThreshold * 0.5 then
    oilLubricationCoef = min(oilLubricationCoef, linearScale(oilStarvingSevernessXY, 0, 1, 1, 0)) --handle XY starvation
    oilLubricationCoef = min(oilLubricationCoef, linearScale(oilStarvingSevernessZ, 0, 10, 1, 0)) --handle Z starvation (scales are different, that's why it's two calls)
  end

  if oilStarvingTimer >= oilStarvingTimerThreshold then
    if not damageTracker.getDamage("engine", "starvedOfOil") then
      damageTracker.setDamage("engine", "starvedOfOil", true, true)
    end
  elseif damageTracker.getDamage("engine", "starvedOfOil") then
    damageTracker.setDamage("engine", "starvedOfOil", false, false)
  end

  if oilStarvingSevernessZ > 1 then
    fluidLeakRates.oil.gravity = 0.005
  else
    fluidLeakRates.oil.gravity = 0
  end

  local absEngineRPM = abs(parentEngine.outputAV1 * conversion.avToRPM)
  local engineAVAdjustedPistonRingOilLeakRate = fluidLeakRates.oil.pistonRingDamage * (absEngineRPM > 10 and 1 or 0)

  if engineAVAdjustedPistonRingOilLeakRate + fluidLeakRates.oil.gravity > 0 or fluidReservoirs.oil.massInCylinders > 0 then
    local oilParticleType = electrics.values.airspeed < 10 and 36 or 38

    for _, n in pairs(nodes.exhaustEnds) do
      if particleTicks.exhaustOilParticleTick > 1 and not parentEngine.isDisabled then
        --emit blue smoke from all exhaust ends because we are burning oil
        obj:addParticleByNodesRelative(n.finish, n.start, absEngineRPM * -0.0004 - 2, oilParticleType, 0, 1)
      end
    end
  end

  fluidLeakRates.oil.combustionToExhaust = (not parentEngine.isDisabled and not parentEngine.isStalled) and absEngineRPM * 0.00001 or 0

  fluidLeakRates.oil.overall = fluidLeakRates.oil.oilpan + fluidLeakRates.oil.radiator + engineAVAdjustedPistonRingOilLeakRate + fluidLeakRates.oil.gravity
  fluidReservoirs.oil.currentMass = clamp(fluidReservoirs.oil.currentMass - fluidLeakRates.oil.overall * dt, constants.minimumOilMass, fluidReservoirs.oil.initialMass)
  fluidReservoirs.oil.massInCylinders = clamp(fluidReservoirs.oil.massInCylinders + (engineAVAdjustedPistonRingOilLeakRate + fluidLeakRates.oil.gravity - fluidLeakRates.oil.combustionToExhaust) * dt, 0, 0.5)

  --too much oil
  if fluidReservoirs.oil.currentMass > fluidReservoirs.oil.maximumSafeMass and fluidReservoirs.oil.maximumSafeMass > 0 then
    oilLubricationCoef = min(oilLubricationCoef, linearScale(fluidReservoirs.oil.currentMass, fluidReservoirs.oil.maximumSafeMass, fluidReservoirs.oil.maximumSafeMass * 1.1, 1, 0.8))
    if not damageTracker.getDamage("engine", "oilLevelTooHigh") then
      damageTracker.setDamage("engine", "oilLevelTooHigh", true, true)
    end
  elseif damageTracker.getDamage("engine", "oilLevelTooHigh") then
    damageTracker.setDamage("engine", "oilLevelTooHigh", false)
  end

  if oilLubricationCoef < 1 and not (parentEngine.isDisabled or parentEngine.isStalled or parentEngine.ignitionCoef < 1) then
    missingOilDamage = missingOilDamage + 0.00001 * dt * absEngineRPM * (1 - oilLubricationCoef)
    parentEngine:scaleFrictionInitial(1 + missingOilDamage)
  end

  engineThermalData.oilStarvingSevernessZ = oilStarvingSevernessZ
  engineThermalData.oilStarvingSevernessXY = oilStarvingSevernessXY
  engineThermalData.maximumSafeG = oilpanMaximumSafeG * maximumSafeGVolumeCoef
  engineThermalData.oilMass = fluidReservoirs.oil.currentMass
  engineThermalData.miniumSafeOilMass = fluidReservoirs.oil.minimumSafeMass
  engineThermalData.maximumSafeOilMass = fluidReservoirs.oil.maximumSafeMass
  engineThermalData.oilLeakRateOilpan = fluidLeakRates.oil.oilpan
  engineThermalData.oilLeakRateRadiator = fluidLeakRates.oil.radiator
  engineThermalData.oilLeakRateGravity = fluidLeakRates.oil.gravity
  engineThermalData.oilLeakRatePistonRingDamage = engineAVAdjustedPistonRingOilLeakRate
  engineThermalData.oilLeakRateOverall = fluidLeakRates.oil.overall
  engineThermalData.oilLubricationCoef = oilLubricationCoef
  engineThermalData.missingOilDamage = missingOilDamage
end

local function updateHeatTicksGFX(dt)
  local engineRunning = parentEngine.outputAV1 > parentEngine.starterMaxAV * 0.8

  if engineRunning then
    -- no ticks should happen if the engine is running. keep the delays at the "start delay"
    -- so the ticks don't start occurring immediately after the engine turns off.

    heatTickData.exhaustTickDelay = heatTickData.exhaustTickStartDelay
    heatTickData.engineTickDelay = heatTickData.engineTickStartDelay
  else
    local invDt = 1 / dt
    -- exhaust ticks
    local adjustedExhaustTemperature = M.exhaustTemperature - heatTickData.exhaustTickMinTemperature
    local deltaTExhaust = heatTickData.exhaustDeltaTempSmoother:get(heatTickData.lastExhaustTemperature - adjustedExhaustTemperature, dt)
    local deltaTExhaustRate = deltaTExhaust * invDt

    heatTickData.exhaustTickDelay = max(heatTickData.exhaustTickDelay - dt, 0)

    if deltaTExhaustRate <= heatTickData.exhaustTickMinRate then
      heatTickData.exhaustTickDelay = heatTickData.exhaustTickStartDelay
    end

    deltaTExhaustRate = min(max(deltaTExhaustRate, heatTickData.exhaustTickMinRate), heatTickData.exhaustTickMaxRate)
    heatTickData.exhaustTickBucket = max(heatTickData.exhaustTickBucket + deltaTExhaustRate * dt, 0)

	-- BEAMLR FIX ON BELOW LINE FOR MISSING EXHAUST NODES TO PLAY COOLING METAL TICKING SFX
	-- #nodes.exhaust > 0 avoids trying to play the SFX if exhaust manifold is removed (only allowed with AVB)
    if #nodes.exhaust > 0 and heatTickData.exhaustTickBucket > heatTickData.exhaustTickBucketThreshold and adjustedExhaustTemperature > 0 and heatTickData.exhaustTickDelay <= 0 then
      local node = nodes.exhaust[random(#nodes.exhaust)]
	  local tickSize = linearScale(randomGauss3(), 0, 3, 0, 1) ^ heatTickData.exhaustTickSizeBias
	  sounds.playSoundOnceFollowNode(heatTickData.exhaustTickEventName, node, heatTickData.exhaustTickVolume, heatTickData.exhaustTickPitch, tickSize)
	  heatTickData.exhaustTickBucket = 0
	  heatTickData.exhaustTickBucketThreshold = heatTickData.exhaustTickPeriodGain * linearScale(randomGauss3(), 0, 3, 0.25, 1.75)
	end

    heatTickData.lastExhaustTemperature = adjustedExhaustTemperature

    -- engine ticks

    local adjustedEngineBlockTemperature = M.engineBlockTemperature - heatTickData.engineTickMinTemperature
    local deltaTEngine = heatTickData.engineDeltaTempSmoother:get(heatTickData.lastEngineBlockTemperature - adjustedEngineBlockTemperature, dt)
    local deltaTEngineRate = deltaTEngine * invDt

    heatTickData.engineTickDelay = max(heatTickData.engineTickDelay - dt, 0)

    if deltaTEngineRate <= heatTickData.engineTickMinRate then
      heatTickData.engineTickDelay = heatTickData.engineTickStartDelay
    end

    deltaTEngineRate = min(max(deltaTEngineRate, heatTickData.engineTickMinRate), heatTickData.engineTickMaxRate)
    heatTickData.engineTickBucket = max(heatTickData.engineTickBucket + deltaTEngineRate * dt, 0)

    if heatTickData.engineTickBucket > heatTickData.engineTickBucketThreshold and adjustedEngineBlockTemperature > 0 and heatTickData.engineTickDelay <= 0 then
      local node = nodes.engine[random(#nodes.engine)]
      local tickSize = linearScale(randomGauss3(), 0, 3, 0, 1) ^ heatTickData.engineTickSizeBias
      sounds.playSoundOnceFollowNode(heatTickData.engineTickEventName, node, heatTickData.engineTickVolume, heatTickData.engineTickPitch, tickSize)
      heatTickData.engineTickBucket = 0
      heatTickData.engineTickBucketThreshold = heatTickData.engineTickPeriodGain * linearScale(randomGauss3(), 0, 3, 0.25, 1.75)
    end

    heatTickData.lastEngineBlockTemperature = adjustedEngineBlockTemperature

    if heatTickData.debugEnabled then
      streams.drawGraph("adjEngBlkTemp", {value = adjustedEngineBlockTemperature, min = 0, max = 150})
      streams.drawGraph("engineTickDelay", {value = heatTickData.engineTickDelay, min = 0, max = 1})
      streams.drawGraph("engineTickBucket", {value = heatTickData.engineTickBucket / max(1e-5, heatTickData.engineTickBucketThreshold), min = 0, max = 1})
      streams.drawGraph("deltaTEngineRate", {value = deltaTEngine * invDt, min = -1, max = 5})
      streams.drawGraph("exhaustTickBucket", {value = heatTickData.exhaustTickBucket / max(1e-5, heatTickData.exhaustTickBucketThreshold), min = 0, max = 1})
      streams.drawGraph("deltaTExhaustRate", {value = deltaTExhaust * invDt, min = -1, max = 5})
    end
  end
end

local function getExhaustEndNodes(startNode, exhaustTree)
  local branch = exhaustTree.children[startNode]
  local endNodes = {}
  local allConnectedNodes = {}

  for k, child in pairs(branch.children) do
    --if at this point something broke away or we reached the original end of the branch
    if (child.childrenCount ~= child.initialChildrenCount or child.initialChildrenCount == 0) and not child.isStartNode then
      --save the nodes as exit nodes
      table.insert(
        endNodes,
        {
          start = child.previous,
          finish = child.cid,
          afterFireAudioCoef = child.afterFireAudioCoef,
          afterFireVolumeCoef = child.afterFireVolumeCoef,
          afterFireMufflingCoef = child.afterFireMufflingCoef,
          afterFireVisualCoef = child.afterFireVisualCoef,
          exhaustAudioOpennessCoef = child.exhaustAudioOpennessCoef,
          exhaustAudioGainChange = child.exhaustAudioGainChange
        }
      )
    end
    table.insert(allConnectedNodes, child.cid)
    --if we have children left and we are not broken
    if child.childrenCount > 0 and not child.isBroken then
      --continue to search for more exit nodes in this branch
      local childEndNodes, childConnectedNodes = getExhaustEndNodes(k, branch)
      arrayConcat(endNodes, childEndNodes)
      arrayConcat(allConnectedNodes, childConnectedNodes)
    end
  end

  return endNodes, allConnectedNodes
end

local function parseExhaustTree(currentBranch, currentExhaustBeams, startNodeLookup)
  --copy table to not mess with the original one
  local beams = shallowcopy(currentExhaustBeams)
  local currentBeamKey, currentBeam = next(beams, nil)
  currentBranch.childrenCount = 0
  currentBranch.children = {}

  if not currentBranch.previous then
    local nodeData = v.data.nodes[currentBranch.cid]
    currentBranch.afterFireAudioCoef = (nodeData.afterFireAudioCoef or 1)
    currentBranch.afterFireVolumeCoef = (nodeData.afterFireVolumeCoef or 1)
    currentBranch.afterFireMufflingCoef = (nodeData.afterFireMufflingCoef or 1)
    currentBranch.afterFireVisualCoef = (nodeData.afterFireVisualCoef or 1)
    currentBranch.exhaustAudioOpennessCoef = (nodeData.exhaustAudioOpennessCoef or 1)
    currentBranch.exhaustAudioGainChange = (nodeData.exhaustAudioGainChange or 0)
  end

  while currentBeam ~= nil do
    --if your node connects to the current beam (via node1 or node2)
    if currentBranch.cid == currentBeam.id1 then
      beams[currentBeamKey] = nil --beam is handled, ignore further down the line
      --build child branch based on current beam
      local nodeData = v.data.nodes[currentBeam.id2]
      local node = {
        cid = currentBeam.id2,
        previous = currentBranch.cid,
        beam = currentBeam.cid,
        level = currentBranch.level + 1,
        afterFireAudioCoef = currentBranch.afterFireAudioCoef * (nodeData.afterFireAudioCoef or 1),
        afterFireVolumeCoef = currentBranch.afterFireVolumeCoef * (nodeData.afterFireVolumeCoef or 1),
        afterFireMufflingCoef = currentBranch.afterFireMufflingCoef * (nodeData.afterFireMufflingCoef or 1),
        afterFireVisualCoef = currentBranch.afterFireVisualCoef * (nodeData.afterFireVisualCoef or 1),
        exhaustAudioOpennessCoef = currentBranch.exhaustAudioOpennessCoef * (nodeData.exhaustAudioMufflingCoef or 1),
        exhaustAudioGainChange = currentBranch.exhaustAudioGainChange + (nodeData.exhaustAudioGainChange or 0)
      }
      currentBranch.children[currentBeam.id2] = parseExhaustTree(node, beams, startNodeLookup)
      currentBranch.childrenCount = currentBranch.childrenCount + 1
    elseif currentBranch.cid == currentBeam.id2 then
      --same as above but with switched id1 <-> id2
      beams[currentBeamKey] = nil
      local nodeData = v.data.nodes[currentBeam.id1]
      local node = {
        cid = currentBeam.id1,
        previous = currentBranch.cid,
        beam = currentBeam.cid,
        level = currentBranch.level + 1,
        afterFireAudioCoef = currentBranch.afterFireAudioCoef * (nodeData.afterFireAudioCoef or 1),
        afterFireVolumeCoef = currentBranch.afterFireVolumeCoef * (nodeData.afterFireVolumeCoef or 1),
        afterFireMufflingCoef = currentBranch.afterFireMufflingCoef * (nodeData.afterFireMufflingCoef or 1),
        afterFireVisualCoef = currentBranch.afterFireVisualCoef * (nodeData.afterFireVisualCoef or 1),
        exhaustAudioOpennessCoef = currentBranch.exhaustAudioOpennessCoef * (nodeData.exhaustAudioMufflingCoef or 1),
        exhaustAudioGainChange = currentBranch.exhaustAudioGainChange + (nodeData.exhaustAudioGainChange or 0)
      }
      currentBranch.children[currentBeam.id1] = parseExhaustTree(node, beams, startNodeLookup)
      currentBranch.childrenCount = currentBranch.childrenCount + 1
    end

    currentBeamKey, currentBeam = next(beams, currentBeamKey)
  end

  currentBranch.initialChildrenCount = currentBranch.childrenCount
  currentBranch.isStartNode = startNodeLookup[currentBranch.cid] and true or false
  return currentBranch
end

local function buildExhaustTree()
  exhaustStartNodes = {}
  exhaustBeams = {}
  local exhaustBeamCache = {}
  local startNodeLookup = {}

  --search for the exhaust start node
  for _, n in pairs(v.data.nodes) do
    if n.isExhaust and (type(n.isExhaust) == "boolean" or n.isExhaust == parentEngine.name) then
      table.insert(exhaustStartNodes, n)
      startNodeLookup[n.cid] = true
    end
  end

  if #exhaustStartNodes <= 0 then
    log("E", "engine.buildExhaustTree", "No exhaust start node(s) specified")
    return false
  end

  --find all exhaust beams
  for _, b in pairs(v.data.beams) do
    if b.isExhaust and (type(b.isExhaust) == "boolean" or b.isExhaust == parentEngine.name) then
      --one table for immediate use
      table.insert(exhaustBeamCache, b)
      --one table for look ups when a beam breaks
      exhaustBeams[b.cid] = true
    end
  end

  exhaustTrees = {}
  for _, n in ipairs(exhaustStartNodes) do
    --build exhaust tree recursively
    local exhaustTree = {children = {}, startCid = n.cid}
    exhaustTree.children[n.cid] = parseExhaustTree({cid = n.cid, level = 0}, exhaustBeamCache, startNodeLookup)
    table.insert(exhaustTrees, exhaustTree)
  end

  local tmpExhaustEndNodes = {}
  local tmpExhaustConnectedNodes = {}
  for _, t in ipairs(exhaustTrees) do
    --find initial exhaust end points
    local treeEndNodes, allTreeNodes = getExhaustEndNodes(t.startCid, t)
    tmpExhaustEndNodes = arrayConcat(tmpExhaustEndNodes, treeEndNodes)
    tmpExhaustConnectedNodes = arrayConcat(tmpExhaustConnectedNodes, allTreeNodes)
  end
  --dump(tmpExhaustEndNodes)

  nodes.exhaustEnds = {}
  local exhaustEndNodeDeDuplicate = {}
  for _, v in ipairs(tmpExhaustEndNodes) do
    if not exhaustEndNodeDeDuplicate[v.finish] then
      table.insert(nodes.exhaustEnds, v)
      exhaustEndNodeDeDuplicate[v.finish] = true
    end
  end

  nodes.exhaust = {}
  local exhaustConnectedNodeDeDuplicate = {}
  for _, v in ipairs(tmpExhaustConnectedNodes) do
    if not exhaustConnectedNodeDeDuplicate[v] then
      table.insert(nodes.exhaust, v)
      exhaustConnectedNodeDeDuplicate[v] = true
    end
  end

  --dump(nodes.exhaustEnds)
  M.exhaustEndNodes = nodes.exhaustEnds

  --BEAMLR EDIT 
  if #nodes.exhaustEnds <= 0 then
    log("E", "engine.buildExhaustTree", "No exhaust end nodes found (BEAMLR EDIT: still turning on thermals system for oil leak mechanic)")
    return true -- usually returns false but this should allow oil to leak even if intake is missing, hopefully wont cause other issues
  end
  -- BEAMLR EDIT

  --dump(exhaustTrees)
  --print(afterFire.exhaustMaxLevel)

  return true
end

local function exhaustBeamBroken(id, exhaustTree)
  for _, v in pairs(exhaustTree.children) do
    --if the broken beam matches one of our tree beams
    if v and v.beam == id then
      --break off this branch
      v.isBroken = true
      exhaustTree.childrenCount = exhaustTree.childrenCount - 1
    elseif v and v.children then
      exhaustBeamBroken(id, v)
    end
  end
end

local function beamBroke(id)
  if exhaustBeams and exhaustBeams[id] then
    exhaustBeams[id] = false
    local tmpExhaustEndNodes = {}
    local tmpExhaustConnectedNodes = {}
    for _, t in ipairs(exhaustTrees) do
      --break off a tree branch
      exhaustBeamBroken(id, t)
      --and find the new exit nodes
      local treeEndNodes, allTreeNodes = getExhaustEndNodes(t.startCid, t)
      tmpExhaustEndNodes = arrayConcat(tmpExhaustEndNodes, treeEndNodes)
      tmpExhaustConnectedNodes = arrayConcat(tmpExhaustConnectedNodes, allTreeNodes)
    end
    --dump(tmpExhaustNodes)

    nodes.exhaustEnds = {}
    local exhaustEndNodeDeDuplicate = {}
    for _, v in ipairs(tmpExhaustEndNodes) do
      if not exhaustEndNodeDeDuplicate[v.finish] then
        table.insert(nodes.exhaustEnds, v)
        exhaustEndNodeDeDuplicate[v.finish] = true
      end
    end

    nodes.exhaust = {}
    local exhaustConnectedNodeDeDuplicate = {}
    for _, v in ipairs(tmpExhaustConnectedNodes) do
      if not exhaustConnectedNodeDeDuplicate[v] then
        table.insert(nodes.exhaust, v)
        exhaustConnectedNodeDeDuplicate[v] = true
      end
    end

    --dump(nodes.exhaustEnds)

    parentEngine:exhaustEndNodesChanged(nodes.exhaustEnds)

    if not damageTracker.getDamage("engine", "exhaustBroken") then
      damageTracker.setDamage("engine", "exhaustBroken", true)
      guihooks.message("vehicle.combustionEngine.exhaustDamaged", 4, "vehicle.damage.exhaust")
    end
  end
end

local function resetExhaustTree(exhaustTree)
  for _, v in pairs(exhaustTree.children) do
    --if one of the children are already broken
    if v then
      if v.isBroken then
        --repair this branch
        v.isBroken = false
        exhaustTree.childrenCount = exhaustTree.childrenCount + 1
      end
      if v.children then
        resetExhaustTree(v)
      end
    end
  end
end

local function reset(jbeamData)
  tEnv = obj:getEnvTemperature() + conversion.kelvinToCelsius
  --default temperatures, can be adjusted to fit whatever our goal is (starting up with cold vs warm car)
  local startingTemperature = startPreHeated and constants.preHeatTemperature or tEnv
  
  M.engineBlockTemperature = startingTemperature
  M.cylinderWallTemperature = startingTemperature
  M.oilTemperature = startingTemperature
  M.coolantTemperature = startingTemperature
  M.exhaustTemperature = startingTemperature

  if not thermalsEnabled then
    --disable the whole thing unless stated otherwise
    --log("D", "engine.initThermals", "Engine thermals are disabled since they are missing in JBeam")
    return
  end

  fanAirSpeed = 0
  radiatorFanElectricSoundPlaying = false
  M.engineBlockOverheatDamage = 0
  M.oilOverheatDamage = 0
  M.cylinderWallOverheatDamage = 0
  M.headGasketBlown = jbeamData.headGasketBlownOverride or false
  M.pistonRingsDamaged = jbeamData.pistonRingsDamagedOverride or false
  M.connectingRodBearingsDamaged = jbeamData.connectingRodBearingsDamagedOverride or false
  radiatorDamage = 0
  M.cylinderWallsMelted = false
  M.engineBlockMelted = false
  M.radiatorFanSpin = 0

  fluidLeakRates.coolant.overpressure = 0
  fluidLeakRates.coolant.headGasket = 0
  fluidLeakRates.coolant.radiator = 0
  fluidLeakRates.coolant.overall = 0
  fluidLeakRates.coolant.previousOverall = 0
  fluidLeakRates.oil.oilpan = 0
  fluidLeakRates.oil.radiator = 0
  fluidLeakRates.oil.gravity = 0
  fluidLeakRates.oil.pistonRingDamage = 0
  fluidLeakRates.oil.combustionToExhaust = 0
  fluidLeakRates.oil.overall = 0

  fluidReservoirs.coolant.currentMass = fluidReservoirs.coolant.initialMass
  fluidReservoirs.oil.currentMass = fluidReservoirs.oil.initialMass
  fluidReservoirs.oil.massInCylinders = 0

  oilStarvingTimer = 0
  missingOilDamage = 0

  oilpanAccXYSmoother:reset()
  oilpanAccZSmoother:set(-powertrain.currentGravity)

  particleTicks.engineSteamParticleTick = 0
  particleTicks.exhaustSteamParticleTick = 0
  particleTicks.exhaustOilParticleTick = 0
  particleTicks.exhaustSmokeParticleTick = 0
  knockSoundTick = 0

  afterFire.afterFireSoundTimer = 0
  afterFire.instantAfterFireFuel = 0
  afterFire.sustainedAfterFireFuel = 0
  afterFire.shiftAfterFireFuel = 0

  electricalRadiatorFanSmoother:reset()

  for k, _ in pairs(exhaustBeams) do
    exhaustBeams[k] = true
  end

  local tmpExhaustEndNodes = {}
  local tmpExhaustConnectedNodes = {}
  for _, t in ipairs(exhaustTrees) do
    --break off a tree branch
    resetExhaustTree(t)
    --and find the new exit nodes
    local treeEndNodes, allTreeNodes = getExhaustEndNodes(t.startCid, t)
    tmpExhaustEndNodes = arrayConcat(tmpExhaustEndNodes, treeEndNodes)
    tmpExhaustConnectedNodes = arrayConcat(tmpExhaustConnectedNodes, allTreeNodes)
  end

  nodes.exhaustEnds = {}
  local exhaustNodeDeDuplicate = {}
  for _, v in ipairs(tmpExhaustEndNodes) do
    if not exhaustNodeDeDuplicate[v.finish] then
      table.insert(nodes.exhaustEnds, v)
      exhaustNodeDeDuplicate[v.finish] = true
    end
  end

  nodes.exhaust = {}
  local exhaustConnectedNodeDeDuplicate = {}
  for _, v in ipairs(tmpExhaustConnectedNodes) do
    if not exhaustConnectedNodeDeDuplicate[v] then
      table.insert(nodes.exhaust, v)
      exhaustConnectedNodeDeDuplicate[v] = true
    end
  end

  --dump(tmpExhaustEndNodes)
  M.exhaustEndNodes = nodes.exhaustEnds
  --invExhaustNodeCount = #nodes.exhaustEnds > 0 and 1 / sqrt(#nodes.exhaustEnds) or 0

  if hasCoolantRadiator then
    damageTracker.setDamage("engine", "radiatorLeak", false)
  end
  damageTracker.setDamage("engine", "coolantOverheating", false)
  damageTracker.setDamage("engine", "oilOverheating", false)
  damageTracker.setDamage("engine", "oilRadiatorLeak", false)
  damageTracker.setDamage("engine", "oilpanLeak", false)
  damageTracker.setDamage("engine", "headGasketDamaged", M.headGasketBlown)
  damageTracker.setDamage("engine", "rodBearingsDamaged", M.connectingRodBearingsDamaged)
  damageTracker.setDamage("engine", "pistonRingsDamaged", M.pistonRingsDamaged)
  damageTracker.setDamage("engine", "cylinderWallsMelted", false)
  damageTracker.setDamage("engine", "blockMelted", false)
  damageTracker.setDamage("engine", "starvedOfOil", false)
  damageTracker.setDamage("engine", "oilLevelCritical", false)
  damageTracker.setDamage("engine", "oilLevelTooHigh", false)
  damageTracker.setDamage("engine", "exhaustBroken", false)
end

local function initThermals(jbeamData)
  thermalsEnabled = false
  tEnv = obj:getEnvTemperature() + conversion.kelvinToCelsius
   --default temperatures, can be adjusted to fit whatever our goal is
  M.engineBlockTemperature = tEnv
  M.cylinderWallTemperature = tEnv
  M.oilTemperature = tEnv
  M.coolantTemperature = tEnv
  M.exhaustTemperature = tEnv
  if not jbeamData.thermalsEnabled then
    --disable the whole thing unless stated otherwise
    --log("D", "engine.initThermals", "Engine thermals are disabled since they are missing in JBeam")
    return
  end

  heatTickData.lastEngineBlockTemperature = M.engineBlockTemperature
  heatTickData.lastExhaustTemperature = M.exhaustTemperature

  fanAirSpeed = 0
  M.engineBlockOverheatDamage = 0
  M.oilOverheatDamage = 0
  M.cylinderWallOverheatDamage = 0
  M.headGasketBlown = jbeamData.headGasketBlownOverride or false
  M.pistonRingsDamaged = jbeamData.pistonRingsDamagedOverride or false
  M.connectingRodBearingsDamaged = jbeamData.connectingRodBearingsDamagedOverride or false
  radiatorDamage = 0
  M.cylinderWallsMelted = false
  M.engineBlockMelted = false
  M.radiatorFanSpin = 0

  oilStarvingTimer = 0
  missingOilDamage = 0
  particleTicks.engineSteamParticleTick = 0
  particleTicks.exhaustSteamParticleTick = 0
  particleTicks.exhaustOilParticleTick = 0
  particleTicks.exhaustSmokeParticleTick = 0
  knockSoundTick = 0

  particulates = jbeamData.particulates or 0
  idleParticulates = jbeamData.idleParticulates or 0

  afterFire = {
    afterFireSoundTimer = 0,
    afterFireDecayTimer = 0,
    instantAfterFireFuel = 0,
    sustainedAfterFireFuel = 0,
    shiftAfterFireFuel = 0,
    instantAudioSample = jbeamData.instantAfterFireSound or "event:>Vehicle>Afterfire>01_Single_EQ1",
    sustainedAudioSample = jbeamData.sustainedAfterFireSound or "event:>Vehicle>Afterfire>01_Multi_EQ1",
    shiftAudioSample = jbeamData.shiftAfterFireSound or "event:>Vehicle>Afterfire>01_Shift_EQ1",
    instantVolumeCoef = jbeamData.instantAfterFireVolumeCoef or 1,
    sustainedVolumeCoef = jbeamData.sustainedAfterFireVolumeCoef or 1,
    shiftVolumeCoef = jbeamData.shiftAfterFireVolumeCoef or 4,
    audibleThresholdInstant = jbeamData.afterFireAudibleThresholdInstant or 500000,
    audibleThresholdSustained = jbeamData.afterFireAudibleThresholdSustained or 40000,
    audibleThresholdShift = jbeamData.afterFireAudibleThresholdShift or 250000,
    visualThresholdInstant = jbeamData.afterFireVisualThresholdInstant or 500000,
    visualThresholdSustained = jbeamData.afterFireVisualThresholdSustained or 150000,
    visualThresholdShift = jbeamData.afterFireVisualThresholdShift or 1000000
  }

  -- Audio Debug
  -- print (string.format("instantAfterFire coef %.2f / sustainedAfterFire coef %.2f / shiftVolumeCoef %.2f", jbeamData.instantAfterFireVolumeCoef, jbeamData.sustainedAfterFireVolumeCoef, jbeamData.shiftAfterFireVolumeCoef))
  -- print (string.format("audibleThresholdInstant %.2f / audibleThresholdSustained %.2f / audibleThresholdShift %.2f", jbeamData.afterFireAudibleThresholdInstant, jbeamData.afterFireAudibleThresholdSustained, jbeamData.afterFireAudibleThresholdShift))

  fluidReservoirs.coolant.currentMass = max(jbeamData.coolantVolume or 0, constants.minimumCoolantMass) --can't have 0 coolant to protect against div by 0
  fluidReservoirs.coolant.initialMass = fluidReservoirs.coolant.currentMass
  fluidReservoirs.coolant.invInitialMass = 1 / fluidReservoirs.coolant.currentMass
  fluidReservoirs.oil.currentMass = (jbeamData.oilVolume or 5) * 0.87
  fluidReservoirs.oil.initialMass = fluidReservoirs.oil.currentMass
  fluidReservoirs.oil.minimumSafeMass = jbeamData.oilMinimumSafeVolume and (jbeamData.oilMinimumSafeVolume * 0.87) or fluidReservoirs.oil.currentMass - 0.87 --1L extra by default
  fluidReservoirs.oil.maximumSafeMass = jbeamData.oilMaximumSafeVolume and (jbeamData.oilMaximumSafeVolume * 0.87) or fluidReservoirs.oil.currentMass + 0.87 --1L extra by default
  fluidReservoirs.oil.massInCylinders = 0

  fluidLeakRates.coolant.overpressure = 0
  fluidLeakRates.coolant.headGasket = 0
  fluidLeakRates.coolant.radiator = 0
  fluidLeakRates.coolant.overall = 0
  fluidLeakRates.coolant.previousOverall = 0
  fluidLeakRates.oil.oilpan = 0
  fluidLeakRates.oil.radiator = 0
  fluidLeakRates.oil.gravity = 0
  fluidLeakRates.oil.pistonRingDamage = 0
  fluidLeakRates.oil.combustionToExhaust = 0
  fluidLeakRates.oil.overall = 0

  if jbeamData.oilpanNodes_nodes then
    oilpanNodeBottom = jbeamData.oilpanNodes_nodes[1] or -1
    oilpanNodeTop = jbeamData.oilpanNodes_nodes[2] or -1
  end
  oilpanMaximumSafeG = jbeamData.oilpanMaximumSafeG or 1.2
  oilpanAccZSmoother:set(-powertrain.currentGravity)

  burnEfficiencyCoef = {}
  for k, v in pairs(parentEngine.invBurnEfficiencyTable) do
    burnEfficiencyCoef[k] = v - 1
  end
  mechanicalRadiatorFanRPMCoef = 1 / (parentEngine.maxRPM * 0.7)

  local engineBlockMaterial = jbeamData.engineBlockMaterial or "iron"
  local engineBlockSpecHeat
  local cylinderWallSpecHeat
  if engineBlockMaterial == "iron" then
    engineBlockSpecHeat = 450
    cylinderWallSpecHeat = 450
    engineBlockMeltingTemperature = 1100
    cylinderWallMeltingTemperature = 1200
  elseif engineBlockMaterial == "aluminium" or engineBlockMaterial == "aluminum" then
    engineBlockSpecHeat = 910
    cylinderWallSpecHeat = 910
    engineBlockMeltingTemperature = 660
    cylinderWallMeltingTemperature = 700
  else
    log("E", "engine.initThermals", "Unknown engine block material specified: " .. engineBlockMaterial)
    log("E", "engine.initThermals", "Engine thermals are disabled due to above error")
    return
  end

  engineBlockAirCoolingEfficiency = jbeamData.engineBlockAirCoolingEfficiency or 50
  engineBlockAirflowCoef = jbeamData.engineBlockAirflowCoef or 1
  blockFanMaxAirSpeed = jbeamData.blockFanMaxAirSpeed or 0
  blockFanRPMCoef = 1 / parentEngine.maxRPM
  radiatorFanType = jbeamData.radiatorFanType
  electricRadiatorFanOverrideIgnitionLevel = jbeamData.electricRadiatorFanOverrideIgnitionLevel or -1
  local radiatorArea = jbeamData.radiatorArea or 0
  local isAirCooledOnly = jbeamData.isAirCooledOnly or false
  radiatorFanMaxAirSpeed = jbeamData.radiatorFanMaxAirSpeed or 0
  mechanicalFanRPMCoef = jbeamData.mechanicalFanRPMCoef or 0.5
  local radiatorEffectiveness = jbeamData.radiatorEffectiveness or 0
  local radiatorFanTemperatureDesired = jbeamData.radiatorFanTemperature or 110
  thermostatTemperature = jbeamData.thermostatTemperature or 90
  radiatorFanTemperature = max(radiatorFanTemperatureDesired, thermostatTemperature * 1.03 + 2) --make sure that rad fan temp and thermostat fan work correctly together
  if radiatorFanTemperature > radiatorFanTemperatureDesired then
    log("W", "engine.initThermals", string.format("Increased desired radiator fan temperature from '%dC' to '%dC' to prevent fan trigger issues with thermostat at '%dC'.", radiatorFanTemperatureDesired, radiatorFanTemperature, thermostatTemperature))
  end

  startPreHeated = settings.getValue("startThermalsPreHeated")
  --default temperatures, can be adjusted to fit whatever our goal is (starting up with cold vs warm car)
  constants.preHeatTemperature = max(thermostatTemperature - 10, tEnv)
  local startingTemperature = startPreHeated and constants.preHeatTemperature or tEnv
  M.engineBlockTemperature = startingTemperature
  M.cylinderWallTemperature = startingTemperature
  M.oilTemperature = startingTemperature
  M.coolantTemperature = startingTemperature
  M.exhaustTemperature = startingTemperature
  airRegulatorClosedCoef = jbeamData.airRegulatorClosedCoef or 0.1
  oilThermostatTemperature = jbeamData.oilThermostatTemperature or 110
  local oilRadiatorArea = jbeamData.oilRadiatorArea or 0
  local oilRadiatorEffectiveness = jbeamData.oilRadiatorEffectiveness or 0
  damageThreshold.cylinderWallTemperature = jbeamData.cylinderWallTemperatureDamageThreshold or 160
  damageThreshold.headGasket = jbeamData.headGasketDamageThreshold or 2000000
  damageThreshold.pistonRing = jbeamData.pistonRingDamageThreshold or 2000000
  damageThreshold.connectingRod = jbeamData.connectingRodDamageThreshold or 2000000
  damageThreshold.engineBlockTemperature = jbeamData.engineBlockTemperatureDamageThreshold or 140
  radiatorDeformThreshold = jbeamData.radiatorDeformThreshold or 0.015
  hasCoolantRadiator = radiatorArea > 0 and radiatorEffectiveness > 0
  hasOilRadiator = oilRadiatorArea > 0 and oilRadiatorEffectiveness > 0
  hasOilStarvingDamage = (jbeamData.hasOilStarvingDamage == nil or jbeamData.hasOilStarvingDamage)

  if radiatorFanType and radiatorFanType ~= "electric" and radiatorFanType ~= "mechanical" then
    log("E", "engine.initThermals", "Unknown radiator fan type specified: " .. radiatorFanType)
  end
  electricalRadiatorFanSmoother = newTemporalSmoothing(500, 1000)

  local engineBlockMass = 0

  if not jbeamData.engineBlock or not jbeamData.engineBlock._engineGroup_nodes then -- little hack to make it not fail while the jbeam parsing is broken
    log("E", "engine.initThermals", "No engineBlock node group specified")
    log("E", "engine.initThermals", "Engine thermals are disabled due to above error")
    return
  end
  for _, n in pairs(jbeamData.engineBlock._engineGroup_nodes) do
    engineBlockMass = engineBlockMass + v.data.nodes[n].nodeWeight
  end

  local cylinderWallMass = math.max(engineBlockMass / 100, 4)
  local exhaustMass = math.max(engineBlockMass / 10, 5)

  -- BEAMLR FIX FOR DIVIDE BY ZERO CAUSING INFINITE ENGINE TEMP WHEN OIL VAL IS AT 0
  -- Basically capping oil value to constants.minimumOilMass, do same for coolant just in case
  energyCoef.coolant = 1 / (max(fluidReservoirs.coolant.currentMass, constants.minimumCoolantMass) * constants.coolantSpecHeat)
  energyCoef.oil = 1 / (max(fluidReservoirs.oil.currentMass, constants.minimumOilMass) * constants.oilSpecHeat)
  -- BEAMLR FIX END
  energyCoef.cylinderWall = 1 / (cylinderWallMass * cylinderWallSpecHeat)
  energyCoef.engineBlock = 1 / (engineBlockMass * engineBlockSpecHeat)
  energyCoef.exhaust = 1 / (constants.exhaustSpecHeat * exhaustMass)
  radiatorCoef = radiatorEffectiveness * radiatorArea
  oilRadiatorCoef = oilRadiatorEffectiveness * oilRadiatorArea
  radiatorDamageDeformGroup = jbeamData.radiatorDamageDeformGroup or "radiator_damage"

  nodes.coolantCap = {}
  nodes.radiator = {}
  nodes.engine = {}

  if hasCoolantRadiator then
    if not jbeamData.radiator then
      log("E", "engine.initThermals", "No radiator node group specified")
      log("E", "engine.initThermals", "Engine thermals are disabled due to above error")
      return
    else
      arrayConcat(nodes.radiator, jbeamData.radiator._engineGroup_nodes or {})
    end
  end

  arrayConcat(nodes.coolantCap, jbeamData.engineBlock._engineGroup_nodes or {})
  arrayConcat(nodes.engine, jbeamData.engineBlock._engineGroup_nodes or {})

  if #nodes.coolantCap < 2 then
    log("D", "engine.initThermals", "Wrong number of coolant cap nodes found. Should be at least 2, is: " .. #nodes.coolantCap)
  end

  if #nodes.engine < 2 then
    log("E", "engine.initThermals", "Wrong number of engine nodes found. Should be at least 2, is: " .. #nodes.engine)
    log("E", "engine.initThermals", "Engine thermals are disabled due to above error")
    return
  end

  if hasCoolantRadiator and #nodes.radiator < 2 then
    log("D", "engine.initThermals", "Wrong number of radiator nodes found. Should be at least 2, is: " .. #nodes.radiator)
  end

  if not buildExhaustTree() then
    log("E", "engine.initThermals", "Building the exhaust tree failed, please look above for the actual reason")
    log("E", "engine.initThermals", "Engine thermals are disabled due to above error")
    return
  end

  if hasCoolantRadiator then
    damageTracker.setDamage("engine", "radiatorLeak", false)
  end
  damageTracker.setDamage("engine", "coolantOverheating", false)
  damageTracker.setDamage("engine", "oilOverheating", false)
  damageTracker.setDamage("engine", "oilRadiatorLeak", false)
  damageTracker.setDamage("engine", "oilpanLeak", false)
  damageTracker.setDamage("engine", "headGasketDamaged", M.headGasketBlown)
  damageTracker.setDamage("engine", "rodBearingsDamaged", M.connectingRodBearingsDamaged)
  damageTracker.setDamage("engine", "pistonRingsDamaged", M.pistonRingsDamaged)
  damageTracker.setDamage("engine", "cylinderWallsMelted", false)
  damageTracker.setDamage("engine", "blockMelted", false)
  damageTracker.setDamage("engine", "starvedOfOil", false)
  damageTracker.setDamage("engine", "oilLevelCritical", false)
  damageTracker.setDamage("engine", "oilLevelTooHigh", false)
  damageTracker.setDamage("engine", "exhaustBroken", false)

  if isAirCooledOnly then
    updateCoolingGFXMethod = updateAirCoolingGFX
  else
    updateCoolingGFXMethod = updateWaterCoolingGFX
  end
  updateExhaustGFXMethod = updateExhaustGFX
  updateMechanicsGFXMethod = updateMechanicsGFX

  thermalsEnabled = true
end

local function initSounds(jbeamData)
  if hasCoolantRadiator then
    local hissSample = jbeamData.radiatorHissLoopEvent or "event:>Vehicle>Failures>failure_radiator"
    radiatorHissSound = obj:createSFXSource2(hissSample, "AudioDefaultLoop3D", "radiatorHiss", nodes.radiator[1] or nodes.engine[1] or parentEngine.engineNodeID, 0)
  end

  local radiatorFanSample = jbeamData.radiatorFanLoopEvent or "event:>Vehicle>Cooling Fan>Mechanical_03"
  radiatorFanVolume = jbeamData.radiatorFanVolume or 0.5
  if radiatorFanType == "mechanical" then
    radiatorFanSound = obj:createSFXSource2(radiatorFanSample, "AudioDefaultLoop3D", "radiatorFan", nodes.radiator[1] or nodes.engine[1] or parentEngine.engineNodeID, 1)
  elseif radiatorFanType == "electric" then
    radiatorFanSound = obj:createSFXSource2(radiatorFanSample, "AudioDefaultLoop3D", "radiatorFan", nodes.radiator[1] or nodes.engine[1] or parentEngine.engineNodeID, 0)
  end

  -- engine cooldown tick parameters
  heatTickData.engineTickPeriodGain = jbeamData.engineTickPeriodGain or 0.04 -- average random delay (arbitrary unit, not seconds) between ticks; the smaller the number, the faster the triggering
  heatTickData.engineTickMinRate = jbeamData.engineTickMinRate or 0 -- engine cooling rate (°C/s) below which no cooldown sounds will play at all
  heatTickData.engineTickMaxRate = jbeamData.engineTickMaxRate or 0.3 -- engine cooling rate above which ticks will not get any more frequent
  heatTickData.engineTickMinTemperature = jbeamData.engineTickMinTemperature or 80 -- minimum engine temperature below which no cooldown sounds will play at all
  heatTickData.engineTickPitch = jbeamData.engineTickPitch or 0.5 -- overall pitch of ticks; 0 = -12 semitones, 1 = +12 semitones, 0.5 = default, e.g. no pitch change
  heatTickData.engineTickSizeBias = jbeamData.engineTickSizeBias or 1.2 -- exponential scale to affect tick "size" (color parameter) probability. larger values result in "lower"-sounding ticks more often. set this to 0 for debugging only the large ticks.
  heatTickData.engineTickVolume = jbeamData.engineTickVolume or 0.5 -- overall volume of ticks; 0 = silent, 0.5 = default, 1 = +14 dB
  heatTickData.engineTickStartDelay = jbeamData.engineTickStartDelay or 2 -- duration of initial delay before cooling ticks can be heard after switching off engine
  heatTickData.engineTickEventName = jbeamData.engineTickEventName or "event:>Engine>Cooldown>Crackles_Engine_V1"

  -- exhaust cooldown tick parameters
  heatTickData.exhaustTickPeriodGain = jbeamData.exhaustTickPeriodGain or 0.64
  heatTickData.exhaustTickMinRate = jbeamData.exhaustTickMinRate or 0.2
  heatTickData.exhaustTickMaxRate = jbeamData.exhaustTickMaxRate or 0.3
  heatTickData.exhaustTickMinTemperature = jbeamData.exhaustTickMinTemperature or 240
  heatTickData.exhaustTickPitch = jbeamData.exhaustTickPitch or 0.5
  heatTickData.exhaustTickSizeBias = jbeamData.exhaustTickSizeBias or 2
  heatTickData.exhaustTickVolume = jbeamData.exhaustTickVolume or 0.5
  heatTickData.exhaustTickStartDelay = jbeamData.exhaustTickStartDelay or 3
  heatTickData.exhaustTickEventName = jbeamData.exhaustTickEventName or "event:>Engine>Cooldown>Crackles_Exhaust_V1"
end

local function resetSounds()
  if radiatorHissSound then
    obj:stopSFX(radiatorHissSound)
  end
  if radiatorFanSound then
    obj:stopSFX(radiatorFanSound)
    if radiatorFanType == "mechanical" then
      obj:playSFX(radiatorFanSound)
    end
  end
end

local function updateGFX(dt)
  updateCoolingGFXMethod(dt)
  updateExhaustGFXMethod(dt)
  updateMechanicsGFXMethod(dt)
  updateHeatTicksGFX(dt)
end

local function init(engine, engineJbeamData)
  parentEngine = engine
  initThermals(engineJbeamData)
end


-- BEAMLR EDITS
M.fluidReservoirs = fluidReservoirs
M.fluidLeakRates = fluidLeakRates
-- BEAMLR EDITS

M.init = init
M.initSounds = initSounds
M.resetSounds = resetSounds
M.reset = reset
M.updateGFX = updateGFX
M.beamBroke = beamBroke

M.applyDeformGroupDamageRadiator = applyDeformGroupDamageRadiator
M.applyDeformGroupDamageOilpan = applyDeformGroupDamageOilpan
M.applyDeformGroupDamageOilRadiator = applyDeformGroupDamageOilRadiator
M.setPartConditionRadiator = setPartConditionRadiator
M.setPartConditionExhaust = setPartConditionExhaust
M.setPartConditionThermals = setPartConditionThermals
M.getPartConditionRadiator = getPartConditionRadiator
M.getPartConditionExhaust = getPartConditionExhaust
M.getPartConditionThermals = getPartConditionThermals

return M
