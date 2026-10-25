require "/scripts/vec2.lua"

function init()
    self.recoil = 0
    self.recoilRate = 0

    self.fireOffset = config.getParameter("fireOffset")
    updateAim()

    self.active = false
    storage.fireTimer = storage.fireTimer or 0
    self.timer = 1
end

function update(dt, fireMode, shiftHeld)
    self.timer = self.timer - dt
    local playerPos = mcontroller.position()
    local searchObjects = world.objectQuery(playerPos, 45)

    updateAim()

    for i, object in pairs(searchObjects) do
        if world.getObjectParameter(object, "hideItem", false) then
            objectFinder(object, playerPos, dt)
        end
    end

    storage.fireTimer = math.max(storage.fireTimer - dt, 0)
    self.recoil = math.max(self.recoil - dt * self.recoilRate, 0)
    self.active = false
end

function objectFinder(objectID, playerPos, dt)
    local objectPos = world.entityPosition(objectID)
    local magnitude = world.magnitude(playerPos, objectPos)
    if self.timer <= 0 then
        self.timer = magnitude / 50
        animator.playSound("pick", 0)
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
