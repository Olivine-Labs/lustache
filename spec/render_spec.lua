local lustache = require "lustache"

describe("rendering", function()
  local template, data, partials, expectation

  before_each(function()
    template = ""
    data =  {}
    partials = {}
    expectation = ""
  end)

  it("RenderNothingTest", function()
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderTextTest", function()
    template = "Hi"
    expectation = "Hi"
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("Render whitespace", function()
    template = "\n"
    expectation = "\n"
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderDataTest", function()
    template = "{{ message }}"
    expectation = "Hi"
    data = { message = "Hi" }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderDataAndTextTest", function()
    template = "{{ message }} Jack!"
    expectation = "Hi Jack!"
    data = { message = "Hi" }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderDataAndTextTest", function()
    template = "{{ message }} Jack!"
    expectation = "Hi Jack!"
    data = { message = "Hi" }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderNestedDataTest", function()
    template = "{{ message.words }} Jack!"
    expectation = "Hi Jack!"
    data = { message = { words = "Hi" } }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderNestedDataSectionsTest", function()
    template = "{{# message }}{{ words }}{{/ message }} Jack!"
    expectation = "Hi Jack!"
    data = { message = { words = "Hi" } }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderMoreNestedDataWithBooleanSectionsTest", function()
    template = "{{# message }}{{# words }}Yo{{/ words }}{{/ message }} Jack!"
    expectation = "Yo Jack!"
    data = { message = { words = "Yo" } }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderNegatedSectionsTest", function()
    template = "{{# message }}{{^ words }}Yo{{/ words }}{{/ message }} Jack!"
    expectation = "Yo Jack!"
    data = { message = { 1 } }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderArrayTest", function()
    template = "{{# message }}{{ . }}, {{/ message }}"
    expectation = "1, 2, 3, "
    data = { message = { 1, 2, 3 } }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderEscapedHTMLTest", function()
    template = "{{message}}"
    expectation = "&lt;h1&gt;HI&lt;&#x2F;h1&gt;"
    data = { message = "<h1>HI</h1>" }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderUnescapedHTMLTest", function()
    template = "{{{message}}}"
    expectation = "<h1>HI</h1>"
    data = { message = "<h1>HI</h1>" }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderPartialsTest", function()
    template = "{{ title }}{{> message_template }}"
    expectation = "Message: Hi, Jack"
    data = { title = "Message: " }
    partials = { message_template = "Hi, Jack" }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderPartialsInContextTest", function()
    template = "{{ title }}{{> message_template }}"
    expectation = "Message: Hi, Jack"
    data = { title = "Message: ", message = "Hi, Jack" }
    partials = { message_template = "{{ message }}" }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderFunctionsTest", function()
    template = "{{ message }} Jack!"
    expectation = "Yo Jack!"
    data = { message = function() return "Yo" end }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderFunctionsWithArgsTest", function()
    template = "{{# message }}H{{/ message }} Jack!"
    expectation = "Hi Jack!"
    data = { message = function(text, render) return render(text).."i" end }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderFunctionsUnrenderedArgsTest", function()
    template = "{{# message }}{{H}}{{/ message }} Jack!"
    expectation = "{{H}}i Jack!"
    data = { message = function(text, render) return text.."i" end }
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("RenderCommentsTest", function()
    template = "{{! comment }}Hi"
    expectation = "Hi"
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("ChangeDelimiterTest", function()
    template = "{{=| |=}}|text|"
    data = { text = "Hi" }
    expectation = "Hi"
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("ArrayOfTablesTest", function()
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
    assert.equal(expectation, lustache:render(template, data, partials))
  end)

  it("ArrayOfTablesFunctionTest", function()
    template = "{{#beatles}}\n* {{name}}\n{{/beatles}}"
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
    assert.equal(expectation, lustache:render(template, data, partials))
  end)
end)
