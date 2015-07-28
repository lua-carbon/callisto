--[[
	Callisto Compiler 2.0.0
]]

local Compiler = {}

local KEYWORDS = {"if", "then", "else", "elseif", "end", "function", "while", "for", "do", "repeat", "until"}

local State = {
	peek = function(self, count)
		count = count or 1

		return self.body:sub(self.pos, self.pos + count)
	end,

	pop = function(self, count)
		count = count or 1

		local opos = self.pos
		self.pos = self.pos + count + 1

		return self.body:sub(opos, opos + count)
	end,

	eat = function(self, count)
		self.pos = self.pos + count
	end,

	peek_pattern = function(self, pattern)
		return self.body:match("^" .. pattern, self.pos + 1)
	end,
}

local function make_state(string)
	local new = setmetatable({}, {
		__index = State
	})

	new.body = string
	new.pos = 0
	new.tree = {}
	new.treepos = new.tree

	return new
end

local function match_keyword(keyword)
	local len = #keyword

	return function(state)
		local possible = state:peek(len)

		if (possible == keyword) then
			state:eat(len)
			return true
		end
	end
end

local function match_chain(state, ...)
	local pos = state.pos
	local stepped = 0

	for i = 1, select("#", ...) do
		local matcher = select(i, ...)

		if (not matcher(state)) then
			--TODO: revert
			return false
		end
	end

	return true
end

local function match_any(state, ...)
	for i = 1, select("#", ...) do
		if (select(i, ...)(state)) then
			return true
		end
	end

	return false
end

local function match_maybe(matcher)
	return function(state)
		matcher(state)

		return true
	end
end

local match
match = {
	statement = function(state)
		return match_any(state,
			match.function_definition
		)
	end,

	spaces = function(state)
		local value = state:peek_pattern("[%s]+")

		if (not value or value == "") then
			return false
		end

		state:eat(#value)
		return true
	end,

	identifier = function(state)
		local accum = ""
		local has = false
		local value

		while (true) do
			if (has) then
				value = state:peek_pattern("[%w_]+")
			else
				value = state:peek_pattern("[%a_]+")
			end

			if (not value or value == "") then
				break
			end

			has = true

			accum = accum .. value
			state:eat(#value)
		end

		return has
	end,

	function_definition = function(state)
		return match_chain(state,
			match_keyword("function"),
			match.spaces,
			match.identifier,
			match_maybe(match.spaces)
		)
	end,

	function_call = function(state)
	end,
}

function Compiler.Parse(body)
	local state = make_state(body)
	print("statement", match.statement(state))

	return state
end

return Compiler