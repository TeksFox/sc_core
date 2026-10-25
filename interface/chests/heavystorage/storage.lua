function init()
    sourceID = pane.containerEntityId()
    playerID = player.uniqueId()

    storagePlayer = world.getObjectParameter(sourceID, "player")

    --sb.logInfo("%s %s", playerID, sourceID)
    if storagePlayer.personal then
        widget.setVisible("unlocker", true)
        widget.setVisible("locker", false)
        if storagePlayer.id ~= playerID then
            pane.dismiss()
        end
    else
        widget.setVisible("unlocker", false)
        widget.setVisible("locker", true)
    end
end

function locker(widgetName)
    local data = widget.getData(widgetName)

    local arr = {
        id = playerID,
        f = data.personal
    }
    world.sendEntityMessage(sourceID, "id", arr)

    widget.setVisible(data.showWidget, true)
    widget.setVisible(widgetName, false)
end

function destroy()
    world.sendEntityMessage(sourceID, "destroy")
end
