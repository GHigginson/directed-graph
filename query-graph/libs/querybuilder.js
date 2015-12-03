'use strict';

var util = require('util');

function escape(s) {
  return s.replace('\'', '\\\'');
}

function build(query) {
  query.sql = util.format(
    "SELECT * FROM dijkstra('g1','%s')", // TODO: request doesn't specify graph
    escape(query.from)
  );
  return query;
}

function buildAll(request) {
  var queries = [];
  request.queries.forEach(function(query) {
    queries.push(build(query));
  });
  return queries;
}

module.exports = {
  "build" : build,
  "buildAll" : buildAll
};
