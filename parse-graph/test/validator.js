'use strict';

var should = require('chai').should(),
    expect = require('chai').expect,
    assert = require('chai').assert,
    parser = require('../libs/parser.js'),
    validator = require('../libs/validator.js');

describe('Validator', function() {

  describe('Positive Tests', function() {
    it('Should Accept...', function(done) {
      assert(true); // TODO
      done();
    });
  });

  describe('Negative Tests', function() {
    it('Should Reject...', function(done) {
      parser.parseFile(__dirname + '/resource/wrong-ccc-count.xml', function (err, node) {
        // TODO: extract to helper method
        try {
          validator.validate(node);
          assert(false);
        } catch (e) {
          assert(true);
        }
        done();
      });
    });
  });

});
