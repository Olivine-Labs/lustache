package.path = './../?.lua;'..package.path

lustache = require 'lustache'

require "lunit"
cjson = require "cjson"

module("lustache_testcase", lunit.testcase, package.seeall)

local template, data, partials, expectation

function setup()
  template = ""
  data =  {}
  partials = {}
  expectation = ""
end

function teardown()
end

function RenderNothingTest()
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderTextTest()
  template = "Hi"
  expectation = "Hi"
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderDataTest()
  template = "{{ message }}"
  expectation = "Hi"
  data = { message = "Hi" }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderDataAndTextTest()
  template = "{{ message }} Jack!"
  expectation = "Hi Jack!"
  data = { message = "Hi" }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderDataAndTextTest()
  template = "{{ message }} Jack!"
  expectation = "Hi Jack!"
  data = { message = "Hi" }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderNestedDataTest()
  template = "{{ message.words }} Jack!"
  expectation = "Hi Jack!"
  data = { message = { words = "Hi" } }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderNestedDataSectionsTest()
  template = "{{# message }}{{ words }}{{/ message }} Jack!"
  expectation = "Hi Jack!"
  data = { message = { words = "Hi" } }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderMoreNestedDataWithBooleanSectionsTest()
  template = "{{# message }}{{# words }}Yo{{/ words }}{{/ message }} Jack!"
  expectation = "Yo Jack!"
  data = { message = { words = "Yo" } }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderNegatedSectionsTest()
  template = "{{# message }}{{^ words }}Yo{{/ words }}{{/ message }} Jack!"
  expectation = "Yo Jack!"
  data = { message = { 1 } }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderArrayTest()
  template = "{{# message }}{{ . }}, {{/ message }}"
  expectation = "1, 2, 3, "
  data = { message = { 1, 2, 3 } }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderEscapedHTMLTest()
  template = "{{message}}"
  expectation = "&lt;h1&gt;HI&lt;&#x2Fh1&gt;"
  data = { message = "<h1>HI</h1>" }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderUnescapedHTMLTest()
  template = "{{{message}}}"
  expectation = "<h1>HI</h1>"
  data = { message = "<h1>HI</h1>" }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderPartialsTest()
  template = "{{ title }}{{> message_template }}"
  expectation = "Message: Hi, Jack"
  data = { title = "Message: " }
  partials = { message_template = "Hi, Jack" }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderPartialsInContextTest()
  template = "{{ title }}{{> message_template }}"
  expectation = "Message: Hi, Jack"
  data = { title = "Message: ", message = "Hi, Jack" }
  partials = { message_template = "{{ message }}" }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderFunctionsTest()
  template = "{{ message }} Jack!"
  expectation = "Yo Jack!"
  data = { message = function() return "Yo" end }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderFunctionsWithArgsTest()
  template = "{{# message }}H{{/ message }} Jack!"
  expectation = "Hi Jack!"
  data = { message = function(text, render) return render(text).."i" end }
  assert_equal(expectation, lustache.render(template, data, partials))
end

function RenderCommentsTest()
  template = "{{! comment }}Hi"
  expectation = "Hi"
  assert_equal(expectation, lustache.render(template, data, partials))
end

function ChangeDelimiterTest()
  template = "{{=| |=}}|text|"
  data = { text = "Hi" }
  expectation = "Hi"
  assert_equal(expectation, lustache.render(template, data, partials))
end
