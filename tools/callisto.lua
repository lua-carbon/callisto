-- This is the callisto command-line interface.

if (COMPILED) then
	package.path = package.path .. ";../?/init.lua"
end

local Callisto = require("Callisto")

local loadstring = loadstring or load

local usage = [=[
USAGE:
  callisto [input.clua [-o output.clua]] [-h] [-v] [-e main.clua] [--option=value]

  -h: Display this dialog
  -v: Enable verbose mode
  -e: Execute Lua or Callisto file after compilation
  --option=value: Send settings to the compiler:
      - 'Legacy': Whether to enable legacy mode
]=]

if (select("#", ...) == 0) then
	print(usage)
	return
end

local mode = "in"
local verbose = false
local infile
local execfile
local map = {}
local settings = {}

local function vprint(...)
	if (verbose) then
		print(...)
	end
end

local function parse_value(value)
	if (value == "true" or value == "yes") then
		return true
	elseif (value == "false" or value == "no") then
		return false
	elseif (tonumber(value)) then
		return tonumber(value)
	else
		return value
	end
end

for i = 1, select("#", ...) do
	local arg = select(i, ...)

	if (arg:sub(1, 1) == "-") then
		if (arg:sub(2) == "o") then
			mode = "out"
		elseif (arg:sub(2) == "v") then
			verbose = true
		elseif (arg:sub(2) == "e") then
			mode = "execute"
		elseif (arg:sub(2) == "h") then
			print(usage)
		elseif (arg:sub(2, 2) == "--") then
			local key, value = arg:sub(3):match("([^=]+)=(.*)")
			settings[key] = parse_value(value)
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
	elseif (mode == "execute") then
		execfile = arg
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
	(function()
		local handle, err = io.open(input, "rb")

		if (not handle) then
			print(("Couldn't open file %s for reading: %s"):format(input, err))
			return
		end

		if (handle) then
			local body = handle:read("*a")
			handle:close()

			local transformed, err = Callisto.Transform(body, settings)

			if (not transformed) then
				print(("Callisto Error in %s: %s"):format(input, err))
				return
			end

			local chunk, err = loadstring(transformed)

			if (not chunk) then
				print(("Lua Error %s: %s"):format(input, err))
				return
			end

			local handle, err = io.open(output, "wb")

			if (not handle) then
				print(("Couldn't open file %s for writing: %s"):format(output, err))
				return
			end

			if (handle) then
				handle:write(transformed)
				handle:close()

				vprint(("Compiled %s to %s successfully."):format(input, output))
			end
		end
	end)()
end

if (execfile) then
	(function()
		local is_callisto = not not execfile:match("%.clua$")
		local handle, err = io.open(execfile, "rb")

		if (not handle) then
			print(("Couldn't open file %s for execution: %s"):format(execfile, err))
			return
		end

		if (handle) then
			local body = handle:read("*a")
			handle:close()

			if (is_callisto) then
				local chunk, err = Callisto.Compile(body, settings)

				if (not chunk) then
					print(("Compilation error in %s: %s"):format(execfile, err))
					return
				end

				vprint(("Executing as Callisto: %s"):format(execfile))
				chunk()
			else
				local chunk, err = loadstring(body)

				if (not chunk) then
					print(("Compilation error in %s: %s"):format(execfile, err))
					return
				end

				vprint(("Executing as Lua: %s"):format(execfile))
				chunk()
			end
		end
	end)()
end