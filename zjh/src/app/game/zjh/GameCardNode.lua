
--[[
    @brief  单张牌
]]--

local GameCardNode = class("GameCardNode", app.base.BaseNode)

-- csb路径
GameCardNode.csbPath         = "game/zjh/csb/card.csb"
GameCardNode.imgCardPath     = "game/zjh/image/card/img_"
local HAND_CARD_TYPE         = 0
local HAND_CARD_TYPE_NO_SELF = 1
local OUT_CARD_TYPE          = 2
local BANKER_CARD_TYPE       = 3

local TAKE_FIRST_DELAY       = 0.1
local MOVE_ACTION_DELAY      = 0.15
local CV_BACK                = 999

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
    
    front:setVisible(not(id == CV_BACK))
    back:setVisible(id == CV_BACK)
    
    if id ~= CV_BACK then    
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
            
            local npath = self.imgCardPath .. self._color % 2 .. "_" .. self._num .. ".png"
            local spath = self.imgCardPath .. "color_" .. self._color .. ".png"
            inum:loadTexture(npath, ccui.TextureResType.plistType)
            ismall:loadTexture(spath, ccui.TextureResType.plistType)
            
            if self._num <= 10 then
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
    local posX = (self._index - 1) * 156 * self._scale
    local posY = 0
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

function GameCardNode:playTakeFirstAction()
    local parent = self._rootNode:getParent()
    if parent ~= nil then
        local visibleRect = cc.Director:getInstance():getOpenGLView():getVisibleRect()
        local center = cc.p(visibleRect.x + visibleRect.width/2,visibleRect.y + visibleRect.height/2)
        local children = parent:getChildren()

        self._rootNode:setColor(cc.c3b(255,255,255))
        local positionX = parent:getPositionX();
        local positionY = parent:getPositionY()
        local tempx = nil
        local tempy = nil
        if self._localSeat == 0 then
            self._rootNode:setPosition(cc.p(center["x"]/2,0))
            tempx = center["x"]/3
            tempy = 100
        elseif self._localSeat == 2 then
            self._rootNode:setPosition(cc.p(-center["x"]/2,0))
            tempx = -center["x"]/4
            tempy = 30
        elseif self._localSeat == 3 then 
            self._rootNode:setPosition(cc.p(-center["x"]/4,-center["y"]/4))
            tempx = -center["x"]/5
            tempy = -center["y"]/5
        elseif self._localSeat == 4 then 
            self._rootNode:setPosition(cc.p(center["x"]/4,-center["y"]/4))
            tempx = -center["x"]/8
            tempy = -center["y"]/6
        end

        local pointEnd = cc.p((#children-1)*10, 0)
        local pointFirst = cc.p(tempx, tempy)
        local pointSecond = cc.p(tempx, tempy)
        local tPoint = {pointFirst, pointSecond, pointEnd}

        local actionFadeIn = cc.FadeIn:create(0.05)
        local actionBezier = cc.BezierTo:create(0.3,tPoint)
        local actionEaseIn = cc.EaseInOut:create(actionBezier,2)
        local actionExpend = cc.MoveTo:create(0.1,cc.p((#children-1)*40,0))
        local delay = cc.DelayTime:create(#children*0.07)
        local actionSpaw = cc.Spawn:create(actionEaseIn,actionFadeIn)

        local action = cc.Sequence:create(delay,actionSpaw,cc.DelayTime:create((3-#children)*0.1),actionExpend)
        self._rootNode:runAction(action)
    end
end

return GameCardNode