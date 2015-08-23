{graphics: lg, keyboard: lk, mouse: lm, physics: lp} = love

class Person
  new: (pos, world) =>
    @body = lp.newBody GAME.world, pos.x, pos.y, "dynamic"
    @fix  = lp.newFixture @body, lp.newCircleShape 6
    @body\setUserData @

    @scale, @rot = 1, 0

    @color = {100, 255, 100, 255}
    @soul = Animations.soul
    --@skin = Sprites.soul
    --@anim = Animations.person
    @skin, @anim = Sprites.soul, @soul

    @steering = Vec!
    @wander_angle = math.random!*math.pi*2

  draw: =>
    pos = @pos!

    if GAME.beastmode
      lg.setColor 255, 255, 255, @color[4]
      @soul\draw Sprites.soul, pos.x, pos.y + (@color[4]-255)*.05, @rot, @scale, @scale, 5, 5
    else
      lg.setColor @color
      @anim\draw @skin, pos.x, pos.y + (@color[4]-255)*.05, @rot, @scale, @scale, 5, 5

  MAX_FORCE = 10
  MAX_VEL   = 50
  update: (dt) =>
    @steering\set 0, 0
    if GAME.beastmode
      @soul\update dt * math.random! * 2
    else
      @anim\update dt

    @steering += 0.3 * @wander dt
    @steering += 1.0 * @seperate!
    @steering += 0.7 * @flee GAME.player\pos! if GAME.beastmode
    @steering += 0.5 * @evade!

    @steering\trim_inplace MAX_FORCE
    @body\applyForce @steering\unpack!

  hit: (delta) =>
    @dead = true
    Flux.to @color, 1, [4]: 0
    Flux.to(@, 1, rot: math.random!-0.5, scale: 1.2)\oncomplete ->
      @destroy = true
      @body\destroy! unless @body\isDestroyed!

    GAME\addScore @@__name, 1

  vel: =>
    Vec @body\getLinearVelocity!
  pos: =>
    Vec @body\getPosition!

  CIRCLE_DIST = 20
  CIRCLE_RAD  = 17
  ANGLE_DELTA = 50
  wander: (dt) =>
    @wander_angle += (math.random! - 0.5) * ANGLE_DELTA*dt
    force = @vel!\normalized! * CIRCLE_DIST
    force += Vec(CIRCLE_RAD, 0)\rotated @wander_angle
    force

  flee: (fr) =>
    delta = @pos! - fr
    if delta\len2! < 120^2
      delta\normalized! * MAX_VEL
    else
      Vec!

  DESIRED_DIST2 = 20 ^ 2
  seperate: =>
    sum, cnt = Vec!, 0
    for o in *GAME.ents
      continue if o.destroy
      delta = @pos! - o\pos!
      if not delta\isNull! and delta\len2! < DESIRED_DIST2
        sum += delta / delta\len!

    delta = @pos! - GAME.player\pos!
    if not delta\isNull! and delta\len2! < DESIRED_DIST2*2
      sum += delta / delta\len!

    sum\normalized! * MAX_VEL

  LOOK_AHEAD = 80
  evade: =>
    pos = @pos!
    vel = @vel!
    return Vec! if @vel!\isNull!
    front = pos + vel\normalized! * LOOK_AHEAD
    res = Vec!
    GAME.world\rayCast pos.x, pos.y, front.x, front.y, (fix, x, y, nx, ny, fract) ->
      return -1 if fix\getBody! == @body
      ud = fix\getBody!\getUserData!
      return -1 unless ud and ud.world
      res = MAX_VEL * (1 - fract) * Vec nx, ny
      0
    res

class Enemy extends Person
  new: (...) =>
    super ...
    @color = {255, 100, 100, 255}

{
  :Person
  :Enemy
}
