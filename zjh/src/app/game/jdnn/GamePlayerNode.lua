--[[
    @brief  游戏玩家类
]]--
local GameHandCardNode = require("app.game.jdnn.GameHandCardNode")
local GameOutCardNode  = require("app.game.jdnn.GameOutCardNode")

local GamePlayerNode   = class("GamePlayerNode", app.base.BaseNodeEx)

local HERO_LOCAL_SEAT  = 1 
local ST = app.game.GameEnum.soundType

function GamePlayerNode:initData(localSeat)
    self._localSeat         = localSeat
        
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
    -- 隐藏玩家选择
    self:showImgChoose(false)
    -- 隐藏牌型
    self:showImgCardtype(false)
    -- 隐藏手牌
    self._gameHandCardNode:resetHandCards()    
    -- 隐藏出牌
    self._gameOutCardNode:resetOutCards()
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
end

-- 游戏开始
function GamePlayerNode:onGameStart()
    -- 隐藏庄家
    self:showImgBanker(false)
    -- 隐藏玩家选择
    self:showImgChoose(false)
    -- 隐藏牌型
    self:showImgCardtype(false)
    -- 隐藏手牌
    self._gameHandCardNode:resetHandCards()    
    -- 隐藏出牌
    self._gameOutCardNode:resetOutCards()
end

-- 发牌
function GamePlayerNode:onTakeFirst(cardID)    
    self._gameHandCardNode:onTakeFirst(cardID)
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
    local imgHead = self:seekChildByName("img_face")
    local resPath = string.format("lobby/image/head/img_head_%d_%d.png", gender, avatar)
    imgHead:loadTexture(resPath, ccui.TextureResType.plistType)
end

-- 庄家
function GamePlayerNode:showImgBanker(visible)
    local imgBanker = self:seekChildByName("img_banker")
    imgBanker:setVisible(visible)
end

-- 玩家选择
function GamePlayerNode:showImgChoose(visible, index)
    local imgChoose = self:seekChildByName("img_choose")
    if index and visible then
        local resPath = string.format("game/jdnn/image/img_choose_%d.png", index)
        imgChoose:loadTexture(resPath, ccui.TextureResType.plistType)        
    end   
    imgChoose:setVisible(visible) 
end

-- 玩家牌型
function GamePlayerNode:showImgCardtype(visible, index)
    local imgtype = self:seekChildByName("img_cardtype")
    if index and visible and index >= 0 and index <= 13  then
        local resPath = string.format("game/jdnn/image/img_card_type_%d.png", index)
        imgtype:loadTexture(resPath, ccui.TextureResType.plistType)        
    end   
    imgtype:setVisible(visible) 
end

-- 庄家动画    
function GamePlayerNode:playBankAction(callback)
    local imgBanker = self:seekChildByName("img_banker")
   
    local visibleRect = cc.Director:getInstance():getOpenGLView():getVisibleRect()
    local center = cc.p(visibleRect.x + visibleRect.width*0.5,visibleRect.y + visibleRect.height*0.6)    
    local pCenter = imgBanker:convertToNodeSpace(center)
    local x,y = imgBanker:getPosition()     
    imgBanker:setPosition(pCenter)
    imgBanker:setVisible(true)
    
    local function next()
        if callback then
        	callback()
        end
    end
    imgBanker:runAction(cc.Sequence:create(
        cc.MoveTo:create(0.5, cc.p(x,y)), 
        cc.CallFunc:create(next)))     
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
        cc.MoveBy:create(0.8, cc.p(0, 15)),
        cc.Spawn:create(
            cc.MoveBy:create(0.8, cc.p(0, 15)), 
            cc.FadeOut:create(3)
        ),
        cc.MoveTo:create(0.01, cc.p(fntScore:getPosition()))
    )

    fntScore:runAction(action)        
end

function GamePlayerNode:getPosition()
    return self._rootNode:getPosition()
end      
    
-- 获取手牌节点
function GamePlayerNode:getGameHandCardNode()
    return self._gameHandCardNode
end

-- 获取出牌节点
function GamePlayerNode:getGameOutCardNode()
    return self._gameOutCardNode
end

function GamePlayerNode:setLocalZOrder(zorder)
    self._rootNode:setLocalZOrder(zorder)
end

-- 音效相关
function GamePlayerNode:playEffectByName(name)
    local soundPath = "game/jdnn/sound/"
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
    
    app.util.SoundUtils.playEffect(soundPath..strRes)   
end

return GamePlayerNode