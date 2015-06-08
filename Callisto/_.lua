--[[
	Callisto
	#class Callisto

	#description {
		A superset of Lua based on Carbide.
	}
]]

local Callisto = (...)
local Compiler = Callisto.Compiler

-- In (string source, [table settings])
-- Out (string source, table sourcemap)
Callisto.Transform = Compiler.Transform

-- In (string source, [table sourcemap])
-- Out (function? chunk, string? error)
Callisto.LoadString = Compiler.LoadString

-- In (string source, [table settings])
-- Out (function? chunk, string? error)
function Callisto.Compile(source, settings)
	local transformed, errmap = Callisto.Transform(source, settings)

	if (not transformed) then
		return false, errmap
	end

	return Callisto.LoadString(transformed, errmap)
end

return Callisto