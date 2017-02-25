##!REFERENCE https://codepen.io/techslides/pen/zowLd/

window.Camera =
  dragging: false
  old: [0, 0]
  origin: [0, 0]
  zoom: 1
  zoomMin: .1
  zoomMax: 6.5
  mouseWheel: (e)->
    [mx, my] = conf.mouse.inCanvas()
    z = if e.wheelDelta > 0 then .1 else -.1
    if @zoom+z > @zoomMin and @zoom+z < @zoomMax
      @camTranslate mx * @zoom, my * @zoom
      @camScale z
      @camTranslate -mx * @zoom, -my * @zoom
      @redraw()
  startDragging: ->
    @dragging = true
    @old = conf.mouse.inCanvasRaw()
  stopDragging: ->@dragging = false
  mouseMove: (e)->
    if @dragging
      [mx, my] = conf.mouse.inCanvasRaw()
      difX = mx-@old[0]
      difY = my-@old[1]
      @camTranslate difX, difY
      @old = conf.mouse.inCanvasRaw()
      @redraw()
  camTranslate: (x, y)->
    @origin[0] += x# / @zoom
    @origin[1] += y# / @zoom
  camScale: (x)->
    @zoom += x
  translate: (c)->
    c.translate @origin[0], @origin[1]
  scale: (c)->
    c.scale @zoom, @zoom
  suspend: (f)->
    [ctx, ctxs, ctxg].forEach (c)->
      c.save()
      c.resetTransform()
    f()
    [ctx, ctxs, ctxg].forEach (c)->
      c.restore()
  redraw: ->
    drawGrid()
    draw()
