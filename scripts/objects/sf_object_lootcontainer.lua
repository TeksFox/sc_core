require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
    lootable = config.getParameter("lootable", false)

    storage.checked = storage.checked or false
    storage.closed = storage.closed or true

    animator.setAnimationState("bodyState", "emptyClosed")
end

function update()
    if storage.closed then
        animator.setAnimationState("bodyState", "closed")
    else
        if storage.checked then
            sb.logInfo("%s", "OPEN")
            if checkEmpty() then
                animator.setAnimationState("bodyState", "emptyOpen")
            else
                animator.setAnimationState("bodyState", "open")
            end
        else
            animator.setAnimationState("bodyState", "default")
        end
    end
end

function onInteraction(args)
    sb.logInfo("%s", "OPEN")
    storage.checked = true
end

function checkEmpty()
    local items = world.containerItems(entity.id())
    if items and next(items) then
        return false
    end
    return true
end

function die(...)
    if storage.closed then
        world.containerTakeAll(entity.id())
    end
end
