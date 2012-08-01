package.path = './../?.lua;'..package.path

lustache = require 'lustache'

require "lunit"

module("lustache_testcase", lunit.testcase, package.seeall)

local topic = function()
  local view = { name = 'parent', message = 'hi', a = { b = 'b' } }
  local context = lustache.Context(view)
  return context, view
end

local push = function(context)
  local child_view = { name = 'child', c = { d = 'd' } }
  return context:push(child_view), child_view
end

function setup()
end

function teardown()
end

function ContextLookupTest()
  local context, view = topic()
  assert_equal(context:lookup("name"), view.name)
end

function ContextLookupNestedTest()
  local context, view = topic()
  assert_equal(context:lookup("a.b"), view.a.b)
end

function ChildContextTest()
  local context, view = topic()
  local child_context, child_view = push(context)
  assert_equal(child_context.view.name, child_view.name)
end

function ChildContextViewPropertyTest()
  local context, view = topic()
  local child_context, child_view = push(context)
  assert_equal(child_context:lookup("name"), child_view.name)
end

function ChildContextParentViewPropertyTest()
  local context, view = topic()
  local child_context, child_view = push(context)
  assert_equal(child_context:lookup("message"), view.message)
end

function ChildContextNestedViewPropertyTest()
  local context, view = topic()
  local child_context, child_view = push(context)
  assert_equal(child_context:lookup("c.d"), "d")
end

function ChildContextParentNestedViewPropertyTest()
  local context, view = topic()
  local child_context, child_view = push(context)
  assert_equal(child_context:lookup("a.b"), "b")
end
