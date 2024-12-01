const fs = require('node:fs');

module.exports = {
  parseLocationListsFile,
  totalDistance,
  totalSimilarityScore,
};

function parseLocationListsFile({ fileName }) {
  const inputStr = fs.readFileSync(fileName, 'utf8');
  const locationLists = _.chain(inputStr)
    .split('\n')
    .reject(_.isEmpty)
    .map((l) => _.chain(l).split(/\s+/).map(_.parseInt).value())
    .unzip()
    .value();
  return { locationLists };
}

function totalDistance({ locationLists }) {
  return _.sum(
    _.zipWith(..._.map(locationLists, _.sortBy), (a, b) => Math.abs(a - b))
  );
}

function totalSimilarityScore({ locationLists }) {
  const [leftList, rightList] = locationLists;
  const rightListLocationFrequencies = _.countBy(rightList);
  return _.chain(leftList)
    .map((n) => n * _.get(rightListLocationFrequencies, n, 0))
    .sumBy()
    .value();
}
