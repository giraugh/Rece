##!REFERENCE https://codepen.io/techslides/pen/zowLd/

window.Camera =
  dragging: false
  old: [0, 0]
  origin: [0, 0]
  zoom: 1
  mouseWheel: (e)->
    [mx, my] = conf.mouse.inCanvasRaw()
    z = Math.pow(1.1, e.wheelDelta / 40)
    @translate mx, my
    @scale z
    @translate -mx, -my
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
      @translate difX, difY
      @old = conf.mouse.inCanvasRaw()
      @redraw()
  translate: (x, y)->
    ctx.translate x, y
    ctxs.translate x, y
    ctxg.translate x, y
    @origin[0] += x
    @origin[1] += y
  scale: (x)->
    ctx.scale x, x
    ctxs.scale x, x
    ctxg.scale x, x
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
