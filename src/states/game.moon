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

  HIT_RANGE = 20
  primary_down: =>
    world = GAME.world
    pos = Vec @body\getPosition!
    delta = Vec(GAME.camera\toWorld lm.getPosition!) - pos
    delta = pos + delta\normalized! * HIT_RANGE
    world\raycast pos.x, pos.y, delta.x, delta.y, (fix, x, y, nx, ny, fract) ->
      if fix\getBody! == @body
        return -1
      other = fix\getBody!\getUserdata!

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

    @map = Sti.new "assets/maps/level-#{level}"
    @world = lp.newWorld!
    @camera = Gamera 0, 0, @map.width*@map.tilewidth, @map.height*@map.tileheight
    @camera\setScale 4

    @collision = {}
    assert @map.layers.collision and @map.layers.collision.type == "objectgroup"
    for box in *@map.layers.collision.objects
      body = lp.newBody @world, box.x + box.width/2, box.y + box.height/2, "static"
      fix  = lp.newFixture body, lp.newRectangleShape box.width, box.height
      body\setUserData table.insert @collision, :body, :fix
    @map\removeLayer "collision"

    assert @map.layers.entities and @map.layers.entities.type == "objectgroup"
    for ent in *@map.layers.entities.objects
      table.insert @ents, Entities[ent.type], ent

    @player = Player 200, 200
    @lag = Vec 200, 200
    @camera\setPosition @lag\unpack!

    for i=1,20
      table.insert @ents, (if math.random! < 0.2 then Enemy else Person) @lag + Vec(math.random!, math.random!) * 200
    
  update: (prev, dt) =>
    delta = Vec(@player.body\getPosition!) - @lag
    @lag += delta * .1

    @player\update dt
    for ent in *@ents
      ent\update dt
    @world\update dt
    @camera\setPosition @lag\unpack!

  draw: (prev) =>
    @camera\draw ->
      @map\draw!
      for obj in *@collision
        lg.polygon "line", obj.body\getWorldPoints obj.fix\getShape!\getPoints!
      @player\draw!
      for ent in *@ents
        ent\draw!

    lg.setColor 0, 0, 0
    lg.rectangle "fill", 20, 22, 10*@player.lunge, 8
    lg.setColor 255, 255, 255
    lg.rectangle "line", 20, 20, 150, 10

  keypressed: (prev, key) =>
    return prev if prev
    switch key
      when "escape"
        love.event.push "quit"
        true
      else
        @player\keypressed key

  keyreleased: (prev, key) =>
    return prev if prev
    switch key
      when "escape"
        print "nope"
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


GAME = Game!
return GAME
