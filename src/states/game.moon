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
    @color = {1, 1, 1}
    @fix  = lp.newFixture @body, lp.newCircleShape 8
    @body\setUserData @
    @body\setBullet true
    @lunge = 0
    @facing = Vec!
    @idle = Animation.player_idle
    @walk = Animation.player_walk
    @anim = @idle
    @swipe = Animation.swipe
    @swipe.onLoop = (swp) ->
      @primary = nil
      swp\pauseAtStart!

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
    @anim\update dt
    @swipe\update dt

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

    desired = Vec! if GAME.beastfade or (GAME.beastmode and @isDown "secondary")
    
    diff = desired - @vel!
    diff *= ACCEL * @body\getMass!
    @body\applyForce diff\unpack!

    @lunge += dt * 2
    @lunge = math.min @lunge, if GAME.beastmode and @isDown "secondary" then 3.5 else 1.5

    if @vel!\len2! > (10^2)
      @walk\gotoFrame 1 unless @anim == @walk
      @anim = @walk
    else
      @idle\gotoFrame 1 unless @anim == @idle
      @anim = @idle

    @facing = Vec(GAME.camera\toWorld lm.getPosition!) - @pos!

  draw: =>
    x, y = @body\getPosition!
    lg.setColor @color[1]*255, @color[2]*255, @color[3]*255
    @anim\draw (if GAME.beastmode then Sprite.beast else Sprite.player), x, y, @facing\angleTo!, 1, 1, 7, 8
    lg.setColor 255, 255, 255
    @primary\draw Sprite.swipe, x, y, @primary.rot, 1, 1, -5, 9 if @primary

  pos: =>
    Vec @body\getPosition!
  vel: =>
    Vec @body\getLinearVelocity!

  rayCast: (pos, delta, cb) =>
    tgt = pos + delta
    GAME.world\rayCast pos.x, pos.y, tgt.x, tgt.y, cb

  primary_down: =>
    return if @primary

    pos = @pos!
    delta = @facing\normalized! * if GAME.beastmode then 35 else 15

    res = {}
    cb = (fix, x, y, nx, ny, fract) ->
      if fix\getBody! == @body
        return -1
      other = fix\getBody!\getUserData!
      res[other] = true
      return -1

    @primary = @swipe
    @primary.rot = delta\angleTo!
    @primary\resume!

    @rayCast pos, delta, cb
    @rayCast pos, delta\rotated( .4), cb
    @rayCast pos, delta\rotated(-.4), cb

    for other,_ in pairs res
      if other.hit
        other\hit delta
      if other.body
        other.body\applyLinearImpulse (delta/2)\unpack!

  secondary_down: =>
    return unless GAME.beastmode
    if @lunge > 1.5
      @lungestate = "charging"
      @lunge = 0

  secondary_up: (x, y) =>
    return unless GAME.beastmode
    @lunge = -math.clamp @lunge-1.5, 0, 2
    delta = Vec(x, y) - Vec @body\getPosition!
    @body\applyLinearImpulse (delta\normalized! * -@lunge * 150)\unpack!

class Game
  canvas: lg.newCanvas!
  shader: lg.isSupported("shader") and lg.newShader "
    extern number amount;
    
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ) {
      vec4 texcolor = Texel(texture, texture_coords);
      vec4 avg = vec4(dot(texcolor.rgb, vec3(1.0f))/3.0f);
      avg.a = texcolor.a;
      return mix(texcolor, avg, amount);
    }", "
    vec4 position( mat4 transform_projection, vec4 vertex_position ) {
      return transform_projection * vertex_position;
    }"
  
  unzip = (tbl) ->
    res = {}
    for i in *tbl
      table.insert res, i.x
      table.insert res, i.y
    unpack res
  enter: (level=1) =>
    GAME = @

    @ents   = {}
    @spawns = {}
    @score  = good: 0, bad: 0, scale: 1, grot: 0, brot: 0
    @timescale = 1
    @fadeOut   = 1
    @colorAmnt = 0
    Flux.to @, 0.5, fadeOut: 0

    @timeleft = 90

    @map = Sti.new "assets/maps/level-#{level}"
    @world = lp.newWorld!
    @world\setCallbacks @\beginTouch
    @camera = Gamera 0, 0, @map.width*@map.tilewidth, @map.height*@map.tileheight
    @camera\setScale 4

    @collision = {}
    assert @map.layers.collision and @map.layers.collision.type == "objectgroup", "no collision layer"
    for box in *@map.layers.collision.objects
      switch box.shape
        when "rectangle"
          body = lp.newBody @world, box.x + box.width/2, box.y + box.height/2, "static"
          fix  = lp.newFixture body, lp.newRectangleShape box.width, box.height
          body\setUserData table.insert @collision, :body, :fix, world: true
        when "polygon"
          body = lp.newBody @world, 0, 0
          fix  = lp.newFixture body, lp.newPolygonShape unzip box.polygon
          body\setUserData table.insert @collision, :body, :fix, world: true
        when "polyline"
          body = lp.newBody @world, 0, 0
          fix  = lp.newFixture body, lp.newChainShape false, unzip box.polyline
          body\setUserData table.insert @collision, :body, :fix, world: true
    @map\removeLayer "collision"

    assert @map.layers.entities and @map.layers.entities.type == "objectgroup", "no entitity layer"
    for ent in *@map.layers.entities.objects
      switch ent.type
        when "player"
          @player = Player ent.x, ent.y
        else
          table.insert @spawns, x: ent.x, y: ent.y, w: ent.width, h: ent.height
    @map\removeLayer "entities"
    
    assert @player, "no player"
    @lag = @player\pos!\clone!
    @camera\setPosition @lag\unpack!

    for i=1,40
      spawn = math.choice @spawns
      table.insert @ents, (if math.random! < 0.4 then Enemy else Person) spawn.x + math.random!*spawn.w, spawn.y + math.random!*spawn.h
    
  update: (prev, dt) =>
    return prev if prev

    return if @done

    if @timeleft < 0
      Flux.to(@, .4, fadeOut: 1)\oncomplete -> St8.swap @, require("states.gameover"), @score
      @done = true
    else
      @timeleft -= dt
  
    dt *= @timescale
    if @beastmode
      @beastmode -= dt
      if @beastmode < 2
        --Sound.demutate! unless @beastfade
        Sound.growl2! unless @beastfade
        @beastfade = Flux.to(@, 2, colorAmnt: 0)\oncomplete (->
          @beastmode = nil
          @beastfade = nil
        ) unless @beastfade

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
    lg.setCanvas @canvas
    @camera\draw ->
      @map\draw!
      @player\draw!
      for ent in *@ents
        ent\draw! if ent.draw and not ent.destroy

    if @canvas and @shader
      lg.setCanvas!
      @shader\send "amount", @colorAmnt
      lg.setShader @shader
      lg.setColor 255, 255, 255, 255
      lg.draw @canvas
      lg.setShader!

    lg.setColor 0, 0, 0, 200
    lg.rectangle "fill", 0, 0, SCREEN.x, 70

    lg.setColor 255, 255, 255, 255
    lg.print "LUNGE", 30, 14
    lg.print "BEAST", 30, 44
    @bar 100, 10, math.abs (@beastmode and @player.lunge or 0)/3.5
    @bar 100, 40, (@beastmode or 0)/BEAST_DURATION

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

  bar: (x, y, val) =>
    lg.setScissor x+2, y, 180*val, 21
    lg.draw Sprite.bar_bottom, x, y
    lg.setScissor!
    lg.draw Sprite.bar_top, x, y

  BEAST_DURATION = 8
  do_beast: =>
    Sound.growl! unless @beastmode
    @beastmode = BEAST_DURATION
    @beastfade\stop! if @beastfade
    @beastfade = nil
    Flux.to(@, 0.2, timescale: 0.7)\after(0.2, timescale: 1)\delay 0.4
    @beastfade = Flux.to(@, 1.4, colorAmnt: 0.6)\oncomplete -> @beastfade = nil
    Flux.to(@player.color, 0.4, {1, .1, .1})\after(0.4, {1, 1, 1})\delay .6

  addScore: (kind) =>
    @score.good += if kind == "Enemy" then 20 else -5
    @score.bad  += 10
    @score.tween\stop! if @score.tween
    @score.tween = Flux.to(@score, .5, scale: 1.5, grot: math.random!/2-.25, brot: math.random!/2-.25)\after(.3, scale: 1, grot: 0, brot: 0)\delay .2
  
    @do_beast! unless @beastmode
    @beastmode = BEAST_DURATION

  keypressed: (prev, key) =>
    return prev if prev
    switch key
      when "escape", "p"
        St8.push require "states.pause"
        true
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

return Game
