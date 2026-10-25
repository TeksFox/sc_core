function init()
  effect.setParentDirectives(config.getParameter("directives", ""))
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "weaksolarradiation", 0.1)
  --self.healthPercentage = config.getParameter("healthPercentage", 0.1)
end

function update(dt)
  status.modifyResource("radiation", 0.025)
end

function uninit()

end
