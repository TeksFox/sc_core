oldinit = init
oldupdate = update
olddie = die
function patch(config)
  return config
end

function update(...)
  if oldupdate ~= nil then
    oldupdate(...)
  end

  sb.logInfo("%sdadadsdadads")
end
