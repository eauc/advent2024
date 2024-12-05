require('../init');
const {
  parseWordSearchFile,
  findWords,
  findCrossedWords,
  wordOccurencesToString,
} = require('./wordSearch');

describe('day04/parseWordSearchFile', () => {
  it('reads word search map as an array of { chars, row, col }', () => {
    expect(parseWordSearchFile({ fileName: 'data/day04/test.txt' })).to.eql({
      wordSearchLines: {
        0: {
          0: { char: 'M', row: 0, col: 0 },
          1: { char: 'M', row: 0, col: 1 },
          2: { char: 'M', row: 0, col: 2 },
          3: { char: 'S', row: 0, col: 3 },
          4: { char: 'X', row: 0, col: 4 },
          5: { char: 'X', row: 0, col: 5 },
          6: { char: 'M', row: 0, col: 6 },
          7: { char: 'A', row: 0, col: 7 },
          8: { char: 'S', row: 0, col: 8 },
          9: { char: 'M', row: 0, col: 9 },
        },
        1: {
          0: { char: 'M', row: 1, col: 0 },
          1: { char: 'S', row: 1, col: 1 },
          2: { char: 'A', row: 1, col: 2 },
          3: { char: 'M', row: 1, col: 3 },
          4: { char: 'X', row: 1, col: 4 },
          5: { char: 'M', row: 1, col: 5 },
          6: { char: 'S', row: 1, col: 6 },
          7: { char: 'M', row: 1, col: 7 },
          8: { char: 'S', row: 1, col: 8 },
          9: { char: 'A', row: 1, col: 9 },
        },
        2: {
          0: { char: 'A', row: 2, col: 0 },
          1: { char: 'M', row: 2, col: 1 },
          2: { char: 'X', row: 2, col: 2 },
          3: { char: 'S', row: 2, col: 3 },
          4: { char: 'X', row: 2, col: 4 },
          5: { char: 'M', row: 2, col: 5 },
          6: { char: 'A', row: 2, col: 6 },
          7: { char: 'A', row: 2, col: 7 },
          8: { char: 'M', row: 2, col: 8 },
          9: { char: 'M', row: 2, col: 9 },
        },
        3: {
          0: { char: 'M', row: 3, col: 0 },
          1: { char: 'S', row: 3, col: 1 },
          2: { char: 'A', row: 3, col: 2 },
          3: { char: 'M', row: 3, col: 3 },
          4: { char: 'A', row: 3, col: 4 },
          5: { char: 'S', row: 3, col: 5 },
          6: { char: 'M', row: 3, col: 6 },
          7: { char: 'S', row: 3, col: 7 },
          8: { char: 'M', row: 3, col: 8 },
          9: { char: 'X', row: 3, col: 9 },
        },
        4: {
          0: { char: 'X', row: 4, col: 0 },
          1: { char: 'M', row: 4, col: 1 },
          2: { char: 'A', row: 4, col: 2 },
          3: { char: 'S', row: 4, col: 3 },
          4: { char: 'A', row: 4, col: 4 },
          5: { char: 'M', row: 4, col: 5 },
          6: { char: 'X', row: 4, col: 6 },
          7: { char: 'A', row: 4, col: 7 },
          8: { char: 'M', row: 4, col: 8 },
          9: { char: 'M', row: 4, col: 9 },
        },
        5: {
          0: { char: 'X', row: 5, col: 0 },
          1: { char: 'X', row: 5, col: 1 },
          2: { char: 'A', row: 5, col: 2 },
          3: { char: 'M', row: 5, col: 3 },
          4: { char: 'M', row: 5, col: 4 },
          5: { char: 'X', row: 5, col: 5 },
          6: { char: 'X', row: 5, col: 6 },
          7: { char: 'A', row: 5, col: 7 },
          8: { char: 'M', row: 5, col: 8 },
          9: { char: 'A', row: 5, col: 9 },
        },
        6: {
          0: { char: 'S', row: 6, col: 0 },
          1: { char: 'M', row: 6, col: 1 },
          2: { char: 'S', row: 6, col: 2 },
          3: { char: 'M', row: 6, col: 3 },
          4: { char: 'S', row: 6, col: 4 },
          5: { char: 'A', row: 6, col: 5 },
          6: { char: 'S', row: 6, col: 6 },
          7: { char: 'X', row: 6, col: 7 },
          8: { char: 'S', row: 6, col: 8 },
          9: { char: 'S', row: 6, col: 9 },
        },
        7: {
          0: { char: 'S', row: 7, col: 0 },
          1: { char: 'A', row: 7, col: 1 },
          2: { char: 'X', row: 7, col: 2 },
          3: { char: 'A', row: 7, col: 3 },
          4: { char: 'M', row: 7, col: 4 },
          5: { char: 'A', row: 7, col: 5 },
          6: { char: 'S', row: 7, col: 6 },
          7: { char: 'A', row: 7, col: 7 },
          8: { char: 'A', row: 7, col: 8 },
          9: { char: 'A', row: 7, col: 9 },
        },
        8: {
          0: { char: 'M', row: 8, col: 0 },
          1: { char: 'A', row: 8, col: 1 },
          2: { char: 'M', row: 8, col: 2 },
          3: { char: 'M', row: 8, col: 3 },
          4: { char: 'M', row: 8, col: 4 },
          5: { char: 'X', row: 8, col: 5 },
          6: { char: 'M', row: 8, col: 6 },
          7: { char: 'M', row: 8, col: 7 },
          8: { char: 'M', row: 8, col: 8 },
          9: { char: 'M', row: 8, col: 9 },
        },
        9: {
          0: { char: 'M', row: 9, col: 0 },
          1: { char: 'X', row: 9, col: 1 },
          2: { char: 'M', row: 9, col: 2 },
          3: { char: 'X', row: 9, col: 3 },
          4: { char: 'A', row: 9, col: 4 },
          5: { char: 'X', row: 9, col: 5 },
          6: { char: 'M', row: 9, col: 6 },
          7: { char: 'A', row: 9, col: 7 },
          8: { char: 'S', row: 9, col: 8 },
          9: { char: 'X', row: 9, col: 9 },
        },
      },
    });
  });
});

describe('day04/findWord', () => {
  it('finds all occurence of word in wordSearchLines', () => {
    const { wordSearchLines } = parseWordSearchFile({
      fileName: 'data/day04/test.txt',
    });
    const { wordOccurences } = findWords({
      word: 'XMAS',
      wordSearchLines,
    });
    expect(_.size(wordOccurences)).to.eql(18);
    expect(`\n${wordOccurencesToString({ wordSearchLines, wordOccurences })}`)
      .to.eql(`
....XXMAS.
.SAMXMS...
...S..A...
..A.A.MS.X
XMASAMX.MM
X.....XA.A
S.S.S.S.SS
.A.A.A.A.A
..M.M.M.MM
.X.X.XMASX`);
  });
});

describe('day04/findCrossedWords', () => {
  it('finds all occurence of words with the nth character in common', () => {
    const { wordSearchLines } = parseWordSearchFile({
      fileName: 'data/day04/test.txt',
    });
    const { wordOccurences } = findCrossedWords({
      word: 'MAS',
      charIndex: 1,
      wordSearchLines,
    });
    expect(_.size(wordOccurences)).to.eql(18);
    expect(`\n${wordOccurencesToString({ wordSearchLines, wordOccurences })}`)
      .to.eql(`
.M.S......
..A..MSMS.
.M.S.MAA..
..A.ASMSM.
.M.S.M....
..........
S.S.S.S.S.
.A.A.A.A..
M.M.M.M.M.
..........`);
  });
});
