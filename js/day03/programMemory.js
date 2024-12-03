require('../init');
const fs = require('fs');

module.exports = {
  parseProgramMemoryFile,
  parseAllInstructions,
  sumInstructions,
};

function parseProgramMemoryFile({ fileName }) {
  const programMemory = fs.readFileSync(fileName, 'utf8');
  return {
    programMemory,
  };
}

function parseInstruction({ programMemory }) {
  const match = /(?<operand>mul|do|don't)\((?<args>\d{1,3},\d{1,3}|)\)/.exec(
    programMemory
  );
  if (!match) {
    return;
  }
  const {
    index,
    groups: { operand, args: argsStr },
  } = match;
  const args = _.split(argsStr, ',');
  return {
    operand,
    args,
    instruction: _.get(
      {
        mul: ([lhs, rhs]) => ({
          operand: 'mul',
          args: {
            lhs: parseInt(lhs),
            rhs: parseInt(rhs),
          },
        }),
        [`don't`]: () => ({ operand: 'dont' }),
        do: () => ({ operand: 'do' }),
      },
      operand,
      (args) => ({ operand, args })
    )(args),
    programMemory: programMemory.substring(index + match[0].length),
  };
}

function parseAllInstructions({ programMemory, instructions = [] }) {
  const nextInstruction = parseInstruction({ programMemory });
  if (!nextInstruction) {
    return { instructions };
  }
  const { programMemory: pc, instruction } = nextInstruction;
  return parseAllInstructions({
    programMemory: pc,
    instructions: [...instructions, instruction],
  });
}

function sumInstructions({ instructions }) {
  return _.reduce(
    instructions,
    ({ sum, active }, { operand, args }) => {
      const result = _.get(
        {
          mul: ({ lhs, rhs }) => ({
            sum: active ? sum + lhs * rhs : sum,
            active,
          }),
          do: () => ({ sum, active: true }),
          dont: () => ({ sum, active: false }),
        },
        operand
      )(args);
      return result;
    },
    { sum: 0, active: true }
  ).sum;
}
