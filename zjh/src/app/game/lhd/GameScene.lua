--[[
@brief  游戏主场景UI基类
]]
local GameScene   = class("GameScene", app.base.BaseScene)

-- csb路径
GameScene.csbPath = "game/lhd/csb/gamescene.csb"

local GE   = app.game.GameEnum
local CT   = app.game.GameEnum.cardsType
local HT   = app.game.GameEnum.hintType   

local CV_BACK = 0
local CV_GRAY = 888
 
GameScene.touchs = {
    "btn_exit", 
    "btn_going",
    "btn_other"
}

GameScene.clicks = {
    "btn_menu",
    "pnl_touch_area_long",
    "pnl_touch_area_hu",
    "pnl_touch_area_he"   
}

function GameScene:onTouch(sender, eventType)
    GameScene.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then        
        if name == "btn_exit" then 
            self._presenter:sendLeaveRoom()     
        elseif name == "btn_going" then
            self._presenter:onTouchGoing()            
        elseif name == "btn_other" then                                  
            self._presenter:onTouchOther()                              
        end
    end
end

function GameScene:onClick(sender)
    GameScene.super.onClick(self, sender)
    local name = sender:getName()
    if name == "pnl_touch_area_long" then
        self._presenter:onClickBetArea(CT.LHD_LONG)
    elseif name == "pnl_touch_area_hu" then
        self._presenter:onClickBetArea(CT.LHD_HU)
    elseif name == "pnl_touch_area_he" then
        self._presenter:onClickBetArea(CT.LHD_HE)
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
    local types = app.game.GameData.getHistory()
    self:addHistory(types)
    
    self:resetBetUI()
end

-- -------------------------------------------------------
-- 龙虎斗相关
function GameScene:showStartEffect()
    local node = self:seekChildByName("node_start_effect")
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/lhd/effect","longhukaiju", 0, 0)
    node:addChild(effect)
end

function GameScene:showClockEffect()
    local node = self:seekChildByName("node_clock_effect")
    if node then
        node:removeAllChildren()
        node:stopAllActions()

        local effect = app.util.UIUtils.runEffectOne("game/lhd/effect","longhdou_naozhong", 0, 0)
        node:addChild(effect)
    end
end

function GameScene:showVSEffect()
    local node = self:seekChildByName("node_clock_effect")
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/lhd/effect","longhudou_vs", 0, 0)
    node:addChild(effect)
end

function GameScene:showEndEffect()
    local node = self:seekChildByName("node_stop_effect")

    local rolAction = cc.CSLoader:createTimeline("game/lhd/csb/stop.csb")
    node:runAction(rolAction)
    rolAction:gotoFrameAndPlay(0, false)
end

function GameScene:showSleepEffect()
    local node = self:seekChildByName("node_clock_effect")
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/lhd/effect","bairennn_321", 0, 0)
    node:addChild(effect)
end

function GameScene:setLongTxt(num)
    local txt = self:seekChildByName("txt_long_total")
    txt:setString(num)
end

function GameScene:setHuTxt(num)
    local txt = self:seekChildByName("txt_hu_total")
    txt:setString(num)
end

function GameScene:setHeTxt(num)
    local txt = self:seekChildByName("txt_he_total")
    txt:setString(num)
end

function GameScene:setSelfLongTxt(num, visible)
    local txt = self:seekChildByName("txt_long_self")
    txt:setString("下注 " .. num) 
    
    if num == 0 then
    	visible = false
    end   
    self:seekChildByName("img_long_self"):setVisible(visible)
end

function GameScene:setSelfHuTxt(num, visible)
    local txt = self:seekChildByName("txt_hu_self")
    txt:setString("下注 " .. num)
    if num == 0 then
        visible = false
    end
    self:seekChildByName("img_hu_self"):setVisible(visible)
end

function GameScene:setSelfHeTxt(num, visible)
    local txt = self:seekChildByName("txt_he_self")
    txt:setString("下注 " .. num)
    if num == 0 then
        visible = false
    end
    self:seekChildByName("img_he_self"):setVisible(visible)
end

function GameScene:setTxtReady(flag)
    local txt = self:seekChildByName("txt_ready")
    if flag then
        txt:setString("准备")
    else
        txt:setString("未准备")    
    end
end

function GameScene:resetBetUI()
    self:setLongTxt(0)
    self:setHuTxt(0)
    self:setHeTxt(0)
    
    self:setSelfLongTxt(0, false)
    self:setSelfHuTxt(0, false)
    self:setSelfHeTxt(0, false)
end

function GameScene:showWinLight(result, callback)
    local long = self:seekChildByName("img_long_light")
    local hu = self:seekChildByName("img_hu_light") 
    local he = self:seekChildByName("img_he_light") 
    
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
    
    long:stopAllActions()
    hu:stopAllActions()
    he:stopAllActions()    
    
    long:setVisible(result == CT.LHD_LONG)
    hu:setVisible(result == CT.LHD_HU)
    he:setVisible(result == CT.LHD_HE)
    
    if result == CT.LHD_LONG then
        long:runAction(sequence)
    elseif result == CT.LHD_HU then
        hu:runAction(sequence)
    elseif result == CT.LHD_HE then
        he:runAction(sequence)
    end
end

-- 添加一排
function GameScene:calRecordForTop(list)
    local count = #list    
    local limit = 1
    local temp = {}
    if count > GE.HISTORY_NUM then
        limit = count - (GE.HISTORY_NUM - 1)
    end
    for k = count, limit, -1 do
        table.insert(temp, 1, list[k])         
    end

    return temp
end

function GameScene:addHistory(tlist)
    local pnl = self:seekChildByName("pnl_history")
    pnl:removeAllChildren() 

    local item = self:seekChildByName("img_result")

    local pnlsize = pnl:getContentSize()
    local itmsize = item:getContentSize()    

    local list = self:calRecordForTop(tlist)

    local count = #list
    for k = count, 1, -1 do        
        local clone = item:clone()
        clone:ignoreContentAdaptWithSize(true)   
        local res = string.format("game/lhd/image/img_result_%d.png", list[k])     
        clone:loadTexture(res, ccui.TextureResType.plistType)             
        clone:setPosition(cc.p(((GE.HISTORY_NUM - 1)-(count-k))*itmsize.width, pnlsize.height/2))        
        pnl:addChild(clone)            
    end     
end

-- 创建龙虎牌
local imgCardPath = "game/public/card/img_"
function GameScene:createLongHuCard(id, result, callback)
    if not self._presenter then
    	return
    end
    local num   = self._presenter:getCardNum(id)
    local color = self._presenter:getCardColor(id)
    
    if num < 10 then
        self._presenter:playEffectByName("n0" .. num) 
    else
        self._presenter:playEffectByName("n" .. num) 
    end

    local parent
    if result == 1 then
        parent = self:seekChildByName("panl_card_long")
    elseif result == 2 then
        parent = self:seekChildByName("panl_card_hu")
    end
    parent:setVisible(true)
    local front = parent:getChildByName("img_card_front")
    local back = parent:getChildByName("img_card_back")
 
    if id ~= CV_BACK then    
        local inum   = front:getChildByName("img_card_num")
        local ismall = front:getChildByName("img_color_small")
        local ibig   = front:getChildByName("img_color_big") 
        local iface  = front:getChildByName("img_card_face") 

        if num and color then
            if color < 0 and color > 3 then
                print("color is error")
                return
            end

            local tempNum   
            if num == 1 then
                tempNum = 14
            else
                tempNum = num
            end

            local npath = imgCardPath .. color % 2 .. "_" .. tempNum .. ".png"
            local spath = imgCardPath .. "color_" .. color .. ".png"

            inum:loadTexture(npath, ccui.TextureResType.plistType)
            ismall:loadTexture(spath, ccui.TextureResType.plistType)

            if tempNum <= 10 or tempNum == 14 then
                iface:setVisible(false)
                ibig:setVisible(true)
                local bpath = imgCardPath .. "color_" .. color .. ".png"         
                ibig:loadTexture(bpath, ccui.TextureResType.plistType)
            else
                ibig:setVisible(false)
                iface:setVisible(true)
                local fpath = imgCardPath .. "face_" .. color % 2 .. "_" .. tempNum .. ".png"
                iface:loadTexture(fpath, ccui.TextureResType.plistType)
            end 
        end       
    end
    
    self:turnCard(front, back, callback)
end

-- 重置手牌
function GameScene:resetLongHuCards(flag)
    local long = self:seekChildByName("panl_card_long")
    local frontl = long:getChildByName("img_card_front")
    local backl  = long:getChildByName("img_card_back")
    
    local hu = self:seekChildByName("panl_card_hu")
    local fronth = hu:getChildByName("img_card_front")
    local backh  = hu:getChildByName("img_card_back")
    
    if flag then
        long:setVisible(true)
        frontl:setVisible(false)
        backl:setVisible(true)

        hu:setVisible(true)
        fronth:setVisible(false)
        backh:setVisible(true)
    else
        long:setVisible(false) 
        hu:setVisible(false)   
    end
end

function GameScene:turnCard(front, back, callback)
    cc.Director:getInstance():setProjection(cc.DIRECTOR_PROJECTION2_D)
    
    front:stopAllActions()
    back:stopAllActions()
    
    back:setVisible(true)
    front:setVisible(false)
    
    self._presenter:playEffectByName("flipcard")
      
    local action = cc.ScaleTo:create(0.5, 1.2)
    local action2 = cc.OrbitCamera:create(0.5,1,0,270,90,0,0)
    
    back:runAction(cc.Sequence:create(
--        cc.OrbitCamera:create(0.3,1,0,0,90,0,0),
        cc.Hide:create(),
        cc.CallFunc:create(function()
            front:runAction(cc.ScaleTo:create(0.5, 1.2))
            front:runAction(cc.Sequence:create(
                cc.Show:create(),                
                cc.OrbitCamera:create(0.5,1,0,270,90,0,0),
                cc.ScaleTo:create(0.1, 1)  
            ))
        end),
        cc.DelayTime:create(1),
        cc.CallFunc:create(function()
            if callback then
            	callback()
            end
        end)
    ))
end

function GameScene:movePlayerPnl(localseat, allbet)
    local pnl = self:seekChildByName("pnl_player_" .. localseat)
    if not pnl then
        print("move no panl")
        return
    end

    local gox = 10
    local tox = -10   
    
    if allbet >= 10000 then
        gox = gox * 3
        tox = tox * 3 
    end
     
    local Action

    if localseat % 2 == 1 then
        if localseat == 7 then
            Action = cc.Sequence:create(
                cc.EaseSineOut:create(cc.MoveBy:create(0.2,cc.p(0,gox))),
                cc.EaseSineOut:create(cc.MoveBy:create(0.1,cc.p(0,tox)))
            )
        else
            Action = cc.Sequence:create(
                cc.EaseSineOut:create(cc.MoveBy:create(0.2,cc.p(gox,0))),
                cc.EaseSineOut:create(cc.MoveBy:create(0.1,cc.p(tox,0)))
            )
        end        
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

-- 结算分数
function GameScene:showWinloseScore(scoreList)
    for localseat, score in pairs(scoreList) do
        if localseat > 7 or score == -1 then
            print("localseat > 7 or score == -1")
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

-- localseat = 8(其他玩家) 
function GameScene:showChipAction(index, area, localseat)    
    if index == -1 then
    	print("index is -1")
    	return
    end
    local pnlarea = self:seekChildByName("pnl_chip_area")
    local pnlplayer
    if localseat < 8 then
        pnlplayer = self:seekChildByName("pnl_player_" .. localseat)
    else
        pnlplayer = self:seekChildByName("btn_other")   
    end

    if not pnlplayer then return end
    
    self._presenter:playEffectByName("bet")  
    
    local fx,fy = pnlplayer:getPosition()  
    local chipParent = self:seekChildByName("img_chip_clone")  

    local imgChip = chipParent:clone()   
    imgChip:loadTexture(string.format("game/lhd/image/img_chip_%d_1.png", index), ccui.TextureResType.plistType)    
    imgChip:setPosition(cc.p(fx, fy+32))    
    pnlarea:addChild(imgChip)
    local bx,ex,by,ey = self:getAreaSize(area)    
    local tx,ty = math.random(bx,ex), math.random(by,ey)            
    imgChip:runAction(cc.MoveTo:create(0.3, cc.p(tx, ty)))                   
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
         
    for i=1, #childrens do
        local action = cc.Sequence:create(
            cc.DelayTime:create(0.05*i),
            cc.Show:create(),
            cc.EaseSineInOut:create(cc.MoveTo:create(0.4, cc.p(tx,ty))),
            cc.DelayTime:create(0.1),
            cc.RemoveSelf:create()) 
        childrens[i]:runAction(action)     
    end   
end

function GameScene:removeAllChip()
    local pnl = self:seekChildByName("pnl_chip_area")
    pnl:removeAllChildren()
end

-- 获取筹码区域
function GameScene:getAreaSize(area)
    local bx, ex, by, ey = 0, 0, 0, 0 
    if area == CT.LHD_LONG then
        bx = 350
        ex = 350 + 200
        by = 420
        ey = 420 + 100
    elseif area == CT.LHD_HU then
        bx = 800
        ex = 800 + 200
        by = 420
        ey = 420 + 100       
    else
        bx = 460
        ex = 460 + 400
        by = 230
        ey = 230 + 100          
    end
        
    return bx, ex, by, ey
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

return GameScene