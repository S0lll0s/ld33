local St8 = {
  _VERSION = "St8 v1.1",
  _DESCRIPTION = "A tiny double-stacked state manging library for Lua/LÖVE",
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2014 Sol Bekic

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local CALLBACKS = {"draw", "focus", "keypressed", "keyreleased", "load", "mousefocus", "mousemoved", "mousepressed", "mousereleased", "quit", "resize", "run", "textinput", "threaderror", "update", "visible"}

St8.old = {}
St8._order = {}

---------------------------------------------------
-- register St8 with LÖVE callbacks and enter `state` (if `state` is numerically indexed, it will be used as a _Stack_)
function St8.init(state, ...)
  for _,cb in ipairs(CALLBACKS) do
    St8.old[cb] = love[cb]
    love[cb] = function (...)
      return St8.handle(cb, ...)
    end
  end
  if not state[1] then state = {state} end
  St8.stacks = {state}
  St8.handle("enter", ...)
end

---------------------------------------
-- handle `evt` using the current _Stack_
function St8.handle(evt, ...)
  local stack = St8.stacks[#St8.stacks]
  local prev
  if St8._order[evt] == "bottom" then
    for _,state in ipairs(stack) do
      if state[evt] then
        prev = state[evt](state, prev, ...)
      end
    end
  else
    for i=#stack,1,-1 do
      if stack[i][evt] then
        prev = stack[i][evt](stack[i], prev, ...)
      end
    end
  end
  if St8.old[evt] then
    return St8.old[evt](...)
  end
end

-----------------------------------------------------
-- set the order in which _States_ handle `evt` to `order` (everything except "bottom" is considered as _top-first_, the default)
function St8.order(evt, order)
  St8._order[evt] = order
end

-----------------------------------------------
-- return the lowest _State_ on the current _Stack_
function St8.base()
  return St8.stacks[#St8.stacks][1]
end

------------------------------------------
-- push the _State_ `new` to the current _Stack_ (it will run in parallel to the current one)
function St8.push(new, ...)
  table.insert(St8.stacks[#St8.stacks], new)
  return new.enter(new, nil, ...)
end

---------------------------------------
-- pop one _State_ from the current _Stack_
function St8.pop(which, ...)
  local stack = St8.stacks[#St8.stacks]
  assert(#stack ~= 0, "Stack is already empty!")
  local prev = nil
  if not which or type(which) == "number" then
    for i=1,(which or 1) do
      local l = table.remove(stack)
      prev = l.exit and l.exit(l, prev, ...) or nil
    end
  else
    for i,v in ipairs(stack) do
      if v == which then
        local l = table.remove(stack, i)
        if l.exit then l.exit(l, prev, ...) end
      end
    end
  end
  St8.handle("popped", ...)
  return prev
end

-------------------------------------------------------
-- swap a _State_ with another one (on the current _Stack_)
function St8.swap(old, new, ...)
  table.insert(St8.stacks[#St8.stacks], new)
  local prev = St8.pop(old, ...)
  return new.enter and new.enter(new, prev, ...)
end

--------------------------------------------------
-- pause current _Stack_ and transition to `new` _State_ (if `new` is numerically indexed, it will be used as a new Stack)
function St8.pause(new, ...)
  local r = St8.handle("pause", ...)
  if not new[1] then new = {new} end
  table.insert(St8.stacks, new)
  St8.handle("enter", ...)
  return r
end

------------------------
-- resume previous _Stack_
function St8.resume(...)
  assert(#St8.stacks > 1, "no Stack to resume!")
  local r = St8.handle("exit", ...)
  table.remove(St8.stacks)
  St8.handle("resume", ...)
  return r
end

function St8.removebelow()
  table.remove(St8.stacks, #St8.stacks - 1)
end

return St8
