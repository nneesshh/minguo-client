--[[
    @brief  游戏玩家类
]]--
local GameHandCardNode = require("app.game.zjh.GameHandCardNode")
local GameOutCardNode  = require("app.game.zjh.GameOutCardNode")

local GamePlayerNode   = class("GamePlayerNode", app.base.BaseNodeEx)
local HERO_LOCAL_SEAT  = 1 

GamePlayerNode.clicks = {}

GamePlayerNode.touchs = {}

function GamePlayerNode:onClick(sender)
    GamePlayerNode.super.onClick(self, sender)
    local name = sender:getName()    
end

function GamePlayerNode:onTouch(sender, eventType)
    GamePlayerNode.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
    end
end

function GamePlayerNode:initData(localSeat)
    self._localSeat         = localSeat

    self._clockProgress     = nil
end

function GamePlayerNode:initUI(localSeat)
    self:initNodeHandCard(localSeat)
    self:initNodeOutCard(localSeat)
end

function GamePlayerNode:initNodeHandCard(localSeat)
    local nodeHandCard = self:seekChildByName("node_hand_card")
    self._gameHandCardNode = GameHandCardNode:create(self._presenter, nodeHandCard, localSeat)
end

function GamePlayerNode:initNodeOutCard(localSeat)
    local nodeOutCard = self:seekChildByName("node_out_card")
    self._gameOutCardNode = GameOutCardNode:create(self._presenter, nodeOutCard, localSeat)
end

-- 玩家进入
function GamePlayerNode:onPlayerEnter()    
    local player = app.game.PlayerData.getPlayerByLocalSeat(self._localSeat)

    -- 显示用户节点    
    self:showPnlPlayer(true)
    -- 设置姓名
    self:showTxtPlayerName(true, player:getNickname())
    -- 设置金币
    self:showTxtSR(true, player:getSR())
    -- 显示头像
    self:showImgFace(player:getSex(), player:getHead(), player:getHeadURL())
    -- 设置牌
    self._gameHandCardNode:resetHandCards()
    self._gameOutCardNode:resetOutCards()
end

-- 重置桌子
function GamePlayerNode:onResetTable()
    if self._localSeat == HERO_LOCAL_SEAT then
        self:onPlayerEnter()
    else
        self:onPlayerLeave()
    end
end

-- 玩家离开
function GamePlayerNode:onPlayerLeave()
    if self._localSeat ~= HERO_LOCAL_SEAT then
        self:showPnlPlayer(false)
    end
end

-- 玩家点击开始
function GamePlayerNode:onPlayerStart()
    -- 显示准备标志
    self:showImgReadyFlag(true)                                    
    -- 隐藏时钟
    self:showPnlClockCircle(false)
    -- 隐藏排名
    self:showPnlRank(false)
    -- 隐藏出牌
    self._gameOutCardNode:resetOutCards()
end

-- 开始游戏
function GamePlayerNode:onGameStart(time)
    
end

-- 发牌
function GamePlayerNode:onTakeFirst(cardID, cardNum)
    self._gameHandCardNode:onTakeFirst(cardID)
end

-- 显示用户节点    
function GamePlayerNode:showPnlPlayer(visible)
    self._rootNode:setVisible(visible)
end

-- 姓名
function GamePlayerNode:showTxtPlayerName(visible, nickName)
    local txtPlayerName = self:seekChildByName("txt_name")

    if visible then
        nickName = app.util.ToolUtils.nameToShort(nickName, 8)
        txtPlayerName:setString(nickName)
    end

    txtPlayerName:setVisible(visible)
end

-- 金币
function GamePlayerNode:showTxtSR(visible, balance)
    local txtBalance= self:seekChildByName("txt_balance")

    if txtBalance then
        if balance ~= nil then
            txtBalance:setString(app.util.ToolUtils.numConversionByDecimal(tostring(balance)))
        end
        txtBalance:setVisible(visible)
    end
end

-- 头像
function GamePlayerNode:showImgFace(sex, head, strHeadUrl)
    
end

function GamePlayerNode:getGameHandCardNode()
    return self._gameHandCardNode
end

function GamePlayerNode:getGameOutCardNode()
    return self._gameOutCardNode
end

return GamePlayerNode