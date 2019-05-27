
--[[
    @brief  单张牌
]]--

local GameCardNode = class("GameCardNode", app.base.BaseNode)

-- csb路径
GameCardNode.csbPath         = "game/zjh/csb/card.csb"
GameCardNode.imgCardPath     = "game/public/card/img_"
local HAND_CARD_TYPE         = 0
local HAND_CARD_TYPE_NO_SELF = 1
local OUT_CARD_TYPE          = 2
local BANKER_CARD_TYPE       = 3

local TAKE_FIRST_DELAY       = 0.2
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
end

function GameCardNode:setCardID(id)
    self._id = id

    self._num          = self._presenter:getCardNum(id)
    self._color        = self._presenter:getCardColor(id)
    
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
                local npath = self.imgCardPath .. self._color % 2 .. "_" .. self._num .. ".png"
                local spath = self.imgCardPath .. "color_" .. self._color .. ".png"
                inum:loadTexture(npath, ccui.TextureResType.plistType)
                ismall:loadTexture(spath, ccui.TextureResType.plistType)

                if self._num <= 10 or self._num == 14 then
                    iface:setVisible(false)
                    ibig:setVisible(true)
                    local bpath = self.imgCardPath .. "color_" .. self._color .. ".png"         
                    ibig:loadTexture(bpath, ccui.TextureResType.plistType)
                else
                    ibig:setVisible(false)
                    iface:setVisible(true)
                    local fpath = self.imgCardPath .. "face_" .. self._color % 2 .. "_" .. self._num .. ".png"
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

function GameCardNode:setCardScale(scale)
    self._scale = scale

    self._rootNode:setScale(self._scale)
end

function GameCardNode:setCardIndex(index)
    self._index = index

    self:setCardPosition()
    self:setCardLocalZorder()
end

function GameCardNode:setCardPosition()
    local posX, posY = 0,0
    posX = (self._index-1)*156*self._scale*0.5
    self._rootNode:setPosition(cc.p(posX, posY))
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

function GameCardNode:getCardSize()
    local pnlCard = self:seekChildByName("panl_card")
    local cardSize = pnlCard:getContentSize()

    cardSize.width = cardSize.width * self._scale
    cardSize.height = cardSize.height * self._scale

    return cardSize
end

-- 发牌动画
function GameCardNode:playTakeFirstAction()
    local parent = self._rootNode:getParent()
    local szScreen = cc.Director:getInstance():getWinSize()
    local pCenter = parent:convertToNodeSpace(cc.p(szScreen.width*0.5, szScreen.height*0.5))
    self._rootNode:setPosition(pCenter)
    
    local pos = self:calHandCardPosition(self._index, self._localSeat)    
    local actMoveTo = cc.Sequence:create(
        cc.MoveTo:create(TAKE_FIRST_DELAY, pos),
        cc.CallFunc:create(function() 
            self._rootNode:setPosition(cc.p(pos)) 
        end))
        
    self._rootNode:runAction(actMoveTo) 
end

function GameCardNode:calHandCardPosition(index, localSeat)    
    local x,y = 0,0
    local size = self:getCardSize()
    index = index - 1
    x = x + index*size.width*0.5    
        
    return cc.p(x, y)
end

return GameCardNode