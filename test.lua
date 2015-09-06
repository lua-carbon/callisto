local Callisto = require("Callisto")
local Compiler = Callisto.Compiler

local tests = {
[1] = [=[
function hello()
	print("hello, world")
	print("OKAY")
end
]=],
[2] = [=[
while (true) do
	if (true) then
		hello()
	end
end
]=],
[3] = [=[
if (true) then
	print("yes!")
else
	print("no?")
end
]=],
[4] = [=[
if (true) then
	print("correct!")
elseif (true) then
	print("uh oh")
end
]=],
[5] = [=[
for i = 1, 10 do
	hello()
end

for i = 1, 10, 2 do
	hello()
end
]=],
[6] = [=[
for key, value in ipairs({1, 2, 3}) do
	print(key, value)
	if (key) then
		print("YES!")
	end
end
]=]
}

for key, test in ipairs(tests) do
	print(("----TEST #%d----"):format(key))
	local state = Compiler.parse(test)

	local completed = state.pos
	local max = #test
	local pass = completed > max
	local msg = pass and "PASS" or "FAIL"
	print(("%d/%d -- %s"):format(state.pos - 1, #test, msg))

	if (not pass) then
		print(test:sub(0, state.pos - 1))
	end
end