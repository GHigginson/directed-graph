#!/usr/bin/node

var parser = require('./libs/parser.js'),
    validator = require('./libs/validator.js');

if (process.argv.length != 3) {
  console.log('Usage: parse-graph.js <url-or-file>');
  process.exit(1);
}
var fname = process.argv[2];

try {
  parser.parseFileOrUrl(fname, function(err, rootNode) {
    if (err) throw new Error(err);
    validator.validate(rootNode);
  });
} catch (e) {
  console.error("Error: " + e.message);
  process.exit(1);
}
console.log("Validated");
