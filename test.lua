local Compiler = require("Callisto.Compiler")

local body = [=[
function hello()
	print("hello, world")
end

if true then
	hello()
end
]=]

local state = Compiler.Parse(body)
print("\"" .. body:sub(0, state.pos - 1) .. "\"")