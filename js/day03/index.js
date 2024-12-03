require('../init');
const {
  parseProgramMemoryFile,
  parseAllInstructions,
  sumInstructions,
} = require('./programMemory');

const { programMemory } = parseProgramMemoryFile({
  fileName: './data/day03/input.txt',
});

const { instructions } = parseAllInstructions({ programMemory });

console.inspect({
  sum: sumInstructions({ instructions }),
});
