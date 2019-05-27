--[[
    @brief  游戏玩家类
]]--

local GamePlayerNode   = class("GamePlayerNode", app.base.BaseNodeEx)

local HERO_LOCAL_SEAT  = 1 
local ST = app.game.GameEnum.soundType

function GamePlayerNode:initData(localSeat)
    self._localSeat         = localSeat
        
    math.randomseed(tostring(os.time()):reverse():sub(1, 7))
end

function GamePlayerNode:initUI(localSeat)
    
end

-- 玩家进入
function GamePlayerNode:onPlayerEnter(player)     
    if not player then
        print("player is nil", self._localSeat)
    	return
    end
    -- 显示用户节点    
    self:showPnlPlayer(true)
    
--    if self._localSeat == HERO_LOCAL_SEAT then
        -- 设置姓名
        self:showTxtPlayerName(true, player:getTicketID())
        -- 设置金币
        self:showTxtBalance(true, player:getBalance())
        -- 显示头像
        self:showImgFace(player:getGender(), player:getAvatar())
--    else
--        -- 设置姓名
--        self:showTxtPlayerName(true, "   - -")
--        -- 设置金币
--        self:showTxtBalance(true, " - -")
--        -- 显示头像
--        self:showImgFace(2, 0)    
--    end   
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

function GamePlayerNode:playWinEffect()
    local node = self:seekChildByName("node_effect")
    node:removeAllChildren()
    node:stopAllActions()

    local effect = app.util.UIUtils.runEffectOne("game/lhd/effect", "longhd_g", 0, 0)
    node:addChild(effect)
end
    
-- 音效相关
function GamePlayerNode:playEffectByName(name)
    local soundPath = "game/qznn/sound/"
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