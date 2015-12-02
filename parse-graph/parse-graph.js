#!/usr/bin/node

var parser = require('./libs/parser.js'),
    validator = require('./libs/validator.js');

if (process.argv.length != 3) {
  console.log('Usage: parse-graph.js <url-or-file>');
  process.exit(1);
}
var fname = process.argv[2];

parser.parseFileOrUrl(fname, function(err, rootNode) {
  if (err) {
    console.error("Error: " + err);
  } else {
    validator.validate(rootNode);
  }
  process.exit(err ? 1 : 0);
});
