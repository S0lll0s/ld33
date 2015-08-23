export GAME

{graphics: lg, keyboard: lk, mouse: lm, physics: lp} = love
import Person, Enemy from require "characters"

lp.newBody = do
  _newBody = lp.newBody
  (...) ->
    b = _newBody ...
    b\setLinearDamping 0.8
    b

mousetrans = {lmb: "l", rmb: "r", mmb: "m", m4: "x1", m5: "x", mwup: "wu", mwdn: "wd"}
class Player
  new: (x, y, @controls=up: "w", left: "a", right: "d", down: "s", primary: "lmb", secondary: "rmb", charge: "mmb") =>
    @body = lp.newBody GAME.world, x, y, "dynamic"
    @fix  = lp.newFixture @body, lp.newCircleShape 15
    @body\setUserData @
    @body\setBullet true
    @lunge = 0

  isDown: (keyspec) =>
    key = @controls[keyspec]
    if mousetrans[key]
      lm.isDown mousetrans[key]
    else
      lk.isDown key
  
  keypressed: (key, ...) =>
    for spec, k in pairs @controls
      @["#{spec}_down"] @, ... if key == k and @["#{spec}_down"]
  keyreleased: (key, ...) =>
    for spec, k in pairs @controls
      @["#{spec}_up"] @, ... if key == k and @["#{spec}_up"]

  MAX_VEL = 100
  ACCEL = 5
  update: (dt) =>
    desired = Vec!
    if @isDown "up"
      desired -= Vec 0, 1
    if @isDown "down"
      desired += Vec 0, 1
    if @isDown "left"
      desired -= Vec 1, 0
    if @isDown "right"
      desired += Vec 1, 0
    desired\normalize_inplace MAX_VEL
    
    diff = desired - Vec @body\getLinearVelocity!
    diff *= ACCEL * @body\getMass!
    @body\applyForce diff\unpack!

    @lunge += dt * 2
    @lunge = math.min @lunge, if @isDown "secondary" then 3.5 else 1.5

  draw: =>
    x, y = @body\getPosition!
    lg.setColor 255, 255, 255
    lg.circle "fill", x, y, 15

  rayCast: (pos, delta, cb) =>
    tgt = pos + delta
    GAME.world\rayCast pos.x, pos.y, tgt.x, tgt.y, cb

  HIT_RANGE = 30
  primary_down: =>
    world = GAME.world
    pos = @pos!
    delta = Vec(GAME.camera\toWorld lm.getPosition!) - pos
    delta = delta\normalized! * HIT_RANGE

    res = {}
    cb = (fix, x, y, nx, ny, fract) ->
      if fix\getBody! == @body
        return -1
      other = fix\getBody!\getUserData!
      res[other] = true
      return -1


    @rayCast pos, delta, cb
    @rayCast pos, delta\rotated( .4), cb
    @rayCast pos, delta\rotated(-.4), cb

    for other,_ in pairs res
      if other.hit
        other\hit delta
      if other.body
        other.body\applyLinearImpulse (delta/2)\unpack!

  pos: =>
    Vec @body\getPosition!
  vel: =>
    Vec @body\getLinearVelocity!

  secondary_down: =>
    if @lunge > 1.5
      @lungestate = "charging"
      @lunge = 0

  secondary_up: (x, y) =>
    @lunge = -math.clamp @lunge-1.5, 0, 2
    delta = Vec(x, y) - Vec @body\getPosition!
    @body\applyLinearImpulse (delta\normalized! * -@lunge * 600)\unpack!

class Game
  enter: (level=1) =>
    @ents   = {}
    @score  = good: 0, bad: 0, scale: 1, grot: 0, brot: 0
    @fadeOut= 1
    Flux.to @, 0.3, fadeOut: 0

    @timeleft = 30

    @map = Sti.new "assets/maps/level-#{level}"
    @world = lp.newWorld!
    @world\setCallbacks @\beginTouch
    @camera = Gamera 0, 0, @map.width*@map.tilewidth, @map.height*@map.tileheight
    @camera\setScale 4

    @collision = {}
    assert @map.layers.collision and @map.layers.collision.type == "objectgroup"
    for box in *@map.layers.collision.objects
      body = lp.newBody @world, box.x + box.width/2, box.y + box.height/2, "static"
      fix  = lp.newFixture body, lp.newRectangleShape box.width, box.height
      body\setUserData table.insert @collision, :body, :fix, world: true
    @map\removeLayer "collision"

    assert @map.layers.entities and @map.layers.entities.type == "objectgroup"
    for ent in *@map.layers.entities.objects
      table.insert @ents, Entities[ent.type], ent

    @player = Player 200, 200
    @lag = Vec 200, 200
    @camera\setPosition @lag\unpack!

    for i=1,20
      table.insert @ents, (if math.random! < 0.4 then Enemy else Person) @lag + Vec(math.random!, math.random!) * 200
    
  update: (prev, dt) =>
    return prev if prev

    if @timeleft < 0
      dt = 0
      Flux.to @, 1.0, fadeOut: 1
    else
      @timeleft -= dt

    if @beastmode and @beastmode < 0
      @beastmode = math.min 0, @beastmode + dt
      dt = dt/3

    delta = Vec(@player.body\getPosition!) - @lag
    @lag += delta * .1

    @player\update dt
    for i=#@ents,1,-1
      if @ents[i].destroy
        table.remove @ents, i
        continue
      @ents[i]\update dt
    @world\update dt
    @camera\setPosition @lag\unpack!

  draw: (prev) =>
    @camera\draw ->
      @map\draw!
      for obj in *@collision
        lg.polygon "line", obj.body\getWorldPoints obj.fix\getShape!\getPoints!
      @player\draw!
      for ent in *@ents
        ent\draw! if ent.draw and not ent.destroy

    lg.setColor 0, 0, 0
    lg.rectangle "fill", 20, 22, 10*@player.lunge, 8
    lg.setColor 255, 255, 255
    lg.rectangle "line", 20, 20, 150, 10

    lg.setColor 0, 0, 0, 100
    lg.rectangle "fill", 0, 0, SCREEN.x, 100

    x = (SCREEN.x - 150)
    lg.printf "SCORE", x-50, 20, 100, "center"
    lg.printf tostring(@score.good), x-5, 45, 50, "right", @score.grot, @score.scale, @score.scale, 50, 5
    lg.printf tostring(@score.bad),  x+5, 45, 50, "left",  @score.brot, @score.scale, @score.scale, 0, 5

    time = math.floor @timeleft
    secs = time % 60
    time -= secs
    time = "#{time/60}:#{secs}"
    lg.printf time, 0, 30, SCREEN.x, "center"

    lg.setColor 0, 0, 0, @fadeOut * 255
    lg.rectangle "fill", 0, 0, SCREEN\unpack!

  addScore: (kind) =>
    @score.good += if kind == "Enemy" then 20 else -5
    @score.bad  += 10
    @score.tween\stop! if @score.tween
    @score.tween = Flux.to(@score, .5, scale: 1.5, grot: math.random!/2-.25, brot: math.random!/2-.25)\after(.3, scale: 1, grot: 0, brot: 0)\delay .2

  keypressed: (prev, key) =>
    return prev if prev
    switch key
      when "escape", "p"
        St8.push require "states.pause"
        true
      when "lshift"
        @beastmode = if @beastmode then nil else -1
      else
        @player\keypressed key

  keyreleased: (prev, key) =>
    return prev if prev
    switch key
      when "escape" then true
      else
        @player\keyreleased key

  mousepressed: (prev, x, y, btn) =>
    return prev if prev
    spec = (-> for k,v in pairs mousetrans do return k if v == btn)!
    @player\keypressed spec, @camera\toWorld x, y

  mousereleased: (prev, x, y, btn) =>
    return prev if prev
    spec = (-> for k,v in pairs mousetrans do return k if v == btn)!
    @player\keyreleased spec, @camera\toWorld x, y

  beginTouch: (a, b, cont) =>
    a, b = a\getBody!\getUserData!, b\getBody!\getUserData!
    return unless a and b

    local chr, ply, wld

    if a.__class
      switch a.__class.__name
        when "Person", "Enemy"
          chr = a
        when "Player"
          ply = a
    elseif a.world
      wld = a

    if b.__class
      switch b.__class.__name
        when "Person", "Enemy"
          chr = b
        when "Player"
          ply = b
    elseif b.world
      wld = b
    
    if ply and chr
      impact_vel = ply\vel! - chr\vel!
      if impact_vel\len2! > 80^2 and ply.lunge < 0
        chr\hit!

GAME = Game!
return GAME
