-- Three in a row game
-- Author: Oleg K.
-- (c) 2019

-- ---------------
-- Headers Section
-- ---------------

color = require("color")
var_dump = require("var_dump")
-- logFile = io.open('game.log', 'w+')
require("string")

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

-- ---------------
-- Classes Section
-- ---------------

-- Cell class
Cell = {}
function Cell:new(gem)

    local cell = {}
        cell.gem = gem

    function cell:getCell()
        return {gem = self.gem} 
    end

    function cell:getGem()
        return self.gem
    end

    setmetatable(cell, self)
    self.__index = self; 
    return cell
end

-- Gem class
Gem = {}
function Gem:new(value)

    -- Params
    local map = {}
        map[-1] = "x"
        map[0] = "A"
        map[1] = "B"
        map[2] = "C"
        map[3] = "D"
        map[4] = "E"
        map[5] = "F"

    local colors = {}
        colors[-1] = color.fg.white
        colors[0] = color.fg.red
        colors[1] = color.fg.yellow
        colors[2] = color.fg.green
        colors[3] = color.fg.blue
        colors[4] = color.fg.pink
        colors[5] = color.fg.cyan

    local gem = {}
        gem.value = value

    -- Draw Gem
    function Gem:drawGem()
        return colors[self.value] .. map[self.value] .. color.fg.white
    end

    -- Get Gem Value
    function Gem:getGemValue()
        return self.value
    end

    -- Get Gem Name
    function Gem:getGemName()
        return map[self.value]
    end

    setmetatable(gem, self)
    self.__index = self
    return gem
end


-- Class Game board
Board = {}
function Board:new(size)

    -- Params
    local size = size
    local board = {}

    -- Init
    function board:Init()
        board:CreateBoard()
        board:Dump()

        local matches = board:FindMatches()
        while matches ~= 0 do
            board:RemoveMatches()
            board:StartGravity()
            matches = board:FindMatches()
        end
        board:Dump()

        board:FillBoard()
        board:Dump()

        local matches = board:FindMatches()
        io.write('Board is ready! Make your move! Use "m x y dir" (dir: l, r, u, d).\n')
        board:CheckForMoves()
    end

    -- Tick
    function board:Tick()
        io.write('**************GAME*TICK***************\n')

        local score = 0
        local matches = board:FindMatches()
        while matches ~= 0 do
            score = score + board:RemoveMatches()
            board:Dump()
            board:StartGravity()
            matches = board:FindMatches()
        end

        board:FillBoard()
        board:Dump()

        totalScore = totalScore + score

        io.write('Gems removed '..score..'!\n')
        board:CheckForMoves()
    end

    -- Check for Moves
    function board:CheckForMoves()
        if (board:AvaliableMoves() == 0) then
            io.write('No more moves! Type "s" to shuffle.\n')
        end
    end

    -- Make a move
    function board:Move(from, to) 
        local fromGem = Gem:new(board[from.y][from.x]:getGem():getGemValue())
        local toGem = Gem:new(board[to.y][to.x]:getGem():getGemValue())
    
        board[from.y][from.x] = Cell:new(toGem)
        board[to.y][to.x] = Cell:new(fromGem)
    end
    
    -- CreateBoard
    function board:CreateBoard()
        math.randomseed(os.time())
        for y = 0, size - 1 do
            local row = {}
            for x = 0, size - 1 do
                local newGem = Gem:new(math.random(0,5))
                local newCell = Cell:new(newGem)
                row[x] = newCell
            end
            board[y] = row
        end
    end

    -- FillBoard
    function board:FillBoard()
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                if board[y][x]:getGem():getGemValue() == -1 then

                    local newGem = Gem:new(math.random(0,5))
                    local isGemFits = false
                    repeat
                        newGem = Gem:new(math.random(0,5))
                        isGemFits = board:TryPutNewGem(y, x, newGem)
                    until isGemFits == true
    
                    local newCell = Cell:new(newGem)
                    board[y][x] = newCell

                end
            end
        end
    end

    -- Shuffle board
    function board:ShuffleBoard()
        math.randomseed(os.time())
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local fromGem = Gem:new(board[y][x]:getGem():getGemValue())
                local from = {}
                local to = {}
                local newX = math.random(0, size - 1)
                local newY = math.random(0, size - 1)

                local shuffleNum = 0
                local isGemFits = false
                repeat
                    newX = math.random(0, size - 1)
                    newY = math.random(0, size - 1)
                    local toGem = Gem:new(board[newY][newX]:getGem():getGemValue())
                    isGemFits = board:TryPutNewGem(newY, newX, fromGem) and board:TryPutNewGem(y, x, toGem)
                    shuffleNum = shuffleNum + 1
                    if shuffleNum >= 1000 then
                        break;
                    end
                until isGemFits == true
                
                from.x = newX
                from.y = newY
                to.x = x
                to.y = y
                
                board:Move(from, to)
            end
        end
    end

    -- AvaliableMoves
    function board:AvaliableMoves()
        local moves = 0
        local to = {}
        local from = {}
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                for direction = 0, 3 do
                    local isProperMove = false
                    from.x = x
                    from.y = y
                    -- Left
                    if direction == 0 and x > 0 then
                        to.x = x - 1
                        to.y = y
                        isProperMove = true
                    end
                     -- Right
                     if direction == 1 and x < size - 1 then
                        to.x = x + 1
                        to.y = y
                        isProperMove = true
                    end
                    -- Up
                    if direction == 2 and y > 0 then
                        to.x = x
                        to.y = y - 1
                        isProperMove = true
                    end
                    -- Down
                    if direction == 3 and y < size - 1 then
                        to.x = x
                        to.y = y + 1
                        isProperMove = true
                    end
                    if isProperMove == true then
                        moves = moves + board:TestMoveGem(from, to)
                        end
                end
                if moves > 0 then 
                    return moves
                end
            end
        end
        return moves
    end

    -- TestMoveGem
    function board:TestMoveGem(from, to)
        board:Move(from, to)
        local matches = board:FindMatches()
        board:Move(to, from)
        if matches > 0 then
            return 1
        end
        return 0
    end

    -- TryPutNewGem
    function board:TryPutNewGem(y, x, newGem)
        local sameGemsAround = 0
        for yi = y - 2, y + 2 do
            if yi >=0 and yi <= size - 1 and board[yi][x]:getGem():getGemValue() == newGem:getGemValue() then
                sameGemsAround = sameGemsAround + 1
            end
        end
        for xi = x - 2, x + 2 do
            if xi >= 0 and xi <= size - 1 and board[y][xi]:getGem():getGemValue() == newGem:getGemValue() then
                sameGemsAround = sameGemsAround + 1
            end
        end

        if sameGemsAround <= 1 then
            return true
        end
        return false
    end

    -- FindMatches
    function board:FindMatches()
        local matches = 0
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local result = board:FindCompleteLine(y, x)
                if result.count >= 3 and result.gemValue >= 0 then
                    matches = matches + result.count
                end
            end
        end
        return matches
    end
    
    -- RemoveMatches
    function board:RemoveMatches()
        local removedCount = 0
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local result = board:FindCompleteLine(y, x)
                if result.count >= 3 and result.gemValue >= 0 then
                    board:RemoveCompleteLine(y, x, result.count, result.direction)
                    removedCount = removedCount + result.count
                end
            end
        end
        return removedCount
    end

    -- StartGravity
    function board:StartGravity()
        for pass = 1, size do
            for y = size - 1, 1, -1 do
                for x = size - 1, 0, -1 do
                    if board[y][x]:getGem():getGemValue() == -1 and board[y-1][x]:getGem():getGemValue() ~= -1 then

                        local emptyGem = Gem:new(-1)
                        local epmtyCell = Cell:new(emptyGem)
                        
                        local fallGem = Gem:new(board[y-1][x]:getGem():getGemValue())
                        local fallCell = Cell:new(fallGem)

                        board[y][x] = fallCell
                        board[y-1][x] = epmtyCell
                    end
                end
            end
        end
    end

    -- RemoveCompleteLine
    function board:RemoveCompleteLine(y, x, count, direction)
        if direction == 'H' then
            local maxX = x + count - 1
            for xi = x, maxX do 
                local emptyGem = Gem:new(-1)
                local newCell = Cell:new(emptyGem)
                board[y][xi] = newCell
            end
        end
        if direction == 'V' then
            local maxY = y + count - 1
            for yi = y, maxY do 
                local emptyGem = Gem:new(-1)
                local newCell = Cell:new(emptyGem)
                board[yi][x] = newCell
            end
        end
    end

    -- CompleteLine
    function board:FindCompleteLine(y, x)
        local resultHorizontal = board:HorizontalMatches(y, x)
        if resultHorizontal >= 3 then
            return {
                count = resultHorizontal,
                direction = 'H',
                gemValue = board[y][x]:getGem():getGemValue()
            }
        end

        local resultVertical = board:VerticalMatches(y, x)
        if resultVertical >= 3 then
            return {
                count = resultVertical,
                direction = 'V',
                gemValue = board[y][x]:getGem():getGemValue()
            }
        end

        return {
            count = 0,
            direction = 'NONE',
            gemValue = nil
        }
    end

    -- HorizontalMatches
    function board:HorizontalMatches(y, x)
        local gemValue = board[y][x]:getGem():getGemValue()
        local result = {}
        local matches = 0
        local rightSide = ''

        if x < size - 1 then
            local xr = x
            while board[y][xr]:getGem():getGemValue() == gemValue and xr ~= size - 1 do
                rightSide = rightSide..' '..board[y][xr]:getGem():getGemName()
                matches = matches + 1
                if xr == size - 2 and board[y][size - 1]:getGem():getGemValue() == gemValue then
                    rightSide = rightSide..' '..board[y][size - 1]:getGem():getGemName()
                    matches = matches + 1
                end
                xr = xr + 1
            end 
        end
        return matches
    end

    -- VerticalMatches
    function board:VerticalMatches(y, x)
        local gemValue = board[y][x]:getGem():getGemValue()
        local result = {}
        local matches = 0
        local downSide = ''

        if y < size - 1 then
            local yd = y
            while board[yd][x]:getGem():getGemValue() == gemValue and yd ~= size - 1 do
                downSide = downSide..' '..board[yd][x]:getGem():getGemName()
                matches = matches + 1
                if yd == size - 2 and board[size - 1][x]:getGem():getGemValue() == gemValue then
                    downSide = downSide..' '..board[size - 1][x]:getGem():getGemName()
                    matches = matches + 1
                end
                yd = yd + 1
            end 
        end
        return matches
    end

    -- Dump
    function board:Dump()
        io.write('=================================\n')
        io.write(' X=> ')
        for x = 0, size - 1 do 
            io.write('-' .. x .. '-')
        end
        io.write('\n')
        for y = 0, size - 1 do
            io.write('-Y=' .. y .. '-')
            for x = 0, size - 1 do 
                io.write(' ' .. board[y][x]:getGem():drawGem() .. ' ')
            end
            io.write('\n')
        end
    end

    setmetatable(board, self)
    self.__index = self
    return board
end

-- ---------------
-- Global Section
-- ---------------

function Init()
    boardSize = 10
    totalScore = 0
    os.execute("cls")
    io.write("=== MATCH 3 GAME! By Oleg K. ===\n")
    gameBoard = Board:new(boardSize)
    gameBoard:Init()
end 

function ExecCommand(cmd)
    if cmd[1] == 'q' then 
        return
    end

    if cmd[1] == 's' then
        gameBoard:ShuffleBoard()
        gameBoard:Dump()
        io.write('Board shuffled.\n')
        gameBoard:CheckForMoves()
        return
    end

    if cmd[1] == 'm' and cmd[2] ~= '' and cmd[3] ~= '' and cmd[4] ~= '' then
        local inputError = false
        local x = tonumber(cmd[2])
        local y = tonumber(cmd[3])
        local direction = cmd[4]
        if x < 0 or x > boardSize - 1 or y < 0 or y > boardSize - 1 or (direction ~= 'l' and direction ~= 'r' and direction ~= 'u' and direction ~= 'd') then
            inputError = true
        end

        local from = {}
        local to = {}
        from.y = y
        from.x = x

        local moveError = false

        if direction == 'l' then
            if x - 1 < 0 then
                moveError = true
            end
            if x - 1 >= 0 then
                to.x = x - 1
                to.y = y
            end
        end

        if direction == 'r' then
            if x + 1 > boardSize - 1 then
                moveError = true
            end
            if x + 1 <= boardSize - 1 then
                to.x = x + 1
                to.y = y
            end
        end

        if direction == 'u' then
            if y - 1 < 0 then
                moveError = true
            end
            if y - 1 >= 0 then
                to.x = x 
                to.y = y - 1
            end
        end

        if direction == 'd' then
            if y + 1 > boardSize - 1 then
                moveError = true
            end
            if y + 1 <= boardSize - 1 then
                to.x = x
                to.y = y + 1
            end
        end

        if moveError == true then
            io.write('Move error! No place to move.\n')
            return
        end

        if moveError == false and inputError == false then
            gameBoard:Move(from, to)
            matches = gameBoard:FindMatches()
            if matches == 0 then
                gameBoard:Move(to, from)
                io.write('No matches.\n')
            end
            if matches > 0 then
                gameBoard:Dump()
                gameBoard:Tick()
            end
            return
        end

        if inputError == true then
            io.write('Command format error! Use "m x y dir" (x, y: min: 0, max: '..(boardSize - 1)..'), (dir: l-eft, r-ight, u-p, d-own) or "q" to quit.\n')
            return
        end
    end

    io.write('Wrong command! Use "m x y dir" (x, y: min: 0, max: '..(boardSize - 1)..'), (dir: l-eft, r-ight, u-p, d-own) or "q" to quit.\n')
    return
end

-- ---------------
-- Main Chunk Section
-- ---------------

local cmd
Init()
repeat
    io.write("Enter command: ")
    io.flush()
    cmd = io.read():split(" ")
    ExecCommand(cmd)
until cmd[1] == 'q'
io.write("Game Over!\n")
io.write("Total score = "..totalScore.."\n")
