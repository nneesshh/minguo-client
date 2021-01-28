
--[[
    @brief  游戏出牌UI基类
]]--
local app = cc.exports.gEnv.app
local requireQZNN = cc.exports.gEnv.HotpatchRequire.requireQZNN

local GameCardNode       = requireQZNN("app.game.qznn.GameCardNode")
local GameOutCardNode    = class("GameOutCardNode", app.base.BaseNodeEx)

local OUT_CARD_TYPE     = 2
local BANKER_CARD_TYPE  = 3

local OUT_CARD_SCALE    = 0.5

function GameOutCardNode:initData(localSeat)
    self._localSeat         = localSeat

    self._gameCards         = {}
    self._outCardCount      = 0
end

function GameOutCardNode:createCards(cards)
    self:resetCards()
    for i = 1, #cards do
        self._outCardCount = self._outCardCount + 1        
    end

    for i = 1, #cards do
        self:createCard(cards[i], OUT_CARD_SCALE, OUT_CARD_TYPE)
    end
end

function GameOutCardNode:resetOutCards()
    self._outCardCount = 0

    for i = 1, #self._gameCards do
        if self._gameCards[i]:isVisible() then
            self._gameCards[i]:resetCard()
        end
    end
end

function GameOutCardNode:createCard(id, scale, type)
    if id == nil then return end
   
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

function GameOutCardNode:setOutCard(index, id)
    if index == nil then return end
    if self._gameCards[index] == nil then return end
    self._gameCards[index]:setCardID(id)
end

function GameOutCardNode:getOutCard(index)
    return self._gameCards[index]:getRootNode()
end

function GameOutCardNode:resetCards()
    self:getRootNode():removeAllChildren()
    self._gameCards = {}
end

function GameOutCardNode:getOutCardCount()
    return self._outCardCount
end

return GameOutCardNode
