-- lustache: Lua mustache templat parsing.
-- Copyright 2012 Olivine Labs,LLC <projects@olivinelabs.com
-- MIT Licensed.

local o_tag = "{{"
local c_tag = "}}"
local data_context = {}
local data = {}

local trim = function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end

local html_escape = function(str)
  if str == nil then return end

  return str:gsub('&', '&amp;'):gsub('>', '&gt;'):gsub('<', '&lt;')
end

local data_in_context = function(data_context, data_in_context)
  if #data_context == 1 then
    return data_in_context[data_context[1]]
  else
    data_in_context = data_in_context[data_context[1]]
    table.remove(data_context, 1)
    return data_in_context(data_context, data_in_context)
  end
end

local return_value = function(fragment)
  return html_escape(data[trim(fragment)])
end

local return_unescaped_value = function(fragment)
  local fragment = fragment:sub(2,fragment:len() - 1)
  return data[trim(fragment)]
end

local return_unescaped_value_amp = function(fragment)
  local fragment = fragment:sub(2,fragment:len())
  return data[trim(fragment)]
end

local return_truthy_boolean_or_set_context = function(fragment)
  
end

local return_falsy_boolean = function(fragment)
end

local end_context = function(fragment)
end

local modifiers = { 
  ["{"] = return_unescaped_value,
  ["&"] = return_unescaped_value_amp,
  ["#"] = return_truthy_boolean_or_set_context,
  ["^"] = return_falsy_boolean,
  ["/"] = end_context,
}

local mt = {__index = function () return return_value end}
setmetatable(modifiers, mt)

local get_data = function(fragment)
  local key = fragment:sub(1,1)
  return modifiers[key](fragment)
end

local parse = function(template, templateData)
  data = templateData
  data_context = {}

  return template:gsub(o_tag.."(.*)"..c_tag, function(w) return get_data(w) end )
end

local lustache = function(template, templateData)
  return parse(template, templateData)
end

return lustache
