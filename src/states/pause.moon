{graphics: lg} = love

class Pause
  enter: (...) =>
    @offset = .5 * Vec Sprite.pause\getDimensions!
    @fadeIn = 0
    @fadeOut= 0
    @fading = false
    Flux.to @, 0.2, fadeIn: 1

  draw: (prev) =>
    lg.origin!
    lg.setColor 255, 255, 255, 100 * @fadeIn
    lg.rectangle "fill", 0, 0, SCREEN\unpack!
    lg.translate 0, SCREEN.y * (@fadeIn - 1), 0
    lg.setColor 255, 255, 255, 255 * @fadeIn
    lg.draw Sprite.pause, SCREEN.x/2, 200, 0, 2, 2, @offset\unpack!

    lg.setColor 0, 0, 0, 255 * @fadeIn
    lg.print "press Q to quit to menu", 400, 400
    lg.print "press ESC or P to resume", 400, 450

    lg.origin!
    lg.setColor 0, 0, 0, 255 * @fadeOut
    lg.rectangle "fill", 0, 0, SCREEN\unpack!

  update: (prev, dt) =>
    true

  keypressed: (prev, key) =>
    return prev if prev
    switch key
      when "q"
        if not @fading
          @fading = Flux.to(@, 0.5, fadeOut: 1, fadeIn: 0)\oncomplete ->
            St8.resume!
      when "p", "escape"
        if not @fading
          @fading = Flux.to(@, 0.5, fadeIn: 0)\oncomplete ->
            St8.pop!
    true

Pause!
