Anim8 = require "lib.anim8"

{graphics: lg} = love

Sprites = {}
for sprite in *{"soul"}
  Sprites[sprite] = lg.newImage "assets/graphics/#{sprite}.png"

Animations = {}

Grids = {}
for name, anim in pairs soul: {w: 10, h: 13, '1-2', 1, 1, 1, 3, 1}
  Grids[name]      = Anim8.newGrid anim.w, anim.h, Sprites[name]\getDimensions!
  Animations[name] = Anim8.newAnimation Grids[name](unpack anim), anim.s or 0.3

{
  :Sprites
  Animations: setmetatable {}, __index: (index) =>
    rawget(Animations, index)\clone! -- clone animations
}
