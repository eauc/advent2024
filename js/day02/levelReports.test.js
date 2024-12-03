require('../init');
const {
  parseLevelReportsFile,
  countSafeReports,
  reportIsSafe,
} = require('./levelReports');

describe('day02/levelReports', () => {
  describe('reportIsSafe', () => {
    it(`a report only counts as safe if both of the following are true:
    - The levels are either all increasing or all decreasing.
    - Any two adjacent levels differ by at least one and at most three.`, () => {
      expect(reportIsSafe({ levelReport: [7, 6, 4, 2, 1] })).to.eql(
        true,
        'levels are all decreasing'
      );
      expect(reportIsSafe({ levelReport: [1, 3, 6, 7, 9] })).to.eql(
        true,
        'levels are all increasing'
      );
      expect(reportIsSafe({ levelReport: [1, 2, 7, 8, 9] })).to.eql(
        false,
        `2 7 is an increase of 5`
      );
      expect(reportIsSafe({ levelReport: [9, 7, 6, 2, 1] })).to.eql(
        false,
        `6 2 is a decrease of 4`
      );
    });

    it(`The Problem Dampener is a reactor-mounted module that 
      lets the reactor safety systems tolerate a single bad level in what would otherwise be a safe report`, () => {
      expect(reportIsSafe({ levelReport: [1, 2, 7, 8, 9] })).to.eql(
        false,
        `2 7 is an increase of 5, unsafe regardless of which level is removed.`
      );
      expect(reportIsSafe({ levelReport: [9, 7, 6, 2, 1] })).to.eql(
        false,
        `6 2 is a decrease of 4, unsafe regardless of which level is removed.`
      );
      expect(reportIsSafe({ levelReport: [1, 3, 2, 4, 5] })).to.eql(
        true,
        `safe by removing the second level, 3`
      );
      expect(reportIsSafe({ levelReport: [8, 6, 4, 4, 1] })).to.eql(
        true,
        `safe by removing the third level, 4`
      );
    });
  });

  describe('countSafeReports', () => {
    it(`a report only counts as safe if both of the following are true:
    - The levels are either all increasing or all decreasing.
    - Any two adjacent levels differ by at least one and at most three.`, () => {
      const { levelReports } = parseLevelReportsFile({
        fileName: 'data/day02/test.txt',
      });
      expect({ levelReports }).to.eql({
        levelReports: [
          [7, 6, 4, 2, 1],
          [1, 2, 7, 8, 9],
          [9, 7, 6, 2, 1],
          [1, 3, 2, 4, 5],
          [8, 6, 4, 4, 1],
          [1, 3, 6, 7, 9],
        ],
      });
      const safeReports = countSafeReports({ levelReports });
      expect(safeReports).to.eql({
        safeReports: 4,
        unsafeReports: 2,
      });
    });
  });
});
