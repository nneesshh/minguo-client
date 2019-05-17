--[[
@brief  游戏主场景UI基类
]]
local GameScene   = class("GameScene", app.base.BaseScene)

-- csb路径
GameScene.csbPath = "game/zjh/csb/gamescene.csb"

local GE   = app.game.GameEnum

GameScene.touchs = {
    "btn_exit", 
    "btn_show_card",  
}

GameScene.clicks = {
    "btn_menu",
    "pnl_player_0",
    "pnl_player_1",
    "pnl_player_2",
    "pnl_player_3",
    "pnl_player_4",
    "pnl_bipai"    
}

GameScene.events = {
    "cbx_gdd_test"
}

function GameScene:onTouch(sender, eventType)
    GameScene.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then        
        if name == "btn_exit" then
            self._presenter:sendLeaveRoom()
        elseif name == "btn_show_card" then
            self._presenter:onTouchBtnKanpai()
        end
    end
end

function GameScene:onClick(sender)
    GameScene.super.onClick(self, sender)
    local name = sender:getName()
    if string.find(name, "pnl_player_") then 
        local localseat = string.split(name, "pnl_player_")[2]
        self._presenter:onTouchPanelBiPai(tonumber(localseat))  
    elseif name == "pnl_bipai" then
        self._presenter:playBiPaiPanel(false, true)  
    end    
end

function GameScene:onEvent(sender, eventType)
    local name = sender:getName()
    if name == "cbx_gdd_test" then
        if eventType == ccui.CheckBoxEventType.selected then  
            self:setSelected(true, name)          
            self._presenter:onEventCbxGendaodi(true)            
        elseif eventType == ccui.CheckBoxEventType.unselected then            
            self:setSelected(false, name)
            self._presenter:onEventCbxGendaodi(false)            
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
    self:showLunShu(0, GE.ALLROUND)
    self:setSelected(false, "cbx_gdd_test")
end

function GameScene:showStartEffect()
    local node = self:seekChildByName("node_start_effect")
    node:removeAllChildren()
    node:stopAllActions()
    
    local effect = app.util.UIUtils.runEffectOne("game/zjh/effect","jiubei_dh", 0, 85)
    node:addChild(effect)
end

function GameScene:showBiPaiEffect()
    local node = self:seekChildByName("node_bipai_effect")
    node:removeAllChildren()
    node:stopAllActions()
    
    local effect = app.util.UIUtils.runEffectOne("game/zjh/effect","vs_dh2", 0, 0)
    node:addChild(effect)
end

function GameScene:showFireEffect()
    for i=0,3 do
        local node = self:seekChildByName("node_fire_" .. i)
    	if node then
            node:removeAllChildren()
            node:stopAllActions()
            local effect = app.util.UIUtils.runEffect("game/zjh/effect","huo_2", 0, 0)
            node:addChild(effect)
            node:setVisible(true)
        else
            print("fire node is nil")    
    	end
    end   
end

function GameScene:stopFireEffectLoop()
    for i=0,3 do
        local node = self:seekChildByName("node_fire_" .. i)
        if node then
            node:stopAllActions()
            node:setVisible(false)
        end
    end 
end

function GameScene:playQMLWeffect()
    local node = self:seekChildByName("node_start_effect")
    node:removeAllChildren()
    node:stopAllActions()
    
    local effect = app.util.UIUtils.runEffectOne("game/zjh/effect","vs_qmlw", 0, -50)
    node:addChild(effect)
end

function GameScene:playGZYZeffect()
    local node = self:seekChildByName("node_gzyz_effect")
    node:removeAllChildren()
    node:stopAllActions()
    
    local effect = app.util.UIUtils.runEffectOne("game/zjh/effect","vs_gzyz", 0, 0)
    node:addChild(effect)
end

function GameScene:playWinEffect(localseat)
    print("sz-effect1")
    local clones =  self:seekChildByName("players_clone")
    local player = clones:getChildByName("clone_player" .. localseat)
    if player then
        print("yes win effect")
        local node = player:getChildByName("node_effect")
        node:removeAllChildren()
        node:stopAllActions()

        local effect = app.util.UIUtils.runEffectOne("game/zjh/effect", "vs_dh3", 0, -25)
        node:addChild(effect)
    end    
end

function GameScene:playLoseEffect(localseat)
    print("sz-effect2")
    local clones =  self:seekChildByName("players_clone")
    local player = clones:getChildByName("clone_player" .. localseat)
    if player then
        print("yes lose effect")
        local node = player:getChildByName("node_effect")
        node:removeAllChildren()
        node:stopAllActions()

        local effect = app.util.UIUtils.runEffectOne("game/zjh/effect", "vs_dh1", 0, 0)
        node:addChild(effect)
    end   
end

function GameScene:showBase()
    local base = app.game.GameConfig.getBase()
    local fntbase = self:seekChildByName("fnt_base")
    fntbase:setString(base)
end

function GameScene:showDanZhu(num)
    local fntDZ = self:seekChildByName("fnt_dz")
    fntDZ:setString(num)
end

function GameScene:showLunShu(num, allround)
    local strNum = string.format("%d/%d", num, allround)
    local fntLS = self:seekChildByName("fnt_turn")
    fntLS:setString(strNum)
end

function GameScene:showZongzhu(num)
    print("zongzhu is", num)
    local fntZZ = self:seekChildByName("fnt_zz")
    fntZZ:setString(num)
end

function GameScene:showBaseChipAction(localseat)        
    local pnlarea = self:seekChildByName("pnl_chip_area")    
    local pnlplayer = self:seekChildByName("pnl_player_"..localseat)
    if not pnlplayer then return end
    local fx,fy = pnlplayer:getPosition()  
        
    local chipParent = self:seekChildByName("imgchip")    
    local imgChip = chipParent:clone()
    local txt = imgChip:getChildByName("txt_chip_value")
    local base = app.game.GameConfig.getBase()
    txt:setString(base)
    imgChip:loadTexture("game/zjh/image/img_chip_small_1.png", ccui.TextureResType.plistType)    
    imgChip:setPosition(cc.p(fx, fy+32))    
    pnlarea:addChild(imgChip)  

    local tx,ty = math.random(457, 457+420) , math.random(280, 280+180)        
    imgChip:runAction(cc.MoveTo:create(0.3, cc.p(tx,ty)))                      
end

function GameScene:showAllInChipAction(localseat)         
    local pnlarea = self:seekChildByName("pnl_chip_area")    
    local pnlplayer = self:seekChildByName("pnl_player_"..localseat)
    if not pnlplayer then return end
    local fx,fy = pnlplayer:getPosition()  

    local chipParent = self:seekChildByName("imgchip")    
    local imgChip = chipParent:clone()
    local txt = imgChip:getChildByName("txt_chip_value")
    local base = app.game.GameConfig.getBase()
    txt:setString("全压")
    imgChip:loadTexture("game/zjh/image/img_chip_small_6.png", ccui.TextureResType.plistType)    
    imgChip:setPosition(cc.p(fx, fy+32))    
    pnlarea:addChild(imgChip)  

    local tx,ty = math.random(457, 457+420) , math.random(280, 280+180)        
    imgChip:runAction(cc.MoveTo:create(0.3, cc.p(tx,ty)))                       
end

function GameScene:showChipAction(index, count, localseat) 
    local base = app.game.GameConfig.getBase()       
    local pnlarea = self:seekChildByName("pnl_chip_area")
    local pnlplayer = self:seekChildByName("pnl_player_"..localseat)
    if not pnlplayer then return end
    local fx,fy = pnlplayer:getPosition()  
    local chipParent = self:seekChildByName("imgchip")  
    
    for i=1,count do
        local imgChip = chipParent:clone()
        local txt = imgChip:getChildByName("txt_chip_value")
        txt:setString(index*2*base)  
        local temp = math.ceil(index)      
        if temp < 1 or temp > 5 then
            temp = 1
        end          
        imgChip:loadTexture(string.format("game/zjh/image/img_chip_small_%d.png", temp), ccui.TextureResType.plistType)    
        imgChip:setPosition(cc.p(fx, fy+32))    
        pnlarea:addChild(imgChip) 
        local tx,ty = math.random(457, 457+420), math.random(280, 280+180)            
        imgChip:runAction(cc.MoveTo:create(0.3, cc.p(tx,ty)))    
    end                
end

function GameScene:showChipBackAction(localseats)
    local pnlarea = self:seekChildByName("pnl_chip_area")
    if not pnlarea then return end
    local childrens = pnlarea:getChildren()
    local total = #localseats
    
    if total > 1 then
        local per = math.floor(#childrens / total)

        for i = 1, total do
            local pnlplayer = self:seekChildByName("pnl_player_"..localseats[i])
            local fx,fy = pnlplayer:getPosition()    

            if i == total then
                for j = per*(i-1)+1, #childrens do                    
                    childrens[j]:runAction(cc.Sequence:create(
                        cc.MoveTo:create(0.5, cc.p(fx,fy+32)),
                        cc.CallFunc:create(function() 
                            childrens[j]:removeFromParent()
                        end))) 
                end
            else
                for j = 1+per*(i-1), per*i do                   
                    childrens[j]:runAction(cc.Sequence:create(
                        cc.MoveTo:create(0.5, cc.p(fx,fy+32)),
                        cc.CallFunc:create(function() 
                            childrens[j]:removeFromParent() 
                        end))) 
                end
            end            
        end
    else
        local pnlplayer = self:seekChildByName("pnl_player_"..localseats[1])
        local fx,fy = pnlplayer:getPosition()    
        for k, child in ipairs(childrens) do
            child:runAction(cc.Sequence:create(
                cc.MoveTo:create(0.5, cc.p(fx,fy+32)),
                cc.CallFunc:create(function() child:removeFromParent() end)
            ))  
    	end
    end
end

function GameScene:showRandomChip(jackpot)
    local base = app.game.GameConfig.getBase()      
    local count = math.floor(jackpot / base) 
    if count < 10 then
        self:createChip(count, 1, base)
    elseif count < 20 then       
        self:createChip(count-10, 1, base)
        self:createChip(5, 1, base*2)   
    elseif count < 40 then
        self:createChip(count-18, 1, base)
        self:createChip(3, 1, base*2)   
        self:createChip(3, 2, base*4)        
    elseif count < 70 then
        self:createChip(count-36, 1, base)
        self:createChip(3, 1, base*2)   
        self:createChip(3, 2, base*4)
        self:createChip(3, 3, base*6)   
    elseif count < 110 then          
        self:createChip(count-60, 1, base)
        self:createChip(3, 1, base*2)   
        self:createChip(3, 2, base*4)
        self:createChip(3, 3, base*6)  
        self:createChip(3, 4, base*8) 
    elseif count < 170 then          
        self:createChip(count-90, 1, base)
        self:createChip(3, 1, base*2)   
        self:createChip(3, 2, base*4)
        self:createChip(3, 3, base*6)  
        self:createChip(3, 4, base*8) 
        self:createChip(3, 5, base*10)
    else
        self:createChip(count-166, 1, base)
        self:createChip(3, 1, base*2)   
        self:createChip(3, 2, base*4)
        self:createChip(5, 3, base*6)  
        self:createChip(6, 4, base*8) 
        self:createChip(7, 5, base*10)  
    end      
end

function GameScene:createChip(count, color, txt)
    local pnlarea = self:seekChildByName("pnl_chip_area")
    local chipParent = self:seekChildByName("imgchip")
    for i=1, count do
        local imgChip = chipParent:clone()
        local txtChip = imgChip:getChildByName("txt_chip_value")
        txtChip:setString(txt)  
        local tx,ty = math.random(457, 457+420), math.random(280, 280+180)    
        imgChip:setPosition(cc.p(tx, ty))            
        imgChip:loadTexture(string.format("game/zjh/image/img_chip_small_%d.png", color), ccui.TextureResType.plistType) 
        pnlarea:addChild(imgChip)  
    end       
end

function GameScene:showBiPaiPanel(visible)
    local pnl = self:seekChildByName("pnl_bipai")
    if pnl then
        pnl:setVisible(visible)
    end    
end

function GameScene:isBiPaiPanelVisible()
    local pnl = self:seekChildByName("pnl_bipai")
    if pnl then
        return pnl:isVisible()
    end	
end

function GameScene:getToPosition()
    local lx,ly = self:seekChildByName("node_left"):getPosition()    
    local lmx,lmy = self:seekChildByName("node_left_m"):getPosition()
    local rmx,rmy = self:seekChildByName("node_right_m"):getPosition()
    local rx,ry = self:seekChildByName("node_right"):getPosition()
    
    return cc.p(lx,ly), cc.p(lmx,lmy), cc.p(rmx,rmy), cc.p(rx,ry) 
end

function GameScene:getPlayerPosition(localseat)
    local node = self:seekChildByName("node_pos_" .. localseat)
	if node then
        local x,y = node:getPosition()
        return cc.p(x,y)
    else
        print("node is nil")    
	end
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

function GameScene:showBtnShowCard(visible)
    local btn = self:seekChildByName("btn_show_card")
    btn:setVisible(visible)
end

function GameScene:getShowCardVisible()
	return self:seekChildByName("btn_show_card"):isVisible()    
end

-- 结算分数
function GameScene:showWinloseScore(scoreList)
    for localseat, score in pairs(scoreList) do
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

function GameScene:resetClonePanel(visible)
    local pnlclones = self:seekChildByName("pnl_clones")
    if pnlclones then
        pnlclones:setVisible(visible)
    end
    
    local players = self:seekChildByName("players_clone")
    if players then
        players:removeAllChildren()
    end
end

local CV_BACK = 0
local CV_GRAY = 888
function GameScene:showCompareAction(localSeat, otherSeat, loserSeat, handcards, callback)   
    if localSeat < 0 or localSeat > 4 or otherSeat < 0 or otherSeat > 4 then
        print("seat is error",localSeat, otherSeat)
    	return
    end
    local flag = otherSeat == loserSeat
    
    self:resetClonePanel(true)
    
    local tl, tlm, trm, tr = self:getToPosition()

    local posl,posr
    if localSeat == 2 or localSeat == 3 then
        posl = tlm
    else
        posl = tl    
    end
    if otherSeat == 0 or otherSeat == 1 or otherSeat == 4 then
        posr = trm
    else
        posr = tr   
    end
    
    local cardl = {}
    local cardo = {}
    
    if localSeat ~= 1 and otherSeat ~= 1 then
        cardl = {CV_BACK, CV_BACK, CV_BACK}
        cardo = {CV_BACK, CV_BACK, CV_BACK}
    elseif localSeat == 1 then
        if #handcards == 0 then
            cardl = {CV_BACK, CV_BACK, CV_BACK}            
        else
            cardl = handcards
        end
        cardo = {CV_BACK, CV_BACK, CV_BACK}
    elseif otherSeat == 1 then
        if #handcards == 0 then
            cardo = {CV_BACK, CV_BACK, CV_BACK}            
        else
            cardo = handcards
        end
        cardl = {CV_BACK, CV_BACK, CV_BACK}         
    end
    
    self:runCompareAction(localSeat, posl, flag, cardl, callback)
    self:runCompareAction(otherSeat, posr, not flag, cardo, callback)
end

function GameScene:runCompareAction(localSeat, pos, flag, cards, callback)
    local player = self:seekChildByName("pnl_player_" .. localSeat)
    local parent = self:seekChildByName("players_clone")  
    
    local fx, fy = player:getPosition()

    local clone = player:clone()    
    clone:setPosition(cc.p(fx, fy)) 
    clone:setVisible(true)
    clone:setName("clone_player" .. localSeat)
    parent:addChild(clone)
    
    local bet   = clone:getChildByName("img_bet_back")
    local speak = clone:getChildByName("img_speak")
    local check = clone:getChildByName("img_check")
    local type = clone:getChildByName("img_card_type")
    local black = self:seekChildByName("panl_black")       
    local fold = black:getChildByName("img_fold")
    local btn  = clone:getChildByName("btn_show_card")

    local pnlcards = clone:getChildByName("pnl_cards")         
   
    self:playEffectByName("pk")
   
    local function afunc()
        pnlcards:removeAllChildren()
        for i, card in ipairs(cards) do
            local card = self:createCompareCards(card)
            card:setPosition(cc.p((i-1)*156*0.2, 0))            
            pnlcards:addChild(card)
        end
        
        bet:setVisible(false)
        speak:setVisible(false)
        check:setVisible(false)
        type:setVisible(false)
        black:setVisible(false)
        fold:setVisible(false)
        if btn then
            btn:setVisible(false)
        end     

        if not flag then
            self:playEffectByName("pk_lose")
        end
    end

    local function bfunc()
        if flag then
            black:setVisible(false)
            self:playWinEffect(localSeat)
        else            
            black:setVisible(true)            
            self:playLoseEffect(localSeat) 
            
            pnlcards:removeAllChildren()
            local graycards = {888, 888, 888}
            for i, card in ipairs(graycards) do
                local card = self:createCompareCards(card)
                card:setPosition(cc.p((i-1)*156*0.2, 0))            
                pnlcards:addChild(card)
            end               
        end              
    end

    local function cfunc()
        self._presenter:showOtherPlayer() 
        self:resetClonePanel(false)
        if callback then
        	callback()
        end
    end

    clone:runAction(
        cc.Sequence:create(
            cc.ScaleTo:create(0.2, 1.1),
            cc.Spawn:create(cc.CallFunc:create(function() afunc() end), cc.MoveTo:create(0.3, cc.p(pos))),             
            cc.DelayTime:create(1),       
            cc.CallFunc:create(function() bfunc() end),  
            cc.DelayTime:create(0.8),      
            cc.ScaleTo:create(0.1, 1),
            cc.MoveTo:create(0.3, cc.p(cc.p(fx, fy))),
            cc.DelayTime:create(0.4),
            cc.CallFunc:create(function() cfunc() end)                                
        ))    
end

local COLOR = {
    C_FANG      = 0,
    C_MEI       = 1,
    C_HONG      = 2,
    C_HEI       = 3,
    C_BIGKING   = 4,
    C_SMALLKING = 5
}
local imgCardPath = "game/public/card/img_"
function GameScene:createCompareCards(id)
    local num   = self._presenter:getCardNum(id)
    local color = self._presenter:getCardColor(id)
    
    local parent = self:seekChildByName("panl_single_card")
    local clone = parent:clone()
    
    local front = clone:getChildByName("img_card_front")
    local back = clone:getChildByName("img_card_back")
    local gary = clone:getChildByName("img_card_gary")

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
        local bking = front:getChildByName("img_card_big_king")
        local sking = front:getChildByName("img_card_small_king")        
        local normal = front:getChildByName("panl_card_normal")

        if color == COLOR.C_BIGKING then
            bking:setVisible(true)
            sking:setVisible(false)
            normal:setVisible(false)
        elseif color == COLOR.C_SMALLKING then
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

            if num and color then
                local npath = imgCardPath .. color % 2 .. "_" .. num .. ".png"
                local spath = imgCardPath .. "color_" .. color .. ".png"
                inum:loadTexture(npath, ccui.TextureResType.plistType)
                ismall:loadTexture(spath, ccui.TextureResType.plistType)

                if num <= 10 or num == 14 then
                    iface:setVisible(false)
                    ibig:setVisible(true)
                    local bpath = imgCardPath .. "color_" .. color .. ".png"         
                    ibig:loadTexture(bpath, ccui.TextureResType.plistType)
                else
                    ibig:setVisible(false)
                    iface:setVisible(true)
                    local fpath = imgCardPath .. "face_" .. color % 2 .. "_" .. num .. ".png"
                    iface:loadTexture(fpath, ccui.TextureResType.plistType)
                end 
            end
        end
    end
    
    return clone
end

-- 音效相关
function GameScene:playEffectByName(name)
    local soundPath = "game/zjh/sound/"
    local strRes = ""
    for alias, path in pairs(app.game.GameEnum.soundType) do
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

return GameScene