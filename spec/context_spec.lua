local lustache = require "lustache"  -- only needed to set string.split

local topic = function()
  local view = { name = 'parent', message = 'hi', a = { b = 'b' } }
  local context = require("lustache.context"):new(view)
  return context, view
end

local push = function(context)
  local child_view = { name = 'child', c = { d = 'd' } }
  return context:push(child_view), child_view
end

describe("context specs", function()
  local context, view = topic()

  before_each(function()
    context, view = topic()
  end)

  it("looks up contexts", function()
    assert.equal(context:lookup("name"), view.name)
  end)

  it("looks up nested contexts", function()
    assert.equal(context:lookup("a.b"), view.a.b)
  end)

  it("looks up child contexts", function()
    local child_context, child_view = push(context)
    assert.equal(child_context.view.name, child_view.name)
  end)

  it("looks up child context view properties", function()
    local child_context, child_view = push(context)
    assert.equal(child_context:lookup("name"), child_view.name)
  end)

  it("looks up child context parent view properties", function()
    local child_context, child_view = push(context)
    assert.equal(child_context:lookup("message"), view.message)
  end)

  it("looks up child context nested view properties", function()
    local child_context, child_view = push(context)
    assert.equal(child_context:lookup("c.d"), "d")
  end)

  it("looks up child context parent nested view properties", function()
    local child_context, child_view = push(context)
    assert.equal(child_context:lookup("a.b"), "b")
  end)
end)
