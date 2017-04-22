fs = require 'fs-extra'
klaw = require 'klaw-sync'
path = require 'path'
cson = require 'cson'
{dialog} = require('electron').remote

loaded = ->path.join __dirname, '..\\..\\_loaded'

window.saveLevel = (spath)->
  o =
    imp: $.extend(true, [], tls)
    layers: []
    lconf: {
      bgColour: conf.lvlCol
    }

  o.imp.forEach (layer)->layer.forEach (entity)->
    if entity.type is 'Instance'
      entity.x /= conf.gridScaleUp
      entity.y /= conf.gridScaleUp

  #Save Layer Names (other than MAIN, TEMPLATE and ADD)
  layers = $('.layer').filter (i, l)-> i > 0 and i isnt $('.layer').length-1
  layers.map (i, l)->o.layers.push l.childNodes[0].nodeValue

  #Save Level Data
  exp = JSON.stringify o, null, 3

  #Dialog
  if spath
    savePath = spath
    console.log 'Set through arg'
  else
    savePath = dialog.showSaveDialog {title: "Save Level", defaultPath: "level.lvl"}
    if not savePath
      ##UnDivide Instance Locations
      tls.forEach (layer)->layer.forEach (entity)->
        if entity.type is 'Instance'
          entity.x *= conf.gridScaleUp
          entity.y *= conf.gridScaleUp
      return

  ##UnDivide Instance Locations
  tls.forEach (layer)->layer.forEach (entity)->
    if entity.type is 'Instance'
      entity.x *= conf.gridScaleUp
      entity.y *= conf.gridScaleUp

  #Write File
  fs.writeFileSync savePath, exp

  #Store Path
  conf.lastIO = savePath

window.openLevel = ->
  #Open User Prompted Level
  levelPath = dialog.showOpenDialog {properties: ['openFile']}
  if not levelPath then return else levelPath = levelPath[0]

  #Read JSON
  dat = fs.readFileSync levelPath, 'utf-8'
  if not dat then return

  #Parse JSON
  {imp, layers, lconf} = JSON.parse dat

  #Level Configuration
  if lconf?.bgColour
    [r, g, b] = lconf.bgColour
    $("#editor").css('background-color', "rgb(#{r}, #{g}, #{b})")
    conf.lvlCol = lconf.bgColour
  else
    conf.lvlCol = undefined
    if conf.projCol
      $("#editor").css('background-color', conf.projCol)
    else
      $("#editor").css('background-color', "#445c82")

  #Make objects into correct class
  for i in [0...imp.length]
    for j in [0...imp[i].length]
      t = imp[i][j]
      if t.type is 'Instance'
        t.x *= conf.gridScaleUp
        t.y *= conf.gridScaleUp
      imp[i][j] = new Entity t.type, t.id, t.x, t.y, t.data

  #Set tls
  window.tls = imp

  #Delete history
  conf.history = [$.extend(true, [], window.tls)]
  conf.rhistory = []

  #Remove all CLONE layers
  $('.layer.clone').map (i, l)->
    l.parentElement.removeChild l

  #Select MAIN
  conf.layer = 0
  $.each $('.layer'), (i, e)->
    $(e).removeClass 'active'
  $('#MainLayer').addClass 'active'

  #Show all layers
  $.each $('.layer'), (i, e)->
    $(e).removeClass 'hidden'
  window.vis[i] = true for i in [0...layers.length]

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

  #Store location of file
  conf.lastIO = levelPath

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
  if $('.folder').length > 0 then $.each $('.folder'), (i, e)->$(e).remove()
  if $('.tile').length > 0 then $.each $('.tile'), (i, e)->$(e).remove()
  if $('.instances').length > 0 then $.each $('.instance'), (i, e)->$(e).remove()

  #Create tiles and append them
  folders = []
  folderEls = {}
  tiles.forEach (t, i)->
    #Set Selected Tile
    if i is 0
      conf.tile = 0

    #Create Image
    d = $ '<img/>', {
      class: "tile-img #{if i is 0 then 'active' else ''}"
      src: t.path
    }

    #Create Tile Div
    e = $ '<div/>', {
      class: "tile"
    }

    #Add img to div
    d.appendTo e

    if conf.folderize
      #Create Folder?
      lpath = t.path.replace(/[\s\S]*[\/\\]_loaded[\/\\]tiles[\/\\]([\s\S]*)/, "$1")
      fpath = lpath.replace(/^([^\/\\]*)[\s\S]*$/, "$1")

      if /[\/\\]/.test lpath

        #Create Folder?
        if -1 is folders.indexOf fpath
          folders.push fpath

          #Create Folder
          ppath = fpath.charAt(0).toUpperCase() + fpath.slice(1)
          fo = $ '<div/>', {
            class: "folder closed",
            title: ppath
          }
          fo.appendTo '.tiles'
          folderEls[fpath] = fo

        #Add to folder
        e.appendTo folderEls[fpath]
      else
        #add to DOM
        e.prependTo $ '.tiles'

    else
      #add to DOM
      e.appendTo $ '.tiles'

  #Create instances and append them
  folders = []
  folderEls = {}
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

    if conf.folderize
      #Create Folder?
      lpath = t.path.replace(/[\s\S]*[\/\\]_loaded[\/\\]instances[\/\\]([\s\S]*)/, "$1")
      fpath = lpath.replace(/^([^\/\\]*)[\s\S]*$/, "$1")

      if /[\/\\]/.test lpath

        #Create Folder?
        if -1 is folders.indexOf fpath
          folders.push fpath

          #Create Folder
          ppath = fpath.charAt(0).toUpperCase() + fpath.slice(1)
          fo = $ '<div/>', {
            class: "folder closed",
            title: ppath
          }
          fo.appendTo '.instances'
          folderEls[fpath] = fo

        #Add to folder
        e.appendTo folderEls[fpath]

      else
        #add to DOM
        e.prependTo $ '.instances'

    else
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
    if lconf.bgColour
      $("#editor").css('background-color', lconf.bgColour)
      conf.projCol = lconf.bgColour
    else
      $("#editor").css('background-color', "#445c82")

  #Draw
  draw()
  drawGrid()

  updateTilesAndInstances()
  updateFolders()

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
