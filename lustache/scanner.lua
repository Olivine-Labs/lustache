local scanner = {}

-- Returns `true` if the tail is empty (end of string).
function scanner:eos()
  return self.tail == ""
end

-- Tries to match the given regular expression at the current position.
-- Returns the matched text if it can match, `null` otherwise.
function scanner:scan(pattern)
  local match = self.tail:match(pattern)

  if match and self.tail:find(pattern) == 1 then
    self.tail = self.tail:sub(#match + 1)
    self.pos = self.pos + #match

    return match
  end

  return nil --> redundant?
end

-- Skips all text until the given regular expression can be matched. Returns
-- the skipped string, which is the entire tail of this scanner if no match
-- can be made.
function scanner:scan_until(pattern)
  local match
  local pos = self.tail:find(pattern)

  if pos == nil then
    match = self.tail
    self.pos = self.pos + #self.tail
    self.tail = ""
  elseif pos == 1 then
    match = nil
  else
    match = self.tail:sub(1, pos - 1)
    self.tail = self.tail:sub(pos)
    self.pos = self.pos + pos
  end

  return match
end

function scanner:new(str)
  local out = {
    str = str,
    tail = str,
    pos = 0
  }
  return setmetatable(out, { __index = self } )
end

return scanner