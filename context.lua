local string_find, string_split, tostring, type =
      string.find, string.split, tostring, type

Context = {}
Context.__index = Context

function Context:clear_cache()
  self.cache = {}
end

function Context:push(view)
  return self:new(view, self)
end

function Context:lookup(name)
  local value = self.cache[name]

  if not value then
    if name == "." then
      value = self.view
    else
      local Context = self

      while Context do
        if string_find(name, ".") > 0 then
          local names = string_split(name, ".")
          local i = 0

          value = Context.view

          if(type(value)) == "number" then
            value = tostring(value)
          end

          while value and i < #names do
            i = i + 1
            value = value[names[i]]
          end
        else
          value = Context.view[name]
        end

        if value then
          break
        end

        Context = Context.parent
      end
    end

    self.cache[name] = value
  end

  return value
end

function Context:new(view, parent)
  local out = {
    view   = view,
    parent = parent,
    cache  = {},
  }
  return setmetatable(out, Context)
end

return Context
