var dialog, fs, klaw, loaded, path;

fs = require('fs-extra');

klaw = require('klaw-sync');

path = require('path');

dialog = require('electron').remote.dialog;

loaded = function() {
  return path.join(__dirname, '..\\_loaded');
};

window.updateProject = function() {
  var instances, tiles;
  tiles = klaw(path.join(loaded(), 'tiles'), {
    nodir: true,
    ignore: ['!(*.png)', '!(*.jpg)', '!(*.cfg)', '!(*.tiff)']
  });
  instances = klaw(path.join(loaded(), 'instances'), {
    nodir: true,
    ignore: ['!(*.png)', '!(*.jpg)', '!(*.cfg)', '!(*.tiff)']
  });
  if ($('.tile').length > 0) {
    $.each($('.tile'), function(i, e) {
      return $(e).remove();
    });
  }
  if ($('.instances').length > 0) {
    $.each($('.instance'), function(i, e) {
      return $(e).remove();
    });
  }
  tiles.forEach(function(t, i) {
    var d;
    d = $('<img/>', {
      "class": "tile " + (i === 0 ? 'active' : ''),
      src: t.path
    });
    d.appendTo($('.tiles'));
    if (i === 0) {
      return conf.tile = 0;
    }
  });
  instances.forEach(function(t, i) {
    var d;
    d = $('<img/>', {
      "class": "instance " + (i === 0 ? 'active' : ''),
      src: t.path
    });
    d.appendTo($('.instances'));
    if (i === 0) {
      return conf.instance = 0;
    }
  });
  window.tls = [[]];
  draw();
  return updateTilesAndInstances();
};

window.loadProject = function() {
  var instancesPath, projectPath, tilesPath;
  projectPath = dialog.showOpenDialog({
    properties: ['openDirectory']
  });
  if (!projectPath) {
    return;
  } else {
    projectPath = projectPath[0];
  }
  tilesPath = path.join(projectPath, 'tiles');
  instancesPath = path.join(projectPath, 'instances');
  fs.removeSync(path.join(loaded()));
  if (fs.existsSync(tilesPath)) {
    fs.copySync(tilesPath, path.join(loaded(), 'tiles'));
  }
  if (fs.existsSync(instancesPath)) {
    fs.copySync(instancesPath, path.join(loaded(), 'instances'));
  }
  return updateProject();
};
