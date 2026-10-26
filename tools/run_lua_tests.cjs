// Fengari's CLI can report Lua errors without a nonzero exit status. Use its
// protected-call result directly so failing assertions fail local/CI checks.
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const files = process.argv.slice(2);
let failed = false;
for (const file of files.length ? files : ['tests/gameplay.lua', 'tests/persistence.lua', 'tests/phase2.lua', 'tests/content.lua', 'tests/fish_models.lua', 'tests/glow_events.lua', 'tests/runtime.lua']) {
  const state = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(state);
  const status = lauxlib.luaL_dofile(state, to_luastring(file));
  if (status !== lua.LUA_OK) {
    console.error(`${file}: ${to_jsstring(lua.lua_tostring(state, -1))}`);
    failed = true;
  }
  lua.lua_close(state);
}
process.exitCode = failed ? 1 : 0;
