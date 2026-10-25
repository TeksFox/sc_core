require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

BeamFire = WeaponAbility:new()

function BeamFire:init()
    self.playerID = activeItem.ownerEntityId()
    --self.damageConfig.baseDamage = self.baseDps * self.fireTime

    self.weapon:setStance(self.stances.idle)

    self.cooldownTimer = self.fireTime
    self.impactSoundTimer = 0

    self.weapon.onLeaveAbility = function()
        self.weapon:setDamage()
        activeItem.setScriptedAnimationParameter("chains", {})
        animator.setParticleEmitterActive("beamCollision", false)
        animator.stopAllSounds("fireLoop")
        self.weapon:setStance(self.stances.idle)
    end
end

function BeamFire:update(dt, fireMode, shiftHeld)
    
    self.beam = world.magnitude(world.entityPosition(self.playerID), activeItem.ownerAimPosition()) 
    self.damage = self.tileDamage * (1 - (self.beam / 100))
    WeaponAbility.update(self, dt, fireMode, shiftHeld)

    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
    self.impactSoundTimer = math.max(self.impactSoundTimer - self.dt, 0)

    if
        self.fireMode == (self.activatingFireMode or self.abilitySlot) and not self.weapon.currentAbility and not world.lineTileCollision(mcontroller.position(), self:firePosition()) and
            self.cooldownTimer == 0 and
            not status.resourceLocked("energy")
     then
        self:setState(self.fire)
    end
end

function BeamFire:fire()
    self.weapon:setStance(self.stances.fire)

    animator.playSound("fireStart")
    animator.playSound("fireLoop", -1)

    local wasColliding = false
    while self.fireMode == (self.activatingFireMode or self.abilitySlot) and status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt) do
        local beamStart = self:firePosition()
        local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(0)), self.beam - 3))
        local beamLength = self.beam
        local collidePoint = world.lineCollision(beamStart, beamEnd)
        

        beamEnd = collidePoint or activeItem.ownerAimPosition()
        beamLength = world.magnitude(beamStart, beamEnd)

        animator.setParticleEmitterActive("beamCollision", true)
        animator.resetTransformationGroup("beamEnd")
        animator.translateTransformationGroup("beamEnd", {beamLength, 0})

        if self.impactSoundTimer == 0 then
            animator.setSoundPosition("beamImpact", {beamLength, 0})
            animator.playSound("beamImpact")
            self.impactSoundTimer = self.fireTime
        end

        self.hitPosition = collidePoint or activeItem.ownerAimPosition()
        local radius = self.shiftHeld and self.altBlockRadius or self.blockRadius
        local brushArea = self:tileAreaBrush(radius, self.hitPosition)
        local playerPos = world.entityPosition(self.playerID)
        sb.logInfo("%s", self.damage)
        world.damageTiles(brushArea, self.layer, playerPos, self.tileDamageType, self.damage)
        local liquidCount = 0
        for _, pos in pairs(brushArea) do
            local liquidRegion = world.liquidAt(pos)

            if liquidRegion and liquidRegion[2] >= 1 then
                local spawnLiquid = world.destroyLiquid(pos)
                if spawnLiquid then
                    liquidCount = liquidCount + spawnLiquid[2]
                    if liquidCount <= 1 then
                        --sb.logInfo("%s", root.liquidConfig(spawnLiquid[1]))
                        world.spawnItem(root.liquidConfig(spawnLiquid[1]).config.itemDrop, pos, 1)
                        liquidCount = liquidCount - 1
                    end
                end
            end
        end

        animator.setSoundPool("blockSound", {self:getBlockSound(brushArea)})
        animator.playSound("blockSound")
        --self.weapon:setDamage(self.damageConfig, {self.weapon.muzzleOffset, {self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2]}}, self.fireTime)

        self:drawBeam(beamEnd, collidePoint)

        coroutine.yield()
    end

    self:reset()
    animator.playSound("fireEnd")

    self.cooldownTimer = self.fireTime
    self:setState(self.cooldown)
end

function BeamFire:drawBeam(endPos, didCollide)
    local newChain = copy(self.chain)
    newChain.startOffset = self.weapon.muzzleOffset
    newChain.endPosition = endPos

    if didCollide then
        newChain.endSegmentImage = nil
    end

    activeItem.setScriptedAnimationParameter("chains", {newChain})
end

function BeamFire:cooldown()
    self.weapon:setStance(self.stances.cooldown)
    self.weapon:updateAim()

    util.wait(
        self.stances.cooldown.duration,
        function()
        end
    )
end

function BeamFire:firePosition()
    return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function BeamFire:aimVector(inaccuracy)
    local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
    aimVector[1] = aimVector[1] * mcontroller.facingDirection()
    return aimVector
end

function BeamFire:uninit()
    self:reset()
end

function BeamFire:reset()
    self.weapon:setDamage()
    activeItem.setScriptedAnimationParameter("chains", {})
    animator.setParticleEmitterActive("beamCollision", false)
    animator.stopAllSounds("fireStart")
    animator.stopAllSounds("fireLoop")
end

function BeamFire:getBlockSound(brushArea)
    local defaultFootstepSound = root.assetJson("/client.config:defaultFootstepSound")

    for _, pos in pairs(brushArea) do
        if world.isTileProtected(pos) then
            return root.assetJson("/client.config:defaultDingSound")
        end
    end

    for _, pos in pairs(brushArea) do
        local material = world.material(pos, "foreground")
        local mod = world.mod(pos, "foreground")
        local blockSound = type(material) == "string" and root.materialMiningSound(material, mod)
        if blockSound then
            return blockSound
        end
    end
    for _, pos in pairs(brushArea) do
        local material = world.material(pos, "foreground")
        local mod = world.mod(pos, "foreground")
        local blockSound = type(material) == "string" and root.materialFootstepSound(material, mod)
        if blockSound and blockSound ~= defaultFootstepSound then
            return blockSound
        end
    end

    return nil
end

function BeamFire:tileAreaBrush(radius, centerPosition)
    local result = jarray()
    local offset = {-radius / 2, -radius / 2}
    local intOffset = util.map(vec2.add(offset, centerPosition), util.round)

    for x = 0, radius - 1 do
        for y = 0, radius - 1 do
            local intPos = util.map({x, y}, util.round)
            table.insert(result, vec2.add(intPos, intOffset))
        end
    end
    return result
end
