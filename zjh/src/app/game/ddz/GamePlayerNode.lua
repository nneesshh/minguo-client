--[[
@brief  游戏玩家类
]]--
local GameHandCardNode = requireDDZ("app.game.ddz.GameHandCardNode")
local GameOutCardNode  = requireDDZ("app.game.ddz.GameOutCardNode")

local GamePlayerNode   = class("GamePlayerNode", app.base.BaseNodeEx)

local HERO_LOCAL_SEAT  = 1 
local ST = app.game.GameEnum.soundType
local CR = app.game.CardRule

GamePlayerNode.clicks = {
    "pnl_hint_back_trust",
}


function GamePlayerNode:onClick(sender)
    GamePlayerNode.super.onClick(self, sender)
    local name = sender:getName()
    if name == "pnl_hint_back_trust" then
        self._presenter:sendAutoHit(0)
    end
end

function GamePlayerNode:initData(localSeat)
    self._localSeat         = localSeat
    self._clockProgress     = nil

    math.randomseed(tostring(os.time()):reverse():sub(1, 7))
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
    if not player then
    	return
    end
    -- 显示用户节点    
    self:showPnlPlayerEx(true)

--    if self._localSeat == HERO_LOCAL_SEAT then
        -- 设置姓名
        self:showTxtPlayerName(true, player:getTicketID())
        -- 设置金币
        self:showTxtBalance(true, player:getBalance())
        -- 显示头像
        self:showImgFace(player:getGender(), player:getAvatar())
--    else
--        -- 设置姓名
--        self:showTxtPlayerName(true, "   - -")
--        -- 设置金币
--        self:showTxtBalance(true, " - -")
--        -- 显示头像
--        self:showImgFace(2, 0) 
--    end
    self:showImgCancelFlag(false) 
    -- 隐藏庄家
    self:showImgBanker(false)
    -- 隐藏加倍
    self:showImgMult(false)
    -- 倍数x1
    self:showMult(1)
    -- 叫地主
    self:showImgCallType(false)    
    -- 隐藏牌型
    self:showImgCardType(false)
    -- 隐藏时钟
    self:showPnlClockCircle(false) 
    -- 隐藏提示
    self:showPlayHint()
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

    self:showPnlClockCircle(false)
end

-- 游戏开始
function GamePlayerNode:onGameStart()
    -- 隐藏庄家
    self:showImgBanker(false)
    -- 隐藏加倍
    self:showImgMult(false)
    -- 倍数x1
    self:showMult(1)
    -- 叫地主
    self:showImgCallType(false)    
    -- 隐藏牌型
    self:showImgCardType(false)
    -- 隐藏时钟
    self:showPnlClockCircle(false) 
    -- 隐藏手牌
    self._gameHandCardNode:resetHandCards()
    self:showImgCancelFlag(false) 
    -- 隐藏出牌
    self._gameOutCardNode:resetOutCards()   
    -- 隐藏提示
    self:showPlayHint() 
end

-- 显示信息
function GamePlayerNode:showPlayerInfo()
    local player = app.game.PlayerData.getPlayerByLocalSeat(self._localSeat)
    if not player then return end
    -- 显示用户节点    
    self:showPnlPlayer(true)

    self:showTxtPlayerName(true, player:getTicketID())
    -- 设置金币
    self:showTxtBalance(true, player:getBalance())
    -- 显示头像
    self:showImgFace(player:getGender(), player:getAvatar())
end

-- 发牌
function GamePlayerNode:onTakeFirst(cardID, cardNum)
    self._gameHandCardNode:onTakeFirst(cardID)
    
    self:showPnlHandCard(true, cardNum)
end

-- 重置手牌
function GamePlayerNode:onRestCards(cards)
    self._gameHandCardNode:resetHandCards()
    self._gameHandCardNode:createCards(cards)
end

-- 时钟
function GamePlayerNode:onClock(time, isFirst)
    if not isFirst then
        self._gameOutCardNode:resetOutCards()

        -- 隐藏该座位玩家的不出标志
        self:showImgCallType(false)
    end
    self:showPnlClockCircle(true, time)
end

function GamePlayerNode:onClockEx()
    -- 隐藏该作为玩家出掉的牌
    self._gameOutCardNode:resetOutCards()

    -- 隐藏该座位玩家的不出标志
--    self:showImgCancelFlag(false)
end

-- 显示用户节点    
function GamePlayerNode:showPnlPlayer(visible)
    if self._rootNode then
        self._rootNode:setVisible(visible)
    end   
end

function GamePlayerNode:showPnlPlayerEx(visible)
    if self._rootNode then
        self._rootNode:setVisible(true)
    end

    local cardcount = 0  
    local childs = self._rootNode:getChildren()
    for i, node in ipairs(childs) do
        if node:getName() == "node_hand_card" then
            node:setVisible(true)                    
        end
    end
end

-- 姓名
function GamePlayerNode:showTxtPlayerName(visible, nickName)
    local txtPlayerName = self:seekChildByName("txt_name")

    if visible then
        --nickName = app.util.ToolUtils.nameToShort(nickName, 10)
        txtPlayerName:setString(nickName)
    end

    txtPlayerName:setVisible(visible)
end

-- 金币
function GamePlayerNode:showTxtBalance(visible, balance)
    local txtBalance = self:seekChildByName("txt_balance")

    if txtBalance then
        if balance ~= nil then
            txtBalance:setString(balance)--app.util.ToolUtils.numConversionByDecimal(tostring(balance)))
        end
        txtBalance:setVisible(visible)
    end
end

-- 头像
function GamePlayerNode:showImgFace(gender, avatar)
    local imgHead = self:seekChildByName("img_face")
    local resPath = string.format("lobby/image/head/img_head_%d_%d.png", gender, avatar)
    imgHead:loadTexture(resPath, ccui.TextureResType.plistType)
end

-- 庄家
function GamePlayerNode:showImgBanker(visible)
    local imgBanker = self:seekChildByName("img_banker")
    imgBanker:setVisible(visible)
end

-- 加倍
function GamePlayerNode:showImgMult(visible)
    local imgMult = self:seekChildByName("img_mult")
    if imgMult then
        imgMult:setVisible(visible)
    end    
end

-- 0不叫1分2分3分4不要5不加倍6加倍
function GamePlayerNode:showImgCallType(visible, index)
    local imgCall = self:seekChildByName("img_call")
    imgCall:setVisible(visible)
    
    if index and index >= 0 and index <= 6 then
        local resPath = "game/ddz/image/img_call_" .. index .. ".png"
        imgCall:ignoreContentAdaptWithSize(true)
        imgCall:loadTexture(resPath, ccui.TextureResType.plistType)        
    end
end

function GamePlayerNode:showTalkMult(mult)
	if mult == 0 then
        self:showImgCallType(true, 5)
	else
        self:showImgCallType(true, 6)
	end
end

function GamePlayerNode:showImgCancelFlag(visible)
	self:showImgCallType(visible, 4)
end

-- 牌型
function GamePlayerNode:showImgCardType(visible, index)
--    local imgType = self:seekChildByName("img_cardtype")
--    imgType:setVisible(visible)
--
--    if index and index >= 1 and index <= 6 then
--        local resPath = "game/ddz/image/img_type_" .. index .. ".png"
--
--        imgType:loadTexture(resPath, ccui.TextureResType.plistType)
--    else
--        imgType:setVisible(false)   
--    end
end

function GamePlayerNode:showPlayHint(type)
    local pcant = self:seekChildByName("pnl_hint_back_cant")
    local ptrust = self:seekChildByName("pnl_hint_back_trust")
    
    if pcant then
        pcant:setVisible(type == "cant")        
    end	
    
    if ptrust then
        ptrust:setVisible(type == "trust")
    end 
end

-- 时钟
function GamePlayerNode:showPnlClockCircle(visible, time)
    local pnlClockCircle = self:seekChildByName("img_clock")
    if visible then
        self._presenter:openSchedulerClock(self._localSeat, time)
    else
        self._presenter:closeSchedulerClock(self._localSeat)
    end

    pnlClockCircle:setVisible(visible)
end

function GamePlayerNode:showClockProgress(time)
    local txtClock = self:seekChildByName("fnt_clock")   
    if txtClock then
        txtClock:setString(time)
    end 
end

function GamePlayerNode:showPnlHandCard(visible, cardNum)
    local pnlHandCard = self:seekChildByName("pnl_hand_card")
    if pnlHandCard then
        if visible then
            if cardNum > 0 then
                pnlHandCard:setVisible(visible)

                self:showFntHandCardCount(true, cardNum)
            else
                pnlHandCard:setVisible(false)
            end
        else
            pnlHandCard:setVisible(visible)
        end
    end
end

function GamePlayerNode:showFntHandCardCount(visible, cardNum)
    local fntHandCardCount = self:seekChildByName("txt_hand_count")
    if visible then
        fntHandCardCount:setString(cardNum)
    end

    fntHandCardCount:setVisible(visible)
end

function GamePlayerNode:showMult(mult)
    if not self._localSeat == HERO_LOCAL_SEAT then
    	return
    end
    
    local txtMult = self:seekChildByName("txt_mult_num")    
    if txtMult then
        txtMult:setString("x" .. mult)
    end
end

function GamePlayerNode:getPosition()
    return self._rootNode:getPosition()
end      

-- 获取手牌
function GamePlayerNode:getGameHandCardNode()
    return self._gameHandCardNode
end

function GamePlayerNode:getHandCardCount()
    return self._gameHandCardNode:getHandCardCount()
end

function GamePlayerNode:getGameOutCardNode()
    return self._gameOutCardNode
end

function GamePlayerNode:setLocalZOrder(zorder)
    self._rootNode:setLocalZOrder(zorder)
end

function GamePlayerNode:visible()
    return self._rootNode:isVisible(), self._rootNode:getLocalZOrder()
end

function GamePlayerNode:getRootNode()
    return self._rootNode
end

function GamePlayerNode:playCardEffect(cardid, count)
    local node = self:seekChildByName("node_card_effect")
    node:removeAllChildren()
    node:stopAllActions()
    
    local cardWidth = 78
    local outCardsLength = (count - 1) * 30 + cardWidth
    local point = outCardsLength / 2
    
    local bx, by = self:seekChildByName("node_out_card"):getPosition() 
    local x,y = 0,0
    if cardid == CR.cardType.CTID_YI_SHUN then
        if self._localSeat == HERO_LOCAL_SEAT then
            x = -55
        elseif self._localSeat == HERO_LOCAL_SEAT-1 then
            x = -55 + point
        else
            x = -55 - point
        end
    elseif cardid == CR.cardType.CTID_ER_SHUN then
        if self._localSeat == HERO_LOCAL_SEAT then
            x = -5
            y = -15    
        elseif self._localSeat == HERO_LOCAL_SEAT-1 then
            x = -5 + point
            y = -15  
        else
            x = -5 - point
            y = -15
        end
    end

    local effect    
    if cardid == CR.cardType.CTID_YI_SHUN then
        effect = app.util.UIUtils.runEffectOne("game/ddz/effect", "shunzi_dh", x, y)
    elseif cardid == CR.cardType.CTID_ER_SHUN then
        effect = app.util.UIUtils.runEffectOne("game/ddz/effect", "liandui_dh", x, y)    
    end

    if effect then
        node:addChild(effect)
    end
end

-- 音效相关
function GamePlayerNode:playEffectByName(name)
    local soundPath = "game/ddz/sound/"
    local strRes = ""
    for alias, path in pairs(ST) do
        if alias == name then
            if type(path) == "table" then
                local index = math.random(1, #path)
                strRes = path[index]
            else
                strRes = path
            end
        end
    end

    app.util.SoundUtils.playEffect(soundPath .. strRes)   
end

function GamePlayerNode:playOutCardVoice(typeID, power, sex, bigger)
    local weight = power
    local sex = sex or 0
    local bigger = bigger or false
    
    local strRes = ""
    local soundPath = ""

    if (weight == 19)then weight = 2 end
    if (weight == 21)then weight = 15 end
    if (weight == 22)then weight = 16 end

    local CardType = app.game.CardRule.cardType
    
    local genderStr = ""
    if sex == 0 then
        genderStr = "Woman"
    else
        genderStr = "Man"
    end
        
    if typeID == CardType.CTID_YI_ZHANG then
        strRes = string.format("%s_%d.mp3", genderStr, weight)
    elseif typeID == CardType.CTID_ER_ZHANG then
        strRes = string.format("%s_dui%d.mp3", genderStr, weight)
    elseif typeID == CardType.CTID_SAN_ZHANG then
        strRes = string.format("%s_tuple%d.mp3", genderStr, weight)
    elseif typeID == CardType.CTID_SI_ZHANG then
        strRes = string.format("%s_zhadan.mp3", genderStr)            
    elseif typeID == CardType.CTID_YI_SHUN then
        strRes = string.format("%s_shunzi.mp3", genderStr)   
    elseif typeID == CardType.CTID_ER_SHUN then
        strRes = string.format("%s_liandui.mp3", genderStr)           
    elseif typeID == CardType.CTID_SAN_SHUN then
        strRes = string.format("%s_feiji.mp3", genderStr)    
    elseif typeID == CardType.CTID_SAN_DAI_YI then
        strRes = string.format("%s_sandaiyi.mp3", genderStr) 
    elseif typeID == CardType.CTID_SAN_DAI_ER then
        strRes = string.format("%s_sandaiyidui.mp3", genderStr) 
    elseif typeID == CardType.CTID_FEI_JI then
        strRes = string.format("%s_feiji.mp3", genderStr)
    elseif typeID == CardType.CTID_HUO_JIAN then
        strRes = string.format("%s_wangzha.mp3", genderStr)
    elseif typeID == CardType.CTID_SI_DAI_ER then
        strRes = string.format("%s_sidaier.mp3", genderStr)  
    end
    
    -- 大你 排除--单张对子三张及王炸
    if bigger and (typeID ~= CardType.CTID_YI_ZHANG and 
                   typeID ~= CardType.CTID_ER_ZHANG and 
                   typeID ~= CardType.CTID_SAN_ZHANG and 
                   typeID ~= CardType.CTID_HUO_JIAN) then               
        strRes = string.format("%s_dani%d.mp3", genderStr, math.random(1,3))
    end
    
    print("--------------")
    print("id----",typeID)
    print("weight",weight)
    print("strRes",strRes)
    print("bigger",bigger)
    print("--------------")

    soundPath = "game/ddz/sound/"             
    if (strRes == "") then
        print("strRes is nil nil") 
        return 
    end

    local sex = tonumber(sex)
    if sex == 0 then
        strRes = soundPath .. "women/" .. strRes
    else        
        strRes = soundPath .. "man/" .. strRes
    end

    app.util.SoundUtils.playEffect(strRes)
end

return GamePlayerNode