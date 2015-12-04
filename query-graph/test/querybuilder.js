'use strict';

var should = require('chai').should(),
    expect = require('chai').expect,
    assert = require('chai').assert,
    builder = require('../libs/querybuilder.js');

describe('Query Builder', function() {

  it('Should build cheapest queries', function(done) {
    var query = builder.build({
      type: 'cheapest',
      start: 'a',
      end: 'z'
    });
    assert(0 <= query.sql.indexOf('dijkstra'));
    done();
  });

  it('Should build paths queries', function(done) {
    var query = builder.build({
      type: 'paths',
      start: 'a',
      end: 'z'
    });
    assert(0 <= query.sql.indexOf('recursive'));
    done();
  });

  it('Should prevent sql injection', function(done) {
    var query = builder.build({
      type: 'paths',
      start: '\'; delete from graphs; \'',
      end: 'z'
    });
    assert(0 <= query.sql.indexOf('\\\''));
    done();
  });

});
