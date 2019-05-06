--[[
@brief  游戏玩家数据
]]

local PlayerData = {}

local HERO_LOCAL_SEAT   = 1

local _maxPlayerCnt     = nil
local _players          = nil

function PlayerData.init(maxPlayerCnt)
    _maxPlayerCnt  = maxPlayerCnt
    _players       = {}
end

function PlayerData.resetPlayerCount(maxPlayerCnt)
    _maxPlayerCnt  = maxPlayerCnt
end

function PlayerData.exit()
    _maxPlayerCnt  = nil
    _players       = nil
end

function PlayerData.getMaxPlayerCount()
    return _maxPlayerCnt
end

function PlayerData.getPlayerCount()
    local count = 0
    for index, player in pairs(_players) do
        count = count + 1
    end
    return count
end

function PlayerData.onPlayerInfo(playerInfo)
    PlayerData.addPlayer(playerInfo)
end

function PlayerData.onPlayerLeave(numID)
    if PlayerData.isHero(numID) then
        PlayerData.delOtherPlayers()
    else
        PlayerData.delPlayerByNumID(numID)
    end
end

-- 添加Player
function PlayerData.addPlayer(playerInfo)
    if not _players then return nil end
    for index, player in pairs(_players) do
        if player:getTicketID() == playerInfo.ticketid then                
            _players[index] = nil
        end
    end
    if PlayerData.isHero(playerInfo.ticketid) then
        app.data.UserData.setBalance(playerInfo.balance)        
    end
    table.insert(_players, app.game.Player.new(playerInfo))
end

-- 更新玩家财富
function PlayerData.updatePlayerRiches(playerSeat, playerBet, playerBalance)
    local player = PlayerData.getPlayerByServerSeat(playerSeat)
    if player then
        if playerBet then
            player:setBet(playerBet)
        end
        if playerBalance then
            player:setBalance(playerBalance)  
            if PlayerData.getHeroSeat() == playerSeat then
                app.data.UserData.setBalance(playerBalance)        
            end  
        end           
    end
end

-- 更新玩家财富
function PlayerData.reducePlayerRiches(playerSeat, playerBalance)
    local player = PlayerData.getPlayerByServerSeat(playerSeat)
    if player then
        local balance = player:getBalance() or 0  
        player:setBalance(balance - playerBalance)
        return balance - playerBalance   
    end
end

-- 更新玩家状态
function PlayerData.updatePlayerStatus(playerSeat, status)
    local player = PlayerData.getPlayerByServerSeat(playerSeat)
    if player then
        player:setStatus(status)       
    end
end

function PlayerData.updatePlayerIsshow(playerSeat, isshow)
    local player = PlayerData.getPlayerByServerSeat(playerSeat)
    if player then
        player:setIsshow(isshow)       
    end
end

function PlayerData.resetPlayerBet(playerSeat)
    local player = PlayerData.getPlayerByServerSeat(playerSeat)
    if player then       
        player:resetBet(0)   
    end
end

-- 删除Player
function PlayerData.delPlayerByNumID(numID)
    if not _players then return nil end
    for index, player in pairs(_players) do
        if player:getTicketID() == numID then
            _players[index] = nil
            return true
        end
    end
    return false
end

-- 删除除自己外其他玩家
function PlayerData.delOtherPlayers()
    if not _players then return nil end
    for index, player in pairs(_players) do
        if player:getTicketID() ~= app.data.UserData.getTicketID() then
            _players[index] = nil
        end
    end
end

-- 获取Player
function PlayerData.getPlayerByNumID(numID)
    if not _players then return nil end
    
    for index, player in pairs(_players) do
        if player:getTicketID() == numID then
            return player
        end
    end
         
    return nil
end

-- 获取Player
function PlayerData.getPlayerByServerSeat(serverSeat)
    if not _players then return nil end
    for index, player in pairs(_players) do
        if player:getSeat() == serverSeat then
            return player
        end
    end
    return nil
end

-- 获取Player
function PlayerData.getPlayerByLocalSeat(localSeat)
    local serverSeat = PlayerData.localSeatToServerSeat(localSeat)
    return PlayerData.getPlayerByServerSeat(serverSeat)
end

-- 判断是否是自己
function PlayerData.isHero(numID)
    return app.data.UserData.getTicketID() == numID
end

function PlayerData.getHeroSeat()
    if not _players then return nil end
    for index, player in pairs(_players) do
        if PlayerData.isHero(player:getTicketID()) then
            return player:getSeat()
        end
    end
    return nil
end

function PlayerData.getHero()
    if not _players then return nil end
    for index, player in pairs(_players) do
        if PlayerData.isHero(player:getTicketID()) then
            return player
        end
    end
    return nil
end

function PlayerData.localSeatToServerSeat(localSeat)
    if localSeat == nil or _maxPlayerCnt == nil  or localSeat < 0 or localSeat >= _maxPlayerCnt then
        print("local seat 非法") 
        return -1
    end

    local heroSeat = PlayerData.getHeroSeat()
    if heroSeat == nil then
         return -1
    end
    local seat = (localSeat - HERO_LOCAL_SEAT + _maxPlayerCnt) % _maxPlayerCnt
    return (seat + heroSeat) % _maxPlayerCnt
end

function PlayerData.serverSeatToLocalSeat(serverSeat)
    if serverSeat == nil or _maxPlayerCnt == nil or serverSeat < 0 or serverSeat >= _maxPlayerCnt then
        print("server seat error") 
        return -1
    end

    local heroSeat = PlayerData.getHeroSeat()
    if heroSeat == nil then
        print("heroseat is nil")
        return -1 
    end
    
    local seat = (serverSeat - heroSeat + _maxPlayerCnt) % _maxPlayerCnt
    return (seat + HERO_LOCAL_SEAT) % _maxPlayerCnt
end

return PlayerData