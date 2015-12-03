'use strict';
/* Query Builder
 *
 * Constructs the appropriate SQL query for each "query" model in a request.
 *
 * Request Format:
 *
 * {
 *   queries: [
 *     {
 *       type:"cheapest" ,
 *       from:"A",
 *       to:"Z"
 *     },
 *     {
 *       type:"paths" ,
 *       from:"A",
 *       to:"Z"
 *     },
       ...
 *   ]
 * }
 */
var util = require('util');

/**
 * Escape quotes to prevent sql injection
 */
function escape(s) {
  return s.replace('\'', '\\\'');
}

/**
 * Adds an "sql" attribute to the query model that contains the appropriate
 * sql query for the query type.
 */
function build(query) {
  if (query.type == "cheapest") {
    query.sql = util.format(
      "SELECT * FROM dijkstra('g1','%s')", // TODO: no graphId in query obj
      escape(query.from)
    );
  } else {
    query.sql = "SELECT 1"; // TODO
  }
  return query;
}

/**
 * Adds an "sql" attribute to each query model that contains the appropriate
 * sql query for the query type.
 */
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
