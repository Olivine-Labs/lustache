package.path = ";;;./../src/?.lua"

local profiler = require "profiler"
local lustache = require "lustache"

local template = [[
Lorem ipsum dolor sit amet, {{word}} adipiscing elit.
Suspendisse sed enim ut dui lobortis consequat pulvinar in sem.
Sed imperdiet, arcu nec sodales ornare, elit urna malesuada erat, quis dapibus massa ante at massa.
Proin id nunc est. In ultricies justo vel risus tincidunt vestibulum.
{{sent}}
Sed varius laoreet feugiat.
Phasellus dapibus, sem non condimentum eleifend, arcu turpis gravida sem, sit amet ultrices mi magna et felis.
{{#list}}{{w}} {{/list}}
Morbi sapien nisi, dapibus cursus aliquam quis, scelerisque non magna.
Suspendisse diam sem, consectetur sed scelerisque id, auctor vel odio.
Curabitur gravida tortor ac lorem malesuada dignissim.
Cras diam quam, consequat id sollicitudin hendrerit, iaculis id magna.
Quisque congue metus sit amet sapien tincidunt eget elementum ante congue.
In hac habitasse platea dictumst. Etiam dui tellus, rutrum eget rutrum id, ultricies in est.
{{#fals}}{{/fals}}{{^fals}}Suspendisse eu arcu eu nunc luctus posuere sit amet in massa.{{/fals}}
Donec odio dolor, congue vitae lacinia eget, ornare nec diam.
Morbi quis augue ac tortor placerat mollis et quis orci. Praesent vitae blandit sem.
{{func}}
{{> part}}
]]

local partial = [[
Ut quis ante sed justo rhoncus commodo sit amet ut tortor. 
Sed augue massa, luctus in mollis eget, gravida id diam. 
Phasellus venenatis egestas vehicula. Mauris nec pharetra ipsum.]]

local data = {
  word = "consectetur",
  sent = "Sed in metus vitae tellus rutrum suscipit.",
  list = {
    { w = "Praesent" },
    { w = "vitae" },
    { w = "luctus" },
    { w = "ipsum." }
  },
  func = function(self)
    return "Sed fringilla quam vel eros bibendum placerat."
  end,
  fals = false,
}

local partials = { part = partial }

profiler.start("benchmark.log")

for i = 1,1e4 do
  lustache:render(template, data, partials)
end

profiler.stop()