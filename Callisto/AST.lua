local AST = {}

function AST.make(data)
	return data
end

function AST.operator(name)
	return AST.make {
		type = "operator",
		name = name,
		value = {}
	}
end

function AST.literal(sort, value)
	return AST.make {
		type = "literal",
		sort = sort,
		value = value
	}
end

function AST.identifier(name)
	return AST.make {
		type = "identifier",
		value = name
	}
end

function AST.block(sort, data)
	local base = {
		type = "block",
		sort = sort,
		value = value
	}

	if (data) then
		for key, value in pairs(data) do
			base[key] = value
		end
	end

	return AST.make(base)
end

return AST