package.path = './../?.lua;'..package.path

lustache = require 'lustache'

require "lunit"

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
  data = { message = function(self, text, render) return render(text).."i" end }
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

function ArrayOfTablesTest()
  template = "{{#beatles}}{{name}} {{/beatles}}"
  data = {
    beatles = {
      { name = "John Lennon" },
      { name = "Paul McCartney" },
      { name = "George Harrison" },
      { name = "Ringo Starr" }
    }
  }
  expectation = "John Lennon Paul McCartney George Harrison Ringo Starr "
  assert_equal(expectation, lustache.render(template, data, partials))
end

function ArrayOfTablesFunctionTest()
  template = "{{#beatles}}* {{name}}\n{{/beatles}}"
  data = {
    beatles = {
      { first_name = "John", last_name = "Lennon" },
      { first_name = "Paul", last_name = "McCartney" },
      { first_name = "George", last_name = "Harrison" },
      { first_name = "Ringo", last_name = "Starr" }
    },
    name = function (self)
      return self.first_name .. " " .. self.last_name
    end
  }
  expectation = "* John Lennon\n* Paul McCartney\n* George Harrison\n* Ringo Starr\n"
  assert_equal(expectation, lustache.render(template, data, partials))
end
