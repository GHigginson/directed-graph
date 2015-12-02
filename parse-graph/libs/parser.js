'use strict';

var fs = require('fs'),
    request = require('request'),
    xml2js = require('xml2js');

function parseFileOrUrl(fname, callback) {
  return fs.existsSync(fname)
      ? parseFile(fname, callback)
      : parseUrl(fname, callback);
}

function parseUrl(url, callback) {
  request(url, function (err, res, body) {
    if (!err && res.statusCode == 200) {
      parseString(body, callback);
    } else {
      callback(err ? err : "Bad status code: " + res.statusCode, null);
    }
  });
}

function parseFile(fname, callback) {
  fs.readFile(fname, function(err, data) {
    if (err) {
      callback(err, null);
    } else {
      parseString(data, callback);
    }
  });
}

function parseString(xml, callback) {
  (new xml2js.Parser({
    explicitArray: false,
    normalizeTags: true
  })).parseString(xml, callback);
}

module.exports = {
  parseFileOrUrl: parseFileOrUrl,
  parseFile: parseFile,
  paserUrl: parseUrl,
  parseString: parseString
};
