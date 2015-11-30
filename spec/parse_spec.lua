local lustache = require "lustache"

expectations = {
  { template = "{{hi}}", value                                  = { { type= "name", value= "hi", startIndex = 1, endIndex = 6} }},
  { template = "{{hi.world}}", value                            = { { type= "name", value= "hi.world", startIndex = 1, endIndex = 12 } }},
  { template = "{{hi . world}}", value                          = { { type= "name", value= "hi . world", startIndex = 1, endIndex = 14 } }},
  { template = "{{ hi}}", value                                 = { { type= "name", value= "hi", startIndex = 1, endIndex = 7 } }},
  { template = "{{hi }}", value                                 = { { type= "name", value= "hi", startIndex = 1, endIndex = 7 } }},
  { template = "{{ hi }}", value                                = { { type= "name", value= "hi", startIndex = 1, endIndex = 8 } }},
  { template = "{{{hi}}}", value                                = { { type= "{", value= "hi", startIndex = 1, endIndex = 8 } }},
  { template = "{{!hi}}", value                                 = { { type= "!", value= "hi", startIndex = 1, endIndex = 7 } }},
  { template = "{{! hi}}", value                                = { { type= "!", value= "hi", startIndex = 1, endIndex = 8 } }},
  { template = "{{! hi }}", value                               = { { type= "!", value= "hi", startIndex = 1, endIndex = 9 } }},
  { template = "{{ !hi}}", value                                = { { type= "!", value= "hi", startIndex = 1, endIndex = 8 } }},
  { template = "{{ ! hi}}", value                               = { { type= "!", value= "hi", startIndex = 1, endIndex = 9 } }},
  { template = "{{ ! hi }}", value                              = { { type= "!", value= "hi", startIndex = 1, endIndex = 10 } }},
  { template = "a{{hi}}", value                                 = { { type= "text", value= "a", startIndex = 1, endIndex = 1 }, { type= "name", value= "hi", startIndex = 2, endIndex = 7 } }},
  { template = "a {{hi}}", value                                = { { type= "text", value= "a ", startIndex = 1, endIndex = 2 }, { type= "name", value= "hi", startIndex = 3, endIndex = 8 } }},
  { template = " a{{hi}}", value                                = { { type= "text", value= " a", startIndex = 1, endIndex = 2 }, { type= "name", value= "hi", startIndex = 3, endIndex = 8 } }},
  { template = " a {{hi}}", value                               = { { type= "text", value= " a ", startIndex = 1, endIndex = 3 }, { type= "name", value= "hi", startIndex = 4, endIndex = 9 } }},
  { template = "a{{hi}}b", value                                = { { type= "text", value= "a", startIndex = 1, endIndex = 1 }, { type= "name", value= "hi", startIndex = 2, endIndex = 7 }, { type= "text", value= "b", startIndex = 8, endIndex = 8 } }},
  { template = "a{{hi}} b", value                               = { { type= "text", value= "a", startIndex = 1, endIndex = 1 }, { type= "name", value= "hi", startIndex = 2, endIndex = 7 }, { type= "text", value= " b", startIndex = 8, endIndex = 9 } }},
  { template = "a{{hi}}b ", value                               = { { type= "text", value= "a", startIndex = 1, endIndex = 1 }, { type= "name", value= "hi", startIndex = 2, endIndex = 7 }, { type= "text", value= "b ", startIndex = 8, endIndex = 9 } }},
  { template = "a\n{{hi}} b \n", value                          = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "name", value= "hi", startIndex = 3, endIndex = 8 }, { type= "text", value= " b \n", startIndex = 9, endIndex = 12 } }},
  { template = "a\n {{hi}} \nb", value                          = { { type= "text", value= "a\n ", startIndex = 1, endIndex = 3 }, { type= "name", value= "hi", startIndex = 4, endIndex = 9 }, { type= "text", value= " \nb", startIndex = 10, endIndex = 12 } }},
  { template = "a\n {{!hi}} \nb", value                         = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "!", value= "hi", startIndex = 4, endIndex = 10 }, { type= "text", value= "b", startIndex = 13, endIndex = 13 } }},
  { template = "a\n{{#a}}{{/a}}\nb", value                      = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "#", value= "a", tokens= {}, startIndex = 3, endIndex = 8, closingTagIndex=9 }, { type= "text", value= "b", startIndex = 16, endIndex = 16 } }},
  { template = "a\n {{#a}}{{/a}}\nb", value                     = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "#", value= "a", tokens= {}, startIndex = 4, endIndex = 9, closingTagIndex=10  }, { type= "text", value= "b", startIndex = 17, endIndex = 17  } }},
  { template = "a\n {{#a}}{{/a}} \nb", value                    = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "#", value= "a", tokens= {}, startIndex = 4, endIndex = 9, closingTagIndex=10 }, { type= "text", value= "b", startIndex = 18, endIndex = 18 } }},
  { template = "a\n{{#a}}\n{{/a}}\nb", value                    = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2  }, { type= "#", value= "a", tokens= { }, startIndex = 3, endIndex = 8, closingTagIndex=10 }, { type= "text", value= "b", startIndex = 17, endIndex = 17 } }},
  { template = "a\n {{#a}}\n{{/a}}\nb", value                   = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "#", value= "a", tokens= { }, startIndex = 4, endIndex = 9, closingTagIndex=11  }, { type= "text", value= "b", startIndex = 18, endIndex = 18 } }},
  { template = "a\n {{#a}}\n{{/a}} \nb", value                  = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "#", value= "a", tokens={}, startIndex = 4, endIndex = 9, closingTagIndex=11 }, { type= "text", value= "b", startIndex = 19, endIndex = 19  } }},
  { template = "a\n{{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb", value    = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "#", value= "a", tokens = { }, startIndex = 3, endIndex = 8, closingTagIndex=10 }, { type= "#", value= "b", tokens= {}, startIndex = 17, endIndex = 22, closingTagIndex=24 }, { type= "text", value= "b", startIndex = 31, endIndex = 31 } }},
  { template = "a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb", value   = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "#", value= "a", tokens = { }, startIndex = 4, endIndex = 9, closingTagIndex=11 }, { type= "#", value= "b", tokens= { }, startIndex = 18, endIndex = 23, closingTagIndex=25  }, { type= "text", value= "b", startIndex = 32, endIndex = 32 } }},
  { template = "a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}} \nb", value  = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "#", value= "a", tokens = { }, startIndex = 4, endIndex = 9, closingTagIndex=11 }, { type= "#", value= "b", tokens= { }, startIndex = 18, endIndex = 23, closingTagIndex=25  }, { type= "text", value= "b", startIndex = 33, endIndex = 33 } }},
  { template = "a\n{{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb", value    = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 },{ type= "#", value= "a", tokens= { { type= "#", value= "b", tokens= { }, startIndex = 10, endIndex = 15, closingTagIndex=17 } },startIndex = 3, endIndex = 8, closingTagIndex=24},{ type= "text", value= "b", startIndex = 31, endIndex = 31 } }},
  { template = "a\n {{#a}}{{#b}}\n{{/b}}{{/a}}b", value         = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "#", value= "a", tokens= { { type= "#", value= "b", tokens= { }, startIndex = 10, endIndex = 15, closingTagIndex=17 } }, startIndex = 4, endIndex = 9, closingTagIndex= 23 }, { type= "text", value= "b", startIndex = 29, endIndex = 29 } }},
  { template = "a\n {{#a}}{{#b}}\n{{/b}}{{/a}} \nb", value      = { { type= "text", value= "a\n", startIndex = 1, endIndex = 2 }, { type= "#", value= "a", tokens= { { type= "#", value= "b", tokens= { }, startIndex = 10, endIndex = 15, closingTagIndex=17 } }, startIndex = 4, endIndex = 9, closingTagIndex= 23 }, { type= "text", value= "b", startIndex = 31, endIndex = 31 } }},
  { template = "{{>abc}}", value                                = { { type= ">", value= "abc", startIndex = 1, endIndex = 8 } }},
  { template = "{{> abc }}", value                              = { { type= ">", value= "abc", startIndex = 1, endIndex = 10 } }},
  { template = "{{=<% %>=}}", value                             = { { type= "=", value= "<% %>", startIndex = 1, endIndex = 11 } }},
  { template = "{{= <% %> =}}", value                           = { { type= "=", value= "<% %>", startIndex = 1, endIndex = 13 } }},
  { template = "{{=<% %>=}}<%={{ }}=%>", value                  = { { type= "=", value= "<% %>", startIndex = 1, endIndex = 11 }, { type= "=", value= "{{ }}", startIndex = 12, endIndex = 22 } }},
  { template = "{{=<% %>=}}<%hi%>", value                       = { { type= "=", value= "<% %>", startIndex = 1, endIndex = 11 }, { type= "name", value= "hi", startIndex = 12, endIndex = 17 } }},
  { template = "{{#a}}{{/a}}hi{{#b}}{{/b}}\n", value            = { { type= "#", value= "a", tokens= {}, startIndex = 1, endIndex = 6, closingTagIndex = 7 }, { type= "text", value= "hi", startIndex = 13, endIndex = 14 }, { type= "#", value= "b", tokens= {}, startIndex = 15, endIndex = 20, closingTagIndex=21 }, { type= "text", value= "\n", startIndex = 27, endIndex = 27 } }},
  { template = "{{a}}\n{{b}}\n\n{{#c}}{{/c}}", value            = { { type= "name", value= "a", startIndex = 1, endIndex = 5  }, { type= "text", value= "\n", startIndex = 6, endIndex = 6  }, { type= "name", value= "b", startIndex = 7, endIndex = 11  }, { type= "text", value= "\n\n", startIndex = 12, endIndex = 13  }, { type= "#", value= "c", tokens= {}, startIndex = 14, endIndex = 19, closingTagIndex= 20 } }},
  { template = "{{#foo}}{{#a}}    {{b}}  {{/a}}{{/foo}}", value = { { type = "#", value = "foo", startIndex = 1, endIndex = 8, closingTagIndex = 32, tokens = { { type = "#", value = "a", startIndex = 9, endIndex = 14, closingTagIndex = 26, tokens = {                           { type = "text", value = "    ", startIndex = 15, endIndex = 18 }, { type = "name", value = "b", startIndex = 19, endIndex = 23 }, { type = "text", value = "  ", startIndex = 24, endIndex = 25 } } } } } }},
  { template = "a", value                                       = { { type= "text", value= "a", startIndex = 1, endIndex = 1 } }},
  { template = "\"", value                                      = { { type= "text", value= "\"", startIndex = 1, endIndex = 1 } }},
  { template = "\"a\"", value                                   = { { type= "text", value= "\"a\"", startIndex = 1, endIndex = 3 } }},
  { template = "\"{{a}}\"", value                               = { { type= "text", value= "\"", startIndex = 1, endIndex = 1 }, { type="name", value="a", startIndex = 2, endIndex = 6 }, { type="text", value="\"", startIndex = 7, endIndex = 7} }}
}

describe("parsing", function()
  local x = 1

  for i,v in ipairs(expectations) do
    it("Tests template #"..x, function()
      local parsed = lustache:parse(v.template)
      assert.same(v.value, parsed)
    end)
    x = x + 1
  end
end)
