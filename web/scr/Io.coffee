fs = require 'fs-extra'
klaw = require 'klaw-sync'
path = require 'path'
{dialog} = require('electron').remote

loaded = ->path.join __dirname, '..\\_loaded'

window.saveLevel = ->
  o =
    imp: tls
    layers: []

  #Save Layer Names (other than MAIN, TEMPLATE and ADD)
  layers = $('.layer').filter (i, l)-> i > 1 and i isnt $('.layer').length-1
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
  for layer in layers
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

  #Remove pre-existing tiles
  if $('.tile').length > 0 then $.each $('.tile'), (i, e)->$(e).remove()
  if $('.instances').length > 0 then $.each $('.instance'), (i, e)->$(e).remove()

  #Create tiles and append them
  tiles.forEach (t, i)->
    d = $ '<img/>', {
      class: "tile #{if i is 0 then 'active' else ''}"
      src: t.path
    }

    #add to DOM
    d.appendTo $ '.tiles'

    #Set Selected Tile
    if i is 0
      conf.tile = 0

  #Create instances and append them
  instances.forEach (t, i)->
    d = $ '<img/>', {
      class: "instance #{if i is 0 then 'active' else ''}"
      src: t.path
    }

    #add to DOM
    d.appendTo $ '.instances'

    #Set Selected Tile
    if i is 0
      conf.instance = 0

  #Reset tiles
  window.tls = [[]]
  draw()

  updateTilesAndInstances()


window.loadProject = ->
  projectPath = dialog.showOpenDialog {properties: ['openDirectory']}
  if not projectPath then return else projectPath = projectPath[0]
  tilesPath = path.join(projectPath, 'tiles')
  instancesPath = path.join(projectPath, 'instances')

  #Delete _loaded
  fs.removeSync path.join loaded()

  #Copy Sprites and Instances to _loaded
  if fs.existsSync tilesPath
    fs.copySync tilesPath, path.join loaded(), 'tiles'
  if fs.existsSync instancesPath
    fs.copySync instancesPath, path.join loaded(), 'instances'

  #Update the project
  updateProject()
