function addDrops(drops)
  storage.extraDrops = storage.extraDrops or {}
  for _,item in pairs(drops) do
    table.insert(storage.extraDrops, item)
  end
end

function spawnDrops()
  world.spawnProjectile("monsterExp", entity.position(), nil, nil, nil)
  if storage.extraDrops then
    for _,item in pairs(storage.extraDrops) do
      world.spawnItem(item, mcontroller.position())
    end
  end
end
