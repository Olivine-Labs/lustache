package = "lustache"
version = "1.0-1"
source = {
  url = "https://github.com/Olivine-Labs/lustache/zipball/v1.0-1"
}
description = {
  summary = "{{Mustache}} rendering for Lua",
  detailed = [[
    lustache allows you to use the Mustache templating standard in Lua by
    passing in a string, data, and partial templates.  It precompiles and
    caches templates for speed, and allows you to build complex strings such
    as html pages by iterating through a table and inserting values. Find out
    more about Mustache at http://mustache.github.com.
  ]],
  homepage = "http://olivinelabs.com/lustache/",
  license = "MIT <http://opensource.org/licenses/MIT>"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
   modules = {
    lustache = "lustache.lua"
  }
}
