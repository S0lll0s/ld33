{graphics: lg} = love

class GameOver
  enter: (frm, @score) =>

  draw: (prev) =>
    lg.setColor 255, 255, 255
    lg.print "your human side prides itself with a score of #{@score.good}", 20, 100
    lg.print "your inner monster has achieved a score of #{@score.bad}", 20, 140

    if @score.good > @score.bad
      lg.print "you emerge victorious over your inner demons!", 30, 200
    else
      lg.print "evil has gotten the better of you...", 30, 200

  update: (prev, dt) =>
    true

  keypressed: (prev, key) =>
    St8.pause require "states.menu" -- @FIXME !!!
    true

GameOver!
