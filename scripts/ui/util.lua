function itemsInContainerRange(containerID, startRange, endRange)
    local slots = world.containerItems(containerID)
    local outputSlots = {}
    local index = 1
    for i = startRange, endRange, 1 do
        outputSlots[index] = slots[i]
        index = index + 1
    end
    return outputSlots
end