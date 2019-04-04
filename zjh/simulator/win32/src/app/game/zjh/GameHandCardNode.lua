
--[[
    @brief  手牌
]]--
local GameCardNode            = require("app.game.zjh.GameCardNode")
local GameHandCardNode        = class("GameHandCardNode", app.base.BaseNodeEx)

local HAND_CARD_TYPE          = 0
local HAND_CARD_TYPE_NO_SELF  = 1

local HAND_CARD_SCALE         = 0.6
local HAND_CARD_SCALE_NO_SELF = 0.4

local HERO_LOCAL_SEAT         = 1

local CARD_NUM                = 3

function GameHandCardNode:initData(localSeat)
    self._localSeat         = localSeat

    self._gameCards         = {}
    self._handCardCount     = 0
end

function GameHandCardNode:createCard(id, scale, type)
    if id == nil then
        return
    end

    local index = 1
    for i = 1, #self._gameCards do
        if self._gameCards[i]:isVisible() then
            index = index + 1
        else
            break
        end
    end

    if self._gameCards[index] then
        self._gameCards[index]:resetCard()
    else
        local gameCard = GameCardNode:create(self._presenter, self._localSeat, type)
        table.insert(self._gameCards, gameCard)

        self._rootNode:addChild(gameCard:getRootNode())
    end

    self._gameCards[index]:setCardID(id)
    self._gameCards[index]:setCardScale(scale)
    self._gameCards[index]:setCardIndex(index)
    self._gameCards[index]:setVisible(true)

    return self._gameCards[index]
end

function GameHandCardNode:resetHandCards()
    self._handCardCount = 0

    for i = 1, #self._gameCards do
        if self._gameCards[i]:isVisible() then
            self._gameCards[i]:resetCard()
        end
    end
end

-- 发牌
function GameHandCardNode:onTakeFirst(id)    
    self._handCardCount = CARD_NUM
    
    if self._localSeat == HERO_LOCAL_SEAT then
        local card = self:createCard(id, HAND_CARD_SCALE, HAND_CARD_TYPE)
        if card then
            card:playTakeFirstAction()
        end 
    else
        local card = self:createCard(id, HAND_CARD_SCALE_NO_SELF, HAND_CARD_TYPE_NO_SELF)
        if card then
            card:playTakeFirstAction()
        end              
    end
end

-- 创建手牌
function GameHandCardNode:createCards(cards)
    self:resetCards()    
    for i = 1, #cards do
        self._handCardCount = self._handCardCount + 1
    end

    for i = 1, #cards do
        if self._localSeat == HERO_LOCAL_SEAT then
            self:createCard(cards[i], HAND_CARD_SCALE, HAND_CARD_TYPE)
        else
            self:createCard(cards[i], HAND_CARD_SCALE_NO_SELF, HAND_CARD_TYPE_NO_SELF)
        end
    end
end

function GameHandCardNode:getHandCardCount()
    return self._handCardCount
end

function GameHandCardNode:resetCards()
    self:getRootNode():removeAllChildren()
    self._gameCards = {}
end

function GameHandCardNode:getCardID()
    if self._gameCards[1] then
        return self._gameCards[1]:getCardID()
    end    
end

function GameHandCardNode:setCardScale(scale)
    if self._gameCards then
        for i = 1, #self._gameCards do            
            self._gameCards[i]:setCardScale(scale)  
            
            if scale == HAND_CARD_SCALE then
                self._gameCards[i]:setCardPosition()
            elseif scale == HAND_CARD_SCALE_NO_SELF then
                self._gameCards[i]:setCardPositionEx()
            end         
        end
    end    
end

return GameHandCardNode