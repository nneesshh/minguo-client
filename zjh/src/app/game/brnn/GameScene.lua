--[[
@brief  游戏主场景UI基类
]]
local GameScene   = class("GameScene", app.base.BaseScene)

-- csb路径
GameScene.csbPath = "game/brnn/csb/gamescene.csb"

local GE   = app.game.GameEnum
local CT   = app.game.GameEnum.cardsType
local HT   = app.game.GameEnum.hintType   

local CV_BACK = 0
local CV_GRAY = 888
 
GameScene.touchs = {
    "btn_exit", 
    "btn_other",
    "btn_trend",
    "btn_banker"
}

GameScene.clicks = {
    "btn_menu",
    "pnl_touch_area_1",
    "pnl_touch_area_2",
    "pnl_touch_area_3",
    "pnl_touch_area_4"     
}

local chipindex = 1
local seatindex = 1
local areaindex = 1

function GameScene:onTouch(sender, eventType)
    GameScene.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then        
        if name == "btn_exit" then 
            self._presenter:sendLeaveRoom()   
        elseif name == "btn_trend" then
            self._presenter:onTouchGoing()            
        elseif name == "btn_other" then                                  
            self._presenter:onTouchOther()                    
        elseif name == "btn_banker" then
            self._presenter:onTouchGoBanker()           
        end       
    end
end

function GameScene:onClick(sender)
    GameScene.super.onClick(self, sender)
    local name = sender:getName()
    if string.find(name, "pnl_touch_area_") then             
        local area = string.split(name, "pnl_touch_area_")[2]        
        self._presenter:onClickBetArea(tonumber(area))
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
    local roomid =  app.game.GameConfig.getRoomID()
    self:showTxtTableInfo(roomid)
    
    self:showImgTouchAreaLight(-1)
    
    for i=1, 5 do
        self:showImgNiuType(i, false)
        self:showImgNobetVisible(i, false)
        self:showTxtTouchAreaBet(i,0,0)
    end 
end

function GameScene:resetBetUI()
    for i=1, 4 do
        self:showTxtTouchAreaBet(i, 0 , 0)      
    end
end

function GameScene:showTxtTableInfo(type)
    local txt = self:seekChildByName("txt_brnn_info")
    if txt then
        local str = ""
        if type == 1 then
            str = "百人牛牛1-5倍场"
        else 
            str = "百人牛牛1-10倍场"
        end
        txt:setString(str) 
    end
end

function GameScene:showTxtTouchAreaBet(index, herobet, allbet)
    local area = self:seekChildByName("pnl_touch_area_" .. index)
    if area then
        local txthero = area:getChildByName("txt_hero_bet")
        local txtall = area:getChildByName("txt_all_bet")
        
        txthero:setString(herobet) 
        txtall:setString(allbet) 
    end
end

function GameScene:showImgTouchAreaLight(index, callback)
    local function next()
        if callback then
            callback()
        end
    end
    
    local sequence = cc.Sequence:create(
        cc.FadeIn:create(0.3),       
        cc.FadeOut:create(0.2),
        cc.DelayTime:create(0.25),        
        cc.FadeIn:create(0.3),
        cc.FadeOut:create(0.2),
        cc.DelayTime:create(0.25),
        cc.FadeIn:create(0.3),
        cc.FadeOut:create(0.2),
        cc.CallFunc:create(next))
    
    if index == -1 then
        for i=1, 4 do
            local light = self:seekChildByName("img_area_light_" .. i) 
            light:setVisible(i == index)
            light:stopAllActions()            
        end 
    end
    
    local light = self:seekChildByName("img_area_light_" .. index) 
    if light then
        light:setVisible(true)
        light:stopAllActions()        
        light:runAction(sequence)
    end   
end

function GameScene:showImgNiuType(index,visible, type)
    local imgtype = self:seekChildByName("img_niu_type_" .. index)
    if imgtype then
        if visible then
            if type ~= -1 then
                imgtype:ignoreContentAdaptWithSize(true)   
                local res = string.format("game/brnn/image/img_card_type_%d.png", type)     
                imgtype:loadTexture(res, ccui.TextureResType.plistType)    
            end            
        end
        
        if type == -1 then
            imgtype:setVisible(false)
        else
            imgtype:setVisible(visible)    
        end 
    end
end

function GameScene:showImgNobetVisible(index, visible)
    local imgbet = self:seekChildByName("img_no_bet_" .. index)
    if imgbet then
        imgbet:setVisible(visible)              
    end 
end

function GameScene:showPnlFntMultVisible(index, visible)
    local pnl = self:seekChildByName("pnl_mult_score_" .. index)
    if pnl then
        pnl:setVisible(visible)              
    end 
end

function GameScene:showFntMultScore(index, bet, mult, iswin)
    local pnl = self:seekChildByName("pnl_mult_score_" .. index)
    local fntmult = pnl:getChildByName("fnt_area_mult")
    local fntscore = pnl:getChildByName("fnt_area_score")
    
    if pnl then
        if bet ~= 0 then
            if iswin == 1 then
                fntmult:setFntFile("game/brnn/image/fnt/winfnt.fnt")
                fntscore:setFntFile("game/brnn/image/fnt/winfnt.fnt")
            else
                fntmult:setFntFile("game/brnn/image/fnt/losefnt.fnt")
                fntscore:setFntFile("game/brnn/image/fnt/losefnt.fnt")
            end
            
            fntmult:setString("x" .. mult)            
            fntscore:setString(bet * mult)
         
            pnl:setVisible(true)            
            self:showImgNobetVisible(index,false)    
        else
            pnl:setVisible(false)
            self:showImgNobetVisible(index,true)    
        end    
    end     
end

function GameScene:showHint(type)
    local nodeWait = self:seekChildByName("img_hint_wait")
    local nodeLess = self:seekChildByName("img_hint_less")
    local nodeMore = self:seekChildByName("img_hint_more")
    local nodeFull = self:seekChildByName("img_hint_full") 
    nodeLess:stopAllActions()
    nodeMore:stopAllActions()

    nodeWait:setVisible(type == "wait")
    nodeLess:setVisible(type == "less")
    nodeMore:setVisible(type == "more")   
    nodeFull:setVisible(type == "full")

    if type == "less" then
        nodeLess:runAction(cc.Sequence:create(
            cc.FadeIn:create(0.5),                       
            cc.FadeOut:create(1)
        ))
    elseif type == "more" then  
        nodeMore:runAction(cc.Sequence:create(
            cc.FadeIn:create(0.5),                       
            cc.FadeOut:create(1)
        ))    
    end 
end

-- 结算分数
function GameScene:showWinloseScore(scoreList)
    for localseat, score in pairs(scoreList) do
        print("localseat is", localseat)
        if localseat > 8 or score == -1 then
            print("localseat > 8 or score == -1")
        else
            local fntScore = nil
            local imgBack = nil

            if score <= 0 then
                imgBack = self:seekChildByName("img_desc_back_" .. localseat)
                fntScore = imgBack:getChildByName("fnt_lose_score")
            else
                imgBack = self:seekChildByName("img_add_back_" .. localseat)
                fntScore = imgBack:getChildByName("fnt_win_score")
                score = "+" .. score
            end

            fntScore:setString(score)

            imgBack:setVisible(true)    
            imgBack:setOpacity(255)

            local action = cc.Sequence:create(
                cc.MoveBy:create(0.8, cc.p(0, 15)),
                cc.Spawn:create(
                    cc.MoveBy:create(0.8, cc.p(0, 15)), 
                    cc.FadeOut:create(2)
                ),
                cc.MoveTo:create(0.01, cc.p(imgBack:getPosition()))
            )

            imgBack:runAction(action)
        end          
    end
end

function GameScene:showChipAction(index, area, localseat)    
    if index == -1 then
        print("index is -1")
        return
    end
    local pnlarea = self:seekChildByName("pnl_chip_area")
    local pnlplayer
    if localseat < 9 then
        pnlplayer = self:seekChildByName("pnl_player_" .. localseat)
    else
        pnlplayer = self:seekChildByName("btn_other")   
    end

    if not pnlplayer then return end
    
    local fx,fy = pnlplayer:getPosition()  
    local chipParent = self:seekChildByName("img_chip_clone")  

    local imgChip = chipParent:clone()   
    imgChip:loadTexture(string.format("game/brnn/image/btn_%d.png", index), ccui.TextureResType.plistType)    
    imgChip:setPosition(cc.p(fx, fy+32))    
    pnlarea:addChild(imgChip)
    local bx,ex,by,ey = self:getAreaSize(area)    
    local tx,ty = math.random(bx,ex), math.random(by,ey)            
    imgChip:runAction(cc.MoveTo:create(0.3, cc.p(tx, ty)))
    
    self:movePlayerPnl(localseat, index) 
    
    self._presenter:playEffectByName("bet")                  
end

function GameScene:showChipBackOtherAction()
    local pnlto = self:seekChildByName("btn_other")
    if not pnlto then
        print("to player 1 not found")
        return
    end    

    local pnl = self:seekChildByName("pnl_chip_area")
    local childrens = pnl:getChildren() 
    local tx,ty = pnlto:getPosition() 
    
    local count = #childrens
    local max = 0
    if count > 60 then
    	max = 60
    else
        max = count	
    end
    
    for i=1, max do
        local action = cc.Sequence:create(
            cc.DelayTime:create(0.05*i),
            cc.Show:create(),
            cc.EaseSineInOut:create(cc.MoveTo:create(0.4, cc.p(tx,ty))),
            cc.DelayTime:create(0.1),
            cc.RemoveSelf:create(),
            cc.CallFunc:create(function()
                if i == max then
                    self:removeAllChip()
                end
            end))
        childrens[i]:runAction(action)     
    end 
    if count > 0 then
        self._presenter:playEffectByName("fly")  
    end    
end

function GameScene:removeAllChip()
    local pnl = self:seekChildByName("pnl_chip_area")
    pnl:removeAllChildren()
end

-- 获取筹码区域
function GameScene:getAreaSize(area)
    local bx, ex, by, ey = 0, 0, 0, 0 
    if area == 1 then
        bx = 295
        ex = 295 + 100       
    elseif area == 2 then
        bx = 510
        ex = 510 + 100
    elseif area == 3 then
        bx = 725
        ex = 725 + 100 
    else
        bx = 940
        ex = 940 + 100          
    end
    by = 380
    ey = 380 + 100
    
    return bx, ex, by, ey
end

function GameScene:movePlayerPnl(localseat, index)
    local pnl = self:seekChildByName("pnl_player_" .. localseat)
    if not pnl then
        print("move no panl")
        return
    end

    local gox = 10
    local tox = -10   

    if index >= 5 then
        gox = gox * 3
        tox = tox * 3 
    end

    local Action
    
    if localseat % 2 == 0 or localseat == 1 then
        Action = cc.Sequence:create(
            cc.EaseSineOut:create(cc.MoveBy:create(0.2,cc.p(gox,0))),
            cc.EaseSineOut:create(cc.MoveBy:create(0.1,cc.p(tox,0)))
        )
    else
        Action = cc.Sequence:create(
            cc.EaseSineOut:create(cc.MoveBy:create(0.2,cc.p(tox,0))),
            cc.EaseSineOut:create(cc.MoveBy:create(0.1,cc.p(gox,0)))
        )
    end
    
    if Action then
        pnl:runAction(Action)
    end
end

function GameScene:showStartEffect()
    local node = self:seekChildByName("node_start_effect")
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/brnn/effect","jiubei_dh", 0, 50)
    node:addChild(effect)
end

function GameScene:showClockEffect()
    local node = self:seekChildByName("node_clock_effect")
    if node then
        node:removeAllChildren()
        node:stopAllActions()

        local effect = app.util.UIUtils.runEffectOne("game/brnn/effect","bairennn_daojishi", 0, 0)
        node:addChild(effect)
    end
end

function GameScene:showEndEffect()
    local node = self:seekChildByName("node_stop_effect")

    local rolAction = cc.CSLoader:createTimeline("game/brnn/csb/stop.csb")
    node:runAction(rolAction)
    rolAction:gotoFrameAndPlay(0, false)
end

function GameScene:showSleepEffect()
    local node = self:seekChildByName("node_clock_effect")
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/brnn/effect","bairennn_321", 0, 0)
    node:addChild(effect)
end

return GameScene