const fs = require('node:fs');
const { performance } = require('node:perf_hooks');

module.exports = {
  parseGuardMapFile,
  getInitialPosition,
  guardIsExiting,
  advanceGuard,
  turnGuardRight,
  traceGuardPath,
  findAllPossibleLoopObstructions,
  visitedMap,
};

function parseGuardMapFile({ fileName }) {
  const data = fs.readFileSync(fileName, 'utf8');
  const map = _.chain(data).split('\n').reject(_.isEmpty).value();
  return {
    guardMap: {
      map,
      height: _.size(map),
      width: _.chain(map).first().size().value(),
    },
  };
}

function getInitialPosition({ guardMap }) {
  for (const row in guardMap.map) {
    for (const col in guardMap.map[row]) {
      if (guardMap.map[row][col] === '^') {
        return {
          direction: 'up',
          row: Number(row),
          col: Number(col),
        };
      }
    }
  }
}

function guardIsExiting({ guardMap, guardPosition }) {
  return _.get(
    {
      up: guardPosition.row === 0,
      down: guardPosition.row === guardMap.height - 1,
      left: guardPosition.col === 0,
      right: guardPosition.col === guardMap.width - 1,
    },
    guardPosition.direction
  );
}

function advanceGuard({ guardPosition }) {
  return _.get(
    {
      up: { ...guardPosition, row: guardPosition.row - 1 },
      down: { ...guardPosition, row: guardPosition.row + 1 },
      left: { ...guardPosition, col: guardPosition.col - 1 },
      right: { ...guardPosition, col: guardPosition.col + 1 },
    },
    guardPosition.direction
  );
}

function turnGuardRight({ guardPosition }) {
  return _.get(
    {
      up: { ...guardPosition, direction: 'right' },
      down: { ...guardPosition, direction: 'left' },
      left: { ...guardPosition, direction: 'up' },
      right: { ...guardPosition, direction: 'down' },
    },
    guardPosition.direction
  );
}

function traceGuardPath({ guardMap }) {
  const initialPosition = getInitialPosition({ guardMap });
  let guardPosition = initialPosition;
  const path = [initialPosition];
  while (true) {
    if (guardIsExiting({ guardMap, guardPosition })) {
      break;
    }
    const nextPosition = advanceGuard({ guardPosition });
    if (guardMap.map[nextPosition.row][nextPosition.col] === '#') {
      guardPosition = turnGuardRight({ guardPosition });
      continue;
    }
    guardPosition = nextPosition;
    path.push(guardPosition);
  }
  return path;
}

function visitedMap({ guardMap, guardPath }) {
  const visitedMarkers = _.chain(guardPath)
    .reverse()
    .uniqBy(({ row, col }) => `${row},${col}`)
    .groupBy('row')
    .mapValues((v) =>
      _.chain(v)
        .keyBy('col')
        .mapValues('direction')
        .mapValues((direction) =>
          _.get({ up: '^', down: 'v', right: '>', left: '<' }, direction)
        )
        .value()
    )
    .value();
  return _.map(guardMap.map, (line, row) =>
    _.map(line, (char, col) => _.get(visitedMarkers, [row, col], char)).join('')
  );
}

function setMapMarker({ guardMap, row, col, marker }) {
  const newGuardMap = _.cloneDeep(guardMap);
  newGuardMap.map[row] =
    `${newGuardMap.map[row].substring(0, col)}${marker}${newGuardMap.map[row].substring(col + 1)}`;
  return newGuardMap;
}

function measure() {
  performance.measure('checkExitDuration', 'start', 'checkExit');
  performance.measure('checkTurnDuration', 'checkExit', 'checkTurn');
  performance.measure('checkLoopDuration', 'checkTurn', 'checkLoop');
  performance.measure('checkEndDuration', 'checkLoop', 'end');
}

function perf() {
  inspect({
    checkExitDuration: _.sumBy(
      performance.getEntriesByName('checkExitDuration'),
      'duration'
    ),
    checkTurnDuration: _.sumBy(
      performance.getEntriesByName('checkTurnDuration'),
      'duration'
    ),
    checkLoopDuration: _.sumBy(
      performance.getEntriesByName('checkLoopDuration'),
      'duration'
    ),
    checkEndDuration: _.sumBy(
      performance.getEntriesByName('checkEndDuration'),
      'duration'
    ),
  });
}

function checkLoop({ guardMap }) {
  const initialPosition = getInitialPosition({ guardMap });
  let guardPosition = initialPosition;
  const path = [initialPosition];
  const start = new Date();
  let loop = false;
  while (true) {
    //performance.mark('start');
    if (guardIsExiting({ guardMap, guardPosition })) {
      inspect({ EXIT: guardPosition, duration: new Date() - start });
      //performance.mark('checkExit');
      break;
    }
    //performance.mark('checkExit');
    const nextPosition = advanceGuard({ guardPosition });
    if (guardMap.map[nextPosition.row][nextPosition.col] === '#') {
      guardPosition = turnGuardRight({ guardPosition });
      //performance.mark('checkTurn');
      continue;
    }
    //performance.mark('checkTurn');
    guardPosition = nextPosition;
    if (
      _.some(
        path,
        (p) =>
          p.row === guardPosition.row &&
          p.col === guardPosition.col &&
          p.direction === guardPosition.direction
      )
    ) {
      inspect({ LOOP: guardPosition, duration: new Date() - start });
      loop = true;
      //performance.mark('checkLoop');
      break;
    }
    //performance.mark('checkLoop');
    path.push(guardPosition);
    //performance.mark('end');
    //measure();
  }
  //measure();
  //perf();
  return loop;
}

function findAllPossibleLoopObstructions({ guardMap, guardPath }) {
  const initialPosition = getInitialPosition({ guardMap });
  return _.chain(guardPath)
    .reject(
      ({ row, col }) =>
        row === initialPosition.row && col === initialPosition.col
    )
    .map(({ row, col }) => ({ row, col }))
    .uniqBy(({ row, col }) => `${row},${col}`)
    .filter(({ row, col }, index) => {
      inspect({ index });
      const newGuardMap = setMapMarker({ guardMap, row, col, marker: '#' });
      return checkLoop({ guardMap: newGuardMap });
    })
    .orderBy(['row', 'col'])
    .value();
}
