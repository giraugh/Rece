module.exports =
  tileSize: 32
  imageSize: 32
  gridScaleUp: 1
  levelWidth: 10
  levelHeight: 10
  history: [[[]]]
  historymax: 20
  rhistory: []
  mouse:
    down: [false, false, false, false]
    x: 0
    y: 0
    inCanvas: ->
      x = @x - $('#editor').position().left
      y = @y - $('#editor').position().top
      x -= Camera.origin[0]
      y -= Camera.origin[1]
      x /= Camera.zoom
      y /= Camera.zoom
      return [x, y]
    inCanvasRaw: ->
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
  grid: true
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
