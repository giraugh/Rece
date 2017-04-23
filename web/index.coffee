#Require 'jquery' and 'jquery-ui'
window.$ = window.jQuery = require 'jquery'

#Require 'vex' prompts
window.vex = require 'vex-js'
vex.registerPlugin require 'vex-dialog'
vex.defaultOptions.className = 'vex-theme-plain'

#Get reference to app
window.remote = require('electron').remote
window.win = remote.getCurrentWindow()

#Load Conf Object
window.conf = require './scr/Conf.coffee'

#Maths
require './scr/Maths.coffee'


#Camera
require './scr/Camera.coffee'


#IO
require './scr/Io.coffee'


#Require 'Entity' Class
require './scr/Entity.coffee'


#Utility

window.tls = [[]]
window.vis = [true]

window.lnm = ["Main"]

window.changeLayer = (x)->
  conf.layer = x
  if tls[conf.layer] is undefined
    lnm[conf.layer] = "Layer #{conf.layer+1}"
    tls[conf.layer] = []
    vis[conf.layer] = true
  for i in [0...tls.length]
    if tls[i] is undefined
      tls[i] = []
      vis[i] = true

window.getLayerName = ->lnm[conf.layer]

window.updateAutos = (sx, sy, ex=sx, ey=sy)->
  [sx, sy, ex, ey] = [sx-4, sy-4, ex+4, ey+4]
  for layer in tls
    for tile in layer
      if tile.auto isnt undefined
        if sx <= tile.x <= ex and sy <= tile.y <= ey
          updateAuto layer, tile, conf.autos[tile.auto]
  draw()

window.updateAllAutos = ->
  for layer in tls
    for tile in layer
      if tile.auto isnt undefined
        updateAuto layer, tile, conf.autos[tile.auto]
  draw()

window.updateAuto = (layer, tile, system)->
  tile.aup = 0
  for rulename, rule of system
    if rulename isnt 'thumb'
      for srulename, srule of rule
        tx = tile.x
        ty = tile.y
        switch srulename
          when 'r' then doSysCheck(layer, tile, rulename, srule, [[ 1,  0]])
          when 'l' then doSysCheck(layer, tile, rulename, srule, [[-1,  0]])
          when 'b' then doSysCheck(layer, tile, rulename, srule, [[ 0,  1]])
          when 't' then doSysCheck(layer, tile, rulename, srule, [[ 0, -1]])

          when 'tr' then doSysCheck(layer, tile, rulename, srule, [[ 0, -1], [ 1,  0]])
          when 'tl' then doSysCheck(layer, tile, rulename, srule, [[ 0, -1], [-1,  0]])
          when 'bl' then doSysCheck(layer, tile, rulename, srule, [[ 0,  1], [-1,  0]])
          when 'br' then doSysCheck(layer, tile, rulename, srule, [[ 0,  1], [ 1,  0]])

          when 'tre' then doSysCheck(layer, tile, rulename, srule, [[ 0, -1], [ 1,  0], [ 1, -1, true]])
          when 'tle' then doSysCheck(layer, tile, rulename, srule, [[ 0, -1], [-1,  0], [-1, -1, true]])
          when 'ble' then doSysCheck(layer, tile, rulename, srule, [[ 0,  1], [-1,  0], [-1,  1, true]])
          when 'bre' then doSysCheck(layer, tile, rulename, srule, [[ 0,  1], [ 1,  0], [ 1,  1, true]])

          when 'all' then doSysCheck(layer, tile, rulename, srule, [
            [ 0,  1]
            [ 0, -1]
            [ 1,  0]
            [-1,  0]

            [ 1, -1]
            [-1, -1]
            [-1,  1]
            [ 1,  1]
          ])

window.doSysCheck = (layer, tile, rulename, rule, conditions)->
  if typeof rule is 'string'
    prec = 0
    rid = rule
  else
    [rid, prec] = rule

  if rulename.charAt(0) is '!'
    rulename = rulename.slice(1)
    negate = true

  if -1 isnt rulename.indexOf '?'
    rest = rulename.replace /[\s\S]*\?/, ""
    test = rulename.replace /\?[\s\S]*/, ""
    if tile.id isnt "tiles/#{test}"
      return
    rulename = rest

  if -1 isnt rulename.indexOf '|'
    rulenames = rulename.split '|'
  else
    rulenames = [rulename]

  for condition in conditions
    [x, y, n] = condition

    t = getTilesSystemAt(layer, tile.x+x, tile.y+y)
    a = false
    for rulen in rulenames
      b = t is rulen
      if negate
        b = t isnt rulename
      if a is false and b is true
        a = true
        break

    if not n
      unless a
        return
    else
      if a
        return
  if tile.aup <= prec
    tile.aup = prec
    tile.id = "tiles/#{rid}"

window.getTilesSystemAt = (layer, x, y)->
  t = getTileAt(layer, x, y)
  if t is undefined or t.auto is undefined
    return 'none'
  return t.auto

window.getTileAt = (layer, x, y)->
  for tile in layer
    if tile.x is x and tile.y is y
      return tile
  return undefined

window.noTileAt = (x, y)->
  for tile in tls[conf.layer]
    if tile.x is x and tile.y is y
      return false
  return true

window.shiftSelected = (x, y)->
  for tile in conf.selection.tiles
    if (conf.switcher is 'Tiles' and tile.type is 'Tile') or (conf.switcher is 'Instances' and tile.type is 'Instance')
      tile.x += x
      tile.y += y
  draw()

window.processClick = (e, isSingle)->
  [mx, my] = conf.mouse.asTile()
  [mxa, mya] = conf.mouse.inCanvas()

  if mxa > Camera.left() and mya > Camera.top()
    switch conf.tool

      when 'Place'
        if conf.switcher is 'Tiles'
          if conf.tile and noTileAt mx, my
            #Autotile System?
            if '%' is conf.tile.charAt 0
              e = new Entity 'Tile', conf.tile, mx, my
              e.auto = conf.tile.slice(1)
              tls[conf.layer].push e
              updateAutos(mx, my)
            else
              tls[conf.layer].push new Entity 'Tile', conf.tile, mx, my

        if conf.switcher is 'Instances' and (isSingle or e.ctrlKey)
          if conf.instance
            tls[conf.layer].push new Entity 'Instance', conf.instance, mxa, mya
        draw()

      when 'Remove'
        for i in [0...tls[conf.layer].length]
          t = tls[conf.layer][i]
          if conf.switcher is 'Tiles'
            if t.x is mx and t.y is my
              tls[conf.layer].splice i, 1
              if t.auto isnt undefined
                updateAutos(mx, my)
              break
          else
            if t.instanceOnMouse()
              tls[conf.layer].splice i, 1
              break
        draw()

      when 'Picker'
        for i in [0...tls[conf.layer].length]
          t = tls[conf.layer][i]
          if conf.switcher is 'Tiles'
            if t.x is mx and t.y is my
              conf.tile = t.id
              if t.auto
                conf.tile = "%#{t.auto}"
              $.each $('.tile'), (i, e)->
                $(e).removeClass 'active'
              $($('.tiles').children()[t.id]).addClass 'active'
              break
          else
            if t.instanceOnMouse()
              conf.instance = t.id
              $.each $('.instance'), (i, e)->
                $(e).removeClass 'active'
              $($('.instances').children()[t.id]).addClass 'active'
              break
      when 'Marquee'
        if not conf.selection.selecting
          conf.selection.selecting = true
          if conf.switcher is 'Tiles'
            conf.selection.start =
              x: mx
              y: my
            conf.selection.end =
              x: mx
              y: my
          if conf.switcher is 'Instances'
            conf.selection.start =
              x: mxa
              y: mya
            conf.selection.end =
              x: mxa
              y: mya
        else
          if conf.switcher is 'Tiles'
            conf.selection.end =
              x: mx
              y: my
          if conf.switcher is 'Instances'
            conf.selection.end =
              x: mxa
              y: mya
        draw()

window.didCommand = ->
  conf.history.push $.extend(true, [], window.tls)
  conf.rhistory = []
  if (conf.history.length+1) > conf.historymax
    conf.history.shift()

window.undoCommand = ->
  if conf.history.length > 1
    conf.rhistory.push $.extend(true, [], conf.history.pop())
    window.tls = $.extend(true, [], conf.history[conf.history.length-1])
    draw()

window.redoCommand = ->
  if conf.rhistory.length > 0
    window.tls = $.extend(true, [], conf.rhistory.pop())
    conf.history.push $.extend(true, [], window.tls)
    draw()

#Document Events
require './scr/Events.coffee'


#Drawing
require './scr/Drawing.coffee'
