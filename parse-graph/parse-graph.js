#!/usr/bin/node

var parser = require('./libs/parser.js'),
    validator = require('./libs/validator.js');

// Expect input file as an argument
if (process.argv.length != 3) {
  console.log('Usage: parse-graph.js <url-or-file>');
  process.exit(1);
}
var fname = process.argv[2];

// Parse and validate input
parser.parseFileOrUrl(fname, function(err, rootNode) {
  var fail = function(msg) {
    console.error("Failed: " + msg);
    process.exit(1);
  }
  if (err) fail(err);
  try {
    validator.validate(rootNode);
    console.log("Validated");
  } catch (e) {
    fail(e.message);
  }
});
