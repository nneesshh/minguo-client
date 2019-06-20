
--[[
    @brief  手牌
]]--
local GameCardNode            = requireJDNN("app.game.jdnn.GameCardNode")
local GameHandCardNode        = class("GameHandCardNode", app.base.BaseNodeEx)

local HAND_CARD_TYPE          = 0
local HAND_CARD_TYPE_NO_SELF  = 1

local HAND_CARD_SCALE         = 1
local HAND_CARD_SCALE_NO_SELF = 0.5

local HERO_LOCAL_SEAT         = 1

local CARD_NUM                = 5

function GameHandCardNode:initData(localSeat)
    self._localSeat         = localSeat

    self._gameCards         = {}
    
    self._selectBeginIndex  = nil
    self._selectEndIndex    = nil
    
    self._handCardCount     = 0
end

function GameHandCardNode:onTouchBegin(touch, event)
    local pos = touch:getLocation()   

    local indexTable = {}
    if self:isTouchOnTheCard(pos, indexTable) then
        self._selectBeginIndex = indexTable[1]
        self._selectEndIndex   = indexTable[1]

        self:onSelectTouchBeginCard()

        return true
    end

    self:downAllHandCards()    

    self._presenter:resetCalculatorNums()

    return false
end

function GameHandCardNode:onTouchMove(touch, event)

end

function GameHandCardNode:onTouchEnd(touch, event)
    local pos = touch:getLocation()

    local indexTable = {}
    if self:isTouchOnTheCard(pos, indexTable) then
        if indexTable[1] == self._selectBeginIndex then
            self._selectEndIndex = indexTable[1]
        end
    end

    if self._selectBeginIndex == self._selectEndIndex then
        local isUp = self._gameCards[self._selectBeginIndex]:getIsUp()
        if not isUp then
            local upCards = self:getUpHandCards()
            if #upCards >= 3 then
                self._gameCards[self._selectBeginIndex]:setIsSelect(false)
                return
            end
        end
    end

    self:onSelectTouchEndCard()        

    if self._selectBeginIndex == self._selectEndIndex then
        self._gameCards[self._selectBeginIndex]:onClickCard()
    end

    self._selectBeginIndex = nil
    self._selectEndIndex   = nil   

    -- app.util.SoundUtils.playSelectCardEffect()
end

function GameHandCardNode:isTouchOnTheCard(pos, indexTable)
    for i = #self._gameCards, 1, -1 do
        if self._gameCards[i]:isVisible() then
            local localPos = self._gameCards[i]:convertToNodeSpace(pos)
            if cc.rectContainsPoint(self._gameCards[i]:getPnlCard():getBoundingBox(), localPos) then
                indexTable[1] = i
                return true
            end
        end
    end
    return false
end

function GameHandCardNode:onSelectTouchBeginCard()
    if self._selectBeginIndex then
        self._gameCards[self._selectBeginIndex]:setIsSelect(true)
    end
end

function GameHandCardNode:downAllHandCards()
    for i = #self._gameCards, 1, -1 do
        if self._gameCards[i]:isVisible() then
            self._gameCards[i]:setIsSelect(false)
            self._gameCards[i]:setIsUpWithAction(false)
        end
    end
end

function GameHandCardNode:onSelectTouchEndCard()    
    if self._selectBeginIndex == self._selectEndIndex then
        local isUp = self._gameCards[self._selectBeginIndex]:getIsUp()

        if isUp then
            self._gameCards[self._selectBeginIndex]:setIsUpWithAction(false)
        else
            self._gameCards[self._selectBeginIndex]:setIsUpWithAction(true)            
        end
        self._gameCards[self._selectBeginIndex]:setIsSelect(false)
    end
end

function GameHandCardNode:getUpHandCards()
    local upHandCards = {}
    for i = 1, #self._gameCards do
        if self._gameCards[i]:getIsUp() and self._gameCards[i]:isVisible() then
            table.insert(upHandCards, self._gameCards[i]:getCardID())
        end
    end

    return upHandCards
end

function GameHandCardNode:setCardsUp(cards)
    self:downAllHandCards()

    for i = 1, #cards do
        local card = self:getDownNodeCardByID(cards[i])
        if card then
            card:setIsUpWithAction(true)
        end
    end
end

function GameHandCardNode:getDownNodeCardByID(id)
    for i = 1, #self._gameCards do
        if self._gameCards[i]:isVisible() and
            self._gameCards[i]:getCardID() == id and not self._gameCards[i]:getIsUp() then
            return self._gameCards[i]
        end
    end
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
function GameHandCardNode:createCards(cards, scale)    
    self:resetCards()    
    for i = 1, #cards do
        self._handCardCount = self._handCardCount + 1
    end

    for i = 1, #cards do
        if self._localSeat == HERO_LOCAL_SEAT then
            scale = scale or HAND_CARD_SCALE
            self:createCard(cards[i], scale, HAND_CARD_TYPE)
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
    self._handCardCount = 0
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
        end
    end    
end

function GameHandCardNode:setCardPosition()
    if self._gameCards then
        for i = 1, #self._gameCards do            
            self._gameCards[i]:setCardPosition()                     
        end
    end    
end

return GameHandCardNode