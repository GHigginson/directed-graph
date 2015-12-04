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
 *       start:"A",
 *       end:"Z"
 *     },
 *     {
 *       type:"paths" ,
 *       start:"A",
 *       end:"Z"
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
  var pattern = (query.type == "cheapest")
    ? "SELECT unnest(dijkstra(null,'%s','%s')) AS id"
    : "SELECT unnest(recursive_path_search(null,'%s','%s')) AS id";
  query.sql = util.format(pattern, escape(query.start), escape(query.end));
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
