local Callisto = (...)

local Match = {}

function Match.keyword(keyword)
	local len = #keyword

	return function(state)
		local possible = state:peek(len)

		if (possible == keyword) then
			state:eat(len)
			return true
		end
	end
end

function Match.chain(...)
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

function Match.any(...)
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

function Match.maybe(matcher)
	return function(state)
		matcher(state)

		return true
	end
end

function Match.onePlus(matcher)
	return function(state)
		local value = matcher(state)

		if (not value) then
			return false
		end

		repeat
			value = matcher(state)
		until not value

		return true
	end
end

function Match.zeroPlus(matcher)
	return function(state)
		local value

		repeat
			value = matcher(state)
		until not value

		return true
	end
end

function Match.pattern(pattern)
	return function(state)
		local sub = state:peekPattern(pattern)

		if (sub and sub ~= "") then
			state:eat(#sub)
			return true
		end

		return false
	end
end

return Match