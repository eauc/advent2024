global._ = require('lodash');

_.mixin({
  inspect(value, ...args) {
    return console.inspect(value, ...args);
  },
  choose(pairs) {
    return _.chain(pairs).find(_.first).nth(1).value();
  },
});
