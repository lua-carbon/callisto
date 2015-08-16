--[[
	Callisto Compiler 2.0.0
]]

local Callisto = (...)
local State = Callisto.State

local Compiler = {}

local KEYWORDS = {"if", "then", "else", "elseif", "end", "function", "while", "for", "do", "repeat", "until"}

local util = {
	start_block = function(state)
		state.blockDepth = state.blockDepth + 1
		return true
	end,

	end_block = function(state)
		state.blockDepth = state.blockDepth - 1
		return true
	end
}

local function make_match_keyword(keyword)
	local len = #keyword

	return function(state)
		local possible = state:peek(len)

		if (possible == keyword) then
			state:eat(len)
			return true
		end
	end
end

local function make_match_chain(...)
	local matchers = {...}

	return function(state)
		state:pend()

		for i = 1, #matchers do
			if (not matchers[i](state)) then
				state:reject()
				return false
			end
		end

		state:accept()

		return true
	end
end

local function match_chain(state, ...)
	return make_match_chain(...)(state)
end

local function make_match_any(...)
	local matchers = {...}

	return function(state)
		for i = 1, #matchers do
			if (matchers[i](state)) then
				return true, i
			end
		end

		return false
	end
end

local function match_any(state, ...)
	return make_match_any(...)(state)
end

local function make_match_maybe(matcher)
	return function(state)
		matcher(state)

		return true
	end
end

local function match_oneplus(state, matcher)
	local value = matcher(state)

	if (not value) then
		return false
	end

	repeat
		value = matcher(state)
	until not value

	return true
end

local function match_zeroplus(state, matcher)
	local value

	repeat
		value = matcher(state)
	until not value

	return true
end

local match
match = {
	statement = function(state)
		return match_any(state,
				match.spaces,
				match.function_definition,
				match.function_call
			)
	end,

	block = function(state)
		local start_depth = state.blockDepth

		while (true) do
			local value, key = match_any(state,
				make_match_keyword("end"),
				match.spaces,
				match.statement,
				match.ifthen,
				match.whiledo
			)

			if (not value or value == "") then
				if (start_depth > 0) then
					return false
				else
					return true
				end
			end

			if (key == 1) then
				util.end_block(state)
				if (state.blockDepth < start_depth) then
					return true
				end
			end
		end
	end,

	expression = function(state)
		return match_any(state,
			match.identifier,
			match.string,
			match.number,
			match.constant,
			match.function_definition,
			match.function_call,
			make_match_chain(
				make_match_keyword("("),
				make_match_maybe(match.spaces),
				match.expression,
				make_match_maybe(match.spaces),
				make_match_keyword(")")
			)
		)
	end,

	spaces = function(state)
		local value = state:peekPattern("[%s]+")

		if (not value or value == "") then
			return false
		end

		state:eat(#value)
		return true
	end,

	constant = function(state)
		return match_any(state,
			make_match_keyword("true"),
			make_match_keyword("false"),
			make_match_keyword("nil")
		)
	end,

	number = function(state)
		--TODO
	end,

	string = function(state)
		--TODO
	end,

	identifier = function(state)
		local accum = ""
		local has = false
		local value

		while (true) do
			if (has) then
				value = state:peekPattern("[%w_]+")
			else
				value = state:peekPattern("[%a_]+")
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

	idlist = function(state)
		local value = state:peekPattern("%(")

		if (not value or value == "") then
			return false
		end

		state:eat(1)

		local depth = 0
		while (true) do
			value = state:pop(1)

			if (not value or value == "") then
				return false
			end

			if (value == "(") then
				depth = depth + 1
			elseif (value == ")") then
				if (depth <= 0) then
					break
				end
			end
		end

		return true
	end,

	function_definition = function(state)
		return match_chain(state,
			make_match_keyword("function"),
			match.spaces,
			match.identifier,
			make_match_maybe(match.spaces),
			match.idlist,
			util.start_block,
			match.block
		)
	end,

	function_call = function(state)
		return match_chain(state,
			match.identifier,
			match.idlist
		)
	end,

	ifthen = function(state)
		return match_chain(state,
			make_match_keyword("if"),
			make_match_maybe(match.spaces),
			match.expression,
			make_match_maybe(match.spaces),
			make_match_keyword("then"),
			util.start_block,
			match.block
		)
	end,

	whiledo = function(state)
		return match_chain(state,
			make_match_keyword("while"),
			make_match_maybe(match.spaces),
			match.expression,
			make_match_maybe(match.spaces),
			make_match_keyword("do"),
			util.start_block,
			match.block
		)
	end,

	fordo = function(state)
		--TODO
	end,

	forindo = function(state)
		--TODO
	end
}

function Compiler.Parse(body)
	local state = State:new(body)
	print("statement", match.block(state))

	return state
end

return Compiler