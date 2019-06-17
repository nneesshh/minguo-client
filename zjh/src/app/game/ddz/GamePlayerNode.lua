--[[
    @brief  游戏玩家UI基类
    @by     斯雪峰
]]--
local GameHandCardNode = require("app.game.card.shuangkou.base.node.GameHandCardNode")
local GameOutCardNode  = require("app.game.card.shuangkou.base.node.GameOutCardNode")

local GamePlayerNode    = class("GamePlayerNode", app.base.BaseNodeEx)

GamePlayerNode.clicks = {
    "KW_IMG_FACE",
}

GamePlayerNode.touchs = {
    "KW_BTN_GAMEMENU_STORE_ENTRANCE",
}

function GamePlayerNode:onClick(sender)
    GamePlayerNode.super.onClick(self, sender)
    local name = sender:getName()
    if name == "KW_IMG_FACE" then
        self:onClickImgFace()
    end
end

function GamePlayerNode:onTouch(sender, eventType)
    GamePlayerNode.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "KW_BTN_GAMEMENU_STORE_ENTRANCE" then
            self:onTouchBtnGameMenuStoreEntance()
        end
    end
end

function GamePlayerNode:initData(localSeat)
    self._localSeat         = localSeat

    self._clockProgress     = nil
end

function GamePlayerNode:initUI(localSeat)
    self:initNodeHandCard(localSeat)
    self:initNodeOutCard(localSeat)
    self:initPnlClockCircle()
end

function GamePlayerNode:initNodeHandCard(localSeat)
    local nodeHandCard = self:seekChildByName("KW_NODE_HAND_CARD")
    self._gameHandCardNode = GameHandCardNode:create(self._presenter, nodeHandCard, localSeat)
end

function GamePlayerNode:initNodeOutCard(localSeat)
    local nodeOutCard = self:seekChildByName("KW_NODE_OUT_CARD")
    self._gameOutCardNode = GameOutCardNode:create(self._presenter, nodeOutCard, localSeat)
end

function GamePlayerNode:initPnlClockCircle()
    local spCircleGreen = self:seekChildByName("KW_SP_CIRCLE_GREEN")
    self._clockProgress = display.newProgressTimer(spCircleGreen, display.PROGRESS_TIMER_RADIAL)
    self._clockProgress:setPosition(cc.p(spCircleGreen:getPosition()))
    self._clockProgress:setReverseDirection(true)
    spCircleGreen:setVisible(false)

    local pnlClockCircle = self:seekChildByName("KW_PNL_CLOCK_CIRCLE")
    pnlClockCircle:addChild(self._clockProgress)
end
----------------------------------------onClick----------------------------------------
function GamePlayerNode:onClickImgFace()
    print("onClickImgFace", self._localSeat)
    self._presenter:onClickImgFace(self._localSeat)
end
----------------------------------------------------------------------------------------------
----------------------------------------onTouch----------------------------------------
function GamePlayerNode:onTouchBtnGameMenuStoreEntance()
    print("onTouchBtnGameMenuStoreEntance")
    self._presenter:onTouchBtnGameMenuStoreEntance()
end
----------------------------------------------------------------------------------------------

-- 玩家进入
function GamePlayerNode:onPlayerEnter()    
    local player = app.game.PlayerData.getPlayerByLocalSeat(self._localSeat)

    -- 显示用户节点    
    self:showPnlPlayer(true)

    -- 设置姓名
    self:showTxtPlayerName(true, player:getNickname())
    -- 设置ID
    self:showTxtPlayerID(true, player:getNumID())
    -- 设置金币
    self:showTxtSR(true, player:getSR())
    -- 显示头像
    self:showImgFace(player:getSex(), player:getHead(), player:getHeadURL())

    -- 设置准备标志
    self:showImgReadyFlag(player:isReady())                                    
    -- 玩家已准备

    -- 隐藏时钟
    self:showPnlClockCircle(false)

    -- 显示断线标志
    self:showImgOfflineFlag(player:isOffLine())

    -- 如果不在游戏中，隐藏一些UI
    if not player:isPlaying() then
        -- 隐藏不出标志
        self:showImgCancelFlag(false)                                    
        -- 隐藏托管标志
        self:showImgTrustFlag(false)                                     
        -- 隐藏排名
        self:showPnlRank(false)                                     
        
        if self._localSeat ~= app.game.GameEnum.HERO_LOCAL_SEAT then
            --播放玩家进入动画
            self:playAnimationPlayerEnter()
        end
    end

    if not player:isPlaying() then
        self._gameHandCardNode:resetHandCards()
    end

    if player:isReady() or not player:isPlaying() then
        self._gameOutCardNode:resetOutCards()
    end

    self:showImgFaceIce(false)
end

-- 重置桌子
function GamePlayerNode:onResetTable()
    if self._localSeat == app.game.GameEnum.HERO_LOCAL_SEAT then
        self:onPlayerEnter()
    else
        self:onPlayerLeave()
    end
end

-- 玩家离开
function GamePlayerNode:onPlayerLeave()
    if self._localSeat ~= app.game.GameEnum.HERO_LOCAL_SEAT then
        self:showPnlPlayer(false)
    end

    self:showPnlClockCircle(false)
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

-- 玩家点击开始前 时钟计时
function GamePlayerNode:onPlayerTimer(time)
    -- 显示时钟
    self:showPnlClockCircle(true, time)
end

-- 开始游戏
function GamePlayerNode:onGameStart(time)
    -- 隐藏准备标志
    self:showImgReadyFlag(false)
    -- 隐藏时钟
    self:showPnlClockCircle(false)
    -- 隐藏排名
    self:showPnlRank(false)
end

-- 发牌
function GamePlayerNode:onTakeFirst(cardID, cardNum)
    self._gameHandCardNode:onTakeFirst(cardID)

    self:showPnlHandCard(true, cardNum)
end

function GamePlayerNode:onClock(time, isFirst)
    if not isFirst then
        -- 隐藏该作为玩家出掉的牌
        self._gameOutCardNode:resetOutCards()

        -- 隐藏该座位玩家的不出标志
        self:showImgCancelFlag(false)
    end

    self:showPnlClockCircle(true, time)
end

function GamePlayerNode:onClockEx()
    -- 隐藏该作为玩家出掉的牌
    self._gameOutCardNode:resetOutCards()

    -- 隐藏该座位玩家的不出标志
    self:showImgCancelFlag(false)
end

function GamePlayerNode:showPartnerCards(visible, cards, isMingPai)
    if visible then
        if not isMingPai and self._localSeat == app.game.GameEnum.HERO_LOCAL_SEAT then
            self._presenter:showSortCardBtn(false)
        end

        self._gameHandCardNode:createCards(cards)
    else
        self._gameHandCardNode:resetHandCards()
    end
end

-- 显示用户节点    
function GamePlayerNode:showPnlPlayer(visible)
    self._rootNode:setVisible(visible)
end

function GamePlayerNode:showPnlPlayerDetail(visible)
    local pnlPlayerDetail = self:seekChildByName("KW_PNL_PLAYER_DETAIL")
    pnlPlayerDetail:setVisible(visible)
end

-- 姓名
function GamePlayerNode:showTxtPlayerName(visible, nickName)
    local txtPlayerName = self:seekChildByName("KW_TXT_PLAYER_NAME")

    if visible then
        if self._localSeat ~= app.game.GameEnum.HERO_LOCAL_SEAT then
            nickName = app.util.ToolUtils.nameToShort(nickName, 8)
        else
            nickName = app.util.ToolUtils.nameToShort(nickName, 10)
        end

        txtPlayerName:setString(nickName)

        local txtSize = txtPlayerName:getContentSize()
        if self._localSeat ~= app.game.GameEnum.HERO_LOCAL_SEAT then 
            if txtSize.width > 80 then 
                if self._localSeat == app.game.GameEnum.HERO_LOCAL_SEAT + 1 then
                    txtPlayerName:setAnchorPoint(cc.p(1, 0.5))
                    txtPlayerName:setPosition(cc.p(0, 29.5))    
                else
                    txtPlayerName:setAnchorPoint(cc.p(0, 0.5))
                    txtPlayerName:setPosition(cc.p(0, 29.5))    
                end
            else
                txtPlayerName:setAnchorPoint(cc.p(0.5, 0.5))
                txtPlayerName:setPosition(cc.p(40, 29.5))
            end
        end
    end

    txtPlayerName:setVisible(visible)
end

-- ID
function GamePlayerNode:showTxtPlayerID(visible, id)
    local txtPlayerID = self:seekChildByName("KW_TXT_PLAYER_ID")
    if visible then
        txtPlayerID:setString("id:"..id)

        if self._localSeat ~= app.game.GameEnum.HERO_LOCAL_SEAT then
            if self._localSeat == app.game.GameEnum.HERO_LOCAL_SEAT + 1 then
                txtPlayerID:setAnchorPoint(cc.p(1, 0.5))
                txtPlayerID:setPosition(cc.p(0, 12.5)) 
            else
                txtPlayerID:setAnchorPoint(cc.p(0, 0.5))
                txtPlayerID:setPosition(cc.p(0, 12.5)) 
            end
        end
    end

    txtPlayerID:setVisible(visible)
end

-- 排名
function GamePlayerNode:showPnlRank(visible, rank)
    local pnlRank = self:seekChildByName("KW_PNL_RANK")
    local imgRank = self:seekChildByName("KW_IMG_RANK")

    if rank == 0 or rank == 4 then
        pnlRank:setVisible(false)
        return
    end

    if visible then
        local resPath = string.format("Game/ShuangKou/Images/Img/Common/img_rank_%d.png", rank)
        imgRank:loadTexture(resPath, ccui.TextureResType.plistType)

        if rank == 1 then
            local nodeRankEffect = self:seekChildByName("KW_NODE_RANK_EFFECT")

            local action = cc.CSLoader:createTimeline("Game/Public/CSB/RankEffectNode.csb")
            action:gotoFrameAndPlay(0, false)
            nodeRankEffect:runAction(action)

            local next = function()
                imgRank:setVisible(visible)
            end

            action:setLastFrameCallFunc(next)

        else
            imgRank:setVisible(visible)
        end
    else
        imgRank:setVisible(visible)
    end

    pnlRank:setVisible(visible)
end

-- 时钟
function GamePlayerNode:showPnlClockCircle(visible, time)
    local pnlClockCircle = self:seekChildByName("KW_PNL_CLOCK_CIRCLE")
    if visible then
        self._presenter:openSchedulerClock(self._localSeat, time)
    else
        self._presenter:closeSchedulerClock(self._localSeat)
    end

    pnlClockCircle:setVisible(visible)
end
function GamePlayerNode:showParTimer(time, allTime, width, height)
    local parTimer = self:seekChildByName("KW_PAR_TIMER")
    app.util.UIUtils.setParticleTimerPos(parTimer, time / allTime * 100, width, height)
end
function GamePlayerNode:showClockProgress(percentage)
    self._clockProgress:setPercentage(percentage)
end
function GamePlayerNode:showFntClock(time)
    local fntClock = self:seekChildByName("KW_FNT_CLOCK")
    local strTime = string.format("%d", math.ceil(time))

    fntClock:setString(strTime)
end
function GamePlayerNode:getPnlClockCircle()           return self:seekChildByName("KW_PNL_CLOCK_CIRCLE") end

-- 金币
function GamePlayerNode:showTxtSR(visible, sr)
    local txtSR = self:seekChildByName("KW_TXT_SR")

    if txtSR then
        if sr ~= nil then
            txtSR:setString(app.util.ToolUtils.numConversionByDecimal(tostring(sr)))
        end
        txtSR:setVisible(visible)
    end
end

-- 头像
function GamePlayerNode:showImgFace(sex, head, strHeadUrl)
    local imgFace = self:seekChildByName("KW_IMG_FACE")
    local resPath = string.format("Lobby/Images/Public/Img/Head/img_head_%d_%d.png", sex, head)
    imgFace:loadTexture(resPath, ccui.TextureResType.plistType)

    if strHeadUrl ~= "" then
        app.logic.download.NetworkResLogic:getInstance():getWXHead(strHeadUrl, 96, function(strHeadImgPath)
            imgFace:loadTexture(strHeadImgPath, ccui.TextureResType.localType)

            local size = imgFace:getContentSize()
            local scaleRate = 77 / size.width;
            imgFace:setScale(scaleRate, scaleRate)

            -- local father = imgFace:getParent()
            -- local zorder = imgFace:getLocalZOrder()

            -- imgFace:removeFromParent()

            -- local x, y = imgFace:getPosition()
            -- local clipper = app.util.UIUtils.runHeadClipper(imgFace, x, y, 0.44)

            -- father:addChild(clipper)
            -- clipper:setLocalZOrder(zorder)
        end)
    else
        local size = imgFace:getContentSize()
        local scaleRate = 77 / size.width;
        imgFace:setScale(scaleRate, scaleRate)
    end
end

-- 手牌
function GamePlayerNode:showPnlHandCard(visible, cardNum)
    local pnlHandCard = self:seekChildByName("KW_PNL_HAND_CARD")
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
    local fntHandCardCount = self:seekChildByName("KW_FNT_HAND_CARD_COUNT")
    if visible then
        fntHandCardCount:setString(cardNum)
    end

    fntHandCardCount:setVisible(visible)
end

-- 断线状态 
function GamePlayerNode:showImgOfflineFlag(visible)
    local imgOfflineFlag = self:seekChildByName("KW_IMG_OFFLINE_FLAG")
    imgOfflineFlag:setVisible(visible)
end

-- 玩家托管
function GamePlayerNode:showImgTrustFlag(visible)
    local imgTrustFlag = self:seekChildByName("KW_IMG_TRUST_FLAG")
    imgTrustFlag:setVisible(visible)
end

-- 准备标志
function GamePlayerNode:showImgReadyFlag(visible)
    local imgReadyFlag = self:seekChildByName("KW_IMG_READY_FLAG")
    if visible then
        app.util.SoundUtils.playReadyEffect()
    end

    imgReadyFlag:setVisible(visible)
end

-- 过牌标志
function GamePlayerNode:showImgCancelFlag(visible)
    local imgCancelFlag = self:seekChildByName("KW_IMG_CANCEL_FLAG")
    if visible then
        app.util.SoundUtils.playCancelEffect()
    end

    imgCancelFlag:setVisible(visible)
end

-- 对话
function GamePlayerNode:showPnlChat(visible, str)
    local pnlChat = self:seekChildByName("KW_PNL_CHAT")
    if visible then
        self:showTxtChat(str)
    end
    pnlChat:setVisible(visible)
end
function GamePlayerNode:showTxtChat(visible, str)
    local txtChat = self:seekChildByName("KW_TXT_CHAT")
    if visible then
        txtChat:setString(str)
    end

    txtChat:setVisible(visible)
end

-- 冰块效果
function GamePlayerNode:showImgFaceIce(visible)
    local imgFaceIce = self:seekChildByName("KW_IMG_FACE_ICE")

    if visible then
        imgFaceIce:setLocalZOrder(2)
    end
    
    imgFaceIce:setVisible(false)
end

function GamePlayerNode:dealPlayerTalk(chatKind, color, index, sex)
    if chatKind == app.game.CardProtocol.msgTalkMsg.CHATKIND.COMMON then
        self:dealTalk(color, index, sex)
    elseif chatKind == app.game.CardProtocol.msgTalkMsg.CHATKIND.EMOTION then
        self:dealExpress(color, index, sex)
    end
end

function GamePlayerNode:dealTalk(color, index, sex)
    local pnlTalk = self:seekChildByName("KW_PNL_TALK")
    local txtTalk = self:seekChildByName("KW_TXT_TALK")

    local nodeExpress = self:seekChildByName("KW_NODE_EXPRESS")

    local talkList = app.game.GameEnum.ChatTalk

    local isFind = false
    for i = 1, #talkList do
        if index == talkList[i].index then 
            index = i
            isFind = true
            break
        end
    end

    if not talkList[index] or not isFind then
        return
    end

    nodeExpress:removeAllChildren()
    pnlTalk:setVisible(true)
    nodeExpress:setVisible(false)

    local text = talkList[index].text
    if string.len(text) > 27 then
        txtTalk:setFontSize(18)
    else
        txtTalk:setFontSize(20)
    end 
    txtTalk:setString(text)

    pnlTalk:stopAllActions()      
    pnlTalk:setOpacity(255)
    pnlTalk:setScale(0)

    pnlTalk:runAction(cc.Sequence:create(
        cc.ScaleTo:create(0.2, 1.0), 
        cc.DelayTime:create(1.5),
        cc.FadeOut:create(1))
    )

    --未开启配音的话不播放配音
    if not app.data.SetData.isOpenDub() then 
        return 
    end
    
    local soundPath = "Game/ShuangKou/Sound/PTH/"     --默认普通话

    local style = app.data.SetData.getDubType()
    if style == app.GameConstants.SoundStyle.WEN_ZHOU_HUA then
        soundPath = "WZH/"
    elseif style == app.GameConstants.SoundStyle.QU_ZHOU_HUA then
        soundPath = "QZH/"
    end

    local strRes = talkList[index].path
    if sex == bf.GameMXY.PlayerInfo.SEX.FEMALE then
        strRes = "Speak_Women/"..strRes
    else
        strRes = "Speak_Man/"..strRes
    end

    local path = cc.FileUtils:getInstance():fullPathForFilename(soundPath..strRes)
    if not io.exists(path) then 
        soundPath = "Game/ShuangKou/Sound/PTH/" 
    end

    app.util.SoundUtils.playEffect(soundPath..strRes)
end

function GamePlayerNode:dealExpress(color, index, sex)
    local pnlTalk = self:seekChildByName("KW_PNL_TALK")

    local nodeExpress = self:seekChildByName("KW_NODE_EXPRESS")

    expressList = app.game.GameEnum.ChatExpress

    local isFind = false
    for i = 1, #expressList do
        if index == expressList[i].index then 
            index = i
            isFind = true
            break
        end
    end

    if not expressList[index] or not isFind then
        return
    end

    nodeExpress:removeAllChildren()
    pnlTalk:setVisible(false)  
    nodeExpress:setVisible(true)

    local imgEffect  = string.split(expressList[index].image, "img")
    local imgEffects = string.split(tostring(imgEffect[2]), ".png")
    local imgs       = "effect"..tostring(imgEffects[1])

    local talkEffect = app.util.UIUtils.runEffectOne("BiaoQing", imgs, 0, 0, nil, nil, 2)
    nodeExpress:addChild(talkEffect)
end

function GamePlayerNode:showCharmScore(score, num)
    local nodeCharmScoreAdd = self:seekChildByName("KW_NODE_CHARM_SCORE_ADD") 
    local nodeCharmScoreDesc = self:seekChildByName("KW_NODE_CHARM_SCORE_DESC") 

    local totalScore = tonumber(score * num)
    if totalScore > 0 then
        local txtScore = nodeCharmScoreAdd:getChildByName("KW_TXT_CHARM_ADD_SCORE")
        txtScore:setString("+"..tostring(totalScore))

        nodeCharmScoreAdd:setVisible(true)
        nodeCharmScoreDesc:setVisible(false)

        local rolAction = cc.CSLoader:createTimeline("Game/Public/CSB/CharmAddNode.csb")
        nodeCharmScoreAdd:runAction(rolAction)
        rolAction:gotoFrameAndPlay(0, 55, 0, false)
    else
        local txtScore = nodeCharmScoreDesc:getChildByName("KW_TXT_CHARM_DESC_SCORE")
        txtScore:setString(tostring(totalScore))

        nodeCharmScoreAdd:setVisible(false)
        nodeCharmScoreDesc:setVisible(true)

        local rolAction = cc.CSLoader:createTimeline("Game/Public/CSB/CharmDescNode.csb")
        nodeCharmScoreDesc:runAction(rolAction)
        rolAction:gotoFrameAndPlay(0, 55, 0, false)
    end
end

function GamePlayerNode:playAnimationPlayerEnter()
    self:showPnlPlayerDetail(false)

    local nodePlayerSmoke = self:seekChildByName("KW_NODE_PLAYER_SMOKE")
    local action = cc.CSLoader:createTimeline("Game/Public/CSB/PlayerEnterExitNode.csb")
    action:gotoFrameAndPlay(0, false)
    nodePlayerSmoke:runAction(action)
    
    local function onFrameEvent(frame)
        local event = frame:getEvent()
        if event == "enter" then 
            self:showPnlPlayerDetail(true)
        end
    end

    action:setFrameEventCallFunc(onFrameEvent)
end

function GamePlayerNode:getGameHandCardNode()
    return self._gameHandCardNode
end

function GamePlayerNode:getGameOutCardNode()
    return self._gameOutCardNode
end

function GamePlayerNode:playOutCardVoice(typeID, power, sex, style)
    local weight = power
    local sex = sex or 0

    local strRes=""
    local soundPath = ""

    --TODO:下面三句是遗留代码
    if (weight == 19)then weight = 2 end
    if (weight == 21)then weight = 15 end
    if (weight == 22)then weight = 16 end

    local CardType = app.game.CardRule.cardType
    local SKCardType = app.game.GameEnum.CardType

    if typeID == CardType.CTID_YI_ZHANG then
        strRes = string.format("1_%d.mp3", weight)
    elseif typeID == CardType.CTID_ER_ZHANG then
        strRes = string.format("2_%d.mp3", weight)
    elseif typeID == CardType.CTID_SAN_ZHANG then
        strRes = string.format("3_%d.mp3", weight)
    elseif typeID == CardType.CTID_SI_ZHANG then
        strRes = string.format("4_%d.mp3", weight)
    elseif typeID == CardType.CTID_WU_ZHANG then
        strRes = string.format("5_%d.mp3", weight)
    elseif typeID == CardType.CTID_LIU_ZHANG then
        strRes = string.format("6_%d.mp3",weight)
    elseif typeID == CardType.CTID_QI_ZHANG then
        strRes = string.format("7_%d.mp3",weight)
    elseif typeID == CardType.CTID_BA_ZHANG then
        strRes = string.format("8_%d.mp3",weight)
    elseif typeID == CardType.CTID_YI_SHUN then
        strRes = "px_1_shunzi.mp3"
    elseif typeID == CardType.CTID_ER_SHUN then
        strRes = "px_2_jiemeidui.mp3"
    elseif typeID == CardType.CTID_SAN_SHUN then
        strRes = "px_3_santuobei.mp3"
    elseif typeID == SKCardType.CTID_TIAN_WANG then
        strRes = "wangzha_4.mp3"
    end

    print("soundPath:"..strRes)

    soundPath = "Game/ShuangKou/Sound/PTH/"               --默认普通话
    if style == app.GameConstants.SoundStyle.WEN_ZHOU_HUA then
        soundPath = "WZH/"
    elseif style == app.GameConstants.SoundStyle.QU_ZHOU_HUA then
        soundPath = "QZH/"
    end

    if (strRes == "") then 
        return 
    end

    local sex = tonumber(sex)
    if sex == bf.GameMXY.PlayerInfo.SEX.FEMALE then
        strRes = "Women/"..strRes
    else
        strRes = "Man/"..strRes
    end

    local path =  cc.FileUtils:getInstance():fullPathForFilename(soundPath..strRes)
    if not io.exists(path) then 
        soundPath = "Game/ShuangKou/Sound/PTH/" 
    end

    app.util.SoundUtils.playEffect(soundPath..strRes)
end

function GamePlayerNode:movePartner()
    self._rootNode:setPositionX(self._rootNode:getPositionX() - 200)
    self._gameOutCardNode:movePartner()
    self:moveImgCancelFlag()
end

function GamePlayerNode:moveImgCancelFlag()
    local imgCancelFlag = self:seekChildByName("KW_IMG_CANCEL_FLAG")
    imgCancelFlag:setPositionX(imgCancelFlag:getPositionX() + 200)
end

function GamePlayerNode:adaptIphoneX()
    if self._localSeat == app.game.GameEnum.HERO_LOCAL_SEAT - 1 then
        self._rootNode:setPositionX(self._rootNode:getPositionX() + 200)
    elseif self._localSeat == app.game.GameEnum.HERO_LOCAL_SEAT + 1 then
        self._rootNode:setPositionX(self._rootNode:getPositionX() - 200)
    end
end

return GamePlayerNode