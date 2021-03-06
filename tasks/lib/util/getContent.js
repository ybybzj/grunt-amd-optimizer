// Generated by CoffeeScript 1.6.3
(function() {
  var File, Http, Promise, Util, grunt;

  Promise = (require('es6-promise')).Promise;

  Http = require('http');

  grunt = require('grunt');

  File = require('fs');

  Util = require('./fs');

  module.exports = function(location) {
    var _content;
    _content = '';
    return new Promise(function(resolve, reject) {
      var e;
      if (Util.isUrl(location)) {
        Http.get(location, function(res) {
          res.on('data', function(data) {
            return _content += data;
          });
          res.on('end', function() {
            return resolve(_content);
          });
          return res.on('error', function(e) {
            e.location = location;
            return reject(e);
          });
        });
      } else {
        try {
          _content = File.readFileSync(location.replace(/[?#]\S+$/i, '')).toString();
          return resolve(_content);
        } catch (_error) {
          e = _error;
          e.location = location;
          return reject(e);
        }
      }
    });
  };

}).call(this);
