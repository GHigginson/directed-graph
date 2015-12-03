#!/usr/bin/node

var fs = require('fs'),
    connector = require('./libs/connector.js'),
    queryBuilder = require('./libs/querybuilder.js'),
    responseBuilder = require('./libs/responsebuilder.js');

if (process.argv.length != 2) {
  console.log('Usage: query-graph.js < input.json');
  process.exit(1);
}

var config = JSON.parse(fs.readFileSync('config.json'));

process.stdin.on('data', function(data) {
  var request = JSON.parse(data);
  var queries = queryBuilder.buildAll(request);
  connector.connect(config, function (err, client) {
    if (err) throw err;
    connector.queryAll(client, queries, function(err, results) {
      if (err) throw err;
      var response = responseBuilder.build(request, results);
      var json = JSON.stringify(response);
      console.log(json);
      process.exit(0);
    });
  });
});
