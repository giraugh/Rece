#Require 'jquery' and 'jquery-ui'
window.$ = window.jQuery = require 'jquery'

#Require 'vex' prompts
vex = require 'vex-js'
vex.registerPlugin require 'vex-dialog'
vex.defaultOptions.className = 'vex-theme-plain'


#Get reference to app
remote = require('electron').remote
win = remote.getCurrentWindow()

window.conf =
  camera:
    origin:
      x: 0
      y: 0
    zoom: 1
  tileSize: 64
  imageSize: 32
  gridScaleUp: 2
  mouse:
    x: 0
    y: 0
    inCanvas: ->
      x = @x - $('#editor').position().left
      y = @y - $('#editor').position().top
      return [x, y]
    asTile: ->
      [x, y] = @inCanvas()
      x = Math.floor(x / conf.tileSize)
      y = Math.floor(y / conf.tileSize)
      return [x, y]
  tool: 'Place'
  oldtool: 'None'
  layer: 0
  switcher: 'Tiles'
  tile: -1
  instance: -1
  colours:
    grid: '#2f3f58'
    selection: '#1f293a'
  selection:
    selecting: false
    tiles: []
    start:
      x: 0
      y: 0
    getCoords: ->
      ss = @start
      se = @end
      x1 = ss.x
      y1 = ss.y
      x2 = (se.x)
      y2 = (se.y)

      if x2 < x1 then [x2, x1] = [x1, x2]
      if y2 < y1 then [y2, y1] = [y1, y2]
      return [x1, y1, x2+1, y2+1]
    getDrawCoords: ->
      [x1, y1, x2, y2] = @getCoords()
      [x1*conf.tileSize, y1*conf.tileSize, x2*conf.tileSize, y2*conf.tileSize]


class Entity
  constructor: (@type, @id, @x, @y) ->
  getDrawCoords: ->
    if @type is 'Tile'
      return [
        @x*conf.tileSize
        @y*conf.tileSize
        @x*conf.tileSize+conf.tileSize
        @y*conf.tileSize+conf.tileSize
      ]
    else
      return [
        @x - (conf.tileSize/2)
        @y - (conf.tileSize/2)
      ]
  instanceOnMouse: ->
    [mxa, mya] = conf.mouse.inCanvas()
    console.log [mxa, mya]
    console.log [@x
                 @y]
    return Math.abs(@x-mxa) < conf.tileSize/2 and
           Math.abs(@y-mya) < conf.tileSize/2


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

#Events

$(document).ready ->

  #Fix Tiles Height
  fixTilesAndInstances = ->
    p = $('.layers').height() + $('.tools').height() + $('#topbar').height()
    e = $(window).height() - (p + 28)
    $('.tiles')[0].style.height = e
    $('.instances')[0].style.height = e
  $(window).resize fixTilesAndInstances
  fixTilesAndInstances()

  #Navbar Items
  $('#Quit').on 'click', ->win.close()
  $('#LoadProject').on 'click', window.loadProject

  #Tool Selection
  $.each $('.tool'), (i, e)->
    $(e).on 'click', (me)->
      $.each $('.tool'), (i, e)->
        $(e).removeClass 'active'
      conf.tool = $(me.target).attr('id')
      $(me.target).addClass 'active'

  #Switcher Selection
  $.each $('.switcheritem'), (i, e)->
    $(e).on 'click', (me)->
      $.each $('.switcheritem'), (i, e)->
        $(e).removeClass 'active'
      conf.switcher = $(me.target).attr('id')
      $(me.target).addClass 'active'

      $('.tiles').removeClass 'active'
      $('.instances').removeClass 'active'
      $(".#{$(me.target).attr('id').toLowerCase()}").addClass 'active'


  window.updateTilesAndInstances = ->
    #Tile Selection
    $.each $('.tile'), (i, e)->
      $(e).on 'click', (me)->
        $.each $('.tile'), (i, e)->
          $(e).removeClass 'active'
        conf.tile =
          Array.prototype.indexOf.call me.target.parentElement.children,
                                       me.target
        $(me.target).addClass 'active'

    #Instance Selection
    $.each $('.instance'), (i, e)->
      $(e).on 'click', (me)->
        $.each $('.instance'), (i, e)->
          $(e).removeClass 'active'
        conf.instance =
          Array.prototype.indexOf.call me.target.parentElement.children,
                                       me.target
        $(me.target).addClass 'active'

    #Collate All Tile Image Src's
    window.tlis = []
    $.each $('.tile'), (i, e)->
      i = new Image
      i.src = e.src
      tlis.push i

    #Collate All Tile Entity Src's
    window.inis = []
    $.each $('.instance'), (i, e)->
      i = new Image
      i.src = e.src
      inis.push i
  updateTilesAndInstances()


  #Layer Selection
  $.each $('.layer'), (i, e)->
    $(e).on 'click', (me)->
      #Change Layer Name
      if $(me.target).hasClass 'active'
        n = me.target.childNodes[0]
        vex.dialog.prompt {
          message: "New Layer Name"
          placeholder: n.nodeValue
          callback: (value)->n.nodeValue = value or n.nodeValue
        }

      #Change Selected Layer
      unless $(me.target).hasClass('remove') or $(me.target).hasClass('add')
        $.each $('.layer'), (i, e)->
          $(e).removeClass 'active'
        changeLayer Array.prototype.indexOf.call(me.target.parentElement.children, me.target) - 1
        $(me.target).addClass 'active'

  #Layer Deletion
  $.each $('.layer'), (i, e)->
    $(e).on 'click', (me)->
      if $(me.target).hasClass 'remove'
        p = me.target.parentElement
        id = Array.prototype.indexOf.call(p.parentElement.children, p)
        p.parentElement.removeChild p
        tls.splice id-1, 1
        conf.layer -= 1
        $($('.layers').children()[id-1]).addClass 'active'
        draw()

  #Layer Addition
  $.each $('.layer'), (i, e)->
    $(e).on 'click', (me)->
      if $(me.target).hasClass 'add'
        n = $('#TemplateLayer').clone true
        r = $('#TemplateLayer').children(0).clone true

        n.removeClass 'template'
        n[0].innerHTML = "Layer #{$('.layers').children().length-2}"

        n.insertBefore me.target
        r.appendTo n


  #Create global reference to editor canvas and its context
  window.cnvs = $('#editor')[0]
  window.cnvsg = $('#grid')[0]
  window.cnvss = $('#selection')[0]
  window.ctx = cnvs.getContext('2d')
  window.ctxg = cnvsg.getContext('2d')
  window.ctxs = cnvss.getContext('2d')

  #Ensure that the canvas is ok with its size!
  resCanvas = ->
    cnvs.width = $(cnvs).width()
    cnvs.height = $(cnvs).height()
    cnvsg.width = $(cnvsg).width()
    cnvsg.height = $(cnvsg).height()
    cnvss.width = $(cnvss).width()
    cnvss.height = $(cnvss).height()

  #Do it when we resize
  $(window).resize ->
    resCanvas()
    drawGrid()
    drawTiles()

  #Do it now!
  resCanvas()
  drawGrid()
  drawTiles()

#Move Camera
$(document).on 'mousewheel', ({originalEvent})->
  e = originalEvent
  [mx, my] = conf.mouse.inCanvas()
  wheel = e.deltaY / 120
  console.log wheel

$(document).on 'keydown', (e)->
  if not e.ctrlKey
    switch e.key
      when 'Alt'
        if conf.oldtool is 'None'
          $.each $('.tool'), (i, e)->
            $(e).removeClass 'active'
          $('#Picker').addClass 'active'
          conf.oldtool = conf.tool
          conf.tool = 'Picker'
        e.preventDefault()
        return

      when 'ArrowLeft'
        shiftSelected(-1, 0)
      when 'ArrowRight'
        shiftSelected(1, 0)
      when 'ArrowUp'
        shiftSelected(0, -1)
      when 'ArrowDown'
        shiftSelected(0, 1)

      when 'd'
        conf.tool = 'Place'
        $.each $('.tool'), (i, e)->
          $(e).removeClass 'active'
        $('#Place').addClass 'active'
      when 'e'
        conf.tool = 'Remove'
        $.each $('.tool'), (i, e)->
          $(e).removeClass 'active'
        $('#Remove').addClass 'active'
      when 's'
        conf.tool = 'Marquee'
        $.each $('.tool'), (i, e)->
          $(e).removeClass 'active'
        $('#Marquee').addClass 'active'
      when 'Delete'
        for tile in conf.selection.tiles
          tls[conf.layer].splice tls[conf.layer].indexOf(tile), 1
        conf.selection.tiles = []
        e.preventDefault()
        draw()
  else
    switch e.key
      when 'a'
        conf.selection.tiles = []
        for tile in tls[conf.layer]
          conf.selection.tiles.push tile
        e.preventDefault()
        draw()
      when 'i'
        os = conf.selection.tiles
        conf.selection.tiles = []
        for tile in tls[conf.layer]
          if -1 is os.indexOf tile
            conf.selection.tiles.push tile
        e.preventDefault()
        draw()
      when 'd'
        conf.selection.tiles = []
        e.preventDefault()
        draw()

      when 'ArrowLeft'
        if conf.switcher is 'Instances' then shiftSelected(-6, 0)
      when 'ArrowRight'
        if conf.switcher is 'Instances' then shiftSelected(6, 0)
      when 'ArrowUp'
        if conf.switcher is 'Instances' then shiftSelected(0, -6)
      when 'ArrowDown'
        if conf.switcher is 'Instances' then shiftSelected(0, 6)

$(document).on 'keyup', (e)->
  if e.key is 'Alt'
    $.each $('.tool'), (i, e)->
      $(e).removeClass 'active'
    $("##{conf.oldtool}").addClass 'active'
    conf.tool = conf.oldtool
    conf.oldtool = 'None'
    e.preventDefault()

$(document).on 'mousemove', (e)->
  conf.mouse.x = e.clientX
  conf.mouse.y = e.clientY
  if e.buttons is 1 or e.buttons is 3
    processClick e, false

$(document).on 'mousedown', (e)->
  if e.target is $('#selection')[0] or
     e.target is $('#grid')[0] or
     e.target is $('#editor')[0]
    window.processClick e, true

$(document).on 'mouseup', (e)->
  #Finish Selecting
  if conf.selection.selecting
    conf.selection.selecting = false
    conf.selection.tiles = []
    [x1, y1, x2, y2] = conf.selection.getCoords()
    for t in tls[conf.layer]
        if t.x >= x1 and t.y >= y1 and t.x < x2 and t.y < y2
          conf.selection.tiles.push t
  draw()

window.processClick = (e, isSingle)->
  [mx, my] = conf.mouse.asTile()
  [mxa, mya] = conf.mouse.inCanvas()

  if mxa >= 0 and mya >= 0
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

#Drawing

window.draw = ->
  #Clear Grid
  ctx.clearRect 0, 0, cnvs.width, cnvs.height
  ctxs.clearRect 0, 0, cnvss.width, cnvss.height

  drawTiles()
  drawSelection()

window.drawGrid = ->
  #Draw a nice grid!
  ctxg.strokeStyle = conf.colours.grid
  for x in [0..cnvsg.width/conf.tileSize]
    for y in [0..cnvsg.height/conf.tileSize]
      ctxg.rect x*conf.tileSize,
               y*conf.tileSize,
               conf.tileSize,
               conf.tileSize
      ctxg.stroke()

window.drawSelection = ->
  ctxs.strokeStyle = conf.colours.selection

  if conf.selection.selecting
    if conf.switcher is 'Tiles'
      [x1, y1, x2, y2] = conf.selection.getDrawCoords()
    if conf.switcher is 'Instances'
      [x1, y1, x2, y2] = conf.selection.getCoords()
    ctxs.lineWidth = 5
    ctxs.beginPath()
    ctxs.rect x1, y1, x2-x1, y2-y1
    ctxs.stroke()
  else
    ctxs.lineWidth = 3
    for t in conf.selection.tiles
      [x1, y1, sx, sy] = t.getDrawCoords()
      ctxs.beginPath()
      ctxs.rect x1, y1, conf.tileSize, conf.tileSize
      ctxs.stroke()

window.drawTiles = ->
  #It also draws instances, dont be fooled!!!

  #Dont blur pixel art
  ctx.imageSmoothingEnabled = false

  #Draw Tiles
  for layer in window.tls
    for tile in layer
      [x, y] = tile.getDrawCoords()
      img = if tile.type is 'Tile' then tlis[tile.id] else inis[tile.id]
      ctx.drawImage img,
                    x, y
                    conf.imageSize*conf.gridScaleUp,
                    conf.imageSize*conf.gridScaleUp
