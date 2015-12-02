#!/usr/bin/node

var parser = require('./libs/parser.js'),
    validator = require('./libs/validator.js');

if (process.argv.length != 3) {
  console.log('Usage: parse-graph.js <url-or-file>');
  process.exit();
}
var fname = process.argv[2];

parser.parseFile(fname, function(err, rootNode) {
  if (err) {
    console.error("Invalid XML: " + err);
  } else {
    validator.validate(rootNode);
  }
});
