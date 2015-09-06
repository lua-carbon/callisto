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
				grammar.whiledo,
				grammar.fordo,
				grammar.forindo,
				grammar.elseblock,
				grammar.elseifblock
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
		return Match.chain(
			Match.maybe(grammar.spaces),
			Match.any(
				grammar.function_definition,
				grammar.function_call,
				grammar.identifier,
				grammar.string,
				grammar.number,
				grammar.constant,
				grammar.table,
				Match.chain(
					Match.keyword("("),
					Match.maybe(grammar.spaces),
					grammar.expression,
					Match.maybe(grammar.spaces),
					Match.keyword(")")
				)
			),
			Match.maybe(grammar.spaces)
		)(state)
	end,

	-- Match a comma-separated list of expressions
	explist = function(state)
		return Match.chain(
			grammar.expression,
			Match.zeroPlus(
				Match.chain(
					Match.keyword(","),
					grammar.expression
				)
			)
		)(state)
	end,

	-- Match a comma-separated list of identifiers
	idlist = function(state)
		return Match.chain(
			grammar.identifier,
			Match.zeroPlus(
				Match.chain(
					Match.maybe(grammar.spaces),
					Match.keyword(","),
					Match.maybe(grammar.spaces),
					grammar.identifier
				)
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
		local digits = Match.pattern("%d+")
		local exp = Match.any("e", "E")
		local mpm = Match.maybe(Match.any("+", "-"))

		return Match.chain(
			mpm,
			digits,
			Match.maybe(Match.chain(
				Match.keyword("."),
				digits
			)),
			Match.maybe(Match.chain(
				exp,
				mpm,
				digits
			))
		)(state)
	end,

	string = function(state)
		--TODO
	end,

	table = function(state)
		--TODO: actual implementation
		return grammar.braced(state)
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

	-- Matches balanced braces
	braced = function(state)
		local value = state:peekPattern("%{")

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

			if (value == "}") then
				depth = depth + 1
			elseif (value == ")") then
				if (depth <= 0) then
					break
				end
			end
		end

		return true
	end,

	-- Matches balanced parens
	parenthed = function(state)
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
			grammar.parenthed,
			State.startBlock,
			grammar.block
		)(state)
	end,

	function_call = function(state)
		return Match.chain(
			grammar.identifier,
			grammar.parenthed
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

	elseblock = function(state)
		return Match.chain(
			Match.maybe(grammar.spaces),
			Match.keyword("else"),
			Match.nope("if"),
			Match.maybe(grammar.spaces)
		)(state)
	end,

	elseifblock = function(state)
		return Match.chain(
			Match.keyword("elseif"),
			Match.maybe(grammar.spaces),
			grammar.expression,
			Match.maybe(grammar.spaces),
			Match.keyword("then")
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
		return Match.chain(
			Match.keyword("for"),
			Match.maybe(grammar.spaces),
			grammar.identifier,
			Match.maybe(grammar.spaces),
			Match.keyword("="),
			grammar.expression,
			Match.keyword(","),
			grammar.expression,
			Match.maybe(
				Match.chain(
					Match.keyword(","),
					grammar.expression
				)
			),
			Match.maybe(grammar.spaces),
			Match.keyword("do"),
			State.startBlock,
			grammar.block
		)(state)
	end,

	forindo = function(state)
		return Match.chain(
			"for",
			Match.maybe(grammar.spaces),
			grammar.idlist,
			Match.maybe(grammar.spaces),
			"in",
			Match.maybe(grammar.spaces),
			grammar.expression,
			"do",
			State.startBlock,
			grammar.block
		)(state)
	end
}

-- Debug tracing
-- for key, value in pairs(grammar) do
-- 	grammar[key] = function(...)
-- 		print("grammar", key)
-- 		return value(...)
-- 	end
-- end

function Compiler.parse(body)
	local state = State:new(body)
	grammar.block(state)

	return state
end

return Compiler