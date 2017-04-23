window.$ = window.jQuery = require('jquery');

window.vex = require('vex-js');

vex.registerPlugin(require('vex-dialog'));

vex.defaultOptions.className = 'vex-theme-plain';

window.remote = require('electron').remote;

window.win = remote.getCurrentWindow();

window.conf = require('./scr/Conf.coffee');

require('./scr/Maths.coffee');

require('./scr/Camera.coffee');

require('./scr/Io.coffee');

require('./scr/Entity.coffee');

window.tls = [[]];

window.vis = [true];

window.lnm = ["Main"];

window.changeLayer = function(x) {
  var i, j, ref, results;
  conf.layer = x;
  if (tls[conf.layer] === void 0) {
    lnm[conf.layer] = "Layer " + (conf.layer + 1);
    tls[conf.layer] = [];
    vis[conf.layer] = true;
  }
  results = [];
  for (i = j = 0, ref = tls.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
    if (tls[i] === void 0) {
      tls[i] = [];
      results.push(vis[i] = true);
    } else {
      results.push(void 0);
    }
  }
  return results;
};

window.getLayerName = function() {
  return lnm[conf.layer];
};

window.updateAutos = function() {
  var j, layer, len, results, tile;
  results = [];
  for (j = 0, len = tls.length; j < len; j++) {
    layer = tls[j];
    results.push((function() {
      var k, len1, results1;
      results1 = [];
      for (k = 0, len1 = layer.length; k < len1; k++) {
        tile = layer[k];
        if (tile.auto !== void 0) {
          results1.push(updateAuto(layer, tile, conf.autos[tile.auto]));
        } else {
          results1.push(void 0);
        }
      }
      return results1;
    })());
  }
  return results;
};

window.updateAuto = function(layer, tile, system) {
  var results, rule, rulename, srule, srulename, tx, ty;
  console.log(layer);
  results = [];
  for (rulename in system) {
    rule = system[rulename];
    if (rulename !== 'thumb') {
      results.push((function() {
        var results1;
        results1 = [];
        for (srulename in rule) {
          srule = rule[srulename];
          tx = tile.x;
          ty = tile.y;
          switch (srulename) {
            case 'r':
              results1.push(doSysCheck(layer, tile, rulename, rule, 1, 0));
              break;
            case 'l':
              results1.push(doSysCheck(layer, tile, rulename, rule, -1, 0));
              break;
            case 'b':
              results1.push(doSysCheck(layer, tile, rulename, rule, 0, 1));
              break;
            case 't':
              results1.push(doSysCheck(layer, tile, rulename, rule, 0, -1));
              break;
            default:
              results1.push(void 0);
          }
        }
        return results1;
      })());
    } else {
      results.push(void 0);
    }
  }
  return results;
};

window.doSysCheck = function(layer, tile, rulename, rule, x, y) {
  if (getTilesSystemAt(layer, tile.x + x, tile.y + y) === rulename) {
    return tile.id = rule;
  }
};

window.getTilesSystemAt = function(layer, x, y) {
  var t;
  t = getTileAt(layer, x, y);
  if (t === void 0 || t.auto === void 0) {
    return 'none';
  }
  return t.auto;
};

window.getTileAt = function(layer, x, y) {
  var j, len, ref, tile;
  ref = tls[layer];
  for (j = 0, len = ref.length; j < len; j++) {
    tile = ref[j];
    if (tile.x === x && tile.y === y) {
      return tile;
    }
  }
  return void 0;
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
    if ((conf.switcher === 'Tiles' && tile.type === 'Tile') || (conf.switcher === 'Instances' && tile.type === 'Instance')) {
      tile.x += x;
      tile.y += y;
    }
  }
  return draw();
};

window.processClick = function(e, isSingle) {
  var i, j, k, mx, mxa, my, mya, ref, ref1, ref2, ref3, results, t;
  ref = conf.mouse.asTile(), mx = ref[0], my = ref[1];
  ref1 = conf.mouse.inCanvas(), mxa = ref1[0], mya = ref1[1];
  if (mxa > Camera.left() && mya > Camera.top()) {
    switch (conf.tool) {
      case 'Place':
        if (conf.switcher === 'Tiles') {
          if (conf.tile && noTileAt(mx, my)) {
            if ('%' === conf.tile.charAt(0)) {
              e = new Entity('Tile', conf.tile, mx, my);
              e.auto = conf.tile.slice(1);
              tls[conf.layer].push(e);
            } else {
              tls[conf.layer].push(new Entity('Tile', conf.tile, mx, my));
            }
          }
        }
        if (conf.switcher === 'Instances' && (isSingle || e.ctrlKey)) {
          if (conf.instance) {
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

window.didCommand = function() {
  conf.history.push($.extend(true, [], window.tls));
  conf.rhistory = [];
  if ((conf.history.length + 1) > conf.historymax) {
    return conf.history.shift();
  }
};

window.undoCommand = function() {
  if (conf.history.length > 1) {
    conf.rhistory.push($.extend(true, [], conf.history.pop()));
    window.tls = $.extend(true, [], conf.history[conf.history.length - 1]);
    return draw();
  }
};

window.redoCommand = function() {
  if (conf.rhistory.length > 0) {
    window.tls = $.extend(true, [], conf.rhistory.pop());
    conf.history.push($.extend(true, [], window.tls));
    return draw();
  }
};

require('./scr/Events.coffee');

require('./scr/Drawing.coffee');
