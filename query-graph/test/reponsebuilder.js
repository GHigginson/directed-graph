'use strict';

var should = require('chai').should(),
    expect = require('chai').expect,
    assert = require('chai').assert,
    builder = require('../libs/responsebuilder.js');

describe('Response Builder', function() {

  describe('Query Cheapest', function() {

    it('Should return false when no result', function(done) {
      var answer = builder.buildAnswer(
        { type: 'cheapest', from: 'x', to: 'y' },
        { rows: [ { id: null } ] }
      );

      assert(answer.path === false);
      done();
    });

    it('Should return path of length one when to=from', function(done) {
      var answer = builder.buildAnswer(
        { type: 'cheapest', from: 'a', to: 'a' },
        { rows: [ { id: 'a' }, { id: null } ] }
      );

      assert(areEqual(answer.path, ['a']));
      done();
    });

    it('Should return cheapest path', function(done) {
      var answer = builder.buildAnswer(
        { type: 'cheapest', from: 'a', to: 'd' },
        {
          rows: [
            { id: 'a' },
            { id: 'b' },
            { id: 'c' },
            { id: 'd' },
            { id: null },
          ]
        }
      );

      assert(areEqual(answer.path, ['a', 'b', 'c', 'd']));
      done();
    });



  });

  describe('Query Paths', function() {

    it('Should return false when no result', function(done) {
      var answer = builder.buildAnswer(
        { type: 'paths', from: 'x', to: 'y' },
        { rows: [ { id: null } ] }
      );

      assert(answer.paths === false);
      done();
    });

    it('Should return multiple paths', function(done) {
      var answer = builder.buildAnswer(
        { type: 'paths', from: 'a', to: 'z' },
        {
          rows: [
            { id: 'a' },
            { id: 'z' },
            { id: null },
            { id: 'a' },
            { id: 'b' },
            { id: 'z' },
            { id: null },
          ]
        }
      );

      assert(areEqual(answer.paths, [['a', 'z'], ['a', 'b', 'z']]));
      done();
    });

  });

});

function areEqual(a1, a2) {
  return JSON.stringify(a1) == JSON.stringify(a2);
}
