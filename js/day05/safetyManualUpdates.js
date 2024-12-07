const fs = require('node:fs');

module.exports = {
  parseSafetyManualUpdatesFile,
  auditSafetyManualUpdates,
  middlePageNumber,
  checkSafetyManualUpdates,
};

function parseSafetyManualUpdatesFile({ fileName }) {
  const lines = _.chain(fs.readFileSync(fileName, 'utf8'))
    .split('\n')
    .map((s) => _.trim(s))
    .value();
  const pageOrders = _.chain(lines)
    .takeWhile((l) => !_.isEmpty(l))
    .map((l) => _.chain(l).split('|').map(_.parseInt).value())
    .groupBy(_.first)
    .mapValues((v) => _.map(v, _.last))
    .value();
  const pageUpdates = _.chain(lines)
    .dropWhile((l) => !_.isEmpty(l))
    .reject(_.isEmpty)
    .map((l) => _.chain(l).split(',').map(_.parseInt).value())
    .value();
  return { pageOrders, pageUpdates };
}

function auditSafetyManualUpdates({ pageOrders, pageUpdates }) {
  const errors = _.chain(pageUpdates)
    .map((pageNumber, index) => [
      pageNumber,
      _.chain(pageUpdates)
        .take(index + 1)
        .intersection(_.get(pageOrders, pageNumber, []))
        .value(),
    ])
    .fromPairs()
    .omitBy(_.isEmpty)
    .value();
  return {
    isOk: _.isEmpty(errors),
    correctPageUpdates: _.chain(pageUpdates)
      .map((pageNumber) => ({
        pageNumber,
        pageOrders: _.chain(pageOrders)
          .get(pageNumber, [])
          .intersection(pageUpdates)
          .value(),
      }))
      .orderBy(({ pageOrders }) => _.size(pageOrders), 'desc')
      .map('pageNumber')
      .value(),
    errors,
  };
}

function middlePageNumber({ pageUpdates }) {
  return pageUpdates[Math.floor(pageUpdates.length / 2)];
}

function checkSafetyManualUpdates({ pageUpdates, pageOrders }) {
  return {
    correctPageUpdatesCheck: _.chain(pageUpdates)
      .filter(
        (pageUpdates) =>
          auditSafetyManualUpdates({ pageOrders, pageUpdates }).isOk
      )
      .map((pageUpdates) => middlePageNumber({ pageUpdates }))
      .sum()
      .value(),
    incorrectPageUpdatesCheck: _.chain(pageUpdates)
      .map((pageUpdates) =>
        auditSafetyManualUpdates({ pageOrders, pageUpdates })
      )
      .reject('isOk')
      .map('correctPageUpdates')
      .map((pageUpdates) => middlePageNumber({ pageUpdates }))
      .sum()
      .value(),
  };
}
