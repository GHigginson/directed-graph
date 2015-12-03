'use strict';

module.exports = {
  "build" : function(request, results) {
    var response = { items : [] };
    results.forEach(function (result) {
      response.items.push(result);
    });
    return response;
  }
};
