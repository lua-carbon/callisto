# Callisto
Callisto is a superset of Lua that transpiles straight down to regular Lua.

Callisto supports the following platforms:
- Lua 5.1, 5.2, and 5.3
- LuaJIT

## Features
- Bang methods - `object:bang!()`
- Increment operator - `number++`
- Mutating operators
	- `a += b`
	- `a -= b`
	- `a *= b`
	- `a /= b`
	- `a ^= b`
	- `a ..= b`
- Compound named array lookups
	- `vec->xyz` translates to `vec[1], vec[2], vec[3]`
	- Supports the following sets of lookups; can be mixed:
		- `(x, y, z, w)`
		- `(r, g, b, a)`
		- `(s, t, p, q)` (legacy mode only)
		- `(u, v)` (legacy mode only)
- Fat-arrow lambdas - `(x) => x^2`
- Default function arguments - `function(x = 5) return x^2 end`

## Usage
Callisto exposes the compiler interface through the `callisto` commmand line tool and through the Lua compiler API.

### Command Line
The command line can be invoked in two ways:
- Through an executable generated through `build.bat` or `build.sh` (requires srlua)
- Directly from the Lua source

Command line:
```bash
# outputs to file.lua
callisto file.clua

# outputs to other.lua
callisto file.clua -o other.lua
```

Directly from Lua source:
```bash
#outputs to file.lua
luajit tools/callisto.lua file.lua

#outputs to other.lua
luajit tools/callisto.lua other.lua
```

### Compiler API
```lua
local Callisto = require("Callisto")
local source = [[
	(x = 1) => x^2
]]

local source, sourcemap = Callisto.Transform(source)
local chunk, err = Callisto.LoadString(source, sourcemap)
if (not chunk) then
	error(err)
end

chunk()

-- OR

local chunk, err = Callisto.Compile(source)
if (not chunk) then
	error(err)
end

chunk()
```