fs = require 'fs-extra'
klaw = require 'klaw-sync'
path = require 'path'
{dialog} = require('electron').remote

loaded = ->path.join __dirname, '..\\_loaded'

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
  projectPath = dialog.showOpenDialog({properties: ['openDirectory']})
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
