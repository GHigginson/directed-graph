'use strict';

var util = require('util');

function escape(s) {
  return s.replace('\'', '\\\'');
}

function build(query) {
  return util.format(
    "SELECT * FROM dijkstra('g1','%s')", // TODO: request doesn't specify graph
    escape(query.from)
  );
}

function buildAll(request) {
  var sql = [];
  request.queries.forEach(function(query) {
    sql.push(build(query));
  });
  return sql;
}

module.exports = {
  "build" : build,
  "buildAll" : buildAll
};
