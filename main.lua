local Grid = require("grid")
local Cell = require("cell")
local Queue = require("queue")
local textures = require("textures")
local conf = require("conf")
-- TODO: local Conf = require("conf")

---@param arg string[]
function love.load(arg)
	love.keyboard.setKeyRepeat(true)

	local difficulty = arg[1] or "medium"
	conf:init(difficulty)

	Game = {
		---@type Queue
		actionQueue = Queue(),
		---@type Grid  -- blank at first
		grid = Grid(),
		---@type integer
		flags = 0,
		---@type Pos
		cursor = {
			i = math.floor(conf.rows / 2),
			j = math.floor(conf.columns / 2),
		},
	}
end

---@param key string
function love.keypressed(key)
	Game.actionQueue:enqueue(key)
end

---@param dt number
function love.update(dt)
	local i, j = Game.cursor.i, Game.cursor.j

	local actionHandlers = {
		-- Vim motions
		["h"] = function()
			Game.cursor.j = Game.cursor.j - 1
		end,
		["j"] = function()
			Game.cursor.i = Game.cursor.i + 1
		end,
		["k"] = function()
			Game.cursor.i = Game.cursor.i - 1
		end,
		["l"] = function()
			Game.cursor.j = Game.cursor.j + 1
		end,
		-- TODO: add, w$, b0, uU, gG

		-- [d]etonate
		["d"] = function() -- TODO: refactor
			if Game.grid.blank then
				Game.grid:placeMines(Game.cursor)
				Game.grid[i][j].clicked = true
				Game.grid:floodFill(i, j)
			else
				Game.grid[i][j].clicked = true
				if Game.grid[i][j].mine then
					-- TODO: Game over screen (show whole map)
				elseif Game.grid[i][j].number == 0 then
					Game.grid:floodFill(i, j)
				end
			end
		end,
		-- flags: "f"|"?"
		["f"] = function()
			Game.flags = Game.flags + 1
			if Game.grid[i][j].flag == "f" then
				Game.grid[i][j].flag = nil
			else
				Game.grid[i][j].flag = "f"
			end
		end,
		["?"] = function()
			if Game.grid[i][j].flag == "?" then
				Game.grid[i][j].flag = nil
			else
				Game.grid[i][j].flag = "?"
			end
		end,
	}

	local action = Game.actionQueue:dequeue()
	if action ~= nil and actionHandlers[action] ~= nil then
		actionHandlers[action]()
	end

	-- Make sure cursor doesn't go out of bounds
	Game.cursor.i = math.min(Game.cursor.i, conf.rows)
	Game.cursor.j = math.min(Game.cursor.j, conf.columns)
	Game.cursor.i = math.max(Game.cursor.i, 1)
	Game.cursor.j = math.max(Game.cursor.j, 1)
end

function love.draw()
	for i = 1, conf.rows do
		for j = 1, conf.columns do
			local cell = Game.grid[i][j]
			local x = (j - 1) * 20
			local y = (i - 1) * 20
			local display = "#"
			if cell.clicked then
				if cell.mine then
					display = "M"
				elseif cell.number > 0 then
					display = tostring(cell.number)
				else
					display = " " -- Empty clicked cell
				end
			end
			love.graphics.print(display, x, y)
		end
	end

	-- Draw the cursor (highlighting the cell)
	if Game.cursor then
		local cx = (Game.cursor.j - 1) * 20
		local cy = (Game.cursor.i - 1) * 20
		love.graphics.rectangle("line", cx, cy, 20, 20)
	end
end
