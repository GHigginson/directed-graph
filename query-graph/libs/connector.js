'use strict';

var util = require('util'),
    pg = require('pg'),
    async = require('async');

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

function connect(config, callback) {
  var client = new pg.Client(toUri(config));
  client.connect(function(err) {
    callback(err, client);
  });
}

function queryAll(client, queries, callback) {
  var results = [];
  async.each(queries, function(query, done) {
    client.query(query.sql, function (err, result) {
      if (!err) results.push(result);
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
