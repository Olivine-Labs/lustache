-- lustache: Lua mustache template parsing.
-- Copyright 2012 Olivine Labs, LLC <projects@olivinelabs.com>
-- MIT Licensed.

-- TODO: kill dangerous unicode https://github.com/janl/mustache.js/blob/master/mustache.js#L66

local string_gmatch = string.gmatch

function string.split(str, sep)
  local out = {}
  for m in string_gmatch(str, "[^"..sep.."]+") do out[#out+1] = m end
  return out
end

local lustache = {
  name     = "lustache",
  version  = "1.1-1",
  renderer = require("lustache.renderer"):new(),
}

return setmetatable(lustache, {
  __index = function(self, idx)
    if self.renderer[idx] then return self.renderer[idx] end
  end,
  __newindex = function(self, idx, val)
    if idx == "tags" then self.renderer.tags = val end
  end
})
