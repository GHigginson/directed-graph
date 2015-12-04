'use strict';

var should = require('chai').should(),
    expect = require('chai').expect,
    assert = require('chai').assert,
    builder = require('../libs/querybuilder.js');

describe('Query Builder', function() {

  it('Should build cheapest queries', function(done) {
    var query = builder.build({
      type: 'cheapest',
      from: 'a',
      to: 'z'
    });
    assert(0 <= query.sql.indexOf('dijkstra'));
    done();
  });

  it('Should build paths queries', function(done) {
    var query = builder.build({
      type: 'paths',
      from: 'a',
      to: 'z'
    });
    assert(0 <= query.sql.indexOf('recursive'));
    done();
  });

  it('Should prevent sql injection', function(done) {
    var query = builder.build({
      type: 'paths',
      from: '\'; delete from graphs; \'',
      to: 'z'
    });
    assert(0 <= query.sql.indexOf('\\\''));
    done();
  });

});
