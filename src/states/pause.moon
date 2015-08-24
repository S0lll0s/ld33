{graphics: lg} = love

class Pause
  enter: (...) =>
    ""

  draw: (prev) =>
    lg.origin!
    lg.setColor 255, 255, 255, 100
    lg.rectangle "fill", 0, 0, SCREEN\unpack!
    lg.setColor 0, 0, 0, 255
    lg.print "PAUSED!", 200, 200

  update: (prev, dt) =>
    true

  keypressed: (prev, key) =>
    return prev if prev
    switch key
      when "p", "escape" then St8.pop!
    true

Pause!
