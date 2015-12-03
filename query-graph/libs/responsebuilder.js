'use strict';

function buildPaths(query, result) {
  return [['???','???']]; // TODO
}

function buildPath(query, result) {
  var parentMap = {};
  result.rows.forEach(function(row) {
    parentMap[row['dest_node']] = row['source_node'];
  });
  var path = [];
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
