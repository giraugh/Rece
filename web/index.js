var Entity, remote, vex, win;

window.$ = window.jQuery = require('jquery');

vex = require('vex-js');

vex.registerPlugin(require('vex-dialog'));

vex.defaultOptions.className = 'vex-theme-plain';

remote = require('electron').remote;

win = remote.getCurrentWindow();

window.conf = {
  camera: {
    origin: {
      x: 0,
      y: 0
    },
    zoom: 1
  },
  tileSize: 64,
  imageSize: 32,
  gridScaleUp: 2,
  mouse: {
    x: 0,
    y: 0,
    inCanvas: function() {
      var x, y;
      x = this.x - $('#editor').position().left;
      y = this.y - $('#editor').position().top;
      return [x, y];
    },
    asTile: function() {
      var ref, x, y;
      ref = this.inCanvas(), x = ref[0], y = ref[1];
      x = Math.floor(x / conf.tileSize);
      y = Math.floor(y / conf.tileSize);
      return [x, y];
    }
  },
  tool: 'Place',
  oldtool: 'None',
  layer: 0,
  switcher: 'Tiles',
  tile: -1,
  instance: -1,
  colours: {
    grid: '#2f3f58',
    selection: '#1f293a'
  },
  selection: {
    selecting: false,
    tiles: [],
    start: {
      x: 0,
      y: 0
    },
    getCoords: function() {
      var ref, ref1, se, ss, x1, x2, y1, y2;
      ss = this.start;
      se = this.end;
      x1 = ss.x;
      y1 = ss.y;
      x2 = se.x;
      y2 = se.y;
      if (x2 < x1) {
        ref = [x1, x2], x2 = ref[0], x1 = ref[1];
      }
      if (y2 < y1) {
        ref1 = [y1, y2], y2 = ref1[0], y1 = ref1[1];
      }
      return [x1, y1, x2 + 1, y2 + 1];
    },
    getDrawCoords: function() {
      var ref, x1, x2, y1, y2;
      ref = this.getCoords(), x1 = ref[0], y1 = ref[1], x2 = ref[2], y2 = ref[3];
      return [x1 * conf.tileSize, y1 * conf.tileSize, x2 * conf.tileSize, y2 * conf.tileSize];
    }
  }
};

Entity = (function() {
  function Entity(type, id1, x3, y3) {
    this.type = type;
    this.id = id1;
    this.x = x3;
    this.y = y3;
  }

  Entity.prototype.getDrawCoords = function() {
    if (this.type === 'Tile') {
      return [this.x * conf.tileSize, this.y * conf.tileSize, this.x * conf.tileSize + conf.tileSize, this.y * conf.tileSize + conf.tileSize];
    } else {
      return [this.x - (conf.tileSize / 2), this.y - (conf.tileSize / 2)];
    }
  };

  Entity.prototype.instanceOnMouse = function() {
    var mxa, mya, ref;
    ref = conf.mouse.inCanvas(), mxa = ref[0], mya = ref[1];
    console.log([mxa, mya]);
    console.log([this.x, this.y]);
    return Math.abs(this.x - mxa) < conf.tileSize / 2 && Math.abs(this.y - mya) < conf.tileSize / 2;
  };

  return Entity;

})();

window.tls = [[]];

window.lnm = ["Main"];

window.changeLayer = function(x) {
  conf.layer = x;
  if (tls[conf.layer] === void 0) {
    lnm[conf.layer] = "Layer " + (conf.layer + 1);
    return tls[conf.layer] = [];
  }
};

window.getLayerName = function() {
  return lnm[conf.layer];
};

window.noTileAt = function(x, y) {
  var j, len, ref, tile;
  ref = tls[conf.layer];
  for (j = 0, len = ref.length; j < len; j++) {
    tile = ref[j];
    if (tile.x === x && tile.y === y) {
      return false;
    }
  }
  return true;
};

window.shiftSelected = function(x, y) {
  var j, len, ref, tile;
  ref = conf.selection.tiles;
  for (j = 0, len = ref.length; j < len; j++) {
    tile = ref[j];
    tile.x += x;
    tile.y += y;
  }
  return draw();
};

$(document).ready(function() {
  var fixTilesAndInstances, resCanvas;
  fixTilesAndInstances = function() {
    var e, p;
    p = $('.layers').height() + $('.tools').height() + $('#topbar').height();
    e = $(window).height() - (p + 28);
    $('.tiles')[0].style.height = e;
    return $('.instances')[0].style.height = e;
  };
  $(window).resize(fixTilesAndInstances);
  fixTilesAndInstances();
  $('#Quit').on('click', function() {
    return win.close();
  });
  $('#LoadProject').on('click', window.loadProject);
  $.each($('.tool'), function(i, e) {
    return $(e).on('click', function(me) {
      $.each($('.tool'), function(i, e) {
        return $(e).removeClass('active');
      });
      conf.tool = $(me.target).attr('id');
      return $(me.target).addClass('active');
    });
  });
  $.each($('.switcheritem'), function(i, e) {
    return $(e).on('click', function(me) {
      $.each($('.switcheritem'), function(i, e) {
        return $(e).removeClass('active');
      });
      conf.switcher = $(me.target).attr('id');
      $(me.target).addClass('active');
      $('.tiles').removeClass('active');
      $('.instances').removeClass('active');
      return $("." + ($(me.target).attr('id').toLowerCase())).addClass('active');
    });
  });
  window.updateTilesAndInstances = function() {
    $.each($('.tile'), function(i, e) {
      return $(e).on('click', function(me) {
        $.each($('.tile'), function(i, e) {
          return $(e).removeClass('active');
        });
        conf.tile = Array.prototype.indexOf.call(me.target.parentElement.children, me.target);
        return $(me.target).addClass('active');
      });
    });
    $.each($('.instance'), function(i, e) {
      return $(e).on('click', function(me) {
        $.each($('.instance'), function(i, e) {
          return $(e).removeClass('active');
        });
        conf.instance = Array.prototype.indexOf.call(me.target.parentElement.children, me.target);
        return $(me.target).addClass('active');
      });
    });
    window.tlis = [];
    $.each($('.tile'), function(i, e) {
      i = new Image;
      i.src = e.src;
      return tlis.push(i);
    });
    window.inis = [];
    return $.each($('.instance'), function(i, e) {
      i = new Image;
      i.src = e.src;
      return inis.push(i);
    });
  };
  updateTilesAndInstances();
  $.each($('.layer'), function(i, e) {
    return $(e).on('click', function(me) {
      var n;
      if ($(me.target).hasClass('active')) {
        n = me.target.childNodes[0];
        vex.dialog.prompt({
          message: "New Layer Name",
          placeholder: n.nodeValue,
          callback: function(value) {
            return n.nodeValue = value || n.nodeValue;
          }
        });
      }
      if (!($(me.target).hasClass('remove') || $(me.target).hasClass('add'))) {
        $.each($('.layer'), function(i, e) {
          return $(e).removeClass('active');
        });
        changeLayer(Array.prototype.indexOf.call(me.target.parentElement.children, me.target) - 1);
        return $(me.target).addClass('active');
      }
    });
  });
  $.each($('.layer'), function(i, e) {
    return $(e).on('click', function(me) {
      var id, p;
      if ($(me.target).hasClass('remove')) {
        p = me.target.parentElement;
        id = Array.prototype.indexOf.call(p.parentElement.children, p);
        p.parentElement.removeChild(p);
        tls.splice(id - 1, 1);
        conf.layer -= 1;
        $($('.layers').children()[id - 1]).addClass('active');
        return draw();
      }
    });
  });
  $.each($('.layer'), function(i, e) {
    return $(e).on('click', function(me) {
      var n, r;
      if ($(me.target).hasClass('add')) {
        n = $('#TemplateLayer').clone(true);
        r = $('#TemplateLayer').children(0).clone(true);
        n.removeClass('template');
        n[0].innerHTML = "Layer " + ($('.layers').children().length - 2);
        n.insertBefore(me.target);
        return r.appendTo(n);
      }
    });
  });
  window.cnvs = $('#editor')[0];
  window.cnvsg = $('#grid')[0];
  window.cnvss = $('#selection')[0];
  window.ctx = cnvs.getContext('2d');
  window.ctxg = cnvsg.getContext('2d');
  window.ctxs = cnvss.getContext('2d');
  resCanvas = function() {
    cnvs.width = $(cnvs).width();
    cnvs.height = $(cnvs).height();
    cnvsg.width = $(cnvsg).width();
    cnvsg.height = $(cnvsg).height();
    cnvss.width = $(cnvss).width();
    return cnvss.height = $(cnvss).height();
  };
  $(window).resize(function() {
    resCanvas();
    drawGrid();
    return drawTiles();
  });
  resCanvas();
  drawGrid();
  return drawTiles();
});

$(document).on('mousewheel', function(arg) {
  var e, mx, my, originalEvent, ref, wheel;
  originalEvent = arg.originalEvent;
  e = originalEvent;
  ref = conf.mouse.inCanvas(), mx = ref[0], my = ref[1];
  wheel = e.deltaY / 120;
  return console.log(wheel);
});

$(document).on('keydown', function(e) {
  var j, k, l, len, len1, len2, os, ref, ref1, ref2, tile;
  if (!e.ctrlKey) {
    switch (e.key) {
      case 'Alt':
        if (conf.oldtool === 'None') {
          $.each($('.tool'), function(i, e) {
            return $(e).removeClass('active');
          });
          $('#Picker').addClass('active');
          conf.oldtool = conf.tool;
          conf.tool = 'Picker';
        }
        e.preventDefault();
        break;
      case 'ArrowLeft':
        return shiftSelected(-1, 0);
      case 'ArrowRight':
        return shiftSelected(1, 0);
      case 'ArrowUp':
        return shiftSelected(0, -1);
      case 'ArrowDown':
        return shiftSelected(0, 1);
      case 'd':
        conf.tool = 'Place';
        $.each($('.tool'), function(i, e) {
          return $(e).removeClass('active');
        });
        return $('#Place').addClass('active');
      case 'e':
        conf.tool = 'Remove';
        $.each($('.tool'), function(i, e) {
          return $(e).removeClass('active');
        });
        return $('#Remove').addClass('active');
      case 's':
        conf.tool = 'Marquee';
        $.each($('.tool'), function(i, e) {
          return $(e).removeClass('active');
        });
        return $('#Marquee').addClass('active');
      case 'Delete':
        ref = conf.selection.tiles;
        for (j = 0, len = ref.length; j < len; j++) {
          tile = ref[j];
          tls[conf.layer].splice(tls[conf.layer].indexOf(tile), 1);
        }
        conf.selection.tiles = [];
        e.preventDefault();
        return draw();
    }
  } else {
    switch (e.key) {
      case 'a':
        conf.selection.tiles = [];
        ref1 = tls[conf.layer];
        for (k = 0, len1 = ref1.length; k < len1; k++) {
          tile = ref1[k];
          conf.selection.tiles.push(tile);
        }
        e.preventDefault();
        return draw();
      case 'i':
        os = conf.selection.tiles;
        conf.selection.tiles = [];
        ref2 = tls[conf.layer];
        for (l = 0, len2 = ref2.length; l < len2; l++) {
          tile = ref2[l];
          if (-1 === os.indexOf(tile)) {
            conf.selection.tiles.push(tile);
          }
        }
        e.preventDefault();
        return draw();
      case 'd':
        conf.selection.tiles = [];
        e.preventDefault();
        return draw();
      case 'ArrowLeft':
        if (conf.switcher === 'Instances') {
          return shiftSelected(-6, 0);
        }
        break;
      case 'ArrowRight':
        if (conf.switcher === 'Instances') {
          return shiftSelected(6, 0);
        }
        break;
      case 'ArrowUp':
        if (conf.switcher === 'Instances') {
          return shiftSelected(0, -6);
        }
        break;
      case 'ArrowDown':
        if (conf.switcher === 'Instances') {
          return shiftSelected(0, 6);
        }
    }
  }
});

$(document).on('keyup', function(e) {
  if (e.key === 'Alt') {
    $.each($('.tool'), function(i, e) {
      return $(e).removeClass('active');
    });
    $("#" + conf.oldtool).addClass('active');
    conf.tool = conf.oldtool;
    conf.oldtool = 'None';
    return e.preventDefault();
  }
});

$(document).on('mousemove', function(e) {
  conf.mouse.x = e.clientX;
  conf.mouse.y = e.clientY;
  if (e.buttons === 1 || e.buttons === 3) {
    return processClick(e, false);
  }
});

$(document).on('mousedown', function(e) {
  if (e.target === $('#selection')[0] || e.target === $('#grid')[0] || e.target === $('#editor')[0]) {
    return window.processClick(e, true);
  }
});

$(document).on('mouseup', function(e) {
  var j, len, ref, ref1, t, x1, x2, y1, y2;
  if (conf.selection.selecting) {
    conf.selection.selecting = false;
    conf.selection.tiles = [];
    ref = conf.selection.getCoords(), x1 = ref[0], y1 = ref[1], x2 = ref[2], y2 = ref[3];
    ref1 = tls[conf.layer];
    for (j = 0, len = ref1.length; j < len; j++) {
      t = ref1[j];
      if (t.x >= x1 && t.y >= y1 && t.x < x2 && t.y < y2) {
        conf.selection.tiles.push(t);
      }
    }
  }
  return draw();
});

window.processClick = function(e, isSingle) {
  var i, j, k, mx, mxa, my, mya, ref, ref1, ref2, ref3, results, t;
  ref = conf.mouse.asTile(), mx = ref[0], my = ref[1];
  ref1 = conf.mouse.inCanvas(), mxa = ref1[0], mya = ref1[1];
  if (mxa >= 0 && mya >= 0) {
    switch (conf.tool) {
      case 'Place':
        if (conf.switcher === 'Tiles') {
          if (conf.tile >= 0 && noTileAt(mx, my)) {
            tls[conf.layer].push(new Entity('Tile', conf.tile, mx, my));
          }
        }
        if (conf.switcher === 'Instances' && (isSingle || e.ctrlKey)) {
          if (conf.instance >= 0) {
            tls[conf.layer].push(new Entity('Instance', conf.instance, mxa, mya));
          }
        }
        return draw();
      case 'Remove':
        for (i = j = 0, ref2 = tls[conf.layer].length; 0 <= ref2 ? j < ref2 : j > ref2; i = 0 <= ref2 ? ++j : --j) {
          t = tls[conf.layer][i];
          if (conf.switcher === 'Tiles') {
            if (t.x === mx && t.y === my) {
              tls[conf.layer].splice(i, 1);
              break;
            }
          } else {
            if (t.instanceOnMouse()) {
              tls[conf.layer].splice(i, 1);
              break;
            }
          }
        }
        return draw();
      case 'Picker':
        results = [];
        for (i = k = 0, ref3 = tls[conf.layer].length; 0 <= ref3 ? k < ref3 : k > ref3; i = 0 <= ref3 ? ++k : --k) {
          t = tls[conf.layer][i];
          if (conf.switcher === 'Tiles') {
            if (t.x === mx && t.y === my) {
              conf.tile = t.id;
              $.each($('.tile'), function(i, e) {
                return $(e).removeClass('active');
              });
              $($('.tiles').children()[t.id]).addClass('active');
              break;
            } else {
              results.push(void 0);
            }
          } else {
            if (t.instanceOnMouse()) {
              conf.instance = t.id;
              $.each($('.instance'), function(i, e) {
                return $(e).removeClass('active');
              });
              $($('.instances').children()[t.id]).addClass('active');
              break;
            } else {
              results.push(void 0);
            }
          }
        }
        return results;
        break;
      case 'Marquee':
        if (!conf.selection.selecting) {
          conf.selection.selecting = true;
          if (conf.switcher === 'Tiles') {
            conf.selection.start = {
              x: mx,
              y: my
            };
            conf.selection.end = {
              x: mx,
              y: my
            };
          }
          if (conf.switcher === 'Instances') {
            conf.selection.start = {
              x: mxa,
              y: mya
            };
            conf.selection.end = {
              x: mxa,
              y: mya
            };
          }
        } else {
          if (conf.switcher === 'Tiles') {
            conf.selection.end = {
              x: mx,
              y: my
            };
          }
          if (conf.switcher === 'Instances') {
            conf.selection.end = {
              x: mxa,
              y: mya
            };
          }
        }
        return draw();
    }
  }
};

window.draw = function() {
  ctx.clearRect(0, 0, cnvs.width, cnvs.height);
  ctxs.clearRect(0, 0, cnvss.width, cnvss.height);
  drawTiles();
  return drawSelection();
};

window.drawGrid = function() {
  var j, ref, results, x, y;
  ctxg.strokeStyle = conf.colours.grid;
  results = [];
  for (x = j = 0, ref = cnvsg.width / conf.tileSize; 0 <= ref ? j <= ref : j >= ref; x = 0 <= ref ? ++j : --j) {
    results.push((function() {
      var k, ref1, results1;
      results1 = [];
      for (y = k = 0, ref1 = cnvsg.height / conf.tileSize; 0 <= ref1 ? k <= ref1 : k >= ref1; y = 0 <= ref1 ? ++k : --k) {
        ctxg.rect(x * conf.tileSize, y * conf.tileSize, conf.tileSize, conf.tileSize);
        results1.push(ctxg.stroke());
      }
      return results1;
    })());
  }
  return results;
};

window.drawSelection = function() {
  var j, len, ref, ref1, ref2, ref3, results, sx, sy, t, x1, x2, y1, y2;
  ctxs.strokeStyle = conf.colours.selection;
  if (conf.selection.selecting) {
    if (conf.switcher === 'Tiles') {
      ref = conf.selection.getDrawCoords(), x1 = ref[0], y1 = ref[1], x2 = ref[2], y2 = ref[3];
    }
    if (conf.switcher === 'Instances') {
      ref1 = conf.selection.getCoords(), x1 = ref1[0], y1 = ref1[1], x2 = ref1[2], y2 = ref1[3];
    }
    ctxs.lineWidth = 5;
    ctxs.beginPath();
    ctxs.rect(x1, y1, x2 - x1, y2 - y1);
    return ctxs.stroke();
  } else {
    ctxs.lineWidth = 3;
    ref2 = conf.selection.tiles;
    results = [];
    for (j = 0, len = ref2.length; j < len; j++) {
      t = ref2[j];
      ref3 = t.getDrawCoords(), x1 = ref3[0], y1 = ref3[1], sx = ref3[2], sy = ref3[3];
      ctxs.beginPath();
      ctxs.rect(x1, y1, conf.tileSize, conf.tileSize);
      results.push(ctxs.stroke());
    }
    return results;
  }
};

window.drawTiles = function() {
  var img, j, layer, len, ref, results, tile, x, y;
  ctx.imageSmoothingEnabled = false;
  ref = window.tls;
  results = [];
  for (j = 0, len = ref.length; j < len; j++) {
    layer = ref[j];
    results.push((function() {
      var k, len1, ref1, results1;
      results1 = [];
      for (k = 0, len1 = layer.length; k < len1; k++) {
        tile = layer[k];
        ref1 = tile.getDrawCoords(), x = ref1[0], y = ref1[1];
        img = tile.type === 'Tile' ? tlis[tile.id] : inis[tile.id];
        results1.push(ctx.drawImage(img, x, y, conf.imageSize * conf.gridScaleUp, conf.imageSize * conf.gridScaleUp));
      }
      return results1;
    })());
  }
  return results;
};
