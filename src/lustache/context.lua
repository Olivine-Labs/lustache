local context = {}

function context:clear_cache()
  self._cache = {}
end

function context:push(view)
  return self:new(view, self)
end

function context:lookup(name)
  local value = self._cache[name]

  if not value then
    if name == "." then
      value = self.view
    else
      local context = self

      while context do
        if name:find(".") > 0 then
          local names = string.split(name, ".")
          local i = 0

          value = context.view

          if(type(value)) == "number" then
            value = tostring(value)
          end

          while value and i < #names do
            i = i + 1
            value = value[names[i]]
          end
        else
          value = context.view[name]
        end

        if value then
          break
        end

        context = context.parent
      end
    end

    self._cache[name] = value
  end

  return value
end

function context:new(view, parent)
  local out = {
    view = view,
    parent = parent,
    _cache = {},
    _magic = "1235123123", --ohgodwhy
  }
  setmetatable(out, { __index = self })
  out:clear_cache() --> is this needed?
  return out
end

return context
