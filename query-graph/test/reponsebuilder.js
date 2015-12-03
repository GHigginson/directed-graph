'use strict';

var should = require('chai').should(),
    expect = require('chai').expect,
    assert = require('chai').assert,
    builder = require('../libs/responsebuilder.js');

describe('Response Builder', function() {

  describe('Query Cheapest', function() {

    it('Should return false when no result', function(done) {
      var answer = builder.buildAnswer(
        { type:'cheapest', from: 'x', to: 'y' },
        { rows: [ ] }
      );

      assert(answer.path === false);
      done();
    });

    it('Should return path of length one when to=from', function(done) {
      var answer = builder.buildAnswer(
        { type:'cheapest', from: 'a', to: 'a' },
        { rows: [ { source_node: null, dest_node: 'a' } ] }
      );

      assert(areEqual(answer.path, ['a']));
      done();
    });

    it('Should return cheapest path', function(done) {
      var answer = builder.buildAnswer(
        { type:'cheapest', from: 'a', to: 'd' },
        {
          rows: [
            { source_node: null, dest_node: 'a' },
            { source_node: 'a', dest_node: 'b' },
            { source_node: 'a', dest_node: 'c' },
            { source_node: 'b', dest_node: 'd' }
          ]
        }
      );

      assert(areEqual(answer.path, ['a', 'b', 'd']));
      done();
    });



  });

  describe('Query Paths', function() {

    it('Should assemble all paths', function(done) {


      assert(false);
      done();
    });
  });

});

function areEqual(a1, a2) {
  console.log ("Comparing " + JSON.stringify(a1) + " = " + JSON.stringify(a2));
  console.log (JSON.stringify(a1) == JSON.stringify(a2));
  return JSON.stringify(a1) == JSON.stringify(a2);
}
