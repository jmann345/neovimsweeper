local conf = {} -- TODO: Add more conf options

---@param difficulty "easy"|"medium"|"hard"
function conf:init(difficulty)
	if difficulty == "easy" then
		self.rows = 9
		self.columns = 9
		self.mines = 10
	elseif difficulty == "medium" then
		self.rows = 16
		self.columns = 16
		self.mines = 40
	elseif difficulty == "hard" then
		self.rows = 16
		self.columns = 30
		self.mines = 99
	end
end

return conf
