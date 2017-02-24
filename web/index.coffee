#Require 'jquery' and 'jquery-ui'
window.$ = window.jQuery = require 'jquery'

#Require 'vex' prompts
vex = require 'vex-js'
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

window.lnm = ["Main"]

window.changeLayer = (x)->
  conf.layer = x
  if tls[conf.layer] is undefined
    lnm[conf.layer] = "Layer #{conf.layer+1}"
    tls[conf.layer] = []

window.getLayerName = ->lnm[conf.layer]

window.noTileAt = (x, y)->
  for tile in tls[conf.layer]
    if tile.x is x and tile.y is y
      return false
  return true

window.shiftSelected = (x, y)->
  for tile in conf.selection.tiles
    tile.x += x
    tile.y += y
  draw()

window.processClick = (e, isSingle)->
  [mx, my] = conf.mouse.asTile()
  [mxa, mya] = conf.mouse.inCanvas()

  switch conf.tool

    when 'Place'
      if conf.switcher is 'Tiles'
        if conf.tile >= 0 and noTileAt mx, my
          tls[conf.layer].push new Entity 'Tile', conf.tile, mx, my
      if conf.switcher is 'Instances' and (isSingle or e.ctrlKey)
        if conf.instance >= 0
          tls[conf.layer].push new Entity 'Instance', conf.instance, mxa, mya
      draw()

    when 'Remove'
      for i in [0...tls[conf.layer].length]
        t = tls[conf.layer][i]
        if conf.switcher is 'Tiles'
          if t.x is mx and t.y is my
            tls[conf.layer].splice i, 1
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


#Document Events
require './scr/Events.coffee'


#Drawing
require './scr/Drawing.coffee'
