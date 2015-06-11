local Callisto = (...)
local TestUtil = Callisto.TestUtil

local settings = {}

local source = [=[
local obj = {
	v = 5,
	Bang! = function(self)
		return self.v
	end
}

Output.a = obj:Bang!()
]=]

local good_output = {
	a = 5
}

return TestUtil.MakeTest(source, settings, good_output)