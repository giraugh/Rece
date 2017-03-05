window.draw = ->
  #Clear Grid
  clearCanvas ctx, cnvs
  clearCanvas ctxs, cnvss

  drawTiles()
  drawSelection()

window.drawGrid = ->
  clearCanvas ctxg, cnvsg

  canvasDraw ctxg, ->

    #Draw a nice grid!
    ctxg.strokeStyle = conf.colours.grid
    if conf.grid
      for x in [0...conf.levelWidth]
        for y in [0...conf.levelHeight]
          ctxg.beginPath()
          ctxg.rect x*conf.tileSize,
                   y*conf.tileSize,
                   conf.tileSize,
                   conf.tileSize
          ctxg.stroke()
    else
      ctxg.beginPath()
      ctxg.rect 0, 0, conf.levelWidth*conf.tileSize, conf.levelHeight*conf.tileSize
      ctxg.stroke()


window.drawSelection = ->
  canvasDraw ctxs, ->
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
        if t.type is 'Tile'
          ctxs.rect x1, y1, conf.tileSize, conf.tileSize
        if t.type is 'Instance'
          ctxs.arc x1+(conf.tileSize/2),
                   y1+(conf.tileSize/2),
                   conf.tileSize*.6, 0, 2 * Math.PI
        ctxs.stroke()

window.drawTiles = ->
  canvasDraw ctx, ->
    #It also draws instances, dont be fooled!!!

    #Dont blur pixel art
    ctx.imageSmoothingEnabled = false

    #Draw Tiles
    for i in [0...tls.length]
      if vis[i]
        layer = tls[i]
        for tile in layer
          [x, y] = tile.getDrawCoords()
          img = if tile.type is 'Tile' then tlis[tile.id] else inis[tile.id]
          ctx.drawImage img,
                        x, y
                        img.width*conf.gridScaleUp,
                        img.height*conf.gridScaleUp

window.clearCanvas = (c, n)->
  c.save()
  c.resetTransform()
  c.clearRect 0, 0,
              n.width,
              n.height
  c.restore()

window.canvasDraw = (ctx, paint)->
  ctx.save()
  Camera.translate(ctx)
  Camera.scale(ctx)
  paint()
  ctx.restore()
