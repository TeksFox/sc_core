Zitem = {}
function Zitem.damage(item, range)
    range = range or self.input
    if item.names ~= nil and item.name == nil then
        return
    end
    local id = entity.id()
    local config = root.itemConfig(item.name).config
    local damage = 1
        if item.damage > 0 then
         damage = math.ceil(item.damage)
    else
         damage = math.floor(-item.damage)
    end
    for offset = range[1], range[2] do
        local stack = world.containerItems(id)[offset] 
        if root.itemDescriptorsMatch(stack, item) then
            stack.parameters.durabilityHit = stack.parameters.durabilityHit or config.durability
            stack.parameters.durabilityHit = stack.parameters.durabilityHit - damage
            if stack.parameters.durabilityHit <= 0 then
                world.containerConsumeAt(id, offset - 1, 1)
            else
                world.containerSwapItemsNoCombine(id, stack, offset - 1)
            end
            return true
        end
    end
    return false
end

