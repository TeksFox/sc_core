oldUpdate = update
oldUninit = uninit
oldInit = init

function init(...)
    statusEnable = config.getParameter("statusEnable", false)

    if oldInit then
        oldInit(...)
    end
end

function update(...)
    if statusEnable then
        status.addEphemeralEffects(config.getParameter("playerEffects"), activeItem.ownerEntityId())
    end

    if oldUpdate then
        oldUpdate(...)
    end
end

function uninit()
    if oldUninit then
        oldUninit()
    end

    status.clearEphemeralEffects()
end
