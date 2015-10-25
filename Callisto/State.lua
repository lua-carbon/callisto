local Callisto = (...)
local AST = Callisto.AST

local State = {
	pos = 1,
	blockDepth = 0,

	new = function(self, body)
		local new = setmetatable({
			posPending = {},
			body = body,
			tree = AST.block()
		}, {
			__index = self
		})

		new.treePos = {new.tree}

		return new
	end,

	navLeaf = function(self, leaf)
		table.insert(self.treePos, leaf)
	end,

	addLeaf = function(self, leaf, dive)
		local now = self.treePos[#self.treePos]

		table.insert(now.value, leaf)

		if (dive) then
			table.insert(self.treePos, leaf)
		end

		return #now.value
	end,

	removeLeaf = function(self, index)
		local now = self.treePos[#self.treePos]
		return table.remove(now.value, index)
	end,

	popLeaf = function(self)
		return table.remove(self.treePos)
	end,

	peek = function(self, count)
		count = count or 1

		return self.body:sub(self.pos, self.pos + count - 1)
	end,

	pop = function(self, count)
		count = count or 1

		local opos = self.pos
		self.pos = self.pos + count

		return self.body:sub(opos, opos + count - 1)
	end,

	eat = function(self, count)
		self.pos = self.pos + count
	end,

	peekPattern = function(self, pattern)
		return self.body:match("^" .. pattern, self.pos)
	end,

	pend = function(self)
		table.insert(self.posPending, self.pos)
	end,

	accept = function(self)
		table.remove(self.posPending)
	end,

	reject = function(self)
		self.pos = table.remove(self.posPending)
	end,

	startBlock = function(self)
		self.blockDepth = self.blockDepth + 1
		return true
	end,

	endBlock = function(self)
		self.blockDepth = self.blockDepth - 1
		return true
	end
}

return State