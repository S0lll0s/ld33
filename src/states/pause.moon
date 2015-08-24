{graphics: lg} = love

class Pause
  enter: (...) =>
    @offset = .5 * Vec Sprite.pause\getDimensions!
    @fadeIn = 0
    @fading = false
    Flux.to @, 0.2, fadeIn: 1

  draw: (prev) =>
    lg.origin!
    lg.setColor 255, 255, 255, 100 * @fadeIn
    lg.rectangle "fill", 0, 0, SCREEN\unpack!
    lg.translate 0, SCREEN.y * (@fadeIn - 1), 0
    lg.setColor 255, 255, 255, 255 * @fadeIn
    lg.draw Sprite.pause, SCREEN.x/2, 200, 0, 2, 2, @offset\unpack!

  update: (prev, dt) =>
    true

  keypressed: (prev, key) =>
    return prev if prev
    switch key
      when "p", "escape"
        if not @fading
          @fading = Flux.to(@, 0.5, fadeIn: 0)\oncomplete ->
            St8.pop!
    true

Pause!
