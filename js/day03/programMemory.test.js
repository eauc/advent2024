const {
  parseProgramMemoryFile,
  parseAllInstructions,
  sumInstructions,
} = require('./programMemory');

describe('day03/parseAllInstructions', () => {
  it(`all instructions like mul(X,Y), where X and Y are each 1-3 digit numbers.
    For instance, mul(44,46) multiplies 44 by 46 to get a result of 2024. Similarly, mul(123,4) would multiply 123 by 4.
    - The do() instruction enables future mul instructions.
    - The don't() instruction disables future mul instructions. `, () => {
    const { programMemory } = parseProgramMemoryFile({
      fileName: './data/day03/test.txt',
    });
    expect({
      programMemory,
      ...parseAllInstructions({
        programMemory,
      }),
    }).to.eql({
      programMemory: `xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))\n`,
      instructions: [
        { operand: 'mul', args: { lhs: 2, rhs: 4 } },
        { operand: `dont` },
        { operand: 'mul', args: { lhs: 5, rhs: 5 } },
        { operand: 'mul', args: { lhs: 11, rhs: 8 } },
        { operand: `do` },
        { operand: 'mul', args: { lhs: 8, rhs: 5 } },
      ],
    });
  });
});

describe('day03/sumInstructions', () => {
  it(`Adds up the result of each multiplication instruction`, () => {
    expect(
      sumInstructions({
        instructions: [
          { operand: 'mul', args: { rhs: 2, lhs: 4 } },
          { operand: 'dont' },
          { operand: 'mul', args: { rhs: 5, lhs: 5 } },
          { operand: 'mul', args: { rhs: 11, lhs: 8 } },
          { operand: 'do' },
          { operand: 'mul', args: { rhs: 8, lhs: 5 } },
        ],
      })
    ).to.eql(48);
  });
});
