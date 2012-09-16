local Scanner  = require "lustache.scanner"
local Context  = require "lustache.context"

local error, ipairs, loadstring, pairs, setmetatable, tostring, type = 
      error, ipairs, loadstring, pairs, setmetatable, tostring, type 
local math_floor, math_max, string_find, string_gsub, string_split, string_sub, table_concat, table_insert, table_remove =
      math.floor, math.max, string.find, string.gsub, string.split, string.sub, table.concat, table.insert, table.remove

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

local function is_array(array)
  local max, n = 0, 0
  for k, _ in pairs(array) do
    if not (type(k) == "number" and k > 0 and math_floor(k) == k) then
      return false 
    end
    max = math_max(max, k)
    n = n + 1
  end
  return n == max
end

local function quote(str)
  return '"'..string_gsub(str, '"', '\\"')..'"'
end

-- Low-level function that compiles the given `tokens` into a
-- function that accepts two arguments: a Context and a
-- Renderer. Returns the body of the function as a string if
-- `returnBody` is true.
-- ohgodwhy

local function compile_tokens(tokens, return_body)
  local body = {'""'}
  local token, method, escape

  if tokens then
    for i,token in ipairs(tokens) do
      if token.type == "#" or token.type == "^" then
        method = token.type == "#" and "_section" or "_inverted"
        body[#body+1] =
          "r:"..method.."("..quote(token.value)..", c, function(c,r)\n"..compile_tokens(token.tokens, true).."\nend)"
      elseif token.type == "{" or token.type == "&" or token.type == "name" then
        escape = token.type == "name" and "true" or "false"
        body[#body+1] = "r:_name("..quote(token.value)..", c, "..escape..")"
      elseif token.type == ">" then
        body[#body+1] = "r:_partial("..quote(token.value)..", c)"
      elseif token.type == "text" then
        body[#body+1] = quote(token.value)
      end
    end
  end

  if return_body then
    return "return "..table_concat(body, " .. ")
  else
    body = "return function(c,r) return "..table_concat(body, " .. ").." end"
    return loadstring(body)()
  end
end

local function escape_tags(tags)
  return {
    string_gsub(tags[1], "%%", "%%%%").."%s*",
    "%s*"..string_gsub(tags[2], "%%", "%%%%"),
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
      sections[#sections+1] = token
      collector[#collector+1] = token
      collector = token.tokens
    elseif token.type == "/" then
      if #sections == 0 then
        error("Unopened section: "..token.value)
      end

      -- Make sure there are no open sections when we're done
      section = table_remove(sections, #sections)

      if not section.value == token.value then
        error("Unclosed section: "..section.value)
      end

      if #sections > 0 then
        collector = sections[#sections].tokens
      else
        collector = tree
      end
    else
      collector[#collector+1] = token
    end
  end

  section = table_remove(sections, #sections)

  if section then
    error("Unclosed section: "..section.value)
  end

  return tree
end


-- Combines the values of consecutive text tokens in the given `tokens` array
-- to a single token.
local function squash_tokens(tokens)
  local last_token, token

  for i = #tokens, 2, -1 do
    token, last_token = tokens[i], tokens[i-1]

    if last_token.type == "text" and token.type == "text" then
      last_token.value = last_token.value..token.value
      table_remove(tokens, i)
    else
      last_token = token  --> this seems redundant but removing it makes it slower?
    end
  end

end

local function make_context(view)
  if not view then return view end
  return view.magic == "1235123123" and view or Context:new(view)
end

local renderer = {}

function renderer:clear_cache()
  self.cache = {}
  self.partial_cache = {}
end

function renderer:compile(tokens, tags)
  tags = tags or self.tags
  if type(tokens) == "string" then
    tokens = self:parse(tokens, tags)
  end

  local fn = compile_tokens(tokens)

  return function(view)
    return fn(make_context(view), self)
  end
end

function renderer:compile_partial(name, tokens, tags)
  tags = tags or self.tags
  self.partial_cache[name] = self:compile(tokens, tags)
  return self.partial_cache[name]
end

function renderer:render(template, view, partials)
  if partials then
    for name, body in pairs(partials) do
      self:compile_partial(name, body)
    end
  end

  if not template then
    return ""
  end

  local fn = self.cache[template]

  if not fn then
    fn = self:compile(template, self.tags)
    self.cache[template] = fn
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

    local scoped_render = function(template)
      return self:render(template, context)
    end

    return value(self, section_text, scoped_render) or ""
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
    return callback(context, self)
  end

  return ""
end

function renderer:_partial(name, context)
  local fn = self.partial_cache[name]
  return fn and fn(context, self) or ""
end

function renderer:_name(name, context, escape)
  local value = context:lookup(name)

  if type(value) == "function" then
    value = value(context.view)
  end

  local str = value == nil and "" or value
  str = tostring(str)

  if escape then
    return string_gsub(str, '[&<>"\'/]', function(s) return html_escape_characters[s] end)
  end

  return str
end

-- Breaks up the given `template` string into a tree of token objects. If
-- `tags` is given here it must be an array with two string values: the
-- opening and closing tags used in the template (e.g. ["<%", "%>"]). Of
-- course, the default is to use mustaches (i.e. Mustache.tags).
function renderer:parse(template, tags)
  tags = tags or self.tags
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
        chr = string_sub(value,i,i)

        if string_find(chr, "%s+") then
          spaces[#spaces+1] = #tokens
        else
          non_space = true
        end

        --chr = (string_match(chr, "[\a\b\f\n\r\t\v]") and "\"..chr or chr

        if chr == "\n" then
          chr = "\\n"
        end

        if chr == "\r" then
          chr = "\\r"
        end
        tokens[#tokens+1] = { type = "text", value = chr }
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

    tokens[#tokens+1] = { type = type, value = value }

    if type == "name" or type == "{" or type == "&" then
      non_space = true
    end

    if type == "=" then
      tags = string_split(value, patterns.space)
      tag_patterns = escape_tags(tags)
    end
  end

  squash_tokens(tokens)

  return nest_tokens(tokens)
end

function renderer:new()
  local out = { 
    cache         = {},
    partial_cache = {},
    tags          = {"{{", "}}"}
  }
  return setmetatable(out, { __index = self })
end

return renderer
