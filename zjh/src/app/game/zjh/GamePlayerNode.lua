--[[
    @brief  游戏玩家类
]]--
local GameHandCardNode = requireZJH("app.game.zjh.GameHandCardNode")

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
    
    if self._localSeat == HERO_LOCAL_SEAT then
        -- 设置姓名
        self:showTxtPlayerName(true, player:getTicketID())
        -- 设置金币
        self:showTxtBalance(true, player:getBalance())
        -- 显示头像
        self:showImgFace(player:getGender(), player:getAvatar())
    else
        -- 设置姓名
        self:showTxtPlayerName(true, "   --")
        -- 设置金币
        self:showTxtBalance(true, " --")
        -- 显示头像
        self:showImgFace(2, 0)    
    end
            
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
function GamePlayerNode:onPlayerLeave(flag)
    if not flag then
        if self._localSeat ~= HERO_LOCAL_SEAT then
            self:showPnlPlayer(false)
        end
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
function GamePlayerNode:onTakeFirst(cardID)
    self._gameHandCardNode:onTakeFirst(cardID)
end

-- 时钟
function GamePlayerNode:onClock(time)
    self:showPnlClockCircle(true, time)
end

-- 显示用户节点    
function GamePlayerNode:showPnlPlayer(visible)
    if self._rootNode then
        self._rootNode:setVisible(visible)
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
function GamePlayerNode:showImgCheck(visible)
    local imgCheck = self:seekChildByName("img_check")
    imgCheck:setVisible(visible)
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

function GamePlayerNode:showPnlBlack(visible, flag)
    local imgType = self:seekChildByName("panl_black")
    imgType:setVisible(visible)
    
    local imgfold = imgType:getChildByName("img_fold")
    imgfold:setVisible(flag)
end

function GamePlayerNode:adjustCardTypePos(x,y)
    if self._localSeat == HERO_LOCAL_SEAT then
        local imgType = self:seekChildByName("img_card_type")
        imgType:setPosition(x, y)
    end
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
    node:removeAllChildren()
    node:stopAllActions()
    
    local effect = app.util.UIUtils.runEffectOne("game/zjh/effect", "vs_dh3", 0, -25)
    node:addChild(effect)
end

function GamePlayerNode:playLoseEffect() 
    local node = self:seekChildByName("node_effect")
    node:removeAllChildren()
    node:stopAllActions()
    
    local effect = app.util.UIUtils.runEffectOne("game/zjh/effect", "vs_dh1", 0, 0)
    node:addChild(effect)
end
    
function GamePlayerNode:playPanleAction(posf, post, flag)    
    local function afunc()
        self._presenter:setCardScale(0.4, self._localSeat)
        self:adjustCardTypePos(152,-12)        
        self:showPnlBlack(false)
        self:showImgBet(false)        
        self._presenter:checkBtnShowCard(false)        
        
        if not flag then
            self:playEffectByName("pk_lose")
        end
    end
    
    local function bfunc()
        if flag then
            self:showPnlBlack(false)
            self:playWinEffect()
        else            
            self:showPnlBlack(true)
            self._presenter:showGaryCard(self._localSeat, 0.4)
            self:playLoseEffect()                
        end              
    end
    
    local function cfunc()
        self._presenter:setCardScale(0.6, self._localSeat)  
        self:adjustCardTypePos(183,-12)               
        self:showImgBet(true)        
    end
    
    local function dfunc()        
        self._presenter:showOtherPlayer() 
        self._presenter:checkBtnShowCard(true)   
    end
    
    self:playEffectByName("pk")
    
    local action1 = cc.CallFunc:create(function() afunc() end)
    local action2 = cc.MoveTo:create(0.5, cc.p(post))    
    local sp1 = cc.Spawn:create(action1, action2)
        
    local action3 = cc.CallFunc:create(function() cfunc() end)
    local action4 = cc.MoveTo:create(0.5, cc.p(posf))
    local sp2 = cc.Spawn:create(action3, action4)
    
    self._rootNode:runAction(
        cc.Sequence:create(
                cc.ScaleTo:create(0.2, 1.1),
                sp1,             
                cc.DelayTime:create(1),       
                cc.CallFunc:create(function() bfunc() end),  
                cc.DelayTime:create(1),      
                cc.ScaleTo:create(0.2, 1),
                sp2,
                cc.CallFunc:create(function() dfunc() end)                                
        ))
end

function GamePlayerNode:playQMLWAction(flag)    
    local function func1()
        if flag then
            self:playWinEffect()
            self:showPnlBlack(false)
        else 
            self:playEffectByName("pk_lose")          
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
                local index = math.random(1, #path)
                strRes = path[index]
            else
                strRes = path
            end
        end
    end
    
    app.util.SoundUtils.playEffect(soundPath..strRes)   
end

return GamePlayerNode