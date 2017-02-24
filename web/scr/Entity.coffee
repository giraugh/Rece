class window.Entity
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
