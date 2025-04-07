---@class Cell
---@field mine boolean
---@field clicked boolean
---@field number integer
---@field flag "f"|"?"|nil
local Cell = {}
Cell.__index = Cell

setmetatable(Cell, {
	__call = function(cls)
		return setmetatable({
			mine = false,
			clicked = false,
			number = 0,
			flag = nil,
		}, cls)
	end,
})

return Cell
