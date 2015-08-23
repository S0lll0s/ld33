export ^

love.graphics.setDefaultFilter "nearest", "nearest"

Gamera  = require "lib.gamera"
Flux    = require "lib.flux"
St8     = require "lib.st8"
Vec     = require "lib.hump-vec"
Sti     = require "lib.sti"
Bump    = require "lib.bump"

import Sprites, Animations from require "sprites"

SCREEN = Vec!

math.randomseed os.time!
for i=1,10 do math.random!

table.find = (val) =>
  for i,v in ipairs self
    return i if v == val
  nil

table.insert = do
  _insert = table.insert
  (a, b) =>
    if b
      _insert @, a, b
      b
    else
      _insert @, a
      a

math.clamp = (val, min, max) ->
  return math.max math.min(val, max or (-min)), min

math.sign = (val) ->
  if val > 0 then 1 else -1

math.choice = (table, ...) ->
  if type(table) ~= "table"
    table = {table, ...}
  return table[math.random #table]

math.raddiff = (a, b) ->
  if math.abs(b - a) <= math.pi
    b-a
  elseif b >= a
    b - a - math.pi*2
  else
    b - a + math.pi*2

math.floor = do
  _floor = math.floor
  (...) ->
    unpack [_floor select i, ... for i=1, select "#", ...]

love.resize = (w, h) ->
  SCREEN = Vec w, h

love.load = ->
  SCREEN = Vec love.graphics.getDimensions!
  
  -- love.graphics.setNewFont "assets/font.ttf", 18

  if arg[#arg] == "game"
    St8.init require "states.game"
  else
    St8.init require "states.menu"
  St8.order "draw", "bottom"
  love.mouse.setGrabbed true

love.update = (dt) ->
  Flux.update dt
