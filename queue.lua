---@class Queue
---@field first integer
---@field last integer
local Queue = {}
Queue.__index = Queue
Queue.__call = function(cls)
	return setmetatable({ first = 1, last = 0 }, cls)
end
setmetatable(Queue, Queue)

---@param item any
function Queue:enqueue(item)
	self.last = self.last + 1
	self[self.last] = item
end

---@return any?
function Queue:dequeue()
	if self.first > self.last then
		return nil
	end
	local item = self[self.first]
	self[self.first] = nil
	self.first = self.first + 1
	return item
end

---@return boolean
function Queue:empty()
	return self.first > self.last
end

return Queue
