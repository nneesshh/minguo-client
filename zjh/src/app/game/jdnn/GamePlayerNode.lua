--[[
    @brief  游戏玩家类
]]--
local GameHandCardNode = requireJDNN("app.game.jdnn.GameHandCardNode")
local GameOutCardNode  = requireJDNN("app.game.jdnn.GameOutCardNode")

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
    -- 隐藏光
    self:showImgLight(false)
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
    -- 隐藏光
    self:showImgLight(false)
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
function GamePlayerNode:showImgLight(visible)
    local imgLight = self:seekChildByName("img_light")
    imgLight:setVisible(visible)
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

-- 播放闪光动画
function GamePlayerNode:playLightAction(pertime, callback)
    local function next()
        if callback then
            callback()
        end
    end
    local sequence = cc.Sequence:create(
        cc.FadeIn:create(pertime*0.3),
        cc.DelayTime:create(pertime*0.4),
        cc.FadeOut:create(pertime*0.3),
        cc.CallFunc:create(next))
    local imgLight = self:seekChildByName("img_light")
    if self._localSeat == 1 or self._localSeat == 3 or self._localSeat == 4 then
        imgLight:setScaleY(1.3)
    end
    imgLight:setVisible(true)
    imgLight:runAction(sequence)
end

-- 庄家动画    
function GamePlayerNode:playBankAction(callback)
    local function bankermove()
        local imgBanker = self:seekChildByName("img_banker")
        local x,y = imgBanker:getPosition() 

        local pos = {
            [0] = cc.p(627, 62.5),
            [1] = cc.p(627, 353),
            [2] = cc.p(-547, 62.5),
            [3] = cc.p(-153, -242),
            [4] = cc.p(342, -242),    
        }
        imgBanker:setPosition(pos[self._localSeat])
        imgBanker:setVisible(true)

        local function next()
            if callback then
                callback()
            end

            imgBanker:setPosition(x, y)
        end
        imgBanker:runAction(cc.Sequence:create(
            cc.MoveTo:create(0.5, cc.p(x,y)), 
            cc.CallFunc:create(next)))     
    end

    local imgLight = self:seekChildByName("img_light")
    local sequence
    if self._localSeat == 1 or self._localSeat == 3 or self._localSeat == 4 then
        sequence = cc.Sequence:create(
            cc.FadeIn:create(0.2),
            cc.ScaleTo:create(0.2,1.2,1.3*1.2),
            cc.DelayTime:create(0.2),
            cc.ScaleTo:create(0.1,1,1.3),
            cc.FadeOut:create(0.2))
    else
        sequence = cc.Sequence:create(
            cc.FadeIn:create(0.2),
            cc.ScaleTo:create(0.2,1.2),
            cc.DelayTime:create(0.2),
            cc.ScaleTo:create(0.1,1),
            cc.FadeOut:create(0.2))
    end
    
    imgLight:runAction(sequence)
    
    local pnlLight = self:seekChildByName("pnl_light")
    pnlLight:runAction(cc.Sequence:create(
        cc.FadeTo:create(0.3, 130), 
        cc.FadeOut:create(0.2),
        cc.CallFunc:create(bankermove)))
end    

function GamePlayerNode:resetLightOpacity()
    local pnlLight = self:seekChildByName("pnl_light")
    pnlLight:setOpacity(0)
end

-- 结算分数
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
    
    app.util.SoundUtils.playEffect(soundPath .. strRes)   
end

return GamePlayerNode