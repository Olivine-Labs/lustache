-- lustache: Lua mustache templat parsing.
-- Copyright 2012 Olivine Labs,LLC <projects@olivinelabs.com
-- MIT Licensed.

local o_tag = "{{"
local c_tag = "}}"

local trim = function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end

local html_escape = function(str)
  if str == nil then return end

  return str:gsub('&', '&amp;'):gsub('>', '&gt;'):gsub('<', '&lt;')
end

local data_in_context = function(data_context, data)
  if #data_context == 1 then
    return data[data_context[1]]
  else
    data = data[data_context[1]]
    table.remove(data_context, 1)
    return data_in_context(data_context, data)
  end
end

local return_value = function(fragment, data)
  return html_escape(data[trim(fragment)])
end

local return_comment = function(fragment, data)
  return ""
end

local return_partial = function(fragment, data, partials)
  local template = partials[trim(fragment:sub(2,fragment:len()))]
  return lustache(template, data, partials)
end

local return_unescaped_value = function(fragment, data)
  local fragment = fragment:sub(2,fragment:len() - 1)
  return data[trim(fragment)]
end

local return_unescaped_value_amp = function(fragment, data)
  local fragment = fragment:sub(2,fragment:len())
  return data[trim(fragment)]
end

local return_truthy_context = function(fragment, data)
  -- start parsing
end

local return_falsy_context = function(fragment)
end

local end_context = function(fragment)
end

local modifiers = { 
  ["{"] = return_unescaped_value,
  ["&"] = return_unescaped_value_amp,
  ["!"] = return_comment,
  [">"] = return_partial,
  ["#"] = return_truthy_boolean_or_set_context,
  ["^"] = return_falsy_boolean,
  ["/"] = end_context,
}

local mt = {__index = function () return return_value end}
setmetatable(modifiers, mt)

local get_data = function(fragment, data, partials)
  local key = fragment:sub(1,1)
  return modifiers[key](fragment, data, partials)
end

local parse = function(template, data, partials)
  return template:gsub(o_tag.."(.*)"..c_tag, function(w) return get_data(w, data, partials) end )
end

local lustache = function(template, data, partials)
  return parse(template, data, partials)
end

return lustache
