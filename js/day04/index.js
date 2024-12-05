require('../init');
const {
  parseWordSearchFile,
  findWords,
  findCrossedWords,
  wordOccurencesToString,
} = require('./wordSearch');

const { wordSearchLines } = parseWordSearchFile({
  fileName: 'data/day04/input.txt',
});

const { wordOccurences } = findWords({
  word: 'XMAS',
  wordSearchLines,
});
console.log(wordOccurencesToString({ wordSearchLines, wordOccurences }));
console.inspect({ wordOccurences: _.size(wordOccurences) });

const { wordOccurences: crossedWordOccurences } = findCrossedWords({
  word: 'MAS',
  charIndex: 1,
  wordSearchLines,
});
console.log(
  wordOccurencesToString({
    wordSearchLines,
    wordOccurences: crossedWordOccurences,
  })
);
console.inspect({ wordOccurences: _.size(crossedWordOccurences) / 2 });
