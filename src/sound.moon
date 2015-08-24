Sound = {}
{
  Sound: setmetatable {}, __index: (name) =>
    if not Sound[name]
      i = 1
      vol, typ = 1, "static"
      {:name, :vol, :typ} = name if type(name) == "table"


      Sound[name] = {}
      load = ->
        table.insert Sound[name], love.audio.newSource "assets/audio/#{name}-#{i}.wav", typ

      while pcall load
        i += 1
    snd = math.choice Sound[name]
    return -> if not snd
    -> snd\play!
}
