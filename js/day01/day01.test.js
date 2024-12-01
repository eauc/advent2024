require('../init');
const {
  parseLocationListsFile,
  totalDistance,
  totalSimilarityScore,
} = require('./locationList');

describe('day01', () => {
  describe('total distance', () => {
    it(`pairs up the numbers and measures how far apart they are. 
    Pair up the smallest number in the left list with the smallest number in the right list, 
    then the second-smallest left number with the second-smallest right number, 
    and so on`, () => {
      const { locationLists } = parseLocationListsFile({
        fileName: 'day01/test.txt',
      });
      expect({ locationLists }).to.eql({
        locationLists: [
          [3, 4, 2, 1, 3, 3],
          [4, 3, 5, 3, 9, 3],
        ],
      });

      expect({
        totalDistance: totalDistance({ locationLists }),
      }).to.eql({
        totalDistance: 11,
      });
    });
  });

  describe('total similarity score', () => {
    it(`adds up each number in the left list 
      after multiplying it by the number of times that number appears in the right list`, () => {
      const { locationLists } = parseLocationListsFile({
        fileName: 'day01/test.txt',
      });
      expect({ locationLists }).to.eql({
        locationLists: [
          [3, 4, 2, 1, 3, 3],
          [4, 3, 5, 3, 9, 3],
        ],
      });
      expect({
        totalSimilarityScore: totalSimilarityScore({ locationLists }),
      }).to.eql({
        totalSimilarityScore: 31,
      });
    });
  });
});
