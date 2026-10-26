const fs = require('fs');
const path = require('path');
const parser = require('luaparse');
let count = 0;
function walk(directory) {
  for (const name of fs.readdirSync(directory)) {
    const file = path.join(directory, name);
    if (fs.statSync(file).isDirectory()) walk(file);
    else if (file.endsWith('.lua')) {
      parser.parse(fs.readFileSync(file, 'utf8'), { luaVersion: '5.3' });
      count++;
    }
  }
}
walk('src');
walk('tests');
console.log(`PASS: ${count} Lua/Luau-compatible source files parsed`);
