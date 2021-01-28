--[[
    @brief  游戏手牌UI类
]]--
local app = cc.exports.gEnv.app
local requireDDZ = cc.exports.gEnv.HotpatchRequire.requireDDZ

local GameCardNode        = requireDDZ("app.game.ddz.GameCardNode")
local GameHandCardNode    = class("GameHandCardNode", app.base.BaseNodeEx)

local HAND_CARD_TYPE          = 0
local HAND_CARD_TYPE_NO_SELF  = 1

local HAND_CARD_SCALE         = 0.8
local HAND_CARD_SCALE_NO_SELF = 0.4

local CARD_NUM                = 17
local HERO_LOCAL_SEAT         = 1
local CV_BACK                 = app.game.CardRule.cards.CV_BACK 

function GameHandCardNode:initData(localSeat)
    self._localSeat               = localSeat

    self._gameCards               = {}

    self._selectBeginIndex        = nil
    self._selectEndIndex          = nil
    self._handCardCount           = 0

    self._lastUpCards             = {}
end

function GameHandCardNode:onTouchBegin(touch, event)
    local pos = touch:getLocation()

    if not self:isCanTouchCard() then
        return false
    end

    local indexTable = {}
    if self:isTouchOnTheCard(pos, indexTable) then
        self._selectBeginIndex = indexTable[1]
        self._selectEndIndex   = indexTable[1]

        self:onSelectTouchBeginCard()

        return true
    end

    self:downAllHandCards()
    self._presenter:setStartHintIndex(1)

    self:checkOutBtnEnable()

    return false
end

function GameHandCardNode:onTouchMove(touch, event)
    local pos = touch:getLocation()

    if not self:isCanTouchCard() then
        return
    end

    local indexTable = {}
    if self:isTouchOnTheCard(pos, indexTable) then
        if self._selectEndIndex ~= indexTable[1] then
            self._selectEndIndex = indexTable[1]
            self:onSelectTouchMoveCard()
        end
    end
end

function GameHandCardNode:onTouchEnd(touch, event)
    local pos = touch:getLocation()

    if not self:isCanTouchCard() then
        return
    end

    local indexTable = {}
    if self:isTouchOnTheCard(pos, indexTable) then
        self._selectEndIndex = indexTable[1]
    end

    self:onSelectTouchEndCard()        

    -- 联想牌逻辑入口
    if self._selectBeginIndex == self._selectEndIndex then
        local upCards = self:getUpHandCards()
        if #upCards > #self._lastUpCards then
            self._presenter:dealSelectAutoUp()
        end
    end

    self._selectBeginIndex = nil
    self._selectEndIndex   = nil

    self:checkOutBtnEnable()
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
    end
end

-- 创建手牌
function GameHandCardNode:createCards(cards, banker, ming)    
    ----- 这里需要先算好手牌数再createCard， 计算手牌位置会用到
    for i = 1, #cards do
        if cards[i] ~= CV_BACK then
            self._handCardCount = self._handCardCount + 1
        end
    end

    for i = 1, #cards do
        if cards[i] ~= CV_BACK then
            if self._localSeat == HERO_LOCAL_SEAT then
                self:createCard(cards[i], HAND_CARD_SCALE, HAND_CARD_TYPE)
            else
                self:createCard(cards[i], HAND_CARD_SCALE_NO_SELF, HAND_CARD_TYPE_NO_SELF)
            end
        end
    end

    if banker then
    	self._gameCards[#self._gameCards]:showImgCardBanker(true)
    end
    
    if ming then
        self._gameCards[#self._gameCards]:showImgCardMing(true)
    end    
end

-- 排序
local DELETE_ACTION = 1
local SORT_ACTION   = 2
function GameHandCardNode:sortNodeCardByWeight(index)
    local count = 0
    for i = 1, #self._gameCards do
        if self._gameCards[i]:isVisible() then
            count = count + 1
        end
    end

    if count > 0 then
        self._presenter:sortNodeCardByWeight(self._gameCards)

        if not index then
            for i = 1, #self._gameCards do
                self._gameCards[i]:setCardIndex(i)
            end
        else
            self:playSortAction(index)
        end       
    end
    
    
end

function GameHandCardNode:playSortAction(index)
    if index == DELETE_ACTION then
        for i = 1, #self._gameCards do
            self._gameCards[i]:setCardIndexEx(i)
            self._gameCards[i]:playMoveAction()
        end
    elseif index == SORT_ACTION then
        for i = 1, #self._gameCards do
            self._gameCards[i]:setCardIndexEx(i)
        end
        
        for i = 1, #self._gameCards do
            self._gameCards[i]:playMoveAction(SORT_ACTION)
        end


    else
        for i = 1, #self._gameCards do
            self._gameCards[i]:setCardIndex(i)
        end
    end
end

function GameHandCardNode:isCanTouchCard()    
    return true
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

function GameHandCardNode:onSelectTouchMoveCard()
    for i = #self._gameCards, 1, -1 do
        if self._selectBeginIndex and self._selectEndIndex and
           (i - self._selectBeginIndex) * (i - self._selectEndIndex) <= 0 then
            self._gameCards[i]:setIsSelect(true)
        else 
            self._gameCards[i]:setIsSelect(false)
        end
    end
end

function GameHandCardNode:onSelectTouchEndCard()
    local bHaveUpCard = false
    local bHaveDownCard = false

    for i = #self._gameCards, 1, -1 do
        if self._selectBeginIndex and self._selectEndIndex and
           (i - self._selectBeginIndex) * (i - self._selectEndIndex) <= 0 then
            if self._gameCards[i]:getIsUp() then
                bHaveUpCard = true
            else
                bHaveDownCard = true
            end
        end
    end

    for i = #self._gameCards, 1, -1 do
        if self._selectBeginIndex and self._selectEndIndex and
            (i - self._selectBeginIndex) * (i - self._selectEndIndex) <= 0 then
            if bHaveUpCard and bHaveDownCard then
                self._gameCards[i]:setIsUpWithAction(true)
            else
                local bUp = self._gameCards[i]:getIsUp()
                if bUp then
                    self._gameCards[i]:setIsUpWithAction(false)
                else
                    self._gameCards[i]:setIsUpWithAction(true)
                end
            end
        end

        self._gameCards[i]:setIsSelect(false)
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

-- 设置手牌弹起
function GameHandCardNode:setCardsUp(cards)
    self:downAllHandCards()

    for i = 1, #cards do
        local card = self:getDownNodeCardByID(cards[i])
        if card then
            card:setIsUpWithAction(true)
        end
    end

    self:checkOutBtnEnable()
end

-- 联想手牌弹起
function GameHandCardNode:setNeedUpCardsAutoUp(cards)
    for i = 1, #cards do
        local card = self:getDownNodeCardByID(cards[i])
        if card then
            card:setIsUpWithAction(true)
        end
    end

    self:checkOutBtnEnable()
end

function GameHandCardNode:getDownNodeCardByID(id)
    for i = 1, #self._gameCards do
        if self._gameCards[i]:isVisible() and
           self._gameCards[i]:getCardID() == id and
           not self._gameCards[i]:getIsUp() then
            return self._gameCards[i]
        end
    end
end

function GameHandCardNode:deleteHandCards(cards)
    for i = 1, #cards do
        if cards[i] ~= CV_BACK then
            self._handCardCount = self._handCardCount - 1
        end
    end

    for i = 1, #cards do
        if cards[i] ~= CV_BACK then
            local card = self:getDeleteNodeCardByID(cards[i])
            if card then
                card:resetCard()
            end
        end
    end

    if self._localSeat == HERO_LOCAL_SEAT then
        self._presenter:sortHandCard(self._localSeat, DELETE_ACTION)
    else
        self._presenter:sortHandCard(self._localSeat)
    end
end

function GameHandCardNode:getDeleteNodeCardByID(id)
    for i = 1, #self._gameCards do
        if self._gameCards[i]:isVisible() and
           self._gameCards[i]:getCardID() == id and
           self._gameCards[i]:getIsUp() then
            return self._gameCards[i]
        end
    end

    for i = 1, #self._gameCards do
        if self._gameCards[i]:isVisible() and
           self._gameCards[i]:getCardID() == id and
           not self._gameCards[i]:getIsUp() then
            return self._gameCards[i]
        end
    end
end

function GameHandCardNode:checkOutBtnEnable()
    local upCards = self:getUpHandCards()

    self._lastUpCards = upCards
    
    self._presenter:checkOutBtnEnable(upCards)    
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

function GameHandCardNode:getHandCardCount()
    return self._handCardCount
end

function GameHandCardNode:showImgCardMing()
    if self._handCardCount > 0 then
        self._gameCards[self._handCardCount]:showImgCardMing(true)
    end    
end

function GameHandCardNode:showImgCardBanker()
    if self._handCardCount > 0 then
        self._gameCards[self._handCardCount]:showImgCardBanker(true)
    end   
end

return GameHandCardNode