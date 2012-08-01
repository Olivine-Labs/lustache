-- lustache: Lua mustache template parsing.
-- Copyright 2012 Olivine Labs, LLC <projects@olivinelabs.com>
-- MIT Licensed.

-- Utility functions.

--TODO: kill dangerous unicode https://github.com/janl/mustache.js/blob/master/mustache.js#L66
patterns = {
  white = "%s*",
  space = "%s+",
  nonSpace = "%S",
  eq = "%s*=",
  curly = "%s*}",
  tag = "[#\^/>{&=!]"
}

html_escape_characters = {
  ["&"] = "&amp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ['"'] = "&quot;",
  ["'"] = "&#39;",
  ["/"] = "&#x2F"
}

test_pattern = function(string, pattern)
  return string:find(pattern) and true or false
end

is_whitespace = function(string)
  return test_pattern(string, patterns.space)
end

is_positive_integer = function(n)
  return type(n) == "number" and n > 0 and math.floor(n) == n
end

is_array = function(array)
  local max, n = 0, 0
  for k, _ in pairs(array) do
    if not is_positive_integer(k) then return false end
    max = math.max(max, k)
    n = n + 1
  end
  return n == max
end

quote = function(string)
  return '"'..string..'"'
end

escape_html = function(string)
  return string:gsub("[&<>\"\'/]", function(string) return html_escape_characters[string] end)
end

split = function(string, sep)
  local sep, fields = sep or ".", {}
  local pattern = string.format("([^%s]+)", sep)
  string:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

-- The Parsing™

function Scanner(string)
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

      if match and self.tail:find(pattern) == 1 then
        self.tail = self.tail:sub(#match + 1)
        self.pos = self.pos + #match

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
        match = self.tail:sub(1, pos - 1)
        self.tail = self.tail:sub(pos)
        self.pos = self.pos + pos
      end

      return match
    end
  }
end

function Context(view, parent)
  local context = {
    view = view,
    parent = parent,
    _cache = {},
    _magic = "1235123123", --ohgodwhy

    clear_cache = function(self)
      self._cache = {}
    end,

    push = function(self, view)
      return Context(view, self)
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
  }

  context:clear_cache()

  return context
end

make_context = function(view)
  return view._magic and view._magic == "1235123123" and view or Context(view)
end

function Renderer()
  local renderer = {
    _cache = {},
    _partial_cache = {},

    clear_cache = function(self)
      self._cache = {}
      self._partial_cache = {}
    end,

    compile = function(self, tokens, tags)
      if type(tokens) == "string" then
        tokens = parse(tokens, tags)
      end

      local fn = compile_tokens(tokens)
      local this = self

      return function(view)
        return fn(make_context(view), this)
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

          for i,v in ipairs(value) do
            buffer = buffer .. callback(context:push(v), self)
          end

          return buffer
        end

        return callback(context:push(value), self)
      elseif type(value) == "function" then
        local section_text = callback(context, self)
        local this = self

        local scoped_render = function(template)
          return this:render(template, context)
        end

        return value(this, section_text, scoped_render) or ""
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
      string = tostring(string)

      if escape then
        return escape_html(string)
      end

      return string
    end
  }

  renderer:clear_cache()

  return renderer
end

-- Low-level function that compiles the given `tokens` into a
-- function that accepts two arguments: a Context and a
-- Renderer. Returns the body of the function as a string if
-- `returnBody` is true.
-- ohgodwhy

compile_tokens = function(tokens, return_body)
  local body = {'""'}
  local token, method, escape, fn

  if tokens then
    for i,token in ipairs(tokens) do
      if token.type == "#" or token.type == "^" then
        method = token.type == "#" and "_section" or "_inverted"
        table.insert(body,
          "r:"..method.."("..quote(token.value)..", c, function(c,r)\n"..compile_tokens(token.tokens, true).."\nend)"
        )
      elseif token.type == "{" or token.type == "&" or token.type == "name" then
        escape = token.type == "name" and "true" or "false"
        table.insert(body, "r:_name("..quote(token.value)..", c, "..escape..")")
      elseif token.type == ">" then
        table.insert(body, "r:_partial("..quote(token.value)..", c)")
      elseif token.type == "text" then
        table.insert(body, quote(token.value))
      end
    end
  end

  if return_body then
    return "return "..table.concat(body, " .. ")
  else
    body = "function f(c,r) return "..table.concat(body, " .. ").." end"
    loadstring (body)()
    return f
  end
end

escape_tags = function(tags)
  return {
    tags[1]:gsub("%%", "%%%%").."%s*",
    "%s*"..tags[2]:gsub("%%", "%%%%"),
  }
end

nest_tokens = function(tokens)
  local tree = {}
  local collector = tree
  local sections = {}
  local token, section

  for i,token in ipairs(tokens) do
    if token.type == "#" or token.type == "^" then
      token.tokens = {}
      table.insert(sections, token)
      table.insert(collector, token)
      collector = token.tokens
    elseif token.type == "/" then
      if #sections == 0 then
        error("Unopened section: "..token.value)
      end

      -- Make sure there are no open sections when we're done
      section = table.remove(sections, #sections)

      if not section.value == token.value then
        error("Unclosed section: "..section.value)
      end

      if #sections > 0 then
        collector = sections[#sections].tokens
      else
        collector = tree
      end
    else
      table.insert(collector, token)
    end
  end

  section = table.remove(sections, #sections)

  if section then
    error("Unclosed section: "..section.value)
  end

  return tree
end


-- Combines the values of consecutive text tokens in the given `tokens` array
-- to a single token.
squash_tokens = function(tokens)
  local last_token, token
  local i = #tokens

  while i > 0 do
    token = tokens[i]
    last_token = nil

    if i > 1 then
      last_token = tokens[i-1]
    end

    if last_token and last_token.type == "text" and token and token.type == "text" then
      last_token.value = last_token.value..token.value
      table.remove(tokens, i)
    else
      last_token = token
    end

    i = i-1
  end

end

-- Breaks up the given `template` string into a tree of token objects. If
-- `tags` is given here it must be an array with two string values: the
-- opening and closing tags used in the template (e.g. ["<%", "%>"]). Of
-- course, the default is to use mustaches (i.e. Mustache.tags).
parse = function(template, tags)
  tags = tags or lustache.tags
  local tag_patterns = escape_tags(tags)
  local scanner = Scanner(template)
  local tokens = {} -- token buffer
  local spaces = {} -- indices of whitespace tokens on the current line
  local has_tag = false -- is there a {{tag} on the current line?
  local non_space = false -- is there a non-space char on the current line?

  -- Strips all whitespace tokens array for the current line if there was
  -- a {{#tag}} on it and otherwise only space

  local type, value, chr

  while not scanner:eos() do
    value = scanner:scan_until(tag_patterns[1])

    if value then
      for i = 1, #value do
        chr = value:sub(i,i)

        if is_whitespace(chr) then
          table.insert(spaces, #tokens)
        else
          non_space = true
        end

        if chr == "\n" then
          chr = "\\n"
        end

        table.insert(tokens, { type = "text", value = chr })
      end
    end

    if not scanner:scan(tag_patterns[1]) then
      break
    end

    has_tag = true
    type = scanner:scan(patterns.tag) or "name"

    scanner:scan(patterns.white)

    if type == "=" then
      value = scanner:scan_until(patterns.eq)
      scanner:scan(patterns.eq)
      scanner:scan_until(tag_patterns[2])
    elseif type == "{" then
      local close_pattern = "%s*}"..tags[2]
      value = scanner:scan_until(close_pattern)
      scanner:scan(patterns.curly)
      scanner:scan_until(tag_patterns[2])
    else
      value = scanner:scan_until(tag_patterns[2])
    end

    if not scanner:scan(tag_patterns[2]) then
      error("Unclosed tag at " .. scanner.pos)
    end

    table.insert(tokens, { type = type, value = value })

    if type == "name" or type == "{" or type == "&" then
      non_space = true
    end

    if type == "=" then
      tags = split(value, patterns.space)
      tag_patterns = escape_tags(tags)
    end
  end


  squash_tokens(tokens)

  return nest_tokens(tokens)
end

_renderer = Renderer()

clear_cache = function()
  _renderer:clear_cache()
end

compile = function(tokens, tags)
  return _renderer:compile(tokens, tags)
end

compile_partial = function(name, tokens, tags)
  return _renderer:compile_partial(name, tokens, tags)
end

render = function(template, view, partials)
  if partials then
    for name, body in pairs(partials) do
      compile_partial(name, body)
    end
  end

  return _renderer:render(template, view)
end

-- Export module.

lustache = {
  name = "lustache",
  version = "1.0-1",
  tags = {"{{", "}}"},

  Context = Context,

  parse = parse,
  clear_cache = clear_cache,
  compile = compile,
  compile_partial = compile_partial,
  render = render
}

return lustache
