'use strict';

var should = require('chai').should(),
    expect = require('chai').expect,
    assert = require('chai').assert,
    parser = require('../libs/parser.js'),
    validator = require('../libs/validator.js');

describe('Validator', function() {

  describe('Positive Tests', function() {

    it('should accept the minimal well-formed xml...', function(done) {
      assertValid('minimal.xml', done);
    });

    it('should accept a typical well-formed xml...', function(done) {
      assertValid('valid.xml', done);
    });

  });

  describe('Negative Tests', function() {

    it('should reject duplicated ids...', function(done) {
      assertInvalid('duplicate-id.xml', done);
    });

    it('should reject empty nodes list...', function(done) {
      assertInvalid('empty-nodes.xml', done);
    });

    it('should reject undeclared nodes in edges...', function(done) {
      assertInvalid('unknown-node.xml', done);
    });

    it('should reject negative cost...', function(done) {
      assertInvalid('negative-cost.xml', done);
    });

    it('should reject malformed edge...', function(done) {
      assertInvalid('malformed-edge.xml', done);
    });

  });

});

function assertValid(fname, done) {
  parser.parseFile(__dirname + '/resource/' + fname, function (err, node) {
    assert(!err, "Error loading resource file: " + err);
    validator.validate(node);
    done();
  });
}

function assertInvalid(fname, done) {
  parser.parseFile(__dirname + '/resource/' + fname, function (err, node) {
    assert(!err, "Error loading resource file: " + err);
    var valid = false;
    try {
      validator.validate(node);
      valid = true;
    } catch (e) {}
    assert(!valid, "Validation succeeded unexpectedly");
    done();
  });
}
