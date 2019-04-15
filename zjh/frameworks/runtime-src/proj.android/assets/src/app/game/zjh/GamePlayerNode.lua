--[[
    @brief  游戏玩家类
]]--
local GameHandCardNode = require("app.game.zjh.GameHandCardNode")

local GamePlayerNode   = class("GamePlayerNode", app.base.BaseNodeEx)

local HERO_LOCAL_SEAT  = 1 
local ST = app.game.GameEnum.soundType

function GamePlayerNode:initData(localSeat)
    self._localSeat         = localSeat
    self._clockProgress     = nil
    
    math.randomseed(tostring(os.time()):reverse():sub(1, 7))
end

function GamePlayerNode:initUI(localSeat)
    self:initNodeHandCard(localSeat)
    self:initPnlClockCircle()
end

function GamePlayerNode:initNodeHandCard(localSeat)
    local nodeHandCard = self:seekChildByName("node_hand_card")
    self._gameHandCardNode = GameHandCardNode:create(self._presenter, nodeHandCard, localSeat)    
end

function GamePlayerNode:initPnlClockCircle()
    local spLight = self:seekChildByName("sp_light")
    if spLight == nil then
    	return
    end
    self._clockProgress = cc.ProgressTimer:create(spLight)
    self._clockProgress:setType(0)
    self._clockProgress:setPosition(cc.p(spLight:getPosition()))
    self._clockProgress:setReverseDirection(true)
    spLight:setVisible(false)

    local pnlClockCircle = self:seekChildByName("pnl_progress")
    pnlClockCircle:addChild(self._clockProgress)
end

-- 玩家进入
function GamePlayerNode:onPlayerEnter()  
    local player = app.game.PlayerData.getPlayerByLocalSeat(self._localSeat)

    -- 显示用户节点    
    self:showPnlPlayer(true)
    -- 设置姓名
    self:showTxtPlayerName(true, player:getTicketID())
    -- 设置金币
    self:showTxtBalance(true, player:getBalance())
    -- 显示头像
    self:showImgFace(player:getGender(), player:getAvatar())
    -- 隐藏庄家
    self:showImgBanker(false)
    -- 隐藏庄家框
    self:showImgBankerLight(false)
    -- 隐藏已押注框
    self:showImgBet(false,0)
    -- 隐藏看牌
    self:showImgCheck(false)
    -- 隐藏牌型
    self:showImgCardType(false)
    -- 隐藏黑遮罩
    self:showPnlBlack(false)
    -- 隐藏时钟
    self:showPnlClockCircle(false)
    -- 隐藏手牌
    self._gameHandCardNode:resetHandCards()    
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
    -- 隐藏庄家框
    self:showImgBankerLight(false)
    -- 隐藏已押注框
    self:showImgBet(false,0)
    -- 隐藏看牌
    self:showImgCheck(false)
    -- 隐藏牌型
    self:showImgCardType(false)
    -- 隐藏黑遮罩
    self:showPnlBlack(false)
    -- 隐藏时钟
    self:showPnlClockCircle(false)
    -- 隐藏手牌
    self._gameHandCardNode:resetHandCards()
end

-- 发牌
function GamePlayerNode:onTakeFirst(cardID)
    self._gameHandCardNode:onTakeFirst(cardID)
end

-- 时钟
function GamePlayerNode:onClock(time)
    self:showPnlClockCircle(true, time)
end

-- 显示用户节点    
function GamePlayerNode:showPnlPlayer(visible)
    self._rootNode:setVisible(visible)
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
    
end

-- 庄家
function GamePlayerNode:showImgBanker(visible)
    local imgBanker = self:seekChildByName("img_banker")
    imgBanker:setVisible(visible)
end

-- 庄家光
function GamePlayerNode:showImgBankerLight(visible)
    local imgLight = self:seekChildByName("img_light")
    imgLight:setVisible(visible)
end

-- 押注详情
function GamePlayerNode:showImgBet(visible, num)
    local imgBet = self:seekChildByName("img_bet_back")
    imgBet:setVisible(visible)
    
    if num then
        local txt = self:seekChildByName("txt_bet")
        txt:setString(num)
    end
end

-- 是否看牌
function GamePlayerNode:showImgCheck(visible, index)
    local imgCheck = self:seekChildByName("img_check")
    imgCheck:setVisible(visible)
    
    local res
    if index == 0 then
        res = "game/zjh/image/img_check.png"
    else
        res = "game/zjh/image/img_fold.png"
    end
    
    if visible then
        imgCheck:loadTexture(res, ccui.TextureResType.plistType) 
    end
end

-- 牌型
function GamePlayerNode:showImgCardType(visible, index)
    local imgType = self:seekChildByName("img_card_type")
    imgType:setVisible(visible)
    
    if index and index >= 1 and index <= 6 then
        local resPath = "game/zjh/image/img_card_type_" .. index .. ".png"
            
        imgType:loadTexture(resPath, ccui.TextureResType.plistType)
    else
        imgType:setVisible(false)   
    end
end

-- 时钟
function GamePlayerNode:showPnlClockCircle(visible, time)
    local pnlClockCircle = self:seekChildByName("pnl_progress")
    if visible then
        self._presenter:openSchedulerClock(self._localSeat, time)
    else
        self._presenter:closeSchedulerClock(self._localSeat)
    end

    pnlClockCircle:setVisible(visible)
end

function GamePlayerNode:showClockProgress(percentage)
    self._clockProgress:setPercentage(percentage)
    if percentage <= 20 then
    	self:playEffectByName("didi")
    end
end

function GamePlayerNode:showPnlBlack(visible)
    local imgType = self:seekChildByName("panl_black")
    imgType:setVisible(visible)
end

-- 庄家动画    
function GamePlayerNode:playBankAction()
    local imgLight = self:seekChildByName("img_light") 
    local imgBanker = self:seekChildByName("img_banker")
   
    local visibleRect = cc.Director:getInstance():getOpenGLView():getVisibleRect()
    local center = cc.p(visibleRect.x + visibleRect.width*0.5,visibleRect.y + visibleRect.height*0.7)    
    local pCenter = imgBanker:convertToNodeSpace(center)
    local x,y = imgBanker:getPosition() 
    local function movebanker()
        imgBanker:setPosition(pCenter)
        imgBanker:setVisible(true)
        imgBanker:runAction(cc.MoveTo:create(0.5, cc.p(x,y)))
    end 
    imgLight:setVisible(true)    
    imgLight:runAction(        
        cc.Sequence:create(
            cc.FadeIn:create(0.1),
            cc.FadeOut:create(0.2),
            cc.FadeIn:create(0.1),
            cc.FadeOut:create(0.2),
            cc.CallFunc:create(function()
                imgLight:setVisible(false) 
                movebanker()
            end)            
           ))          
end    

function GamePlayerNode:playBlinkAction()
    local imgLight = self:seekChildByName("img_light") 
    imgLight:setVisible(true)
    imgLight:runAction(cc.RepeatForever:create(     
        cc.Sequence:create(
            cc.FadeIn:create(0.2),
            cc.FadeOut:create(0.5)               
        )))      
end

function GamePlayerNode:stopBlinkAction()
    local imgLight = self:seekChildByName("img_light")
    imgLight:setVisible(false)
    imgLight:stopAllActions()
end

function GamePlayerNode:playWinEffect()
    local node = self:seekChildByName("node_effect")
    local effect = app.util.UIUtils.runEffectOne("game/zjh/effect", "vs_dh3", 0, -25)
    node:addChild(effect)
end

function GamePlayerNode:playLoseEffect()
    local node = self:seekChildByName("node_effect")
    local effect = app.util.UIUtils.runEffectOne("game/zjh/effect", "vs_dh1", 0, 0)
    node:addChild(effect)
end
    
function GamePlayerNode:playPanleAction(posf, post, flag)    
    local function afunc()
        self._rootNode:setLocalZOrder(1)
        self._presenter:setCardScale(0.4, self._localSeat)        
        self:showPnlBlack(false)
        self:showImgBet(false)
        self:playEffectByName("pk")
    end
    
    local function bfunc()
        if flag then
            self:showPnlBlack(false)
            self:playWinEffect()
        else
            self:showPnlBlack(true)
            self._presenter:showGaryCard(self._localSeat)
            self:playLoseEffect()    
        end
        self:playEffectByName("pk_lose")       
    end
    
    local function cfunc()
        self._presenter:setCardScale(0.6, self._localSeat)                 
        self:showImgBet(true)        
    end
    
    self._rootNode:runAction(
        cc.Sequence:create(
                cc.CallFunc:create(function() afunc() end),
                cc.ScaleTo:create(0.2, 1.1),
                cc.MoveTo:create(0.5, cc.p(post)),                
                cc.DelayTime:create(1),        
                cc.CallFunc:create(function() bfunc() end),  
                cc.DelayTime:create(1),      
                cc.ScaleTo:create(0.2, 1),
                cc.MoveTo:create(0.5, cc.p(posf)),
                cc.DelayTime:create(0.4), 
                cc.CallFunc:create(function() cfunc() end)
        ))
end

function GamePlayerNode:playQMLWAction(flag)    
    local function func1()
        if flag then
            self:playWinEffect()
            self:showPnlBlack(false)
        else           
            self:playLoseEffect()    
            self:showPnlBlack(true)
        end                  
    end
    
    local function func2()
       self._presenter:playQMLWeffect()
    end
    
    self._rootNode:runAction(
        cc.Sequence:create(            
            cc.ScaleTo:create(0.2, 1.1),  
            cc.CallFunc:create(function() func2() end),
            cc.DelayTime:create(1),       
            cc.CallFunc:create(function() func1() end),
            cc.DelayTime:create(1), 
            cc.ScaleTo:create(0.2, 1)            
        ))
end

function GamePlayerNode:showWinloseScore(score)
    local fntScore = nil
    if score <= 0 then
        fntScore = self:seekChildByName("fnt_lose_score")
    else
        fntScore = self:seekChildByName("fnt_win_score")
        score = "+"..score
    end

    fntScore:setVisible(true)
    fntScore:setString(score)
    fntScore:setOpacity(255)

    local action = cc.Sequence:create(
        cc.MoveBy:create(0.8, cc.p(0, 30)),
        cc.Spawn:create(
            cc.MoveBy:create(0.8, cc.p(0, 30)), 
            cc.FadeOut:create(3)
        ),
        cc.MoveTo:create(0.01, cc.p(fntScore:getPosition()))
    )

    fntScore:runAction(action)        
end

 local SPEAKE = {
    "img_speak_1.png",  -- 跟注
    "img_speak_2.png",  -- 加注
    "img_speak_3.png",  -- 弃牌
 }
function GamePlayerNode:playSpeakAction(index)
    local imgSpeak = self:seekChildByName("img_speak") 	
    local resPath = "game/zjh/image/" .. SPEAKE[index]
    imgSpeak:loadTexture(resPath, ccui.TextureResType.plistType)
    
    imgSpeak:stopAllActions()   
    imgSpeak:setVisible(true)   
    imgSpeak:setOpacity(255)
    imgSpeak:setScale(0)

    imgSpeak:runAction(cc.Sequence:create(
        cc.ScaleTo:create(0.2, 1.0), 
        cc.DelayTime:create(1.5),
        cc.FadeOut:create(1))
    )
end

function GamePlayerNode:getPosition()
    return self._rootNode:getPosition()
end      
    
-- 获取手牌
function GamePlayerNode:getGameHandCardNode()
    return self._gameHandCardNode
end

function GamePlayerNode:setLocalZOrder(zorder)
    self._rootNode:setLocalZOrder(zorder)
end

function GamePlayerNode:visible()
    return self._rootNode:isVisible(), self._rootNode:getLocalZOrder()
end

-- 音效相关
function GamePlayerNode:playEffectByName(name)
    local soundPath = "game/zjh/sound/"
    local strRes = ""
    for alias, path in pairs(ST) do
        if alias == name then
            if type(path) == "table" then
                local index = math.random(1, 3)
                strRes = path[index]
            else
                strRes = path
            end
        end
    end
    local path = cc.FileUtils:getInstance():fullPathForFilename(soundPath .. strRes)
    if not io.exists(path) then 
        return
    end
    
    app.util.SoundUtils.playEffect(soundPath..strRes)   
end

return GamePlayerNode