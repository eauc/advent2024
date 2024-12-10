require('../init');
const {
  parseGuardMapFile,
  getInitialPosition,
  guardIsExiting,
  advanceGuard,
  turnGuardRight,
  traceGuardPath,
  findAllPossibleLoopObstructions,
  visitedMap,
} = require('./guardMap');

describe('day06', () => {
  it('parseGuardMapFile', () => {
    const { guardMap } = parseGuardMapFile({ fileName: 'data/day06/test.txt' });
    expect({ guardMap }).to.eql({
      guardMap: {
        map: [
          '....#.....',
          '.........#',
          '..........',
          '..#.......',
          '.......#..',
          '..........',
          '.#..^.....',
          '........#.',
          '#.........',
          '......#...',
        ],
        height: 10,
        width: 10,
      },
    });
  });

  describe('getInitialPosition', () => {
    it('extracts initial position from map, denoted "^"', () => {
      const { guardMap } = parseGuardMapFile({
        fileName: 'data/day06/test.txt',
      });
      expect(
        getInitialPosition({
          guardMap,
        })
      ).to.eql({
        direction: 'up',
        row: 6,
        col: 4,
      });
    });
  });

  describe('guardIsExiting', () => {
    it('checks if advancing the guard means they exit the map', () => {
      const guardMap = { width: 10, height: 10 };
      expect(
        guardIsExiting({
          guardMap,
          guardPosition: { direction: 'up', row: 4, col: 4 },
        })
      ).to.eql(false);
      expect(
        guardIsExiting({
          guardMap,
          guardPosition: { direction: 'up', row: 0, col: 4 },
        })
      ).to.eql(true, 'up');
      expect(
        guardIsExiting({
          guardMap,
          guardPosition: { direction: 'down', row: 9, col: 4 },
        })
      ).to.eql(true, 'down');
      expect(
        guardIsExiting({
          guardMap,
          guardPosition: { direction: 'left', row: 4, col: 0 },
        })
      ).to.eql(true, 'left');
      expect(
        guardIsExiting({
          guardMap,
          guardPosition: { direction: 'right', row: 4, col: 9 },
        })
      ).to.eql(true, 'right');
    });
  });

  describe('advanceGuard', () => {
    it('advance guard in their current direction', () => {
      expect(
        advanceGuard({
          guardPosition: { direction: 'up', row: 4, col: 4 },
        })
      ).to.eql({ direction: 'up', row: 3, col: 4 });
      expect(
        advanceGuard({
          guardPosition: { direction: 'down', row: 4, col: 4 },
        })
      ).to.eql({ direction: 'down', row: 5, col: 4 });
      expect(
        advanceGuard({
          guardPosition: { direction: 'left', row: 4, col: 4 },
        })
      ).to.eql({ direction: 'left', row: 4, col: 3 });
      expect(
        advanceGuard({
          guardPosition: { direction: 'right', row: 4, col: 4 },
        })
      ).to.eql({ direction: 'right', row: 4, col: 5 });
    });
  });

  describe('turnGuardRight', () => {
    it('change guard direction to turn right', () => {
      expect(
        turnGuardRight({
          guardPosition: { direction: 'up', row: 4, col: 4 },
        })
      ).to.eql({ direction: 'right', row: 4, col: 4 });
      expect(
        turnGuardRight({
          guardPosition: { direction: 'right', row: 4, col: 4 },
        })
      ).to.eql({ direction: 'down', row: 4, col: 4 });
      expect(
        turnGuardRight({
          guardPosition: { direction: 'down', row: 4, col: 4 },
        })
      ).to.eql({ direction: 'left', row: 4, col: 4 });
      expect(
        turnGuardRight({
          guardPosition: { direction: 'left', row: 4, col: 4 },
        })
      ).to.eql({ direction: 'up', row: 4, col: 4 });
    });
  });

  describe('traceGuardPath', () => {
    it('trace guard in map until they exit', () => {
      expect(
        traceGuardPath({
          guardMap: {
            map: ['.', '^'],
            width: 1,
            height: 2,
          },
        })
      ).to.eql([
        { direction: 'up', row: 1, col: 0 },
        { direction: 'up', row: 0, col: 0 },
      ]);
    });

    it('turn guard to the right when they encounter an obstruction', () => {
      expect(
        traceGuardPath({
          guardMap: {
            map: ['#.', '..', '^.'],
            width: 2,
            height: 3,
          },
        })
      ).to.eql([
        { direction: 'up', row: 2, col: 0 },
        { direction: 'up', row: 1, col: 0 },
        { direction: 'right', row: 1, col: 1 },
      ]);
    });

    it('trace test map', () => {
      const { guardMap } = parseGuardMapFile({
        fileName: 'data/day06/test.txt',
      });
      const guardPath = traceGuardPath({ guardMap });
      expect(visitedMap({ guardMap, guardPath })).to.eql([
        '....#.....',
        '....^>>>>#',
        '....^...v.',
        '..#.^...v.',
        '..^>>>>#v.',
        '..^.^.v.v.',
        '.#<<<<v<v.',
        '.^>>>>>>#.',
        '#<<<<<vv..',
        '......#v..',
      ]);
    });
  });

  describe('findAllPossibleLoopObstructions', () => {
    it('checks along guard path for any possible obstruction leading them into a loop', () => {
      const { guardMap } = parseGuardMapFile({
        fileName: 'data/day06/test.txt',
      });
      const guardPath = traceGuardPath({ guardMap });
      expect(findAllPossibleLoopObstructions({ guardMap, guardPath })).to.eql([
        { row: 6, col: 3 },
        { row: 7, col: 6 },
        { row: 7, col: 7 },
        { row: 8, col: 1 },
        { row: 8, col: 3 },
        { row: 9, col: 7 },
      ]);
    });
  });
});
