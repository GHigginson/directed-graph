'use strict';

var _ = require('lodash');

var Validator = function() {}

Validator.prototype.hasA = function(node, child) {
console.dir(node);
  if (undefined === node[child]) {
    throw new Error('Missing child: ' + child);
  }
  return this;
}

Validator.prototype.hasOne = function(node, child) {
  return this.hasMany(node, child, 1);
}

Validator.prototype.hasMany = function(node, child, count) {
  var children = node[child];
  if (!_.isArray(children)) {
    throw new Error('Expected ' + count + ' but was not an array: ' + child);
  }
  if (children.length != count) {
    throw new Error('Expected ' + count + ' but was ' + children.length + ': ' + child);
  }
  return this;
}

function validate(node) {
  (new Validator()); // TODO
}

module.exports = {
  validate: validate
}
