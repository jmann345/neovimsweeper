local conf = require("conf")
local Cell = require("cell")
local Queue = require("queue")

---@type Cell[][]
---@class Grid
---@field [any] any
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

---@param r integer
---@param c integer
---@return table<integer, integer>[] neighbors
function Grid.getNeighbors(r, c)
	local neighbors = {}
	for i = r - 1, r + 1 do
		for j = c - 1, c + 1 do
			local neighbor = not (i == r and j == c)
			local validCell = neighbor and (i > 0 and j > 0 and i <= conf.rows and j <= conf.columns)
			if validCell then
				table.insert(neighbors, { i, j })
			end
		end
	end
	return neighbors
end

---@param firstClickPos Pos
function Grid:placeMines(firstClickPos)
	local pairs = {} -- Table to hold the unique pairs
	local seen = {} -- Tracks which pairs have been generated

	-- Don't place mines at first click position and neighbors
	seen[firstClickPos.i .. "," .. firstClickPos.j] = true
	local firstClickNeighbors = self.getNeighbors(firstClickPos.i, firstClickPos.j)
	for _, nb in ipairs(firstClickNeighbors) do
		local ni, nj = nb[1], nb[2]
		seen[ni .. "," .. nj] = true
	end

	while #pairs < conf.mines do
		math.randomseed()
		local i = math.random(1, conf.rows)
		local j = math.random(1, conf.columns)
		local key = i .. "," .. j -- Needed bc u cant compare tables

		if not seen[key] then
			seen[key] = true
			table.insert(pairs, { i, j })
		end
	end

	for _, value in ipairs(pairs) do
		local i, j = value[1], value[2]
		self[i][j].mine = true
	end

	for i = 1, conf.rows do
		for j = 1, conf.columns do
			if not self[i][j].mine then
				local neighbors = self.getNeighbors(i, j)
				for _, nb in ipairs(neighbors) do
					local ni, nj = nb[1], nb[2]

					if self[ni][nj].mine then
						self[i][j].number = self[i][j].number + 1
					end
				end
			end
		end
	end

	self.blank = false
end

---@param r integer
---@param c integer
function Grid:floodFill(r, c)
	local queue = Queue()
	queue:enqueue({ r, c })

	repeat
		local pos = queue:dequeue()
		local i, j = pos[1], pos[2]

		local neighbors = self.getNeighbors(i, j)
		for _, nb in ipairs(neighbors) do
			local ni, nj = nb[1], nb[2]
			if not self[ni][nj].mine and not self[ni][nj].clicked then
				self[ni][nj].clicked = true

				if self[ni][nj].number == 0 then
					queue:enqueue({ ni, nj })
				end
			end
		end
	until queue:empty()
end

return Grid
