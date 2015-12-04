'use strict';
/* Parser
 *
 * Wrapper module for the xml2js parser, mostly to abstract the process of
 * loading the target resource into a string for the parser to demarshal.
 */

var fs = require('fs'),
    request = require('request'),
    xml2js = require('xml2js');

/**
 * Parse a resource that is eithher (1) a local file path or (2) a URL
 */
function parseFileOrUrl(fname, callback) {
  return fs.existsSync(fname)
      ? parseFile(fname, callback)
      : parseUrl(fname, callback);
}

/**
 * Fetch a remote xml resource, and return the demarshaled value.
 */
function parseUrl(url, callback) {
  request(url, function (err, res, body) {
    if (!err && res.statusCode == 200) {
      parseString(body, callback);
    } else {
      callback(err ? err : "Bad status code: " + res.statusCode, null);
    }
  });
}

/**
 * Load a local xml resource, and return the demarshaled value.
 */
function parseFile(fname, callback) {
  fs.readFile(fname, function(err, data) {
    if (err) {
      callback(err, null);
    } else {
      parseString(data, callback);
    }
  });
}

/**
 * Demarshal an xml document.
 */
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
