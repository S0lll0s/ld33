Sound = {}
{
  Sound: setmetatable {}, __index: (name) =>
    local fullname
    typ = "static"
    if type(name) == "table"
      {:name, :typ, :fullname} = name
      name or= fullname

    if not Sound[name]
      i = 1

      Sound[name] = {}
      load = ->
        table.insert Sound[name], love.audio.newSource "assets/audio/" .. (fullname or "#{name}-#{i}.wav"), typ

      while pcall load
        i += 1
        break if fullname

    snd = math.choice Sound[name]
    return -> if not snd
    ->
      snd\play!
      snd
}
