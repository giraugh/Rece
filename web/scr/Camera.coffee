##!REFERENCE https://github.com/pbakaus/scroller

{Scroller} = require '../ext/Zynga.js'
window.Scroller = Scroller# undefined, {animation: false}

###
(window.Scroller.FixSize = ->
  Scroller.setDimensions cnvs.width, cnvs.height, Math.infinity, Math.infinity
)()
###
