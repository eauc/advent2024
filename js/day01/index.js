require('../init');
const {
  parseLocationListsFile,
  totalDistance,
  totalSimilarityScore,
} = require('./locationList');

(function main() {
  const { locationLists } = parseLocationListsFile({
    fileName: 'data/day01/input.txt',
  });
  inspect({
    totalDistance: totalDistance({ locationLists }),
    totalSimilarityScore: totalSimilarityScore({ locationLists }),
  });
})();
