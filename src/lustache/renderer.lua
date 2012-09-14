local Scanner  = require "lustache.scanner"
local Context  = require "lustache.context"

local patterns = {
  white = "%s*",
  space = "%s+",
  nonSpace = "%S",
  eq = "%s*=",
  curly = "%s*}",
  tag = "[#\\^/>{&=!]"
}

local html_escape_characters = {
  ["&"] = "&amp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ['"'] = "&quot;",
  ["'"] = "&#39;",
  ["/"] = "&#x2F"
}

local function test_pattern (str, pattern)
  return str:find(pattern) and true or false
end

local function is_whitespace(str)
  return test_pattern(str, patterns.space)
end

local function is_positive_integer(n)
  return type(n) == "number" and n > 0 and math.floor(n) == n
end

local function is_array(array)
  local max, n = 0, 0
  for k, _ in pairs(array) do
    if not is_positive_integer(k) then return false end
    max = math.max(max, k)
    n = n + 1
  end
  return n == max
end

local function quote(str)
  return '"'..string.gsub(str, "\"","\\\"")..'"'
end

local function escape_html(str)
  return str:gsub("[&<>\"\'/]", function(str) return html_escape_characters[str] end)
end

-- Low-level function that compiles the given `tokens` into a
-- function that accepts two arguments: a Context and a
-- Renderer. Returns the body of the function as a string if
-- `returnBody` is true.
-- ohgodwhy

local function compile_tokens(tokens, return_body)
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
    body = "return function(c,r) return "..table.concat(body, " .. ").." end"
    return loadstring(body)()
  end
end

local function escape_tags(tags)
  return {
    tags[1]:gsub("%%", "%%%%").."%s*",
    "%s*"..tags[2]:gsub("%%", "%%%%"),
  }
end

local function nest_tokens(tokens)
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
local function squash_tokens(tokens)
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
local function parse(template, tags)
  local tag_patterns = escape_tags(tags)
  local scanner = Scanner:new(template)
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

        if chr == "\r" then
          chr = "\\r"
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
      tags = string.split(value, patterns.space)
      tag_patterns = escape_tags(tags)
    end
  end

  squash_tokens(tokens)

  return nest_tokens(tokens)
end

local function make_context(view)
  if not view then return view end

  return view._magic and view._magic == "1235123123" and view or Context:new(view)
end

local renderer = {}

function renderer:clear_cache()
  self._cache = {}
  self._partial_cache = {}
end

function renderer:compile(tokens, tags)
  if type(tokens) == "string" then
    tokens = parse(tokens, tags)
  end

  local fn = compile_tokens(tokens)
  local this = self --> ???

  return function(view)
    return fn(make_context(view), this)
  end
end

function renderer:compile_partial(name, tokens, tags)
  self._partial_cache[name] = self:compile(tokens, tags)
  return self._partial_cache[name]
end

function renderer:render(template, view, tags)
  if not template then
    return ""
  end

  local fn = self._cache[template]

  if not fn then
    fn = self:compile(template, tags)
    self._cache[template] = fn
  end

  return fn(view)
end

function renderer:_section(name, context, callback)
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
    local this = self --> ???

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
end

function renderer:_inverted(name, context, callback)
  local value = context:lookup(name)

  -- From the spec: inverted sections may render text once based on the
  -- inverse value of the key. That is, they will be rendered if the key
  -- doesn't exist, is false, or is an empty list.

  if value == nil or value == false or (is_array(value) and #value == 0) then
    return callback(context, this)
  end

  return ""
end

function renderer:_partial(name, context)
  local fn = self._partial_cache[name]

  if fn then --> save four lines: return fn and fn(context, self) or ""
    return fn(context, self)
  end

  return ""
end

function renderer:_name(name, context, escape)
  local value = context:lookup(name)

  if type(value) == "function" then
    value = value(context.view)
  end

  local str = value == nil and "" or value
  str = tostring(str)

  if escape then
    return escape_html(str)
  end

  return str
end

function renderer:parse(template, tags) --> refactor this properly
  return parse(template, tags)
end

function renderer:new()
  local out = { 
    _cache = {},
    _partial_cache = {},
  }
  setmetatable(out, { __index = self })
  out:clear_cache()
  return out
end

return renderer