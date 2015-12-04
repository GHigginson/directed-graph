'use strict';
/* Response Builder
 *
 * Utility methods for assembling a response object from a set of query results
 * and the query model objects that produced them.
 *
 * Response Format:
 *
 * {
 *   answers: [
 *     {
 *       type:"cheapest" ,
 *       from:"A",
 *       to:"Z",
 *       path:["A", ... "Z"]
 *     },
 *     {
 *       type:"paths" ,
 *       from:"A",
 *       to:"Z",
 *       paths:[["A", ...],["A", ...]]
 *     },
       ...
 *   ]
 * }
 */

/**
 * Constructs a single path from a cheapest-path query result. The rows
 * retrieved are each node id in the path, and a terminal null, eg.
 *
 *   [{id : A} .. {id:'Z'}, {id:null}}]
 */
function buildPath(query, result) {
  var path = [];
  result.rows.forEach(function(row) {
    if (row && row.id) {
      path.push(row.id);
    }
  });
  return path.length ? path : false;
}

/**
 * Constructs a set of paths path from an all-paths query result. The rows
 * retrieved are the concatenation of all the paths seen, in the same Format
 * as the cheapest query paths, eg:
 *
 *   [{id : A} .. {id:'Z'}, {id:null}, {id : A} .. {id:'Z'}, {id:null}]
 */
function buildPaths(query, result) {
  var paths = [], path = [];
  result.rows.forEach(function(row) {
    if (row && row.id) {
      path.push(row.id);
    } else if (path.length) {
      paths.push(path);
      path = [];
    }
  });
  return paths.length ? paths : false;
}

/**
 * Assembles an answer containing either a 'path' or 'paths' element depending
 * on the type of the originating query.
 */
function buildAnswer(query, result) {
  var answer = {
    type: query.type,
    from: query.from,
    to: query.to
  };
  if (query.type == 'paths') {
    answer.paths = buildPaths(query, result)
  } else {
    answer.path = buildPath(query, result);
  }
  return answer;
}

/**
 * Constructs a response object containing an array of answers of the same
 * length and order as queries.
 */
function build(queries, results) {
  var response = { answers : [] };
  for (var i = 0; i < queries.length; i++) {
    var answer = buildAnswer(queries[i], results[i]);
    response.answers.push(answer);
  }
  return response;
}

module.exports = {
  "build" : build,
  "buildAnswer" : buildAnswer
};
