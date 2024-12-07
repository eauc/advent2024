require('../init');
const {
  parseSafetyManualUpdatesFile,
  checkSafetyManualUpdates,
} = require('./safetyManualUpdates');

const { pageOrders, pageUpdates } = parseSafetyManualUpdatesFile({
  fileName: 'data/day05/input.txt',
});

const check = checkSafetyManualUpdates({ pageOrders, pageUpdates });

console.log({ check });
