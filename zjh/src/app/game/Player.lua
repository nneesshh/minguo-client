--[[
@brief  游戏内玩家类
]]
local Player = class("Player")

function Player:ctor(playerInfo)
    self._playerInfo = {}
    self._playerInfo.ticketid     = playerInfo.ticketid     -- id    
    self._playerInfo.nickname     = playerInfo.nickname     -- 昵称
    self._playerInfo.avatar       = playerInfo.avatar       -- 头像
    self._playerInfo.gender       = playerInfo.gender       -- 性别
    self._playerInfo.balance      = playerInfo.balance      -- 财富数量(金币)
    self._playerInfo.status       = playerInfo.status       -- 状态
    self._playerInfo.seat         = playerInfo.seat         -- 座位号(服务端)
    self._playerInfo.bet          = playerInfo.bet          -- 下注
    self._playerInfo.isshow       = playerInfo.isshow       -- 是否已经看牌 
end

-- 获取数字账号
function Player:getTicketID()
    return self._playerInfo.ticketid or 0
end

-- 玩家昵称
function Player:getNickname()
    if self._playerInfo.nickname == "" then
        return "用户" .. self._playerInfo.ticketid           
    end
    
    return self._playerInfo.nickname
end

-- 玩家头像
function Player:getAvatar()
    local avatar = tonumber(self._playerInfo.avatar)    
    if avatar == nil or avatar < 0 or avatar > 5 then
        return 0
    end
    return avatar
end

-- 玩家性别
function Player:getGender()
    local gender = tonumber(self._playerInfo.gender)    
    if gender == nil or gender < 0 or gender > 1 then
        return 0
    end
    return gender
end

-- 玩家金币
function Player:setBalance(balance)
    self._playerInfo.balance = balance or 0
end

function Player:getBalance()
    return self._playerInfo.balance or 0
end

-- 玩家状态
-- 0 默认 1坐下 2准备 3游戏中 4等待 5弃牌 6失败 
function Player:getStatus()
    return self._playerInfo.status or 0
end

function Player:setStatus(status)
    self._playerInfo.status = status
end

function Player:isReady()
    return self._playerInfo.status == 2
end

function Player:isPlaying()
    return self._playerInfo.status == 3
end

function Player:isWaiting()
    return self._playerInfo.status == 4
end

function Player:isGiveup()
    return self._playerInfo.status == 5
end

function Player:isLeave()
    return self._playerInfo.status == 7 or self._playerInfo.status == 8 or self._playerInfo.status == 9
end

-- 玩家服务端座号
function Player:getSeat()
    return self._playerInfo.seat or -1
end

function Player:setSeat(seat)
    self._playerInfo.seat = seat
end

-- 玩家下注
function Player:getBet()
    return self._playerInfo.bet or 0
end

function Player:setBet(bet)
    self._playerInfo.bet = self._playerInfo.bet + bet
end

function Player:resetBet()
    self._playerInfo.bet = 0
end

-- 玩家是否已经看牌
function Player:getIsshow()
    return self._playerInfo.isshow == 1
end

function Player:setIsshow(isshow)
    self._playerInfo.isshow = isshow
end

return Player