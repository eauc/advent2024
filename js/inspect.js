/* eslint-disable no-console */
const { inspect } = require('node:util');

console.debug = (...args) => {
  console.log(...args);
};

console.inspect = (value) => {
  console.debug(inspect(value, false, null, true));
  return value;
};

global.inspect = console.inspect;
