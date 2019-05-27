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
    print("playerdata is exit")
    _maxPlayerCnt  = nil
    _players       = nil
end

function PlayerData.getMaxPlayerCount()
    return _maxPlayerCnt
end

function PlayerData.getList()
    return _players
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

function PlayerData.onSelfPlayerInfo(seat)
    local info = {}
    info.ticketid     = app.data.UserData.getTicketID()    -- id    
    info.nickname     = app.data.UserData.getNickname()    -- 昵称
    info.avatar       = app.data.UserData.getAvatar()      -- 头像
    info.gender       = app.data.UserData.getGender()      -- 性别
    info.balance      = app.data.UserData.getBalance()     -- 财富数量(金币)
    info.status       = 0                                  -- 状态
    info.seat         = seat                               -- 座位号(服务端)
    info.bet          = 0                                  -- 下注(psz)/是否摊牌(nn)

    info.long         = 0                                  -- 龙
    info.hu           = 0                                  -- 虎
    info.he           = 0                                  -- 和
    info.area4        = 0                   

    info.bankermult   = -1                                 -- 抢庄倍数(nn)
    info.mult         = -1                                 -- 闲家倍数(nn)
    info.isshow       = 0                                  -- false
    
    PlayerData.addPlayer(info)
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

function PlayerData.getNumIDBySeat(seat)
    if not _players then return nil end
    for index, player in pairs(_players) do
        if player:getSeat() == seat then
            return player:getTicketID()
        end
    end
    return -1
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
        print("server seat error", serverSeat)  
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