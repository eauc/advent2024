const fs = require('node:fs');

module.exports = {
  parseLevelReportsFile,
  reportIsSafe,
  countSafeReports,
};

function parseLevelReportsFile({ fileName }) {
  const inputStr = fs.readFileSync(fileName, 'utf8');
  const levelReports = _.chain(inputStr)
    .split('\n')
    .reject(_.isEmpty)
    .map((l) => _.chain(l).split(/\s+/).map(_.parseInt).value())
    .value();
  return {
    levelReports,
  };
}

function reportIsSafeStrict({ levelReport }) {
  const deltas = _.chain(_.initial(levelReport))
    .zip(_.tail(levelReport))
    .map(([a, b]) => b - a)
    .value();
  return (
    (_.every(deltas, (d) => d < 0) || _.every(deltas, (d) => d > 0)) &&
    _.every(deltas, (delta) => Math.abs(delta) <= 3)
  );
}

function dampenedLevelReports({ levelReport }) {
  // returns a list of all possible reports
  // obtained from removing one level in the inital report
  return _.chain(levelReport)
    .size()
    .range()
    .map((i) => _.reject(levelReport, (level, index) => i === index))
    .value();
}

function reportIsSafe({ levelReport }) {
  return (
    reportIsSafeStrict({ levelReport }) ||
    _.some(dampenedLevelReports({ levelReport }), (levelReport) =>
      reportIsSafeStrict({ levelReport })
    )
  );
}

function countSafeReports({ levelReports }) {
  return _.countBy(levelReports, (levelReport) =>
    reportIsSafe({ levelReport }) ? 'safeReports' : 'unsafeReports'
  );
}
