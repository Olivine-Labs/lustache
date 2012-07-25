package.path = './../?.lua;'..package.path

lustache = require 'lustache'

require "lunit"

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
  ["{{hi}}"]                                  = { { type= 'name', value= 'hi' } }--[[,
  ["{{hi.world}}"]                            = { { type= 'name', value= 'hi.world' } },
  ["{{hi . world}}"]                          = { { type= 'name', value= 'hi . world' } },
  ["{{ hi}}"]                                 = { { type= 'name', value= 'hi' } },
  ["{{hi }}"]                                 = { { type= 'name', value= 'hi' } },
  ["{{ hi }}"]                                = { { type= 'name', value= 'hi' } },
  ["{{{hi}}}"]                                = { { type= '{', value= 'hi' } },
  ["{{!hi}}"]                                 = { { type= '!', value= 'hi' } },
  ["{{! hi}}"]                                = { { type= '!', value= 'hi' } },
  ["{{! hi }}"]                               = { { type= '!', value= 'hi' } },
  ["{{ !hi}}"]                                = { { type= '!', value= 'hi' } },
  ["{{ ! hi}}"]                               = { { type= '!', value= 'hi' } },
  ["{{ ! hi }}"]                              = { { type= '!', value= 'hi' } },
  ["a{{hi}}"]                                 = { { type= 'text', value= 'a' }, { type= 'name', value= 'hi' } },
  ["a {{hi}}"]                                = { { type= 'text', value= 'a ' }, { type= 'name', value= 'hi' } },
  [" a{{hi}}"]                                = { { type= 'text', value= ' a' }, { type= 'name', value= 'hi' } },
  [" a {{hi}}"]                               = { { type= 'text', value= ' a ' }, { type= 'name', value= 'hi' } },
  ["a{{hi}}b"]                                = { { type= 'text', value= 'a' }, { type= 'name', value= 'hi' }, { type= 'text', value= 'b' } },
  ["a{{hi}} b"]                               = { { type= 'text', value= 'a' }, { type= 'name', value= 'hi' }, { type= 'text', value= ' b' } },
  ["a{{hi}}b "]                               = { { type= 'text', value= 'a' }, { type= 'name', value= 'hi' }, { type= 'text', value= 'b ' } },
  ["a\n{{hi}} b \n"]                          = { { type= 'text', value= 'a\n' }, { type= 'name', value= 'hi' }, { type= 'text', value= ' b \n' } },
  ["a\n {{hi}} \nb"]                          = { { type= 'text', value= 'a\n ' }, { type= 'name', value= 'hi' }, { type= 'text', value= ' \nb' } },
  ["a\n {{!hi}} \nb"]                         = { { type= 'text', value= 'a\n' }, { type= '!', value= 'hi' }, { type= 'text', value= 'b' } },
  ["a\n{{#a}}{{/a}}\nb"]                      = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= {} }, { type= 'text', value= 'b' } },
  ["a\n {{#a}}{{/a}}\nb"]                     = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= {} }, { type= 'text', value= 'b' } },
  ["a\n {{#a}}{{/a}} \nb"]                    = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= {} }, { type= 'text', value= 'b' } },
  ["a\n{{#a}}\n{{/a}}\nb"]                    = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= {} }, { type= 'text', value= 'b' } },
  ["a\n {{#a}}\n{{/a}}\nb"]                   = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= {} }, { type= 'text', value= 'b' } },
  ["a\n {{#a}}\n{{/a}} \nb"]                  = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= {} }, { type= 'text', value= 'b' } },
  ["a\n{{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb"]    = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= {} }, { type= '#', value= 'b', tokens= {} }, { type= 'text', value= 'b' } },
  ["a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb"]   = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= {} }, { type= '#', value= 'b', tokens= {} }, { type= 'text', value= 'b' } },
  ["a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}} \nb"]  = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= {} }, { type= '#', value= 'b', tokens= {} }, { type= 'text', value= 'b' } },
  ["a\n{{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb"]    = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= { { type= '#', value= 'b', tokens= {} } } }, { type= 'text', value= 'b' } },
  ["a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb"]   = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= { { type= '#', value= 'b', tokens= {} } } }, { type= 'text', value= 'b' } },
  ["a\n {{#a}}\n{{#b}}\n{{/b}}\n{{/a}} \nb"]  = { { type= 'text', value= 'a\n' }, { type= '#', value= 'a', tokens= { { type= '#', value= 'b', tokens= {} } } }, { type= 'text', value= 'b' } },
  ["{{>abc}}"]                                = { { type= '>', value= 'abc' } },
  ["{{> abc }}"]                              = { { type= '>', value= 'abc' } },
  ["{{ > abc }}"]                             = { { type= '>', value= 'abc' } },
  ["{{=<% %>=}}"]                             = { { type= '=', value= '<% %>' } },
  ["{{= <% %> =}}"]                           = { { type= '=', value= '<% %>' } },
  ["{{=<% %>=}}<%={{ }}=%>"]                  = { { type= '=', value= '<% %>' }, { type= '=', value= '{{ }}' } },
  ["{{=<% %>=}}<%hi%>"]                       = { { type= '=', value= '<% %>' }, { type= 'name', value= 'hi' } },
  ["{{#a}}{{/a}}hi{{#b}}{{/b}}\n"]            = { { type= '#', value= 'a', tokens= {} }, { type= 'text', value= 'hi' }, { type= '#', value= 'b', tokens= {} }, { type= 'text', value= '\n' } },
  ["{{a}}\n{{b}}\n\n{{#c}}\n{{/c}}\n"]        = { { type= 'name', value= 'a' }, { type= 'text', value= '\n' }, { type= 'name', value= 'b' }, { type= 'text', value= '\n\n' }, { type= '#', value= 'c', tokens= {} } },
  ["{{#foo}}\n  {{#a}}\n    {{b}}\n  {{/a}}\n{{/foo}}\n"]
  --]]
}

function setup()
end

function teardown()
end

function Tests()
  local x = 1

  for i,v in pairs(expectations) do
    parsed = lustache.parse(i)

    print("---Got---")

    for i,v in ipairs(parsed) do
      print(i)
      print(v)
    end

    print("---Expected---")

    for i,v in ipairs(v) do
      print(i)
      print(v)
    end

    --print("---Assertion---")

    --assert(equalTables(parsed, v))

    print("===")
  end
end
