--[[
    @brief  游戏出牌UI基类
]]--

local GameCardNode          = requireDDZ("app.game.ddz.GameCardNode")
local GameBankCardNode      = class("GameBankCardNode", app.base.BaseNodeEx)

local BANK_CARD_TYPE        = 3
local BANK_CARD_SCALE       = 0.4
local BANK_CARD_SCALE_SMALL = 0.6
local CV_BACK               = app.game.CardRule.cards.CV_BACK 

function GameBankCardNode:initData(localSeat)
    self._localSeat         = 3

    self._gameCards         = {}
    self._bankCardCount     = 0
end

function GameBankCardNode:createCards(cards)
    for i = 1, #cards do
        self._bankCardCount = self._bankCardCount + 1        
    end

    for i = 1, #cards do
       self:createCard(cards[i], BANK_CARD_SCALE, BANK_CARD_TYPE)            
    end
end

function GameBankCardNode:resetBankCards()
    self._bankCardCount = 0

    for i = 1, #self._gameCards do
        if self._gameCards[i]:isVisible() then
            self._gameCards[i]:resetCard()
        end
    end
end

function GameBankCardNode:createCard(id, scale, type)
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
end

function GameBankCardNode:getBankCardCount()
    return self._bankCardCount
end

return GameBankCardNode