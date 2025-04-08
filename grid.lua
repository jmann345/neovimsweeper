local conf = require("conf")
local Cell = require("cell")
local Queue = require("queue")

---@class Grid
---@field [integer] Cell[]  -- Each Grid[i] is a row of cells
---@field blank boolean
---@operator call: Grid
local Grid = {}
Grid.__index = Grid
Grid.__call = function(cls)
	local grid = setmetatable({}, cls)
	for i = 1, conf.rows do
		grid[i] = {}
		for j = 1, conf.columns do
			grid[i][j] = Cell()
		end
	end
	grid.blank = true

	return grid
end
setmetatable(Grid, Grid)

---@param pos Pos
---@return Pos[] neighbors
function Grid.getNeighbors(pos)
	local neighbors = {}
	for i = pos.i - 1, pos.i + 1 do
		for j = pos.j - 1, pos.j + 1 do
			local neighbor = not (i == pos.i and j == pos.j)
			local validCell = neighbor and (i > 0 and j > 0 and i <= conf.rows and j <= conf.columns)
			if validCell then
				table.insert(neighbors, { i = i, j = j })
			end
		end
	end
	return neighbors
end

---@param firstClickPos Pos
function Grid:placeMines(firstClickPos)
	---@type Pos[]
	local minePositions = {} -- Table to hold the unique pairs
	---@type table<string, boolean>
	local seen = {} -- Tracks which pairs have been generated

	-- Don't place mines at first click position and neighbors
	seen[firstClickPos.i .. "," .. firstClickPos.j] = true
	local firstClickNeighbors = self.getNeighbors(firstClickPos)
	for _, nb in ipairs(firstClickNeighbors) do
		seen[nb.i .. "," .. nb.j] = true
	end

	math.randomseed()
	while #minePositions < conf.mines do
		local i = math.random(1, conf.rows)
		local j = math.random(1, conf.columns)
		local key = i .. "," .. j -- Needed bc u cant compare tables

		if not seen[key] then
			seen[key] = true
			table.insert(minePositions, { i = i, j = j })
		end
	end

	for _, pos in ipairs(minePositions) do
		self[pos.i][pos.j].mine = true
	end

	for i = 1, conf.rows do
		for j = 1, conf.columns do
			if not self[i][j].mine then
				local neighbors = self.getNeighbors({ i = i, j = j })

				for _, nb in ipairs(neighbors) do
					if self[nb.i][nb.j].mine then
						self[i][j].number = self[i][j].number + 1
					end
				end
			end
		end
	end

	self.blank = false
end

---@param origin Pos
function Grid:floodFill(origin)
	local queue = Queue()
	queue:enqueue(origin)
	repeat
		local pos = queue:dequeue()
		local neighbors = self.getNeighbors(pos)
		for _, nb in ipairs(neighbors) do
			if not self[nb.i][nb.j].mine and not self[nb.i][nb.j].clicked then
				self[nb.i][nb.j].clicked = true

				if self[nb.i][nb.j].number == 0 then
					queue:enqueue({ i = nb.i, j = nb.j })
				end
			end
		end
	until queue:empty()
end

return Grid
