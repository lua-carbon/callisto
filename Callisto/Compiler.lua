--[[
	Callisto Compiler 2.0.0
]]

local Callisto = (...)
local State = Callisto.State
local Match = Callisto.Match

local Compiler = {}

local KEYWORDS = {"if", "then", "else", "elseif", "end", "function", "while", "for", "do", "repeat", "until"}

local grammar
grammar = {
	statement = function(state)
		return Match.any(
				grammar.spaces,
				grammar.function_definition,
				grammar.function_call
			)(state)
	end,

	block = function(state)
		local start_depth = state.blockDepth

		while (true) do
			local value, key = Match.any(
				Match.keyword("end"),
				grammar.spaces,
				grammar.statement,
				grammar.ifthen,
				grammar.whiledo
			)(state)

			if (not value or value == "") then
				if (start_depth > 0) then
					return false
				else
					return true
				end
			end

			if (key == 1) then
				state:endBlock()
				if (state.blockDepth < start_depth) then
					return true
				end
			end
		end
	end,

	expression = function(state)
		return Match.any(
			grammar.identifier,
			grammar.string,
			grammar.number,
			grammar.constant,
			grammar.function_definition,
			grammar.function_call,
			Match.chain(
				Match.keyword("("),
				Match.maybe(grammar.spaces),
				grammar.expression,
				Match.maybe(grammar.spaces),
				Match.keyword(")")
			)
		)(state)
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
		return Match.any(
			Match.keyword("true"),
			Match.keyword("false"),
			Match.keyword("nil")
		)(state)
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
		return Match.chain(
			Match.keyword("function"),
			grammar.spaces,
			grammar.identifier,
			Match.maybe(grammar.spaces),
			grammar.idlist,
			State.startBlock,
			grammar.block
		)(state)
	end,

	function_call = function(state)
		return Match.chain(
			grammar.identifier,
			grammar.idlist
		)(state)
	end,

	ifthen = function(state)
		return Match.chain(
			Match.keyword("if"),
			Match.maybe(grammar.spaces),
			grammar.expression,
			Match.maybe(grammar.spaces),
			Match.keyword("then"),
			State.startBlock,
			grammar.block
		)(state)
	end,

	whiledo = function(state)
		return Match.chain(
			Match.keyword("while"),
			Match.maybe(grammar.spaces),
			grammar.expression,
			Match.maybe(grammar.spaces),
			Match.keyword("do"),
			State.startBlock,
			grammar.block
		)(state)
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
	print("statement", grammar.block(state))

	return state
end

return Compiler