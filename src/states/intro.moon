{graphics: lg} = love

class Intro
  enter: =>
    @fadeIn = 0
    @image = Sprite.s0lll0s
    @dim = Vec @image\getDimensions!
    blink = (cb) ->
      Flux.to(@, 0.6, fadeIn: 1)\after(0.4, fadeIn: 0)\delay(1.5)\after(.7,{})\oncomplete(cb)
    
    blink ->
      @image = Sprite.stewart
      @dim = Vec @image\getDimensions!
      blink ->
        @image = Sprite.eric
        @dim = Vec @image\getDimensions!
        blink ->
          St8.pause require "states.menu"

  draw: =>
    lg.setColor 255, 255, 255, @fadeIn*255
    lg.draw @image, ((SCREEN-@dim)/2)\unpack!

Intro!
