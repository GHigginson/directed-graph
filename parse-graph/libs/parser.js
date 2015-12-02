'use strict';

var fs = require('fs'),
    xml2js = require('xml2js');

function parseFile(fname, callback) {
  fs.readFile(fname, function(err, data) {
    if (err) {
      throw new Error(err);
    } else {
      parseString(data, callback);
    }
  });
}

function parseString(xml, callback) {
  (new xml2js.Parser({
    explicitArray: true,
    normalizeTags: true
  })).parseString(xml, callback);
}

module.exports = {
  parseFile: parseFile,
  parseString: parseString
};
