'use strict';

var _ = require('lodash');

var Validator = function() {
  this.encountered = [];
  this.declared = [];
  return this;
}

Validator.prototype.hasA = function(node, child) {
  if (undefined === node[child]) {
    throw new Error('Missing child: ' + child);
  }
  return this;
}

Validator.prototype.hasOne = function(node, child) {
  return this.hasExactly(node, child, 1);
}

Validator.prototype.hasExactly = function(node, child, expected) {
  var found = _lengthOf(node[child]);
  if (found != expected) {
    throw new Error('Expected ' + expected + ' but was ' + found + ': ' + child);
  }
  return this;
}

Validator.prototype.hasAtLeastOne = function(node, child) {
  return this.hasAtLeast(node, child, 1);
}

Validator.prototype.hasAtLeast = function(node, child, expected) {
  var found = _lengthOf(node[child]);
  if (found < expected) {
    throw new Error('Expected at least ' + expected + ' but was ' + found + ': ' + child);
  }
  return this;
}

Validator.prototype.isUnique = function(id) {
  if (-1 < this.encountered.indexOf(id)) {
    throw new Error('Duplicate identifier ' + id);
  }
  this.encountered.push(id);
  return this;
}

Validator.prototype.declareNode = function(id) {
  this.declared.push(id);
  return this;
}

Validator.prototype.isDeclaredNode = function(id) {
  if (-1 == this.declared.indexOf(id)) {
    throw new Error('Undeclared identifier ' + id);
  }
  return this;
}

Validator.prototype.isNotNegative = function(cval) {
  if (cval) {
    var val = parseFloat(cval);
    if (_.isNaN(val) || val < 0) {
      throw new Error('Expected positive number ' + cval);
    }
  }
  return this;
}

Validator.prototype.each = function(array, method) {
  if (_.isArray(array)) {
    array.forEach(function (element) {
      method(element);
    });
  } else if (array) {
    method(array);
  }
  return this;
}

function _lengthOf(element) {
  if(_.isArray(element)) {
    return element.length;
  }
  return element == undefined ? 0 : 1;
}

module.exports = {
  validate: function(o) {
    var assert = new Validator(o);
    assert
        .hasA(o, 'graph')
        .hasOne(o.graph, 'id')
        .hasOne(o.graph, 'name')
        .hasAtLeastOne(o.graph, 'nodes')
        .hasAtLeastOne(o.graph.nodes, 'node')
        .hasA(o.graph, 'edges')
        .each(o.graph.nodes.node, function (node) {
          assert
              .hasOne(node, 'id')
              .isUnique(node.id)
              .declareNode(node.id);
        })
        .each(o.graph.edges.edge, function (edge) {
          assert
              .hasOne(edge, 'id')
              .hasOne(edge, 'to')
              .hasOne(edge, 'from')
              .isUnique(edge.id)
              .isDeclaredNode(edge.to)
              .isDeclaredNode(edge.from)
              .isNotNegative(edge.cost);
        });
  }
}
