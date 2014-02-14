// Generated by CoffeeScript 1.7.1
var changeExtName, changeFileNameWithoutExt, checkFileExt, getFileNameWithoutExt, isUrl, normalizeBasePath, path, pathToUrl, resolveRelativePath, unixifyPath;

path = require('path');

changeExtName = function(fpath, ext) {
  var oext;
  ext = ext.charAt(0) === '.' ? ext : '.' + ext;
  oext = path.extname(fpath);
  return path.dirname(fpath) + '/' + path.basename(fpath, oext) + ext;
};

checkFileExt = function(ext, str) {
  var reg;
  reg = new RegExp('\\.' + ext + '([\\?#]\\S+)?$', 'i');
  return reg.test(str);
};

normalizeBasePath = function(basePath) {
  if (basePath.length === 0) {
    return '';
  }
  if (basePath[basePath.length - 1] !== '/') {
    return basePath + '/';
  } else {
    return basePath;
  }
};

isUrl = function(str) {
  return /^(\S+:)?\/\//i.test(str.trim());
};

resolveRelativePath = function(relTo, relPath) {
  var parentBase, part, parts, _i, _len;
  if (relPath.charAt(0) !== '.') {
    return relPath;
  }
  parts = relPath.split('/');
  parentBase = relTo.split('/').slice(0, -1);
  for (_i = 0, _len = parts.length; _i < _len; _i++) {
    part = parts[_i];
    switch (part) {
      case '..':
        parentBase.pop();
        break;
      case '.':
        break;
      default:
        parentBase.push(part);
    }
  }
  return parentBase.join('/');
};

pathToUrl = function(path) {
  return path.replace(/\\{1,2}/g, function() {
    return "/";
  });
};

getFileNameWithoutExt = function(p) {
  return path.basename(p, path.extname(p));
};

changeFileNameWithoutExt = function(p, newName) {
  if (p == null) {
    return void 0;
  }
  return pathToUrl(path.join(path.dirname(p), newName + path.extname(p)));
};

unixifyPath = function(filepath) {
  if (process.platform === 'win32') {
    return filepath.replace(/\\/g, '/');
  } else {
    return filepath;
  }
};

exports.changeExtName = changeExtName;

exports.checkFileExt = checkFileExt;

exports.normalizeBasePath = normalizeBasePath;

exports.isUrl = isUrl;

exports.resolveRelativePath = resolveRelativePath;

exports.pathToUrl = pathToUrl;

exports.getFileNameWithoutExt = getFileNameWithoutExt;

exports.changeFileNameWithoutExt = changeFileNameWithoutExt;

exports.unixifyPath = unixifyPath;