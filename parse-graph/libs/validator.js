'use strict';
/* Validator
 *
 * Ensures the contents of the graph meet the impose constraints. Ensuring
 * well-formedness of the document is managed by the parser.
 */

var util = require('util'),
    _ = require('lodash');

var Validator = function() {
  this.encountered = [];
  this.declared = [];
  return this;
}

/**
 * Is he attribute present on the node?
 */
Validator.prototype.hasA = function(node, child) {
  if (undefined === node[child]) {
    throw new Error(util.format('Missing child: %s', child));
  }
  return this;
}

/**
 * Is there exactly one instance of the child present at node?
 */
Validator.prototype.hasOne = function(node, child) {
  return this.hasExactly(node, child, 1);
}

/**
 * Is there exactly N instances of the child present at node?
 */
Validator.prototype.hasExactly = function(node, child, expected) {
  var found = _lengthOf(node[child]);
  if (found != expected) {
    throw new Error(util.format('Expected %d but was %d in %s',
         expected, found, child));
  }
  return this;
}

/**
 * Is there at least one instance of the child present at node?
 */
Validator.prototype.hasAtLeastOne = function(node, child) {
  return this.hasAtLeast(node, child, 1);
}

/**
 * Is there at least N instances of the child present at node?
 */
Validator.prototype.hasAtLeast = function(node, child, expected) {
  var found = _lengthOf(node[child]);
  if (found < expected) {
    throw new Error('Expected at least %d but was %d in %s',
         expected, found, child);
  }
  return this;
}

/**
 * Is this the first time id has been encountered?
 */
Validator.prototype.isUnique = function(id) {
  if (-1 < this.encountered.indexOf(id)) {
    throw new Error('Duplicate identifier ' + id);
  }
  this.encountered.push(id);
  return this;
}

/**
 * Remember the id is valid as a reference in edges.
 */
Validator.prototype.declareNode = function(id) {
  this.declared.push(id);
  return this;
}

/**
 * Is id valid as a reference in edges?
 */
Validator.prototype.isDeclaredNode = function(id) {
  if (-1 == this.declared.indexOf(id)) {
    throw new Error('Undeclared identifier ' + id);
  }
  return this;
}

/**
 * Is the value non-negative if it is present?
 */
Validator.prototype.isNotNegative = function(cval) {
  if (cval) {
    var val = parseFloat(cval);
    if (_.isNaN(val) || val < 0) {
      throw new Error('Expected positive number ' + cval);
    }
  }
  return this;
}

/**
 * Call method on each element of array. The parser only creates an array
 * if multiple children are present, so handle scalars also.
 */
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

/**
 * Length of element if an array, or 1 if scalar.
 */
function _lengthOf(element) {
  if(_.isArray(element)) {
    return element.length;
  }
  return element == undefined ? 0 : 1;
}

/**
 * Validate all the things.
 */
function validate(o) {
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

module.exports = {
  validate: validate
}
