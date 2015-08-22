{graphics: lg, keyboard: lk, mouse: lm, physics: lp} = love

class Person
  new: (pos, world) =>
    @body = lp.newBody GAME.world, pos.x, pos.y, "dynamic"
    @fix  = lp.newFixture @body, lp.newCircleShape 6
    @body\setUserData @
    @anim = Animations.soul

  draw: =>
    x, y = @body\getPosition!
    if GAME.ragemode
      lg.setColor 255, 0, 0
    else
      lg.setColor 0, 255, 0
    -- lg.circle "fill", x, y, 5
    lg.setColor 255, 255, 255
    @anim\draw Sprites.soul, x, y, 0, 1, 1, 5, 5

  update: (dt) =>
    @anim\update dt

class Enemy extends Person
  draw: =>
    x, y = @body\getPosition!
    lg.setColor 255, 0, 0
    lg.circle "fill", x, y, 10

{
  :Person
  :Enemy
}
