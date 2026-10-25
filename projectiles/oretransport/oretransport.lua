function update()
  local poly = world.objectAt(entity.position())
  if poly and poly == projectile.sourceEntity() then
    world.sendEntityMessage(projectile.sourceEntity(), "addItem", projectile.getParameter("item"))
    projectile.die()
  end
  --projectile.sourceEntity()
  --
end