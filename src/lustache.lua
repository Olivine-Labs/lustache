-- lustache: Lua mustache template parsing.
-- Copyright 2012 Olivine Labs, LLC <projects@olivinelabs.com>
-- MIT Licensed.

-- TODO: kill dangerous unicode https://github.com/janl/mustache.js/blob/master/mustache.js#L66

-- Utility functions.

function string.split(str, sep) --> this is bad practice but i don't care right now
  local sep, fields = sep or ".", {}
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

--> this is more efficient:

-- function string.split(str, sep)
--   local out = {}
--   for m in str:gmatch("[^"..sep.."]+") do out[#out+1] = m end
--   return out
-- end

local lustache = {
  name     = "lustache",
  version  = "1.1-1",
  renderer = require("lustache.renderer"):new(),
}

function lustache:render(template, view, partials)
  --> seems like this should be done by renderer.render?
  if partials then
    for name, body in pairs(partials) do
      self:compile_partial(name, body)
    end
  end

  return self.renderer:render(template, view)
end

--> setmetatable returns the table, so this saves a line
return setmetatable(lustache, {
  --> expose renderer's functions
  __index = function(self, idx)
    if self.renderer[idx] then return self.renderer[idx] end
  end,
  --> allow setting renderer.tags with lustache.tags
  __newindex = function(self, idx, val)
    if idx == "tags" then self.renderer.tags = val end
    --> use this to expose everything in renderer (probably not desirable):
    -- if self.renderer[idx] then self.renderer[idx] = val end
  end
})