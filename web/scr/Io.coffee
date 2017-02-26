fs = require 'fs-extra'
klaw = require 'klaw-sync'
path = require 'path'
cson = require 'cson'
{dialog} = require('electron').remote

loaded = ->path.join __dirname, '..\\..\\_loaded'

window.saveLevel = ->
  o =
    imp: tls
    layers: []

  #Save Layer Names (other than MAIN, TEMPLATE and ADD)
  layers = $('.layer').filter (i, l)-> i > 0 and i isnt $('.layer').length-1
  layers.map (i, l)->o.layers.push l.childNodes[0].nodeValue

  #Save Level Data
  exp = JSON.stringify o, null, 3

  #Dialog
  savePath = dialog.showSaveDialog {title: "Save Level", defaultPath: "level.lvl"}
  if not savePath then return

  #Write File
  fs.writeFileSync savePath, exp

window.openLevel = ->
  #Open User Prompted Level
  levelPath = dialog.showOpenDialog {properties: ['openFile']}
  if not levelPath then return else levelPath = levelPath[0]

  #Read JSON
  dat = fs.readFileSync levelPath, 'utf-8'
  if not dat then return

  #Parse JSON
  {imp, layers} = JSON.parse dat

  #Make objects into correct class
  for i in [0...imp.length]
    for j in [0...imp[i].length]
      t = imp[i][j]
      imp[i][j] = new Entity t.type, t.id, t.x, t.y

  #Set tls
  window.tls = imp

  #Remove all CLONE layers
  $('.layer.clone').map (i, l)->
    l.parentElement.removeChild l

  #Select MAIN
  conf.layer = 0
  $.each $('.layer'), (i, e)->
    $(e).removeClass 'active'
  $('#MainLayer').addClass 'active'

  #Add layers
  mainl = layers[0]
  $('#MainLayer')[0].childNodes[0].nodeValue = mainl
  for layer in layers
    if layer isnt mainl
      n = $('#TemplateLayer').clone true
      r = $('#TemplateLayer').children(0).clone true

      n.removeClass 'template'
      n.addClass 'clone'
      n.prop('id', '')
      n[0].innerHTML = layer

      n.insertBefore $('.layer.add')
      r.appendTo n

  #Redraw
  Camera.redraw()

window.updateProject = ->
  tiles = klaw path.join(loaded(), 'tiles'), {
    nodir: true
    ignore: [
      '!(*.png)'
      '!(*.jpg)'
      '!(*.cfg)'
      '!(*.tiff)'
    ]
  }

  instances = klaw path.join(loaded(), 'instances'), {
    nodir: true
    ignore: [
      '!(*.png)'
      '!(*.jpg)'
      '!(*.cfg)'
      '!(*.tiff)'
    ]
  }

  getTileValue = (t)-> return eval t.path.match(/tile([0-9]+)/)[1] or 0

  tiles.sort (a, b)->
    if getTileValue(a) is getTileValue(b)
      return 0

    if getTileValue(a) < getTileValue(b)
      return -1

    if getTileValue(a) > getTileValue(b)
      return 1



  #Remove pre-existing tiles
  if $('.tile').length > 0 then $.each $('.tile'), (i, e)->$(e).remove()
  if $('.instances').length > 0 then $.each $('.instance'), (i, e)->$(e).remove()

  #Create tiles and append them
  tiles.forEach (t, i)->
    d = $ '<img/>', {
      class: "tile-img #{if i is 0 then 'active' else ''}"
      src: t.path
    }

    e = $ '<div/>', {
      class: "tile"
    }

    #Add img to div
    d.appendTo e

    #add to DOM
    e.appendTo $ '.tiles'

    #Set Selected Tile
    if i is 0
      conf.tile = 0

  #Create instances and append them
  instances.forEach (t, i)->
    d = $ '<img/>', {
      class: "instance-img #{if i is 0 then 'active' else ''}"
      src: t.path
    }

    e = $ '<div/>', {
      class: "instance"
    }

    #Add img to div
    d.appendTo e

    #add to DOM
    e.appendTo $ '.instances'

    #Set Selected Tile
    if i is 0
      conf.instance = 0

  #Reset tiles
  window.tls = [[]]

  #Read Config
  if fs.existsSync path.join loaded(), 'project.cson'
    lconf = cson.load path.join loaded(), 'project.cson'
    conf.tileSize = lconf.tileSize or conf.tileSize
    conf.gridScaleUp = lconf.gridScaleUp or conf.gridScaleUp
    conf.imageSize = lconf.imageSize or conf.imageSize
    conf.levelWidth = lconf.levelWidth or conf.levelWidth
    conf.levelHeight = lconf.levelHeight or conf.levelHeight

  #Draw
  draw()
  drawGrid()

  updateTilesAndInstances()


window.loadProject = ->
  projectPath = dialog.showOpenDialog {properties: ['openDirectory']}
  if not projectPath then return else projectPath = projectPath[0]
  tilesPath = path.join(projectPath, 'tiles')
  instancesPath = path.join(projectPath, 'instances')
  configPath = path.join(projectPath, 'project.cson')

  #Delete _loaded
  fs.removeSync path.join loaded()

  #Copy Sprites and Instances to _loaded
  if fs.existsSync tilesPath
    fs.copySync tilesPath, path.join loaded(), 'tiles'
  if fs.existsSync instancesPath
    fs.copySync instancesPath, path.join loaded(), 'instances'

  #Copy Config
  if fs.existsSync configPath
    fs.copySync configPath, path.join loaded(), 'project.cson'

  #Update the project
  updateProject()
