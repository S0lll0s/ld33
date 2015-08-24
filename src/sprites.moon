Anim8 = require "lib.anim8"

{graphics: lg} = love

Sprite = {}
for sprite in *{"soul", "swipe", "player"}
  Sprite[sprite] = lg.newImage "assets/graphics/#{sprite}.png"

Animation = {}

Grid = {}
for name, anim in pairs {
    soul:         {w: 10, h: 13, "1-2", 1, 1, 1, 3, 1},
    swipe:        {w: 6,  h: 19, s: 0.02, "1-13", loop: "pauseAtEnd", 1},
    player_walk:  {w: 13, h: 16, sprite: "player", s: 0.1, "4-7", 1}
    player_idle:  {w: 13, h: 16, sprite: "player", "3-1", 1, "1-3", 1, 3, 1, 3, 1}
  }
  anim.sprite or= name
  Grid[anim.sprite] = Anim8.newGrid anim.w, anim.h, Sprite[anim.sprite]\getDimensions! unless Grid[anim.sprite]
  Animation[name]   = Anim8.newAnimation Grid[anim.sprite](unpack anim), anim.s or 0.3, anim.loop

{
  :Sprite,
  Animation: setmetatable {}, __index: (index) =>
    rawget(Animation, index)\clone! -- clone animations
}
