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
 * TODO
 */
function buildPaths(query, result) {
  return [['???','???']]; // TODO
}

/**
 * Constructs a single path from a cheapest-path query result. The rows
 * retrieved represent a tree in the format:
 *
 *   [{source_node:null,dest_node:'A'} .. {source_node:'Y',dest_node:'Z'}]
 *
 * Are not guaranteed to have either the desired source or target, and may
 * contain additional branches not on the path.
 */
function buildPath(query, result) {
  var path = [];

  // Create a map of child node to parent node
  var parentMap = {};
  result.rows.forEach(function(row) {
    parentMap[row['dest_node']] = row['source_node'];
  });

  // Recurse the map from leaf to root, assembling path in reverse order
  var node = query.to;
  if (parentMap[node] === undefined) {
    path = false;
  } else {
    while (node) {
      path.unshift(node);
      node = parentMap[node];
    }
  }
  return path;
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
