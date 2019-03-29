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
end

-- 获取数字账号
function Player:getTicketID()
    return self._playerInfo.ticketid or 0
end

-- 玩家昵称
function Player:getNickname()
    return self._playerInfo.nickname or ""
end

-- 玩家头像
function Player:getAvatar()
    return self._playerInfo.avatar or "0"
end

-- 玩家性别
function Player:getGender()
    return self._playerInfo.gender or 1
end

-- 玩家金币
function Player:getBalance()
    return self._playerInfo.balance or 0
end

-- 玩家状态
function Player:getStatus()
    return self._playerInfo.status or 0
end

function Player:setStatus(status)
    self._playerInfo.status = status
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
    self._playerInfo.bet = bet
end

return Player