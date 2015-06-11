local Callisto = require("Callisto")
local Tests = Callisto.Tests:FullyLoad()

for key, test in pairs(Tests) do
	if (type(test) == "table" and test.Run) then
		print("Test", key)
		local success, err = test.Run()

		if (success) then
			print("", "PASS")
		else
			print("", "FAIL:", err)
		end
	end
end