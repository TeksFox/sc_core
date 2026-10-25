require "/scripts/vec2.lua"

function init()
  self.recoil = 0
  self.recoilRate = 0

  self.fireOffset = config.getParameter("fireOffset")
  updateAim()

  self.active = false
  storage.fireTimer = storage.fireTimer or 0
end

function update(dt, fireMode, shiftHeld)
  updateAim()

  storage.fireTimer = math.max(storage.fireTimer - dt, 0)

  if self.active then
    self.recoilRate = 0
  else
    self.recoilRate = math.max(1, self.recoilRate + (10 * dt))
  end
  self.recoil = math.max(self.recoil - dt * self.recoilRate, 0)

  if self.active and not storage.firing and storage.fireTimer <= 0 then
    self.recoil = math.pi / 2 - self.aimAngle
    if animator.animationState("firing") == "off" then
      animator.setAnimationState("firing", "fire")
    end
    storage.fireTimer = config.getParameter("fireTime", 1.0)
    storage.firing = true
  end

  self.active = false

  if storage.firing and animator.animationState("firing") == "off" then
    if player then
      local o = world.objectAt(activeItem.ownerAimPosition())
      if o and world.getObjectParameter(o, "repairable", false) and world.getObjectParameter(o, "drillDurability") > 0 then
        item.consume(1)
        world.sendEntityMessage(world.objectAt(activeItem.ownerAimPosition()), "repair")
      end
    end
    storage.firing = false
    return
  end
end

function activate(fireMode, shiftHeld)
  if not storage.firing then
    self.active = true
  end
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  self.aimAngle = self.aimAngle + self.recoil
  activeItem.setArmAngle(self.aimAngle)
  activeItem.setFacingDirection(self.aimDirection)
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, self.aimAngle + sb.nrand(config.getParameter("inaccuracy", 0), 0))
  aimVector[1] = aimVector[1] * self.aimDirection
  return aimVector
end

function holdingItem()
  return true
end

function recoil()
  return false
end

function outsideOfHand()
  return false
end
