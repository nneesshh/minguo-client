--[[
@brief  游戏主场景UI基类
]]--

local GameScene   = class("GameScene", app.base.BaseScene)

-- csb路径
GameScene.csbPath = "game/ddz/csb/gamescene.csb"

local GE   = app.game.GameEnum
local CR   = app.game.CardRule

GameScene.touchs = {
    "btn_exit", 
    "btn_trust"
}

GameScene.clicks = {
    "btn_menu",   
}

function GameScene:onTouch(sender, eventType)
    GameScene.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then        
        if name == "btn_exit" then
--            self._presenter:sendLeaveRoom()
            self._presenter:testeffect()
        elseif name == "btn_trust" then
            self._presenter:onTouchBtnTrust()                                           
        end
    end
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
    self:showTrustRecordNode(false)    
end

function GameScene:showBase()
    local base = app.game.GameConfig.getBase()
    local fntbase = self:seekChildByName("txt_base_score")
    fntbase:setString(base)
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
        elseif type == 5 then       
            nodeHint2:setVisible(false)
            self._presenter:closeSchedulerRunLoading()  
            nodeHint3:setVisible(false)         
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

-- 游戏开始
function GameScene:showStartEffect()
    local node = self:seekChildByName("node_start_effect")
    node:removeAllChildren()
    node:stopAllActions()
    
    local effect = app.util.UIUtils.runEffectOne("game/ddz/effect","doudizhu_kaishiyouxi_dh", 0, 0)
    node:addChild(effect)
end

-- 春天
function GameScene:showSpringEffect()
    local node = self:seekChildByName("node_start_effect")
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/ddz/effect","chuentian_dh", 0, 0)
    node:addChild(effect)

    self._presenter:playEffectByName("win")
end

function GameScene:playCardEffect(cardid)
    local node = self:seekChildByName("node_start_effect")
    node:removeAllChildren()
    node:stopAllActions()

    local effect
    if cardid == CR.cardType.CTID_HUO_JIAN then
        effect = app.util.UIUtils.runEffectOne("game/ddz/effect", "huojian_dh", 0, 70)         
        self._presenter:playEffectByName("bwang") 
    elseif cardid == CR.cardType.CTID_SI_ZHANG then 
        effect = app.util.UIUtils.runEffectOne("game/ddz/effect", "zhadan_dh", 0, 70)        
        self._presenter:playEffectByName("boom") 
    elseif cardid == CR.cardType.CTID_FEI_JI then
        self:playPlaneEffect()
        self._presenter:playEffectByName("plan")     
    end

    if effect then
        node:addChild(effect)
    end
end

function GameScene:showTrustRecordNode(visible)
    local record = self:seekChildByName("node_record")
    local trust = self:seekChildByName("btn_trust") 
	
    record:setVisible(visible)
    trust:setVisible(visible)
end

function GameScene:playPlaneEffect()
    local fp, tp = {}, {}
    local szScreen = cc.Director:getInstance():getWinSize()
    fp.x, fp.y = szScreen.width-100, szScreen.height+100
    tp.x, tp.y = -100, 200

    local bezier = self:getBezierAction(fp, tp)    
    local plane = self:seekChildByName("img_plane")
    local father = plane:getParent()
    local node = plane:clone()  
    node:setPosition(fp.x, fp.y)  
    node:setVisible(true)
    node:setScale(0.5)
    father:addChild(node)

    node:runAction(cc.Sequence:create(
        cc.Spawn:create(cc.ScaleTo:create(1.2,1.3), bezier),
        cc.CallFunc:create(function()
            node:removeFromParent(true)
        end)
    ))     
end

function GameScene:getBezierAction(fromPo, toPo)
    local ctrX = (fromPo["x"] + toPo["x"]) / 1.3
    local ctrY = toPo["y"] + math.abs(fromPo["y"] - toPo["y"]) * 1 / 5   

    local ctrlPoint = cc.p(ctrX, ctrY)
    local BezierConfig = {ctrlPoint, ctrlPoint, toPo}     

    --移动的动作
    local move = cc.BezierTo:create(1.2, BezierConfig)
   
    return move
end

return GameScene