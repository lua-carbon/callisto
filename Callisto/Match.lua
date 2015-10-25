local Callisto = (...)

local Match = {}

function Match.astUnblock(data, bound)
	return function(state)
		local last = state:popLeaf()
		local id = state:addLeaf(data, true)
		local result = bound(state)

		if (not result) then
			state:popLeaf()
			state:removeLeaf(id)
			state:navLeaf(last)
		end

		return result
	end
end

function Match.astBlock(data, bound)
	return function(state)
		local id = state:addLeaf(data, true)
		local result = bound(state)

		if (not result) then
			state:popLeaf()
			state:removeLeaf(id)
		end

		return result
	end
end

function Match.ast(data, bound)
	return function(state)
		local id = state:addLeaf(data)
		local result = bound(state)

		if (not result) then
			state:removeLeaf(id)
		end

		return result
	end
end

function Match.ensure(item)
	if (type(item) == "function") then
		return item
	elseif (type(item) == "string") then
		return Match.keyword(item)
	else
		return item
	end
end

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

function Match.nope(matcher)
	matcher = Match.ensure(matcher)

	return function(state)
		state:pend()

		if (matcher(state)) then
			state:reject()
			return false
		end

		state:accept()
		return true
	end
end

function Match.chain(...)
	local matchers = {...}

	return function(state)
		state:pend()

		for i = 1, #matchers do
			local matcher = Match.ensure(matchers[i])

			if (not matcher(state)) then
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
			local matcher = Match.ensure(matchers[i])
			local val = matcher(state)

			if (val) then
				return true, i
			end
		end

		return false
	end
end

function Match.maybe(matcher)
	matcher = Match.ensure(matcher)

	return function(state)
		matcher(state)

		return true
	end
end

function Match.onePlus(matcher)
	matcher = Match.ensure(matcher)

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
	matcher = Match.ensure(matcher)

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