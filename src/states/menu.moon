{graphics: lg} = love

class Menu
  anim:  Animation.soul
  shader: love.graphics.isSupported("shader") and love.graphics.newShader "
    extern number blink;
    
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ) {
      vec4 texcolor = Texel(texture, texture_coords);
      number val = screen_coords.x + screen_coords.y / -4;
      if ( val > blink - 30.0f && val < blink + 30.0f ) {
        color = color + vec4(0.5f, 0.5f, 0.5f, 1.0f);
      }
      return texcolor * color;
    }", "
    vec4 position( mat4 transform_projection, vec4 vertex_position ) {
      return transform_projection * vertex_position;
    }"

  enter: =>
    @logoalpha = 0
    @blink     = 0
    @play      = 0
    @fadeOut   = 1

    blink = ->
      @swag = Flux.to(@, .5, play: 0)\after(.5, play:1)\oncomplete blink
    Flux.to(@, 0.5, fadeOut: 0)\after(0.4, logoalpha: 1)\oncomplete(blink)\after(.8, blink: 1)\ease("linear")\after(.8, blink: 0)\ease "linear"
    @shader\send "blink", 0 if @shader
    @size = Vec Sprite.logo\getDimensions!
  resume: =>
    @enter!

  draw: (prev) =>
    --lg.setColor 120, 120, 120
    --lg.rectangle "fill", 0, 0, SCREEN\unpack!

    lg.setColor 255, 150, 155, @logoalpha*255
    lg.setShader @shader
    lg.draw Sprite.logo, ((SCREEN-@size-Vec 0, 300)/2)\unpack! -- Sprites.logo
    lg.setShader!

    lg.setColor 255, 255, 255, @play*255
    lg.printf "- SPACE TO START GAME -", 0, SCREEN.y-200, SCREEN.x, "center"

    lg.setColor 0, 0, 0, @fadeOut*255
    lg.rectangle "fill", 0, 0, SCREEN\unpack!

  update: (prev, dt) =>
    if @shader then
      @shader\send "blink", @blink * SCREEN.x
    @anim\update dt

  keypressed: (prev, key) =>
    return if @fadeOut > 0
    switch key
      when " "
        @swag\stop! if @swag
        Flux.to(@, 0.6, fadeOut: 1)\oncomplete -> St8.pause require("states.game")!
      when "escape"
        love.event.quit!

Menu!
