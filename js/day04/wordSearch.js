const fs = require('node:fs');

module.exports = {
  parseWordSearchFile,
  findWords,
  findCrossedWords,
  wordOccurencesToString,
};

function parseWordSearchFile({ fileName }) {
  const wordSearchLines = _.chain(fs.readFileSync(fileName, 'utf8'))
    .split('\n')
    .map((line) => line.trim())
    .filter(_.identity)
    .flatMap((line, row) => _.map(line, (char, col) => ({ char, row, col })))
    .groupBy('row')
    .mapValues((row) => _.keyBy(row, 'col'))
    .value();
  return { wordSearchLines };
}

function wordsStartingAt({ row, col, wordSearchLines }) {
  const nRows = _.size(wordSearchLines);
  const nCols = _.size(wordSearchLines[row]);
  return _.map(
    [
      {
        direction: 'right',
        chars: _.chain(0)
          .range(nCols - col)
          .map((i) => wordSearchLines[row][col + i])
          //.map('char')
          //.join('')
          .value(),
      },
      {
        direction: 'left',
        chars: _.chain(0)
          .range(col + 1)
          .map((i) => wordSearchLines[row][col - i])
          //.map('char')
          //.join('')
          .value(),
      },
      {
        direction: 'down',
        chars: _.chain(0)
          .range(nRows - row)
          .map((i) => wordSearchLines[row + i][col])
          //.map('char')
          //.join('')
          .value(),
      },
      {
        direction: 'up',
        chars: _.chain(0)
          .range(row + 1)
          .map((i) => wordSearchLines[row - i][col])
          //.map('char')
          //.join('')
          .value(),
      },
      {
        direction: 'down-right',
        chars: _.chain(0)
          .range(Math.min(nRows - row, nCols - col))
          .map((i) => wordSearchLines[row + i][col + i])
          //.map('char')
          //.join('')
          .value(),
      },
      {
        direction: 'up-left',
        chars: _.chain(0)
          .range(Math.min(row + 1, col + 1))
          .map((i) => wordSearchLines[row - i][col - i])
          //.map('char')
          //.join('')
          .value(),
      },
      {
        direction: 'down-left',
        chars: _.chain(0)
          .range(Math.min(nRows - row, col + 1))
          .map((i) => wordSearchLines[row + i][col - i])
          //.map('char')
          //.join('')
          .value(),
      },
      {
        direction: 'up-right',
        chars: _.chain(0)
          .range(Math.min(row + 1, nCols - col))
          .map((i) => wordSearchLines[row - i][col + i])
          //.map('char')
          //.join('')
          .value(),
      },
    ],
    ({ direction, chars }) => ({
      direction,
      chars,
      word: _.chain(chars).map('char').join('').value(),
    })
  );
}

function findWords({ word, wordSearchLines }) {
  const wordOccurences = _.chain(wordSearchLines)
    .flatMap((row) => _.values(row))
    .filter(({ char }) => char === word[0])
    .map(({ row, col }) => ({
      row,
      col,
      words: wordsStartingAt({ row, col, wordSearchLines }),
    }))
    .flatMap('words')
    .filter(({ word: w }) => w.startsWith(word))
    .map(({ direction, chars }) => ({
      direction,
      chars: _.take(chars, word.length),
      word,
    }))
    .value();
  return { wordOccurences };
}

function findCrossedWords({ word, charIndex, wordSearchLines }) {
  const { wordOccurences } = findWords({ word, wordSearchLines });
  return {
    wordOccurences: _.chain(wordOccurences)
      .filter(({ direction }) =>
        _.includes(
          ['down-right', 'up-left', 'down-left', 'up-right'],
          direction
        )
      )
      .filter(({ chars }, i, diagOccurences) =>
        _.some(
          _.reject(diagOccurences, (_w, j) => i === j),
          ({ chars: otherChars }) => chars[charIndex] === otherChars[charIndex]
        )
      )
      .value(),
  };
}

function wordOccurencesToString({ wordSearchLines, wordOccurences }) {
  const displayChar = _.chain(wordOccurences)
    .flatMap('chars')
    .groupBy('row')
    .mapValues((row) => _.keyBy(row, 'col'))
    .value();
  return _.chain(wordSearchLines)
    .map((line, row) =>
      _.chain(line)
        .map(({ char }, col) => (_.get(displayChar, [row, col]) ? char : '.'))
        .join('')
        .value()
    )
    .join('\n')
    .value();
}
