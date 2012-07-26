package.path = './../?.lua;'..package.path

lustache = require 'lustache'

require "lunit"
cjson = require "cjson"

module("lustache_testcase", lunit.testcase, package.seeall)

-- define function prototypes
equalTables = (function(traverse, equalTables)
  -- traverse a table, and test equality to another
  traverse = function(primary, secondary)
    -- use pairs for both the hash, and array part of the table
    for k,v in pairs(primary) do
      -- value is a table (do a deep equality), and the secondary value
      if not secondary or not secondary[k] then return false end
      local tableState, secondVal = type(v) == 'table', secondary[k]
      -- check for deep table inequality, or value inequality
      if (tableState and not equalTables(v, secondVal)) or (not tableState and v ~= secondVal) then
        return false
      end
    end
    -- passed all tests, the tables are equal
    return true
  end

  -- main equality function
  equalTables = function(first, second)
    -- traverse both first, and second tables to be sure of equality
    return traverse(first, second) and traverse(second, first)
  end

  -- return main function to keep traverse private
  return equalTables

end)()

expectations = {
  { template = "{{hi}}", value                                  = { { type= "name", value= "hi" } }},
  { template = "{{hi.world}}", value                            = { { type= "name", value= "hi.world" } }},
  { template = "{{hi . world}}", value                          = { { type= "name", value= "hi . world" } }},
  { template = "{{ hi}}", value                                 = { { type= "name", value= "hi" } }},
  { template = "{{hi }}", value                                 = { { type= "name", value= "hi" } }},
  { template = "{{ hi }}", value                                = { { type= "name", value= "hi" } }},
  { template = "{{{hi}}}", value                                = { { type= "{", value= "hi" } }},
  { template = "{{!hi}}", value                                 = { { type= "!", value= "hi" } }},
  { template = "{{! hi}}", value                                = { { type= "!", value= "hi" } }},
  { template = "{{! hi }}", value                               = { { type= "!", value= "hi" } }},
  { template = "{{ !hi}}", value                                = { { type= "!", value= "hi" } }},
  { template = "{{ ! hi}}", value                               = { { type= "!", value= "hi" } }},
  { template = "{{ ! hi }}", value                              = { { type= "!", value= "hi" } }},
  { template = "a{{hi}}", value                                 = { { type= "text", value= "a" }, { type= "name", value= "hi" } }},
  { template = "a {{hi}}", value                                = { { type= "text", value= "a " }, { type= "name", value= "hi" } }},
  { template = " a{{hi}}", value                                = { { type= "text", value= " a" }, { type= "name", value= "hi" } }},
  { template = " a {{hi}}", value                               = { { type= "text", value= " a " }, { type= "name", value= "hi" } }},
  { template = "a{{hi}}b", value                                = { { type= "text", value= "a" }, { type= "name", value= "hi" }, { type= "text", value= "b" } }},
  { template = "a{{hi}} b", value                               = { { type= "text", value= "a" }, { type= "name", value= "hi" }, { type= "text", value= " b" } }},
  { template = "a{{hi}}b ", value                               = { { type= "text", value= "a" }, { type= "name", value= "hi" }, { type= "text", value= "b " } }},
  { template = "a\n{{hi}} b \n", value                          = { { type= "text", value= "a\n" }, { type= "name", value= "hi" }, { type= "text", value= " b \n" } }},
  { template = "a\n {{hi}} \nb", value                          = { { type= "text", value= "a\n " }, { type= "name", value= "hi" }, { type= "text", value= " \nb" } }},
  { template = "a\n {{!hi}} \nb", value                         = { { type= "text", value= "a\n " }, { type= "!", value= "hi" }, { type= "text", value= " \nb" } }},
  { template = "a\n{{#a}}{{/a}}\nb", value                      = { { type= "text", value= "a\n" }, { type= "#", value= "a", tokens= {} }, { type= "text", value= "\nb" } }},
  { template = "a\n {{#a}}{{/a}}\nb", value                     = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= {} }, { type= "text", value= "\nb" } }},
  { template = "a\n {{#a}}{{/a}} \nb", value                    = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= {} }, { type= "text", value= " \nb" } }},
  { template = "a\n{{#a}}\n{{/a}}\nb", value                    = { { type= "text", value= "a\n" }, { type= "#", value= "a", tokens= { { value = "\n", type = "text" } } }, { type= "text", value= "\nb" } }},
  { template = "a\n {{#a}}\n{{/a}}\nb", value                   = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= { { value = "\n", type = "text" } } }, { type= "text", value= "\nb" } }},
  { template = "a\n {{#a}}\n{{/a}} \nb", value                  = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= { { value = "\n", type = "text" } } }, { type= "text", value= " \nb" } }},
  { template = "a\n{{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb", value    = { { type= "text", value= "a\n" }, { type= "#", value= "a", tokens= { { value = "\n", type = "text" } } }, { value = "\n",type = "text"}, { type= "#", value= "b", tokens= {{ value = "\n",type = "text"}} }, { type= "text", value= "\nb" } }},
  { template = "a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb", value   = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= { { value = "\n", type = "text" } } }, { type= "#", value= "b", tokens= { { value = "\n", type = "text" } } }, { type= "text", value= "\nb" } }},
  { template = "a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}} \nb", value  = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= { { value = "\n", type = "text" } } }, { type= "#", value= "b", tokens= { { value = "\n", type = "text" } } }, { type= "text", value= "\nb" } }},
  { template = "a\n{{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb", value    = { { type= "text", value= "a\n" }, { type= "#", value= "a", tokens= { { type= "#", value= "b", tokens= { { value = "\n", type = "text" } } } } }, { type= "text", value= "b" } }},
  { template = "a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb", value   = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= { { type= "#", value= "b", tokens= { { value = "\n", type = "text" } } } } }, { type= "text", value= "b" } }},
  { template = "a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}} \nb", value  = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= { { type= "#", value= "b", tokens= { { value = "\n", type = "text" } } } } }, { type= "text", value= "b" } }},
  { template = "{{>abc}}", value                                = { { type= ">", value= "abc" } }},
  { template = "{{> abc }}", value                              = { { type= ">", value= "abc" } }},
  { template = "{{ > abc }}", value                             = { { type= ">", value= "abc" } }},
  { template = "{{=<% %>=}}", value                             = { { type= "=", value= "<% %>" } }},
  { template = "{{= <% %> =}}", value                           = { { type= "=", value= "<% %>" } }},
  { template = "{{=<% %>=}}<%={{ }}=%>", value                  = { { type= "=", value= "<% %>" }, { type= "=", value= "{{ }}" } }},
  { template = "{{=<% %>=}}<%hi%>", value                       = { { type= "=", value= "<% %>" }, { type= "name", value= "hi" } }},
  { template = "{{#a}}{{/a}}hi{{#b}}{{/b}}\n", value            = { { type= "#", value= "a", tokens= {} }, { type= "text", value= "hi" }, { type= "#", value= "b", tokens= {} }, { type= "text", value= "\n" } }},
  { template = "{{a}}\n{{b}}\n\n{{#c}}\n{{/c}}\n", value        = { { type= "name", value= "a" }, { type= "text", value= "\n" }, { type= "name", value= "b" }, { type= "text", value= "\n\n" }, { type= "#", value= "c", tokens= {} } }},
  { template = "{{#foo}}\n  {{#a}}\n    {{b}}\n  {{/a}}\n{{/foo}}\n", value = { { type = "#", value = "foo", tokens = { { type = "#", value = "a", tokens = { { type = "text", value = "    " }, { type = "name", value = "b" }, { type = "text", value = "\n" } } } } } }}
}

function setup()
end

function teardown()
end

function Tests()
  local x = 1

  for i,v in ipairs(expectations) do
    local parsed = lustache.parse(v.template)
    if not equalTables(parsed, v.value) then
      print(cjson.encode(parsed))
      print(cjson.encode(v.value))
    end

    assert(equalTables(parsed, v.value))
  end
end
