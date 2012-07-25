-- lustache: Lua mustache template parsing.
-- Copyright 2012 Olivine Labs, LLC <projects@olivinelabs.com>
-- MIT Licensed.

-- Utility functions.

--TODO: kill dangerous unicode https://github.com/janl/mustache.js/blob/master/mustache.js#L66
local patterns = {
  white = "%s*",
  space = "%s+",
  nonSpace = "^%s",
  eq = "%s*=",
  curly = "%s*}",
  tag = "[#\^/>{&=!]"
}

local html_escape_characters = {
  ["&"] = "&amp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ['"'] = "&quot;",
  ["'"] = "&#39;",
  ["/"] = "&#x2F"
}

local test_pattern = function(string, pattern)
  return string:find(pattern) and true or false
end

local is_whitespace = function(string)
  return test_pattern(string, patterns.space)
end

local is_positive_integer = function(n)
  return type(n) == "number" and n > 0 and math.floor(n) == n
end

local is_array = function(array)
  local max, n = 0, 0
  for k, _ in pairs(array) do
    if not is_positive_integer(k) then return false end
    max = math.max(max, k)
    n = n + 1
  end
  return n == max
end

local quote = function(string)
  return '"'..string..'"'
end

local escape_html = function(string)
  return string:gsub("[&<>\"\'/]", function(string) return html_escape_characters[string] end)
end


local split = function(string, sep)
  local sep, fields = sep or ".", {}
  local pattern = string.format("([^%s]+)", sep)
  string:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end


-- The Parsing™

local scanner = function(string)
  return {
    string = string,
    tail = string,
    pos = 0,

    -- Returns `true` if the tail is empty (end of string).
    eos = function(self)
      return self.tail == ""
    end,

    -- Tries to match the given regular expression at the current position.
    -- Returns the matched text if it can match, `null` otherwise.
    scan = function(self, pattern)
      local match = self.tail:match(pattern)

      if match then
        self.tail = self.tail.substring(#match + 1)
        self.pos = #match
        return match
      end

      return nil
    end,

    -- Skips all text until the given regular expression can be matched. Returns
    -- the skipped string, which is the entire tail of this scanner if no match
    -- can be made.
    scan_until = function(self, pattern)
      local match
      local pos = self.tail:find(pattern)

      if pos == nil then
        match = self.tail
        self.pos = self.pos + #self.tail
        self.tail = ""
      elseif pos == 1 then
        match = nil
      else
        match = this.tail:sub(1, pos)
        self.tail = self.tail:substring(pos + 1)
        self.pos = self.pos + (pos + 1)
      end

      return match
    end
  }
end

local context = function(view, parent)
  return {
    view = view,
    parent = parent,
    _cache = {},

    make = function(view)
      return view["_cache"] and view or context(view)
    end,

    clear_cache = function(self)
      self._cache = {}
    end,

    push = function(self, view)
      return context(view, self)
    end,

    lookup = function(self, name)
      local value = self._cache[name]

      if not value then
        if name == "." then
          value = self.view
        else
          local context = self

          while context do
            if name:find(".") > 0 then
              local names = split(name, ".")
              local i = 0

              value = context.view

              while value and i < #names do
                i = i + 1
                value = value[names[i]]
              end
            else
              value = context.view[name]
            end

            if not value == nil then
              break
            end

            context = context.parent
          end
        end

        self._cache[name] = value
      end

      return value
    end
  }
end

local renderer = function()
  return {
    _cache = {},

    clear_cache = function(self)
      self._cache = {}
    end,

    compile = function(self, tokens, tags)
      if type(tokens) == "string" then
        tokens = parse(tokens, tags)
      end

      local fn = compile_tokens(tokens)
      local this = self

      return function(view)
        return fn(context.make(view), self)
      end
    end,

    compile_partial = function(self, name, tokens, tags)
      self._partial_cache[name] = self:compile(tokens, tags)
      return self._partial_cache[name]
    end,

    render = function(self, template, view)
      local fn = self._cache[template]

      if not fn then
        fn = self:compile(template)
        self._cache[template] = fn
      end

      return fn(view)
    end,

    _section = function(self, name, context, callback)
      local value = context:lookup(name)

      if type(value) == "table" then
        if is_array(value) then
          local buffer = ""

          for i in value do
            buffer = buffer + callback(context:push(i), self)
          end

          return buffer
        end
      elseif type(value) == "function" then
        local section_text = callback(context, self)
        local this = self

        local scoped_render = function(template)
          return this:render(template, context)
        end

        return value(context.view, section_text, scoped_render) or ""
      else
        if value then
          return callback(context, self)
        end
      end

      return ""
    end,

    _inverted = function(self, name, context, callback)
      local value = context:lookup(name)

      -- From the spec: inverted sections may render text once based on the
      -- inverse value of the key. That is, they will be rendered if the key
      -- doesn't exist, is false, or is an empty list.

      if value == nil or value == false or (is_array(value) and #value == 0) then
        return callback(context, this)
      end

      return ""
    end,

    _partial = function(self, name, context)
      local fn = self._partial_cache[name]

      if fn then
        return fn(context, self)
      end

      return ""
    end,

    _name = function(self, name, context, escape)
      local value = context:lookup(name)

      if type(value) == "function" then
        value = value(context.view)
      end

      local string = value == nil and "" or value

      if escape then
        return escape_html(string)
      end

      return string
    end
  }
end

-- Low-level function that compiles the given `tokens` into a
-- function that accepts two arguments: a Context and a
-- Renderer. Returns the body of the function as a string if
-- `returnBody` is true.
-- ohgodwhy

local compile_tokens = function(tokens, return_body)
  local body = {'""'}
  local token, method, escape

  for t in tokens do
    if t.type == "#" or t.type == "^" then
      method = token.type == "#" and "_section" or "_inverted"
      table.insert(body,
        "r."..method.."("..quote(token.value)..", c, function(c,r)\n"..compile_tokens(token.tokens, true).."\nend)"
      )
    elseif t.type == "{" or t.type == "&" or t.type == "name" then
      escape = token.type == "name" and "true" or "false"
      table.insert(body, "r._name("..quote(token.value)..", c, "..escape..")")
    elseif t.type == ">" then
      table.insert(body, "r._partial("..quote(token.value)..", c)")
    elseif t.type == "text" then
      table.insert(body, quote(token.value))
    end
  end

  body = "return "..table.concat(body, " + ")..";"
  return loadstring(body)
end

-- Export module.

local lustache = {
  name = "lustache",
  version = "0.0.1-dev",
  tags = {"{{", "}}"},

  parse = parse,
  clear_cache = clear_cache,
  compile = compile,
  compile_partial = compile_partial,
  render = render,
}

return lustache
