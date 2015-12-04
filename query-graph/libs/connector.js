'use strict';
/* Connector
 *
 * Wrapper for pg client with convenience methods for processing the datasource
 * config, and query batching
 */
var util = require('util'),
    pg = require('pg'),
    async = require('async');

/**
 * Generates a connect-string from the datasource config
 */
function toUri(config) {
  return util.format(
      "postgres://%s:%s@%s:%d/%s",
      config.username,
      config.password,
      config.host,
      config.port,
      config.database
  );
}

/**
 * Establishes a new connection, then calls callback(err, client)
 */
function connect(config, callback) {
  var client = new pg.Client(toUri(config));
  client.connect(function(err) {
    callback(err, client);
  });
}

/**
 * Runs the requested queries, and calls calback(err, result) when all have
 * completed.
 */
function queryAll(client, queries, callback) {
  var results = [];
  async.each(queries, function(query, done) {
    client.query(query.sql, function (err, result) {
      if (err) throw err;
      else results.push(result);
      done();
    });
  }, function(err) {
    callback(err, results);
  });
}

module.exports = {
  "connect" : connect,
  "queryAll" : queryAll
};
