#!/usr/bin/node

var fs = require('fs'),
    connector = require('./libs/connector.js'),
    queryBuilder = require('./libs/querybuilder.js'),
    responseBuilder = require('./libs/responsebuilder.js');

// Expect no arguments
if (process.argv.length != 2) {
  console.log('Usage: query-graph.js < input.json');
  process.exit(1);
}

// Datasource configuration is in local json file
var config = JSON.parse(fs.readFileSync('config.json'));

// Expect request as json on standard input
process.stdin.on('data', function(data) {
  var request = JSON.parse(data);
  var queries = queryBuilder.buildAll(request);

  // Establish connection and perform all queries in the request
  connector.connect(config, function (err, client) {
    if (err) throw err;
    connector.queryAll(client, queries, function(err, results) {
      if (err) throw err;

      // Deliver response as json on stdout
      var response = responseBuilder.build(queries, results);
      var json = JSON.stringify(response, null, 2);
      console.log(json);
      process.exit(0);
    });
  });
});
