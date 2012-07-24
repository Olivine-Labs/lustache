package.path = './../?.lua;'..package.path

lustache = require 'lustache'

require "lunit"

module("lustache_testcase", lunit.testcase, package.seeall)

testData = {
  name = "Coffee",
  hot = true,
  sugar = false,
  sizesAvailable = { 12, 16, 20 },
  origin = {
    lat = -16.194,
    long = -67.728
  },
  description = "<p>A full bodied roast.</p>"
}

assertions = {
  { input = "Type: {{name}}", expected = "Type: "..testData.name },
  { input = "Type: {{ name }}", expected = "Type: "..testData.name },
  { input = "Description: {{description}}", expected = "Description: &lt;p&gt;A full bodied roast.&lt;/p&gt;" },
  { input = "Description: {{{description}}}", expected = "Description: "..testData.description },
  { input = "Description: {{{ description }}}", expected = "Description: "..testData.description },
  { input = "Description: {{&description}}", expected = "Description: "..testData.description },
  { input = "Description: {{& description }}", expected = "Description: "..testData.description },
  { input = "Comment: {{! comment}}", expected = "Comment: " },
  { input = "Partial: {{> partial }}", partials = { partial = "Yup" }, expected = "Partial: Yup" },
  { input = "{{> partial }}", partials = { partial = "{{> inception }}", inception = "{{name}}" }, expected = "Coffee" },
  { input = "{{#hot}}Hot!{{/hot}}", expected = "Hot!" },
  { input = "{{^hot}}Cold!{{/hot}}", expected = "Cold!" },
  { input = "{{# hot }}Hot!{{/ hot }}", expected = "Hot!" },
  { input = "{{^ hot }}Cold!{{/ hot }}", expected = "Cold!" }
}

function setup()
end

function teardown()
end

function Tests()
  for i,v in pairs(assertions) do
    assert_equal(v.expected, lustache(v.input, testData, v.partials))
  end
end
