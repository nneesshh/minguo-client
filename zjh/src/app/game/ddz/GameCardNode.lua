
--[[
    @brief  游戏牌UI基类
]]--

local GameCardNode = class("GameCardNode", app.base.BaseNode)

-- csb路径
GameCardNode.csbPath         = "game/qznn/csb/card.csb"
GameCardNode.imgCardPath     = "game/public/card/img_"

local HAND_CARD_TYPE         = 0
local HAND_CARD_TYPE_NO_SELF = 1
local OUT_CARD_TYPE          = 2
local BANKER_CARD_TYPE       = 3

local TAKE_FIRST_DELAY       = 0.1
local MOVE_ACTION_DELAY      = 0.15

local CV_BACK                = 0
local CV_GRAY                = 888
local HERO_LOCAL_SEAT        = 1

local COLOR = {
    C_FANG      = 0,
    C_MEI       = 1,
    C_HONG      = 2,
    C_HEI       = 3,
    C_BIGKING   = 4,
    C_SMALLKING = 5
}

function GameCardNode:initData(localSeat, type)
    self._localSeat    = localSeat
    self._type         = type

    self._id           = nil
    self._scale        = nil
    self._index        = nil

    self._num          = nil
    self._color        = nil
    self._weight       = nil

    self._bSelect      = false
    self._bUp          = false
    self._bBomb        = false
end

function GameCardNode:setCardID(id)
    self._id = id

    self._num          = self._presenter:getCardNum(id)
    self._color        = self._presenter:getCardColor(id)    
    self._weight       = self._presenter:getCardWeight(id)

    local front = self:seekChildByName("img_card_front")
    local back = self:seekChildByName("img_card_back")
    local gary = self:seekChildByName("img_card_gary")

    if id == CV_BACK then
        front:setVisible(false)
        back:setVisible(true)
        gary:setVisible(false)
    elseif id == CV_GRAY then
        front:setVisible(false)
        back:setVisible(false)
        gary:setVisible(true)
    else
        front:setVisible(true)
        back:setVisible(false)
        gary:setVisible(false)
    end

    if id ~= CV_BACK and id ~= CV_GRAY then    
        local bking = self:seekChildByName("img_card_big_king")
        local sking = self:seekChildByName("img_card_small_king")        
        local normal = self:seekChildByName("panl_card_normal")

        if self._color == COLOR.C_BIGKING then
            bking:setVisible(true)
            sking:setVisible(false)
            normal:setVisible(false)
        elseif self._color == COLOR.C_SMALLKING then
            bking:setVisible(false)
            sking:setVisible(true)
            normal:setVisible(false)
        else
            bking:setVisible(false)
            sking:setVisible(false)
            normal:setVisible(true) 

            local inum = normal:getChildByName("img_card_num")
            local ismall = normal:getChildByName("img_color_small")
            local ibig = normal:getChildByName("img_color_big") 
            local iface = normal:getChildByName("img_card_face") 

            if self._num and self._color then          
                local tempNum   
                if self._num == 1 then
                    tempNum = 14
                else
                    tempNum = self._num
                end
                local npath = self.imgCardPath .. self._color % 2 .. "_" .. tempNum .. ".png"
                local spath = self.imgCardPath .. "color_" .. self._color .. ".png"
                inum:loadTexture(npath, ccui.TextureResType.plistType)
                ismall:loadTexture(spath, ccui.TextureResType.plistType)

                if tempNum <= 10 or tempNum == 14 then
                    iface:setVisible(false)
                    ibig:setVisible(true)
                    local bpath = self.imgCardPath .. "color_" .. self._color .. ".png"         
                    ibig:loadTexture(bpath, ccui.TextureResType.plistType)
                else
                    ibig:setVisible(false)
                    iface:setVisible(true)
                    local fpath = self.imgCardPath .. "face_" .. self._color % 2 .. "_" .. tempNum .. ".png"
                    iface:loadTexture(fpath, ccui.TextureResType.plistType)
                end 
            end
        end
    end
end

function GameCardNode:getCardID()
    return self._id
end

function GameCardNode:getCardNum()
    return self._num
end

function GameCardNode:getCardColor()
    return self._color
end

function GameCardNode:getCardWeight()
    return self._weight
end

function GameCardNode:setCardScale(scale)
    self._scale = scale

    self._rootNode:setScale(self._scale)
end

function GameCardNode:setCardIndex(index)
    self._index = index

    self:setCardPosition()
    self:setCardLocalZorder()
end

function GameCardNode:setCardIndexEx(index)
    self._index = index

    self:setCardLocalZorder()
end

function GameCardNode:setCardPosition()
    local pos = cc.p(0, 0)
    if self._type == HAND_CARD_TYPE or self._type == HAND_CARD_TYPE_NO_SELF then
        pos = self._presenter:calHandCardPosition(self._index, self:getCardSize(), self._localSeat, self._bUp)
    elseif self._type == OUT_CARD_TYPE or self._type == BANKER_CARD_TYPE then 
        pos = self._presenter:calOutCardPosition(self._index, self:getCardSize(), self._localSeat)
    end

    self._rootNode:setPosition(pos)
end

function GameCardNode:getCardSize()
    local pnlCard = self:seekChildByName("panl_card")
    local cardSize = pnlCard:getContentSize()

    cardSize.width = cardSize.width * self._scale
    cardSize.height = cardSize.height * self._scale

    return cardSize
end

function GameCardNode:setCardLocalZorder()
    if self._type == HAND_CARD_TYPE then
        self._rootNode:setLocalZOrder(self._index + 100)
        return
    end

    self._rootNode:setLocalZOrder(self._index)
end

function GameCardNode:convertToNodeSpace(pos)
    return self._rootNode:convertToNodeSpace(pos)
end

function GameCardNode:resetCard()
    if self._type == HAND_CARD_TYPE then
        self:setIsSelect(false)
        self:setIsUp(false)
    end

    if self._type == HAND_CARD_TYPE or
       self._type == HAND_CARD_TYPE_NO_SELF then
        self:setIsBomb(false)
    end

    self._rootNode:stopAllActions()

    self:setVisible(false)
end

function GameCardNode:setVisible(visible)
    self._rootNode:setVisible(visible)
end

function GameCardNode:isVisible()
    return self._rootNode:isVisible()
end

function GameCardNode:getPnlCard()
    return self:seekChildByName("panl_card")
end

function GameCardNode:getPosition()
    return self._rootNode:getPosition()
end

function GameCardNode:showImgSelectBG(visible)
    local imgSelectBG = self:seekChildByName("img_card_select")
    imgSelectBG:setVisible(visible)
end

function GameCardNode:setIsSelect(bSelect)
    self._bSelect = bSelect
    self:showImgSelectBG(self._bSelect)
end

function GameCardNode:setIsUp(bUp)
    self._bUp = bUp
    self:setCardPosition()
end

function GameCardNode:setIsUpWithAction(bUp)
    self._bUp = bUp
    self:playMoveAction()
end

function GameCardNode:getIsUp()
    return self._bUp
end

function GameCardNode:setIsBomb(bBomb)
    self._bBomb = bBomb
end

-- 发牌动画
function GameCardNode:playTakeFirstAction()
    local pos = cc.p(0, 0)
    if self._type == HAND_CARD_TYPE then
        pos = self._presenter:calHandCardPosition(self._index, self:getCardSize(), self._localSeat, self._bUp)
    elseif self._type == HAND_CARD_TYPE_NO_SELF then
        pos = self._presenter:calHandCardPosition(self._index, self:getCardSize(), self._localSeat, self._bUp)
    end

    local parent = self._rootNode:getParent()
    local szScreen = cc.Director:getInstance():getWinSize()
    local pCenter = parent:convertToNodeSpace(cc.p(szScreen.width*0.5, szScreen.height*0.5))
    self._rootNode:setPosition(pCenter)
    self._rootNode:setOpacity(0)

    if self._type == HAND_CARD_TYPE_NO_SELF then
        self._rootNode:setScale(0.4)
    end

    local actMoveTo = cc.MoveTo:create(TAKE_FIRST_DELAY, pos)
    local actFadeIn = cc.FadeIn:create(TAKE_FIRST_DELAY)
    local actSpawn = cc.Spawn:create(actMoveTo, actFadeIn)

    local actRemove = cc.CallFunc:create(function()
        self._rootNode:setVisible(false)
    end)

    if self._type == HAND_CARD_TYPE then
        self._rootNode:runAction(actSpawn)
    elseif self._type == HAND_CARD_TYPE_NO_SELF then
        self._rootNode:runAction(actSpawn)
    else
        self._rootNode:runAction(
            cc.Sequence:create(
                actSpawn, 
                actRemove
            )
        )        
    end
end

-- 上移牌动作
local DELETE_ACTION = 1
local SORT_ACTION   = 2
function GameCardNode:playMoveAction(index)
    if index == SORT_ACTION then
        self._rootNode:stopAllActions()

        local actMoveTo = cc.MoveTo:create(MOVE_ACTION_DELAY, cc.p(0, 0))
        local actRemove = cc.CallFunc:create(function()
            self._rootNode:setPosition(cc.p(0, 0))
        end)        

        local pos = self._presenter:calHandCardPosition(self._index, self:getCardSize(), self._localSeat, self._bUp)    

        local actMoveTo2 = cc.MoveTo:create(MOVE_ACTION_DELAY * 2, pos)
        local actRemove2 = cc.CallFunc:create(function()
            self._rootNode:setPosition(pos)
        end)        
        self._rootNode:runAction(
            cc.Sequence:create(
                actMoveTo, 
                actRemove,
                actMoveTo2, 
                actRemove2
            )
        )
    else
        local pos = self._presenter:calHandCardPosition(self._index, self:getCardSize(), self._localSeat, self._bUp)    

        self._rootNode:stopAllActions()

        local actMoveTo = cc.MoveTo:create(MOVE_ACTION_DELAY, pos)
        local actRemove = cc.CallFunc:create(function()
            self._rootNode:setPosition(pos)
        end)        

        self._rootNode:runAction(
            cc.Sequence:create(
                actMoveTo, 
                actRemove
            )
        )
    end
end

return GameCardNode