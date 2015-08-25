{graphics: lg, keyboard: lk, mouse: lm, physics: lp} = love

local Person, Enemy
class Person
  new: (x, y) =>
    @body = lp.newBody GAME.world, x, y, "dynamic"
    @fix  = lp.newFixture @body, lp.newCircleShape 6
    @body\setUserData @

    @scale, @rot, @alpha = 1, 0, 1

    @soul = Animation.soul
    @skin = Sprite["civilian-#{math.random 1, 4}"]
    @anim = Animation.person

    @steering = Vec!
    @wander_angle = math.random!*math.pi*2

  draw: =>
    pos = @pos!

    lg.setColor 255, 255, 255, @alpha*255
    if GAME.beastmode
      @soul\draw Sprite.soul, pos.x, pos.y + (@alpha-1)*.05, @rot, @scale, @scale, 5, 5
    else
      @anim\draw @skin, pos.x, pos.y, @vel!\angleTo!, @scale, @scale, 5, 7

  MAX_FORCE = 10
  MAX_VEL   = 50
  update: (dt) =>
    return if (GAME.player\pos! - @pos!)\len2! > 300^2
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
    @steering *= 0.7
    @body\applyForce @steering\unpack!

  hit: (delta) =>
    @dead = true
    Flux.to(@, 1, alpha: 0, rot: math.random!-0.5, scale: 1.2)\oncomplete ->
      @destroy = true
      @body\destroy! unless @body\isDestroyed!

    Sound.hit!

    GAME\addScore @@__name, 1

    Flux.to(@, 6, {})\oncomplete ->
      spawn = math.choice GAME.spawns
      table.insert GAME.ents, (if math.random! < 0.4 then Enemy else Person) spawn.x + math.random!*spawn.w, spawn.y + math.random!*spawn.h

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
    @skin = Sprite.enemy

{
  :Person
  :Enemy
}
