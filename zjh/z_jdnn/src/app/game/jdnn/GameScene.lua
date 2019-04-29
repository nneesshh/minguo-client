--[[
@brief  游戏主场景UI基类
]]
local GameScene   = class("GameScene", app.base.BaseScene)

-- csb路径
GameScene.csbPath = "game/jdnn/csb/gamescene.csb"

local GE   = app.game.GameEnum

GameScene.touchs = {
    "btn_exit", 
}

GameScene.clicks = {
    "btn_menu",   
}

GameScene.events = {
    "cbx_banker_test",
    "cbx_mult_test",
    "cbx_cal_test"
}

function GameScene:onTouch(sender, eventType)
    GameScene.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then        
        if name == "btn_exit" then
            self._presenter:sendLeaveRoom()                             
        end
    end
end

function GameScene:onEvent(sender, eventType)
    local name = sender:getName()
    if name == "cbx_banker_test" then
        if eventType == ccui.CheckBoxEventType.selected then  
            self:setSelected(true, name)                          
            self._presenter:onEventCbxBanker()            
        elseif eventType == ccui.CheckBoxEventType.unselected then            
            self:setSelected(false, name)                                              
        end
    elseif name == "cbx_mult_test" then
        if eventType == ccui.CheckBoxEventType.selected then  
            self:setSelected(true, name)          
            self._presenter:onEventCbxMult()                
        elseif eventType == ccui.CheckBoxEventType.unselected then            
            self:setSelected(false, name)                   
        end
    elseif name == "cbx_cal_test" then 
        if eventType == ccui.CheckBoxEventType.selected then  
            self:setSelected(true, name)          
            self._presenter:onEventCbxCal()            
        elseif eventType == ccui.CheckBoxEventType.unselected then            
            self:setSelected(false, name)
        end
    end
end

function GameScene:setSelected(flag, name)
    local cbx = self:seekChildByName(name)
    if cbx then
        cbx:setSelected(flag)
    end
end

function GameScene:isSelected(name)
    local cbx = self:seekChildByName(name)
    if cbx then
        return cbx:isSelected()
    end
    return false
end

function GameScene:exit()
    GameScene.super.exit(self)

    GameScene._instance = nil
end

function GameScene:initData()    
    math.randomseed(tostring(os.time()):reverse():sub(1, 7))
end 

function GameScene:initUI()
    self:showBase()  
    
    self:setSelected(false, "cbx_banker_test")
    self:setSelected(false, "cbx_mult_test")
    self:setSelected(false, "cbx_cal_test")
end

function GameScene:showBase()
    local base = app.game.GameConfig.getBase()
    local fntbase = self:seekChildByName("txt_base_score")
    fntbase:setString("底分 " .. base)
end

function GameScene:showPnlHint(type)
    local nodeHint1 = self:seekChildByName("node_hint_1")
    local nodeHint2 = self:seekChildByName("node_hint_2")
    local nodeHint3 = self:seekChildByName("node_hint_3")
    if nodeHint1 then
        -- 开始倒计时
        if type == 1 then            
            nodeHint2:setVisible(false)
            nodeHint3:setVisible(false)
            self._presenter:closeSchedulerRunLoading()
            self._presenter:openSchedulerPrepareClock(3)   
            nodeHint1:setVisible(true)         
        -- 等待
        elseif type == 2 then
            nodeHint1:setVisible(false)            
            nodeHint3:setVisible(false)      
            self._presenter:closeSchedulerPrepareClock()     
            self._presenter:openSchedulerRunLoading("请耐心等待其他玩家") 
            nodeHint2:setVisible(true)           
        -- 换桌成功   
        elseif type == 3 then
            nodeHint1:setVisible(false)
            nodeHint2:setVisible(false)            
            local txt = nodeHint3:getChildByName("txt_wait")
            txt:setString("换桌成功!")
            nodeHint3:setVisible(true)
            self._presenter:closeSchedulerRunLoading()
            self._presenter:closeSchedulerPrepareClock()
        elseif type == 4 then
            nodeHint1:setVisible(false)            
            nodeHint3:setVisible(false)
            self._presenter:closeSchedulerPrepareClock()   
            self._presenter:openSchedulerRunLoading("您正在旁观，请等待下一局开始")  
            nodeHint2:setVisible(true)          
        else
            nodeHint1:setVisible(false)
            nodeHint2:setVisible(false)
            nodeHint3:setVisible(false)
            self._presenter:closeSchedulerRunLoading()
            self._presenter:closeSchedulerPrepareClock()
        end
    end       
end

function GameScene:setTxtwait(txt)
    local txtNode = self:seekChildByName("txt_wait")
    if txtNode then
        txtNode:setString(txt)
    end    
end

function GameScene:showClockPrepare(time)
    local fntClock = self:seekChildByName("fnt_hint_clock")
    if fntClock then
        fntClock:setString(time)
    end    
end

-- 结算飞金币
function GameScene:playFlyGoldAction(from, to, callback)
    print("enter fly")
    
--    if from ~= to then
--        if from == 1 then
--            self:showLoseEffect() 
--        end
--        if to == 1 then
--            self:showWinEffect()
--        end
--    end

    local pnlfrom = self:seekChildByName("pnl_player_" .. from)
    local fx, fy = pnlfrom:getPosition()      
    local pnlto = self:seekChildByName("pnl_player_" .. to)
    local tx,ty = pnlto:getPosition()  
    fx, fy = fx+40, fy-40
    tx, ty = tx+40, ty-40
    
    local function getAvgRandom(a,b)
        if b<a then return nil end
        local powA = math.pow(a,2)
        local powB = math.pow(b,2)
        local randC = math.random(powA,powB)
        return math.sqrt(randC)
    end
    
    local pnl = self:seekChildByName("player")
    local img = self:seekChildByName("img_fly_gold")
    
    local num = math.random(5, 10)
    for i=1, num do
        local gold = img:clone()        
        gold:setPosition(cc.p(fx,fy))
        gold:setVisible(false)    
        pnl:addChild(gold)  
        local function next()
            pnl:removeChild(gold,true)
            
            if callback and i == num then
                callback()
            end
        end
        
        local tmpToX = tx + getAvgRandom(0,30) * math.random(-1,1)
        local tmpToY = ty + getAvgRandom(0,30) * math.random(-1,1) 
        
        local action = cc.Sequence:create(
            cc.DelayTime:create(0.08*i),
            cc.Show:create(),
            cc.EaseSineInOut:create(cc.MoveTo:create(0.7, cc.p(tmpToX, tmpToY))),
            cc.DelayTime:create(0.1),
            cc.CallFunc:create(next)) 
                     
        gold:runAction(action)       
    end
    self._presenter:playEffectByName("fly")    
end

-- 游戏开始
function GameScene:showStartEffect()
    local node = self:seekChildByName("node_start_effect")
    node:removeAllChildren()
    node:stopAllActions()
    
    local effect = app.util.UIUtils.runEffectOne("game/jdnn/effect","jiubei_dh", 0, 85)
    node:addChild(effect)
end

-- 胜利
function GameScene:showWinEffect()
    local node = self:seekChildByName("node_win")
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/jdnn/effect","nnshengli_dh", 0, 0)
    node:addChild(effect)

    self._presenter:playEffectByName("win")
end

-- 失败
function GameScene:showLoseEffect()
    local node = self:seekChildByName("node_lose")
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/jdnn/effect","nnsbai_dh", 0, 0)
    node:addChild(effect)

    self._presenter:playEffectByName("lose")
end

function GameScene:showWinloseEffect(flag, heroseat)
	if flag then       
	   print("win")
	    self:showWinEffect()
	else        
	   print("lose")
		self:showLoseEffect()
	end
end

-- 通杀
function GameScene:showTongShaEffect()
    local effect = app.util.UIUtils.runEffectOne("game/jdnn/effect","tongsha", 0, 20)
    self:seekChildByName("node_start_effect"):addChild(effect)
    
    self._presenter:playEffectByName("bankerwin")
end

-- 炸弹牛 五花牛 五小牛
function GameScene:showSpecialNiuType(index)
    local node = self:seekChildByName("node_niu_type")
    local imgniu = self:seekChildByName("whn_2")
    local res = string.format("game/jdnn/image/img_type_%d.png", index)
    local sp = cc.Sprite:createWithSpriteFrameName(res)
    imgniu:setSpriteFrame(sp:getSpriteFrame())
    local action = cc.CSLoader:createTimeline("game/jdnn/csb/niutype.csb")
    action:gotoFrameAndPlay(0, false)
    action:setTimeSpeed(0.33)
    node:runAction(action)
    
    self._presenter:playEffectByName(string.format("m_niu_%d", index))
end

return GameScene