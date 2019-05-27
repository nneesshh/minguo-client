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
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/lhd/effect","longhdou_naozhong", 0, 0)
    node:addChild(effect)
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

function GameScene:setSelfLongTxt(num)
    local txt = self:seekChildByName("txt_long_self")
    txt:setString("下注 " .. num)
end

function GameScene:setSelfHuTxt(num)
    local txt = self:seekChildByName("txt_hu_self")
    txt:setString("下注 " .. num)
end

function GameScene:setSelfHeTxt(num)
    local txt = self:seekChildByName("txt_he_self")
    txt:setString("下注 " .. num)
end

function GameScene:resetBetUI()
    self:setLongTxt(0)
    self:setHuTxt(0)
    self:setHeTxt(0)
    
    self:setSelfLongTxt(0)
    self:setSelfHuTxt(0)
    self:setSelfHeTxt(0)
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
        cc.FadeIn:create(0.2),       
        cc.FadeOut:create(0.3),        
        cc.FadeIn:create(0.2),
        cc.FadeOut:create(0.3),
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

function GameScene:showPnlHint(visible, type)
    local pnl_hint  = self:seekChildByName("pnl_hint")
    local nodeHint1 = self:seekChildByName("img_hint_wait")
    local nodeHint2 = self:seekChildByName("img_hint_less")
         
    if visible then
        if type == HT.LHD_WAIT then
            nodeHint1:setVisible(true)  
            nodeHint2:setVisible(false)   
            
        elseif type == HT.LHD_LESS then	
            nodeHint1:setVisible(false)  
            nodeHint2:setVisible(true)
             
        elseif type == HT.LHD_BOTH then
            nodeHint1:setVisible(true)  
            nodeHint2:setVisible(true)          
        end    
    end
    
    pnl_hint:setVisible(visible)   
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
function GameScene:createLongHuCard(id, result, action)
    local num   = self._presenter:getCardNum(id)
    local color = self._presenter:getCardColor(id)

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
    
    if action then
        self:turnCard(front, back)
    else
        front:setVisible(true)
        back:setVisible(false)   
    end    
end

-- 重置手牌
function GameScene:resetLongHuCards(flag)
    local long = self:seekChildByName("panl_card_long")
    local hu = self:seekChildByName("panl_card_hu")

    if flag then
        local frontl = long:getChildByName("img_card_front")
        local backl  = long:getChildByName("img_card_back")
        local fronth = hu:getChildByName("img_card_front")
        local backh  = hu:getChildByName("img_card_back")

        frontl:setVisible(false)
        backl:setVisible(true)
        fronth:setVisible(false)
        backh:setVisible(true)
    end

    long:setVisible(flag)
    hu:setVisible(flag)
end

function GameScene:turnCard(front, back)
    cc.Director:getInstance():setProjection(cc.DIRECTOR_PROJECTION2_D)
    
    front:stopAllActions()
    back:stopAllActions()
    
    back:setVisible(true)
    front:setVisible(false)

    back:runAction(cc.Sequence:create(
        cc.OrbitCamera:create(0.3,1,0,0,90,0,0),
        cc.Hide:create(),
        cc.CallFunc:create(function()
            front:runAction(cc.Sequence:create(
                cc.Show:create(),
                cc.OrbitCamera:create(0.3,1,0,270,90,0,0)
            ))
        end)
    ))
end

function GameScene:movePlayerPnl(localseat)
	
end

-- 结算分数
function GameScene:showWinloseScore(scoreList)
    for localseat, score in pairs(scoreList) do
        if localseat > 7 then
            print("localseat > 7")
            return
        end
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

-- localseat = 8(其他玩家) 
function GameScene:showChipAction(index, area, localseat)    
    local pnlarea = self:seekChildByName("pnl_chip_area")
    local pnlplayer
    if localseat < 8 then
        pnlplayer = self:seekChildByName("pnl_player_" .. localseat)
    else
        pnlplayer = self:seekChildByName("btn_other")   
    end

    if not pnlplayer then return end
    local fx,fy = pnlplayer:getPosition()  
    local chipParent = self:seekChildByName("img_chip_clone")  

    local imgChip = chipParent:clone()   
    imgChip:loadTexture(string.format("game/lhd/image/img_chip_%d_1.png", index), ccui.TextureResType.plistType)    
    imgChip:setPosition(cc.p(fx, fy+32))    
    pnlarea:addChild(imgChip)
    imgChip:setName(string.format("name_bet_chip_%d_%d", localseat, index))
    local bx,ex,by,ey = self:getAreaSize(area)    
    local tx,ty = math.random(bx,ex), math.random(by,ey)            
    imgChip:runAction(cc.MoveTo:create(0.3, cc.p(tx, ty)))                   
end

-- 结算飞金币
function GameScene:showChipBackAction(to, bets, callback)     
    local pnlto = self:seekChildByName("pnl_player_" .. to)
    if not pnlto then
        print("to player not found")
        return
    end    

    local function getAvgRandom(a,b)
        if b<a then return nil end
        local powA = math.pow(a, 2)
        local powB = math.pow(b, 2)
        local randC = math.random(powA, powB)
        return math.sqrt(randC)
    end

    local pnl = self:seekChildByName("pnl_chip_area")
    local childrens = pnl:getChildren() 
    
    local tx,ty = pnlto:getPosition()  
    local tmpToX = tx + getAvgRandom(0, 30) * math.random(-1,1)
    local tmpToY = ty + getAvgRandom(0, 30) * math.random(-1,1)     
    
    local function next()        
        if callback then
            callback()
        end
    end
    
    for i, index in pairs(bets) do
        for j=1, #childrens do
            if childrens[j]:getName() == string.format("name_bet_chip_%d_%d", to, index) then
                local action = cc.Sequence:create(
                    cc.DelayTime:create(0.08*j),
                    cc.Show:create(),
                    cc.EaseSineInOut:create(cc.MoveTo:create(0.5, cc.p(tmpToX, tmpToY))),
                    cc.DelayTime:create(0.1),
                    cc.RemoveSelf:create(),
                    cc.CallFunc:create(next)) 

                childrens[j]:runAction(action)     
            end 
        end   
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
        bx = 290
        ex = 290 + 300
        by = 390
        ey = 390 + 180
    elseif area == CT.LHD_HU then
        bx = 700
        ex = 700 + 400
        by = 390
        ey = 390 + 180       
    else
        bx = 290
        ex = 290 + 800
        by = 180
        ey = 180 + 180          
    end
        
    return bx, ex, by, ey
end

return GameScene