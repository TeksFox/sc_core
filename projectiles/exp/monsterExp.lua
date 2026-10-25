function update()
  local poly = world.playerQuery(entity.position(), 1)
  if poly and next(poly) then
    projectile.die()
    world.spawnItem("monsterExp", entity.position(), math.random(1, 5) * math.ceil(world.threatLevel()))
  end
  --projectile.sourceEntity()
  --
end

