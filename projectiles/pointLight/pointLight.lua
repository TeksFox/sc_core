function update()
  local poly = world.objectAt(entity.position())
  if poly and poly == projectile.sourceEntity() then
    projectile.die()
  end
  --
end