if (COMPILED) then
	package.path = package.path .. ";../?/init.lua"
end

local Callisto = require("Callisto")

local usage = [[
USAGE:
  callisto input.clua [-o output.clua] [-v] [--option=value]

  -v: Enable verbose mode
]]

local mode = "in"
local verbose = false
local infile
local map = {}
local settings = {}

local function vprint(...)
	if (verbose) then
		print(...)
	end
end

for i = 1, select("#", ...) do
	local arg = select(i, ...)

	if (arg:sub(1, 1) == "-") then
		if (arg:sub(2) == "o") then
			mode = "out"
		elseif (arg:sub(2) == "v") then
			verbose = true
		elseif (arg:sub(2, 2) == "--") then
			local key, value = arg:sub(3):match("([^=]+)=(.*)")
			settings[key:upper()] = value
		end
	elseif (mode == "in") then
		infile = arg
		mode = "any"
	elseif (mode == "out") then
		if (not infile) then
			print("ERROR: No input file to use for output")
		end

		map[infile] = arg
		infile = nil
		mode = "any"
	end
end

if (infile) then
	local ext = infile:match("%.([^%.]+)$")
	local filename = infile

	if (ext == "clua") then
		filename = infile:match("^(.-)%.[^%.]+$") .. ".lua"
	end

	map[infile] = filename
end

for input, output in pairs(map) do
	local handle, err = io.open(input, "rb")

	if (handle) then
		local body = handle:read("*a")
		handle:close()

		local transformed, err = Callisto.Transform(body, settings)

		if (not transformed) then
			print(("Error in %s: %s"):format(input, err))
		end

		local chunk, err = loadstring(transformed)

		if (not chunk) then
			print(("Error in %s: %s"):format(input, err))
		end

		local handle, err = io.open(output, "wb")

		if (handle) then
			handle:write(transformed)
			handle:close()

			vprint(("Compiled %s to %s successfully."):format(input, output))
		else
			print(("Couldn't open file %s for writing: %s"):format(output, err))
		end
	else
		print(("Couldn't open file %s for reading: %s"):format(input, err))
	end
end