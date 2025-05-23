local Grid = require("grid")
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
	local shiftChars = {
		["1"] = "!",
		["2"] = "@",
		["3"] = "#",
		["4"] = "$",
		["5"] = "%",
		["6"] = "^",
		["7"] = "&",
		["8"] = "*",
		["9"] = "(",
		["0"] = ")",
		["-"] = "_",
		["="] = "+",
		["["] = "{",
		["]"] = "}",
		["\\"] = "|",
		[";"] = ":",
		["'"] = '"',
		[","] = "<",
		["."] = ">",
		["/"] = "?",
		["`"] = "~",
	}
	local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
	if shift and shiftChars[key] then
		Game.actionQueue:enqueue(shiftChars[key])
	elseif shift and #key == 1 and key:match("%a") then
		Game.actionQueue:enqueue(string.upper(key))
	else
		Game.actionQueue:enqueue(key)
	end
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
		-- For w[right], b[left], u[up], and g[down] motions,
		-- We move the cursor from an 'unclicked' cell to the next 'clicked' cell
		-- Or vice versa. If nothing found, these function the same as 0/$/U/G
		-- NOTE: Moves a minimum of two cells
		["w"] = function()
			local cursorClicked = Game.grid[i][j].clicked
			for nj = j + 2, conf.columns do
				if cursorClicked ~= Game.grid[i][nj].clicked then
					Game.cursor.j = nj
					return
				end
			end
			Game.cursor.j = conf.columns
		end,
		["b"] = function()
			local cursorClicked = Game.grid[i][j].clicked
			for nj = j - 2, 1, -1 do
				if cursorClicked ~= Game.grid[i][nj].clicked then
					Game.cursor.j = nj
					return
				end
			end
			Game.cursor.j = 1
		end,
		["u"] = function()
			local cursorClicked = Game.grid[i][j].clicked
			for ni = i - 2, 1, -1 do
				if cursorClicked ~= Game.grid[ni][j].clicked then
					Game.cursor.i = ni
					return
				end
			end
			Game.cursor.i = 1
		end,
		["g"] = function()
			local cursorClicked = Game.grid[i][j].clicked
			for ni = i + 2, conf.rows do
				if cursorClicked ~= Game.grid[ni][j].clicked then
					Game.cursor.i = ni
					return
				end
			end
			Game.cursor.i = conf.rows
		end,
		-- Top/bot/farleft/farright
		["0"] = function()
			Game.cursor.j = 1
		end,
		["$"] = function()
			Game.cursor.j = conf.columns
		end,
		["U"] = function()
			Game.cursor.i = 1
		end,
		["G"] = function()
			Game.cursor.i = conf.rows
		end,

		-- [d]etonate
		["d"] = function() -- TODO: refactor
			if Game.grid[i][j].flag then
				return
			end
			if Game.grid.blank then
				Game.grid:placeMines(Game.cursor)
				Game.grid[i][j].clicked = true
				Game.grid:floodFill(Game.cursor)
			else
				Game.grid[i][j].clicked = true
				if Game.grid[i][j].mine then
					-- TODO: Game over screen (show whole map)
				elseif Game.grid[i][j].number == 0 then
					Game.grid:floodFill(Game.cursor)
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

-- TODO: Full implementation w/ textures
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
			elseif cell.flag ~= nil then
				display = cell.flag
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
