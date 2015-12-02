#!/usr/bin/node

var fs = require('fs'),
    connector = require('./libs/connector.js'),
    queryBuilder = require('./libs/querybuilder.js'),
    responseBuilder = require('./libs/responsebuilder.js');

if (process.argv.length != 2) {
  console.log('Usage: query-graph.js < input.json');
  process.exit(1);
}

fs.readFile('config.json' , function(err, data) {
  if (err) throw err
  var config = JSON.parse(data);
  process.stdin.on('data', function(data) {
    var request = JSON.parse(data);
    connector.connect(config, function (err, connection) {
      if (err) throw err;
      var queries = queryBuilder.buildAll(request);
      var results = connection.queryAll(queries);
      var response = responseBuilder.build(request, results);
      console.log(JSON.stringify(response));
    });
  });
});
