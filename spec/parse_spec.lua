local lustache = require "lustache"

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
  { template = "a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}}\nb", value   = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= { { value = "\n", type = "text" } } }, { value = "\n", type = "text" }, { type= "#", value= "b", tokens= { { value = "\n", type = "text" } } }, { type= "text", value= "\nb" } }},
  { template = "a\n {{#a}}\n{{/a}}\n{{#b}}\n{{/b}} \nb", value  = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= { { value = "\n", type = "text" } } }, { value = "\n", type = "text" },{ type= "#", value= "b", tokens= { { value = "\n", type = "text" } } }, { type= "text", value= " \nb" } }},
  { template = "a\n{{#a}}\n{{#b}}\n{{/b}}\n{{/a}}\nb", value    = { { type= "text", value= "a\n" }, { type= "#", value= "a", tokens= { { type= "text", value= "\n" }, { type= "#", value= "b", tokens= { { value = "\n", type = "text" } } }, { type= "text", value= "\n" } } }, { type= "text", value= "\nb" } }},
  { template = "a\n {{#a}}{{#b}}\n{{/b}}{{/a}}b", value   = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= { { type= "#", value= "b", tokens= { { value = "\n", type = "text" } } } } }, { type= "text", value= "b" } }},
  { template = "a\n {{#a}}{{#b}}\n{{/b}}{{/a}} \nb", value  = { { type= "text", value= "a\n " }, { type= "#", value= "a", tokens= { { type= "#", value= "b", tokens= { { value = "\n", type = "text" } } } } }, { type= "text", value= " \nb" } }},
  { template = "{{>abc}}", value                                = { { type= ">", value= "abc" } }},
  { template = "{{> abc }}", value                              = { { type= ">", value= "abc" } }},
  { template = "{{=<% %>=}}", value                             = { { type= "=", value= "<% %>" } }},
  { template = "{{= <% %> =}}", value                           = { { type= "=", value= "<% %>" } }},
  { template = "{{=<% %>=}}<%={{ }}=%>", value                  = { { type= "=", value= "<% %>" }, { type= "=", value= "{{ }}" } }},
  { template = "{{=<% %>=}}<%hi%>", value                       = { { type= "=", value= "<% %>" }, { type= "name", value= "hi" } }},
  { template = "{{#a}}{{/a}}hi{{#b}}{{/b}}\n", value            = { { type= "#", value= "a", tokens= {} }, { type= "text", value= "hi" }, { type= "#", value= "b", tokens= {} }, { type= "text", value= "\n" } }},
  { template = "{{a}}\n{{b}}\n\n{{#c}}{{/c}}", value        = { { type= "name", value= "a" }, { type= "text", value= "\n" }, { type= "name", value= "b" }, { type= "text", value= "\n\n" }, { type= "#", value= "c", tokens= {} } }},
  { template = "{{#foo}}{{#a}}    {{b}}  {{/a}}{{/foo}}", value = { { type = "#", value = "foo", tokens = { { type = "#", value = "a", tokens = { { type = "text", value = "    " }, { type = "name", value = "b" }, { type = "text", value = "  " } } } } } }},
  { template = "a", value                                = { { type= "text", value= "a" } }},
  { template = "\"", value                                = { { type= "text", value= "\"" } }},
  { template = "\"a\"", value                                = { { type= "text", value= "\"a\"" } }},
  { template = "\"{{a}}\"", value                                = { { type= "text", value= "\"" }, { type="name", value="a" }, { type="text", value="\""} }}
}

describe("parsing", function()
  local x = 1

  for i,v in ipairs(expectations) do
    it("Tests template #"..x, function()
      local parsed = lustache:parse(v.template)
      assert.same(parsed, v.value)
    end)
    x = x + 1
  end
end)
