-- lustache: Lua mustache template parsing.
-- Copyright 2012 Olivine Labs, LLC <projects@olivinelabs.com>
-- MIT Licensed.

-- Utility functions.

--TODO: kill dangerous unicode https://github.com/janl/mustache.js/blob/master/mustache.js#L66

function string.split(str, sep) --> this is bad practice but i don't care right now
  local sep, fields = sep or ".", {}
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

--> trying not to tamper with code, but this is better:

-- function string.split(str, sep)
--   local out = {}
--   for m in str:gmatch("[^"..sep.."]+") do out[#out+1] = m end
--   return out
-- end

local Renderer = require "lustache.renderer"

local lustache = {
  name = "lustache",
  version = "1.0-1",
  tags = {"{{", "}}"},
  renderer = Renderer:new(),
  Context = Context,
}

function lustache:clear_cache()
  return self.renderer:clear_cache()
end

function lustache:compile(tokens, tags)
  return self.renderer:compile(tokens, tags or self.tags)
end

function lustache:compile_partial(name, tokens, tags)
  return self.renderer:compile_partial(name, tokens, tags or self.tags)
end

function lustache:render(template, view, partials)
  if partials then
    for name, body in pairs(partials) do
      self:compile_partial(name, body)
    end
  end

  return self.renderer:render(template, view, self.tags)
end

function lustache:parse(template, tags)
  return self.renderer:parse(template, tags or self.tags)
end

return lustache