require('../init');
const { parseLevelReportsFile, countSafeReports } = require('./levelReports');

(function main() {
  const { levelReports } = parseLevelReportsFile({
    fileName: 'day02/input.txt',
  });
  inspect(countSafeReports({ levelReports }));
})();
