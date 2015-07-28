local lpeg = require("lpeg")
local V = lpeg.V
local P = lpeg.P

local space = lpeg.S(" \r\n\t")

-- {p}
local function zeromore(p)
	return p^0
end

-- [p]
local function maybe(p)
	return p^-1
end

local function kw(n)
	return space^0 * lpeg.P(n) * space^0
end

local function anyof(...)
	local res = select(1, ...)

	for i = 2, select("#", ...) do
		res = res + select(i, ...)
	end

	return res
end

local letters = lpeg.R("az", "AZ") + lpeg.P("_")
local lettersnumbers = letters + lpeg.R("09")
local Name = letters^1 * lettersnumbers^0

-- These string rules suck
local String = anyof(
	P("\"") * (P(1) - P("\"")) * P("\""),
	P("'") * (P(1) - P("'")) * P("'")
	-- Multiline string someday
)

local digits = lpeg.R("09")^1
local mpm = maybe(lpeg.S("+-"))
local dot = lpeg.P(".")
local exp = lpeg.S("eE")
local Number = mpm * digits * maybe(dot*digits) * maybe(exp*mpm*digits)

local luag = lpeg.P { "chunk",
	chunk = zeromore(lpeg.V("stat")) * maybe(kw(";")),
	block = V("chunk"),
	value = anyof(
		kw("nil"), kw("false"), kw("true"),
		Number, String,
		kw("..."),
		V("function"),
		V("tableconstructor"),
		V("functioncall"),
		V("var"),
		kw("(") * V("exp") * kw(")")
	),
	exp = anyof(
		V("unop") * V("exp"),
		V("value") * maybe(V("binop") * V("exp"))
	),
	prefix = anyof(
		kw("(") * V("exp") * kw(")"),
		Name
	),
	index = anyof(
		kw("[") * V("exp") * kw("]"),
		kw(".") * Name
	),
	call = anyof(
		V("args"),
		kw(":") * Name * V("args")
	),
	suffix = anyof(
		V("call"), V("index")
	),
	var = anyof(
		V("prefix") * zeromore(V("suffix")) * V("index"),
		Name
	),
	functioncall = V("prefix") * zeromore(space^0 * V("suffix") * space^0) * V("call"),
	stat = anyof(
		V("varlist") * kw("=") * V("explist"),
		V("functioncall"),
		kw("do") * V("block") * kw("end"),
		kw("while") * V("exp") * kw("do") * V("block") * kw("end"),
		kw("repeat") * V("block") * kw("until") * V("exp"),
		kw("if") * V("exp") * kw("then") * V("block") *
			zeromore(kw("elseif") * V("exp") * kw("then") * V("block")) *
			maybe(kw("else") * V("block"))
			* kw("end"),
		kw("for") * Name * kw("=") * V("exp") * kw(",") * V("exp") *
			maybe(kw(",") * V("exp")) * kw("do") * V("block") * kw("end"),
		kw("for") * V("namelist") * kw("in") * V("explist") * kw("do") * V("block") * kw("end"),
		kw("function") * V("funcname") * V("funcbody"),
		kw("local") * kw("function") * Name * V("funcbody"),
		kw("local") * V("namelist") * maybe(kw("=") * V("explist"))
	),
	laststat = anyof(
		kw("return") * maybe(V("explist")),
		kw("break")
	),
	funcname = Name * zeromore(kw(".") * Name) * maybe(kw(":") * Name),
	varlist = V("var") * zeromore(kw(",") * V("var")),
	namelist = Name * zeromore(kw(",") * Name),
	explist = zeromore(V("exp") * kw(",")) * V("exp"),
	args = anyof(
		kw("(") * maybe(V("explist")) * kw(")"),
		V("tableconstructor"),
		String
	),
	["function"] = kw("function") * V("funcbody"),
	funcbody = kw("(") * V("parlist") * kw(")") * V("block") * kw("end"),
	parlist = anyof(
		V("namelist") * maybe(kw(",") * kw("...")),
		kw("...")
	),
	tableconstructor = kw("{") * V("fieldlist") * kw("}"),
	fieldlist = V("field") * zeromore(V("fieldsep") * V("field")) * maybe(V("fieldsep")),
	field = anyof(
		kw("[") * V("exp") * kw("]") * kw("=") * V("exp"),
		Name * kw("=") * V("exp"),
		V("exp")
	),
	fieldsep = anyof(
		kw(","),
		kw(";")
	),
	binop = anyof(
		kw("+"), kw("-"), kw("*"), kw("/"), kw("^"), kw("%"), kw(".."),
		kw("<"), kw("<="), kw(">"), kw(">="), kw("=="), kw("~="),
		kw("and"), kw("or")
	),
	unop = anyof(
		kw("-"), kw("not"), kw("#")
	)
}

local prog = [=[
local x = 10
if (x > 5) then
	x = x + 5
	print(x)
end
]=]

local fin = luag:match(prog)

if (fin) then
	print("matched to", fin - 1)
	print(prog:sub(1, fin - 1))
else
	print("no match")
end