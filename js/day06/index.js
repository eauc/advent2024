require('../init');
const {
  parseGuardMapFile,
  traceGuardPath,
  visitedMap,
  findAllPossibleLoopObstructions,
} = require('./guardMap');

const { guardMap } = parseGuardMapFile({
  fileName: 'data/day06/input.txt',
});

const guardPath = traceGuardPath({ guardMap });
console.log(visitedMap({ guardMap }).join('\n'));
console.inspect({
  visitedPositions: _.size(
    _.uniqBy(guardPath, ({ row, col }) => `${row},${col}`)
  ),
});

const possibleObstructions = findAllPossibleLoopObstructions({
  guardMap,
  guardPath,
});
console.inspect({
  possibleObstructions: _.size(possibleObstructions),
});
