--[[
@brief  游戏主场景控制基类
]]

local GamePlayerNode = requireZJH("app.game.zjh.GamePlayerNode")
local GameBtnNode    = requireZJH("app.game.zjh.GameBtnNode")
local GameMenuNode   = requireZJH("app.game.zjh.GameMenuNode")

local GamePresenter  = class("GamePresenter", app.base.BasePresenter)

GamePresenter._ui    = requireZJH("app.game.zjh.GameScene")

local scheduler = cc.Director:getInstance():getScheduler()

local GE   = app.game.GameEnum
local GECT = app.game.GameEnum.cardsType
local GEPS = app.game.GameEnum.playerStatus

local HERO_LOCAL_SEAT   = 1
local CARD_NUM          = 3
local CV_BACK           = 0

local TIME_START_EFFECT = 0
local TIME_MAKE_BANKER  = 0.5
local TIME_THROW_CHIP   = 1.5
local TIME_TAKE_FIRST   = 2

local TIME_PLAYER_BET   = 15
local SCHEDULE_WAIT_TIME= 0

-- 初始化
function GamePresenter:init(...)
    self._maxPlayerCnt = app.game.PlayerData.getMaxPlayerCount() or 5
    self:createDispatcher()
    self:playGameMusic()  
    self:initPlayerNode()
    self:initBtnNode()
    self:initMenuNode()
    self:initScheduler() 
    
    self._overDelaytime = 0
    self._gameOver = false
    self._playing = false
end

function GamePresenter:createDispatcher()   
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BROADCAST, handler(self, self.onBroadCast))     
end

function GamePresenter:onBroadCast(text)
    if not self:isCurrentUI() then
        return
    end
    
    app.lobby.notice.BroadCastNode:create(self, text)
end

function GamePresenter:initPlayerNode()
    self._gamePlayerNodes = {}
    for i = 0, self._maxPlayerCnt - 1 do
        local pnlPlayer = self._ui:getInstance():seekChildByName("pnl_player_"..i) 
        self._gamePlayerNodes[i] = GamePlayerNode:create(self, pnlPlayer, i)
    end    
end

function GamePresenter:initBtnNode()
    local nodeBtn = self._ui:getInstance():seekChildByName("node_game_btn")
    nodeBtn:setLocalZOrder(1000)
    self._gameBtnNode = GameBtnNode:create(self, nodeBtn)
end

function GamePresenter:initMenuNode()
    local nodeMenu = self._ui:getInstance():seekChildByName("node_menu")
    self._gameMenuNode = GameMenuNode:create(self, nodeMenu)
end

function GamePresenter:initScheduler()    
    self._schedulerClocks       = {}      -- 时钟    
    self._schedulerTakeFirst    = nil     -- 发牌    
    self._schedulerPrepareClock = nil     -- 倒计时
    self._schedulerAutoReady    = nil     -- 自动准备  
    self._schedulerRunLoading   = nil     -- 等待...
end

-- 退出界面
function GamePresenter:exit()
    GamePresenter.super.exit(self)
    
    self:closeSchedulerTakeFirst()
    self:closeSchedulerClocks()
    self:closeSchedulerPrepareClock()
    self:closeSchedulerRunLoading()
    self:closeScheduleSendReady()
    GamePresenter._instance = nil
end

-- 处理玩家状态
function GamePresenter:onPlayerStatus(data)
    local player = app.game.PlayerData.getPlayerByNumID(data.ticketid)        
    if not player then
        return
    end
    
    -- 更新本家状态
    if app.game.PlayerData.isHero(data.ticketid) then
        local heroseat = app.game.PlayerData.getHeroSeat()
        app.game.PlayerData.updatePlayerStatus(heroseat, data.status)
    end
    
    if data.status == 7 then    -- 退出
        self:onLeaveNormal(data)
    elseif data.status == 8 or data.status == 9 then -- 服务踢出房间     
        self:onLeaveKick(data)                           
    end
end

function GamePresenter:onLeaveNormal(data)
    local numID = data.ticketid
    local player = app.game.PlayerData.getPlayerByNumID(numID)        
    if not player then
        return
    end

    app.game.PlayerData.onPlayerLeave(numID)
    self:onPlayerLeave(player)        
    if app.game.PlayerData.isHero(data.ticketid) then 
        self:onLeaveRoom()
    end 
end

function GamePresenter:onLeaveKick(data)
    local hint = ""
    if data.status == 8 then
        hint = "亲，你身上的金币不太多了噢~请换个房间或者再补充点金币吧！"
    elseif data.status == 9 then        
        hint = "你由于长时间未操作，已被系统请 出房间！" 
    end
    self:performWithDelayGlobal(
        function()
            local numID = data.ticketid
            local player = app.game.PlayerData.getPlayerByNumID(numID)        
            if not player then               
                return
            end
            app.game.PlayerData.onPlayerLeave(numID)
            self:onPlayerLeave(player)
            if app.game.PlayerData.isHero(data.ticketid) then 
                self:dealHintStart(hint,function(bFlag)
                    self:onLeaveRoom()
                end, 0)
            end 
        end, 3)
end

-- 处理玩家离开
function GamePresenter:onPlayerLeave(player)
    local numID = player:getTicketID()

    app.game.GameData.removePlayerseat(player:getSeat())

    -- 自己离开重置桌子
    if app.game.PlayerData.isHero(numID) then 
        for i = 0, self._maxPlayerCnt - 1 do
            if self._gamePlayerNodes[i] then
                self._gamePlayerNodes[i]:onResetTable()
            end
        end        
    -- 某个玩家离开将该节点隐藏
    else 
        local localSeat = app.game.PlayerData.serverSeatToLocalSeat(player:getSeat())
        if self._gamePlayerNodes[localSeat] then
            self._gamePlayerNodes[localSeat]:onPlayerLeave()
        end

        if app.game.PlayerData.getPlayerCount() <= 1 then
            if self._gamePlayerNodes[HERO_LOCAL_SEAT] then
                self:performWithDelayGlobal(
                    function()
                        if app.game.GamePresenter and not self._playing then
                            self._ui:getInstance():showPnlHint(2)
                            self._gameBtnNode:showBetNode(false) 
                            self._gamePlayerNodes[HERO_LOCAL_SEAT]:onResetTable()
                        end   
                    end, 4)
            end
        end
    end
end

-- 退出游戏区
function GamePresenter:onLeaveRoom()
    app.game.GameEngine:getInstance():exit()
end

-- 处理玩家进入
function GamePresenter:onPlayerEnter(player)     
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(player:getSeat()) 
    
    if localSeat == HERO_LOCAL_SEAT then
        app.game.GameData.setHeroReady(false)
    end

    if self._gamePlayerNodes then
        self._gamePlayerNodes[localSeat]:onPlayerEnter() 
    end 
    
    self:playBiPaiPanel(false)
      
    if app.game.PlayerData.getPlayerCount() <= 1 then
        if not self._ischangeTable then
            self._ui:getInstance():showPnlHint(2)     
            self._gameBtnNode:showBetNode(false)                   
        end  
    else        
        local heroseat = app.game.PlayerData.getHeroSeat()      
        if heroseat == player:getSeat() then
            local seats = app.game.GameData.getPlayerseat()
            if #seats ~= 0 then
                local isIn = false
                for i, seat in ipairs(seats) do
                    if player:getSeat() == seat then
                        isIn = true
                    end
                end
                if not isIn then
                    self._ui:getInstance():showPnlHint(4) 
                    self._gameBtnNode:showBetNode(false)  
                    app.game.PlayerData.updatePlayerStatus(player:getSeat(), 4)             
                end         
            end         
        end
    end
end

-- 处理玩家坐下
function GamePresenter:onPlayerSitdown(player)     
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(player:getSeat()) 
    
    if localSeat == HERO_LOCAL_SEAT then
        app.game.GameData.setHeroReady(false)
    end

    if self._gamePlayerNodes then
        self._gamePlayerNodes[localSeat]:onPlayerEnter() 
    end 
    
    self:playBiPaiPanel(false)
      
    if app.game.PlayerData.getPlayerCount() <= 1 then
        if not self._ischangeTable then
            self._ui:getInstance():showPnlHint(2)     
            self._gameBtnNode:showBetNode(false)                   
        end  
    else
        if not app.game.PlayerData.getHero():isWaiting() then
            self._ui:getInstance():showPnlHint(5)
        end                      
    end
end

-- 玩家准备
function GamePresenter:onPlayerReady(seat)
    local localseat = app.game.PlayerData.serverSeatToLocalSeat(seat)
    if localseat == HERO_LOCAL_SEAT then      
        app.game.GameData.setHeroReady(true)
        self:closeScheduleSendReady()
    end         
end

-- 游戏准备
function GamePresenter:onGamePrepare()  
    self._ui:getInstance():showPnlHint(1)
    self._gameBtnNode:showBetNode(false) 
end

-- 开始
function GamePresenter:onGameStart()  
    self._overDelaytime = 0
    self._gameOver = false
    self._playing = true    
    
    self._ui:getInstance():showPnlHint()
    
    self._gameBtnNode:showBetNode(false)       
    
    for i = 0, self._maxPlayerCnt - 1 do        
        app.game.PlayerData.updatePlayerStatus(i, 0)
        app.game.PlayerData.updatePlayerIsshow(i, 0)
        app.game.PlayerData.resetPlayerBet(i)
    end
    
    local heroseat = app.game.PlayerData.getHeroSeat()
    local seats = app.game.GameData.getPlayerseat()    
    for k, i in ipairs(seats) do
        app.game.PlayerData.updatePlayerStatus(i, 3)      
    end
    
    app.game.GameData.resetDataEx()
    
    -- 隐藏看牌按钮
    self._ui:getInstance():showBtnShowCard(false)
    -- 隐藏比牌
    self:playBiPaiPanel(false)
    
    -- 玩家开始
    for i = 0, self._maxPlayerCnt - 1 do
        if self._gamePlayerNodes[i] then
            self._gamePlayerNodes[i]:onGameStart()
            self._gamePlayerNodes[i]:showPlayerInfo()
        end
    end
    
    -- 初始化场景
    self:refreshUI()
    
    -- 开局动画    
    self:performWithDelayGlobal(
        function()
            self._ui:getInstance():showStartEffect()
        end, TIME_START_EFFECT)
    
    -- 确定庄家    
    self:performWithDelayGlobal(
        function()
            self:playBankerAction()
        end, TIME_MAKE_BANKER)
    
    -- 扔筹码
    self:performWithDelayGlobal(
        function()
            self:playBaseChipAction()
        end, TIME_THROW_CHIP)
   
    -- 发牌
    self:performWithDelayGlobal(
        function()
            for i = 0, self._maxPlayerCnt - 1 do
                if self._gamePlayerNodes[i] then                   
                    self._gamePlayerNodes[i]:showPlayerInfo()
                end
            end
            
            self:onTakeFirst()
        end, TIME_TAKE_FIRST)  
end

-- 发牌
function GamePresenter:onTakeFirst()
    if self:checkHeroWaiting() then
    	return
    end
    
    for i = 0, self._maxPlayerCnt - 1 do
        local gameHandCardNode = self._gamePlayerNodes[i]:getGameHandCardNode()
        gameHandCardNode:resetHandCards()  
    end
    
    local function callback()
        local hero = app.game.PlayerData.getHero()
        if hero and hero:isPlaying() then
            self._gameBtnNode:showBetNode(true, 1)
        end
        if app.game.GameData then
            local banker = app.game.GameData.getCurrseat()
            self:onPlayerBet(banker, 0)
        end
    end
    
    self:openSchedulerTakeFirst(callback)
end

-- 时钟
function GamePresenter:onClock(serverSeat)
    if self:checkHeroWaiting() then
        return
    end
    
    for i = 0, self._maxPlayerCnt - 1 do
        if serverSeat == i then
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(serverSeat)
            self._gamePlayerNodes[localSeat]:onClock(TIME_PLAYER_BET)    
        else
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
            self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
        end
    end    
end

-- 玩家押注
function GamePresenter:onPlayerBet(seat, index)
    local banker = app.game.GameData.getBanker()
    print("player bet seat is",seat, banker)
    
    if seat == -1 then
        print("next is -1")
    	return
    end
    
    if self:checkHeroWaiting() then
        return
    end
    
    self:onClock(seat)
    
    self:playBiPaiPanel(false)
    
    if app.game.PlayerData.getHeroSeat() == seat then
        local player = app.game.PlayerData.getPlayerByServerSeat(seat)            
        local normal, disable = self:checkButtonEnable(player)
        self._gameBtnNode:setEnableByName(normal, disable)  
        -- index之后的按钮可点击
        local round = app.game.GameData.getRound()
        if round > 2 then
            self._gameBtnNode:setDisableByIndex(index) 
        else
            self._gameBtnNode:setDisableByIndex(index, true)
        end
        
        if player:isPlaying() and not player:getIsshow() then
            self._ui:getInstance():showBtnShowCard(true)
        else
            self._ui:getInstance():showBtnShowCard(false)   
        end
    else
        local heroseat = app.game.PlayerData.getHeroSeat()
        local player = app.game.PlayerData.getPlayerByServerSeat(heroseat)    
        local normal, disable = self:checkButtonEnable(player)
        self._gameBtnNode:setEnableByName(normal, disable)
        
        if player:isPlaying() and not player:getIsshow() then
            self._ui:getInstance():showBtnShowCard(true)
        else
            self._ui:getInstance():showBtnShowCard(false)   
        end     
    end
    
    local heroseat = app.game.PlayerData.getHeroSeat()
    if seat == heroseat and (self._gameBtnNode:isSelected("cbx_gdd") or self._ui:getInstance():isSelected("cbx_gdd_test")) then
        self:performWithDelayGlobal(function()
            self:sendBetmult(-1) 
        end, 1)
    end
end

-- 弃牌
function GamePresenter:onPlayerGiveUp(now, next, round)
    if self:checkHeroWaiting() then
        return
    end
    self:playBiPaiPanel(false)
    
    app.game.PlayerData.updatePlayerStatus(now, 5)
    local basebet = app.game.GameData.getBasebet()
    local base = app.game.GameConfig.getBase()

    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(now)    
    self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)   
    self._gamePlayerNodes[localSeat]:playSpeakAction(3) 
    self._gamePlayerNodes[localSeat]:showPnlBlack(true, true)
    self:showGaryCard(localSeat)
    
    local playerobj = app.game.PlayerData.getPlayerByServerSeat(now)     
    local gender = playerobj:getGender() 
    if gender == 1 then
        self._gamePlayerNodes[localSeat]:playEffectByName("m_qp")   
    else
        self._gamePlayerNodes[localSeat]:playEffectByName("w_qp")       
    end
        
    app.game.GameData.setCurrseat(next)
    
    local heroseat = app.game.PlayerData.getHeroSeat()
    if heroseat == now then
        local player = app.game.PlayerData.getPlayerByServerSeat(now)            
        local normal, disable = self:checkButtonEnable(player)
        self._gameBtnNode:setEnableByName(normal, disable)
            
        self._ui:getInstance():showBtnShowCard(false) 
        
        self._gameBtnNode:showBetNode(false)  
        if player:getIsshow() then
            self._gameBtnNode:showBetNode(true, 2)      
        end
    elseif heroseat == next then	
        local player = app.game.PlayerData.getPlayerByServerSeat(next)    
        local normal, disable = self:checkButtonEnable(player)
        self._gameBtnNode:setEnableByName(normal, disable)    
    end
    
    self:onPlayerBet(next, basebet / base)
end

-- 比牌
function GamePresenter:onPlayerCompareCard(data) 
    print("onPlayerCompareCard")      
    if self:checkHeroWaiting() then
        return
    end
    
    app.game.PlayerData.updatePlayerRiches(data.playerSeat, data.playerBet, data.playerBalance)    
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(data.playerSeat)
    local otherSeat = app.game.PlayerData.serverSeatToLocalSeat(data.acceptorSeat)
    local loserSeat = app.game.PlayerData.serverSeatToLocalSeat(data.loserSeat)    
    local base = app.game.GameConfig.getBase()
    local player = app.game.PlayerData.getPlayerByServerSeat(data.playerSeat)   
    local playerbet = data.playerBet
    if player == nil then
        print("player compare is nil")
        return
    end
    
    if localSeat == HERO_LOCAL_SEAT then
        app.game.GameData.setCompareSeat(otherSeat)
    elseif otherSeat == HERO_LOCAL_SEAT	then
        app.game.GameData.setCompareSeat(localSeat)
    end
    
    local isshow = player:getIsshow() 
    local gender = player:getGender() 
    if gender == 1 then
        self._gamePlayerNodes[localSeat]:playEffectByName("m_bp")   
    else
        self._gamePlayerNodes[localSeat]:playEffectByName("w_bp")       
    end
    
    local count = 1
    if isshow then
        playerbet = playerbet / 2
        count = 2
    end             
    local ib = playerbet / base / 2  -- 玩家跟注的筹码index
   
    self:refreshUI()    
    self._ui:getInstance():showChipAction(ib, count, localSeat)
    
    self:playCompareAction(localSeat, otherSeat, loserSeat)
    
    self._gamePlayerNodes[localSeat]:playEffectByName("chip")
    self._gamePlayerNodes[localSeat]:showTxtBalance(true, data.playerBalance)    
    self._gamePlayerNodes[localSeat]:showImgBet(true,  player:getBet())
    self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
    
    app.game.GameData.setBasebet(data.basebet)
    
    app.game.PlayerData.updatePlayerStatus(data.loserSeat, 6)
    
    if loserSeat == HERO_LOCAL_SEAT then
        self._gameBtnNode:showBetNode(false)  
        self:performWithDelayGlobal(function()
            if app.game.PlayerData.getHero():getIsshow() then
                self._gameBtnNode:showBetNode(true, 2)      
            end           
        end, 3)        
    end
    
    self:performWithDelayGlobal(function()
        self:onPlayerBet(app.game.GameData.getCurrseat(), ib) 
    end, 3) 

    local cnt = 0
    for seat = 0, self._maxPlayerCnt - 1 do
        local player = app.game.PlayerData.getPlayerByServerSeat(seat)            
        if player and player:isPlaying() then                      
            cnt = cnt + 1
        end 
    end
    
    if cnt <= 1 then       
        self._overDelaytime = self._overDelaytime + 3 -- 比牌结束    
    end
end 

-- 看牌
function GamePresenter:onPlayerShowCard(seat, cards, cardtype)
    if self:checkHeroWaiting() then
        return
    end

    app.game.PlayerData.updatePlayerIsshow(seat, 1) 
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)
    local player = app.game.PlayerData.getPlayerByServerSeat(seat)
    if not player then
    	return
    end
    local gender = player:getGender() 
    if gender == 1 then
        self._gamePlayerNodes[localSeat]:playEffectByName("m_kp")   
    else
        self._gamePlayerNodes[localSeat]:playEffectByName("w_kp")       
    end 

    if localSeat == 1 then
        self._gamePlayerNodes[localSeat]:showImgCardType(true, cardtype)              
        local normal, disable = self:checkButtonEnable(player)
        self._gameBtnNode:setEnableByName(normal, disable) 
        self._ui:getInstance():showBtnShowCard(false) 
        self._gamePlayerNodes[localSeat]:showImgCheck(false)  
        
        app.game.GameData.setHandcards(cards)
    else
        self._gamePlayerNodes[localSeat]:showImgCheck(true)     
    end
    
    if cards then
        local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
        gameHandCardNode:resetHandCards()
        gameHandCardNode:createCards(cards)
    end    
end

-- 押注
function GamePresenter:onPlayerAnteUp(data) 
    if self:checkHeroWaiting() then
        return
    end   
    if data.isAllIn == 1 then
        self:onPlayerAnteUpAllIn(data)    	
    else
        self:onPlayerAnteUpNormal(data)	
    end
end

-- 全压(其他玩家判断是否要进行跟注)
function GamePresenter:onPlayerAnteUpAllIn(data)
    if self:checkHeroWaiting() then
        return
    end
    app.game.PlayerData.updatePlayerRiches(data.playerSeat, data.playerBet, data.playerBalance)
    app.game.GameData.setAllIn(true)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(data.playerSeat) 
    local player = app.game.PlayerData.getPlayerByServerSeat(data.playerSeat)   
    if player == nil then
        print("player anteup is nil")
        return
    end 
    local gender = player:getGender()
    if gender == 1 then
        self._gamePlayerNodes[localSeat]:playEffectByName("m_qy")   
    else
        self._gamePlayerNodes[localSeat]:playEffectByName("w_qy")       
    end
    
    self:refreshUI()
    
    self._ui:getInstance():showAllInChipAction(localSeat)
    self._ui:getInstance():showFireEffect()
    self._gamePlayerNodes[localSeat]:playEffectByName("chip")
    self._gamePlayerNodes[localSeat]:showTxtBalance(true, data.playerBalance)    
    self._gamePlayerNodes[localSeat]:showImgBet(true, player:getBet())
       
    app.game.GameData.setBasebet(data.basebet)

    self:onPlayerAllIn(app.game.GameData.getCurrseat())
end

-- 按钮显示
function GamePresenter:onPlayerAllIn(seat)
    if seat == -1 then
        print("next is -1")
        return
    end
    
    if self:checkHeroWaiting() then
        return
    end
    
    if app.game.PlayerData.getHeroSeat() == seat then
        local player = app.game.PlayerData.getPlayerByServerSeat(seat)            
        local normal, disable = self:checkButtonEnable(player)
        self._gameBtnNode:setEnableByName(normal, disable)  
    else
        local heroseat = app.game.PlayerData.getHeroSeat()
        local player = app.game.PlayerData.getPlayerByServerSeat(heroseat)    
        local normal, disable = self:checkButtonEnable(player)
        self._gameBtnNode:setEnableByName(normal, disable)     
    end
    
    self:onClock(seat)

    local heroseat = app.game.PlayerData.getHeroSeat()
    if seat == heroseat and (self._gameBtnNode:isSelected("cbx_gdd") or self._ui:getInstance():isSelected("cbx_gdd_test")) then
        self:performWithDelayGlobal(function()
            self:sendBetmult(-1) 
        end, 1)
    end
end

-- 正常押注
function GamePresenter:onPlayerAnteUpNormal(data)
    app.game.PlayerData.updatePlayerRiches(data.playerSeat, data.playerBet, data.playerBalance)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(data.playerSeat) 
    local base = app.game.GameConfig.getBase()
    local basebet = app.game.GameData.getBasebet()
    local playerbet = data.playerBet
    local player = app.game.PlayerData.getPlayerByServerSeat(data.playerSeat)   
    if player == nil then
        print("player anteup is nil")
        return
    end
    local isshow = player:getIsshow()
    local count = 1
    if isshow then
        playerbet = playerbet / 2
        count = 2
    end             
    local ib = playerbet / base / 2  -- 玩家跟注的筹码index

    self:refreshUI()
    self._ui:getInstance():showChipAction(ib, count, localSeat)
    self._gamePlayerNodes[localSeat]:showTxtBalance(true, data.playerBalance)    
    self._gamePlayerNodes[localSeat]:showImgBet(true,  player:getBet())
    self._gamePlayerNodes[localSeat]:playEffectByName("chip")
    
    local gender = player:getGender()
    if playerbet / basebet == 1 then
        self._gamePlayerNodes[localSeat]:playSpeakAction(1)        
        if gender == 1 then
            self._gamePlayerNodes[localSeat]:playEffectByName("m_gz")   
        else
            self._gamePlayerNodes[localSeat]:playEffectByName("w_gz")       
        end    
    else
        self._gamePlayerNodes[localSeat]:playSpeakAction(2) 
        if gender == 1 then
            self._gamePlayerNodes[localSeat]:playEffectByName("m_jz")   
        else
            self._gamePlayerNodes[localSeat]:playEffectByName("w_jz")       
        end        
    end

    app.game.GameData.setBasebet(data.basebet)

    self:onPlayerBet(app.game.GameData.getCurrseat(), ib) 
end

-- 孤注一掷(当前玩家与其他玩家进行比牌)
function GamePresenter:onPlayerLastBet(data)
    print("onPlayerLastBet")      
    app.game.GameData.setCurrseat(data.nextseat)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(data.playerSeat)
    self._ui:getInstance():showAllInChipAction(localSeat)    
    for i, seat in ipairs(data.otherSeat) do
        local otherSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)
        
        app.game.GameData.setCompareSeat(otherSeat)
        
        self:performWithDelayGlobal(function()
            if i < #data.otherSeat then
                self:playCompareAction(localSeat, otherSeat, otherSeat, true)
            else
                if data.win == 0 then
                    self:playCompareAction(localSeat, otherSeat, localSeat, true) 
                else
                    self:playCompareAction(localSeat, otherSeat, otherSeat, true)     
                end               
            end   
        end, (i-1)*3)            
    end
        
    self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
        
    local basebet = app.game.GameData.getBasebet()
    local base = app.game.GameConfig.getBase()
    local index = basebet / base / 2
    
    self:performWithDelayGlobal(function()
        self:onPlayerBet(app.game.GameData.getCurrseat(), index) 
    end, (#data.otherSeat)*3) 
    
    self._overDelaytime = self._overDelaytime + 3*(#data.otherSeat) -- 孤注一掷结束
end

-- 游戏结束
function GamePresenter:onGameOver(data, players) 
    print("on game over")  
    self._gameOver = true 
    self._playing = false
    app.game.GameData.setHeroReady(false)
    app.game.GameData.setTableStatus(zjh_defs.TableStatus.TS_ENDING)
    
    if self:checkHeroWaiting() then               
        self:performWithDelayGlobal(function()
            self:sendPlayerReady()                             
        end, self._overDelaytime + 3)
        
        print("time",self._overDelaytime + 3)        
        return
    end
    
    -- 清理时钟
    for seat = 0, self._maxPlayerCnt - 1 do
        if players[seat] then                      
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)                        
            self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)          
        end 
    end

    -- 暂停全压动画
    self._ui:getInstance():stopFireEffectLoop()
    
    -- 隐藏看牌按钮
    self._ui:getInstance():showBtnShowCard(false)
    -- 当前座位为-1
    app.game.GameData.setCurrseat(-1) 
    
    -- 保存玩家的手牌
    local pCards = {}
    for seat, player in pairs(players) do         
        pCards[seat] = pCards[seat] or {}
        pCards[seat].cards = player.cards
        pCards[seat].type = player.type                          
    end
    app.game.GameData.setCardsData(pCards)
        
    -- 是否全压
    local isallin = app.game.GameData.getAllIn()
    local round = app.game.GameData.getRound()
    
    if isallin or round == GE.ALLROUND then
        --找出参与全压的人 
        local liveSeat = {}   
        for seat = 0, self._maxPlayerCnt - 1 do
            local player = app.game.PlayerData.getPlayerByServerSeat(seat)            
            if players[seat] and player and player:isPlaying() then                      
                table.insert(liveSeat,seat)  
            end 
        end
        
        local intab = false
        for _, seat in ipairs(liveSeat) do
            local localseat = app.game.PlayerData.serverSeatToLocalSeat(seat) 
            if localseat == HERO_LOCAL_SEAT then
            	intab = true
            end
        end
        
        if intab then
            for _, seat in ipairs(liveSeat) do
                local localseat = app.game.PlayerData.serverSeatToLocalSeat(seat) 
                if localseat ~= HERO_LOCAL_SEAT then
                    app.game.GameData.setCompareSeat(localseat)  
                end
            end        	
        end

        if #liveSeat > 2 then
            -- 群魔乱舞动画
            self:playQMLWAction(liveSeat, data.winnerSeat) 
            self._overDelaytime = self._overDelaytime + 3  -- 群魔乱舞结束                     
        elseif #liveSeat == 2 then 
            -- 比牌动画
            local winseat = app.game.PlayerData.serverSeatToLocalSeat(data.winnerSeat)  
            local live1 = app.game.PlayerData.serverSeatToLocalSeat(liveSeat[1])
            local live2 = app.game.PlayerData.serverSeatToLocalSeat(liveSeat[2]) 
            if live1 == winseat then
                self:playCompareAction(live1, live2, live2)
            else
                self:playCompareAction(live1, live2, live1) 
            end 
            self._overDelaytime = self._overDelaytime + 3 -- 比牌结束              
        end           	
    end

    -- 延时结算
    self:performWithDelayGlobal(function()        
        self:onResult(data, players)
    end, self._overDelaytime)     
end

-- 结算
function GamePresenter:onResult(data, players)
    self._gameBtnNode:showBetNode(false)  
    if app.game.PlayerData.getHero():getIsshow() then
        self._gameBtnNode:showBetNode(true, 2)      
    end  

    self:showOtherPlayer()
    
    local tempSeat = data.winnerSeat
    local newWinseats = {}
    if tempSeat == 255 then   -- 平分        
    	for seat = 0, self._maxPlayerCnt - 1 do
            if players[seat] and players[seat].iswin == 1 then 
                table.insert(newWinseats, seat)
            end
        end   
    else
        table.insert(newWinseats, tempSeat)                
    end
    
    local showseats = app.game.GameData.getShowSeat()
    for _, seat in ipairs(showseats) do
        local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)
        if localSeat >= 0 and localSeat <= self._maxPlayerCnt-1 then
            local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()       
            gameHandCardNode:resetHandCards()
            gameHandCardNode:createCards(players[seat].cards)  

            self._gamePlayerNodes[localSeat]:showImgCardType(true, players[seat].type)
            self._gamePlayerNodes[localSeat]:showImgCheck(false)              
        end
    end

    local chipBackseats = {}
    for i, winseat in ipairs(newWinseats) do
        local localSeat = app.game.PlayerData.serverSeatToLocalSeat(winseat)
        if localSeat >= 0 and localSeat <= self._maxPlayerCnt-1 then
            local comparedata = app.game.GameData.getCompareSeat()
            for _, tmpseat in ipairs(comparedata) do
                if tmpseat == localSeat then
                    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()       
                    gameHandCardNode:resetHandCards()
                    gameHandCardNode:createCards(players[winseat].cards)  
                    self._gamePlayerNodes[localSeat]:showImgCardType(true, players[winseat].type) 
                end
            end

            self._gamePlayerNodes[localSeat]:showImgCheck(false)
                        
            local playerobj = app.game.PlayerData.getPlayerByServerSeat(winseat)     
            if playerobj:getIsshow() then
                if players[winseat].type == GECT.zjh_shunjin then
                    self._gamePlayerNodes[localSeat]:playEffectByName("shunjin")
                elseif players[winseat].type == GECT.zjh_baozi then
                    self._gamePlayerNodes[localSeat]:playEffectByName("baozi")
                end
            end
            
            self._gamePlayerNodes[localSeat]:playEffectByName("win")
            
            table.insert(chipBackseats, localSeat)
        end
    end
    
    -- 筹码回收
    self._ui:getInstance():showChipBackAction(chipBackseats)
    
    local scoreLists = {}    
    for seat, player in pairs(players) do  
        if player.cards[1] ~= CV_BACK then
            app.game.PlayerData.updatePlayerRiches(seat, 0, player.balance)
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)    
            scoreLists[localSeat] = player.score           
            self._gamePlayerNodes[localSeat]:showTxtBalance(true, player.balance)    
        end                    
    end
    
    self._ui:getInstance():showWinloseScore(scoreLists)
    
    -- 将正在游戏的玩家状态设为默认
    for i = 0, self._maxPlayerCnt - 1 do 
        local player = app.game.PlayerData.getPlayerByServerSeat(i)
        if player and player:isPlaying() then
            app.game.PlayerData.updatePlayerStatus(i, 0) 
        end              
    end        
     
    -- 延时准备
    self:performWithDelayGlobal(function()
        print("delay 4")
        self:sendPlayerReady()        
    end, 4)                 
end

function GamePresenter:onRelinkEnter(data)   
    self._playing = true
    -- 展示玩家信息
    for i = 0, self._maxPlayerCnt - 1 do
        if self._gamePlayerNodes[i] then            
            self._gamePlayerNodes[i]:showPlayerInfo()
        end
    end
    -- 根据总注生成筹码
    local jackpot = app.game.GameData.getJackpot() or 0
    self._ui:getInstance():showRandomChip(jackpot)
    
    -- 庄家
    local banker = app.game.GameData.getBanker()
    local localBanker = app.game.PlayerData.serverSeatToLocalSeat(banker) 
    if self._gamePlayerNodes[localBanker] then
        self._gamePlayerNodes[localBanker]:showImgBanker(true)                     
    end
    
    -- 是否轮到自己下注
    local currseat = app.game.GameData.getCurrseat()
    local heroseat = app.game.PlayerData.getHeroSeat()
    local basebet = app.game.GameData.getBasebet()
    local base = app.game.GameConfig.getBase()
    if currseat == heroseat then        
        self:onPlayerBet(currseat, basebet / base / 2)
    end
    
    -- 每个玩家的状态
    for i = 0, self._maxPlayerCnt - 1 do
        local player = app.game.PlayerData.getPlayerByServerSeat(i)
        if player then
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
            local isshow = player:getIsshow()
            local status = player:getStatus()
            if i == heroseat then       
                -- 押注按钮
                local normal, disable = self:checkButtonEnable(player)
                self._gameBtnNode:showBetNode(true, 1)
                self._gameBtnNode:setEnableByName(normal, disable)
                -- 手牌
                local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
                gameHandCardNode:resetHandCards()
                gameHandCardNode:createCards(data.cards)  
                -- 牌型
                self._gamePlayerNodes[localSeat]:showImgCardType(true, data.cardtype) 
                -- 是否看牌                
                self._ui:getInstance():showBtnShowCard(not isshow)
                -- 是否弃牌
                if status == GEPS.zjh_giveup then   -- 弃牌
                    self._gamePlayerNodes[localSeat]:showPnlBlack(true, true)
                elseif status == GEPS.zjh_lost then -- 比牌失败
                    self._gamePlayerNodes[localSeat]:showPnlBlack(true)
                end
            else                
                local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
                gameHandCardNode:resetHandCards()
                gameHandCardNode:createCards({0, 0, 0})     
            end           
            self._gamePlayerNodes[localSeat]:showImgBet(true, player:getBet())
        end            
    end    
end

function GamePresenter:onChangeTable(flag)
    self._ischangeTable = true    
	self._ui:getInstance():showPnlHint(3)
    self._gameBtnNode:showBetNode(false) 
    self:performWithDelayGlobal(
        function()
            if app.game.PlayerData.getPlayerCount() <= 1 then
                self._ischangeTable = false  
                self._ui:getInstance():showPnlHint(2)
            end
        end, 2)
end

function GamePresenter:onGameOverShow(showseat)
    print("onGameOverShow")
    local localseat = app.game.PlayerData.serverSeatToLocalSeat(showseat)
    
    app.game.GameData.setShowSeat(showseat)
    
    if localseat == HERO_LOCAL_SEAT then
        self._gameBtnNode:showBetNode(false)  
    end
   
    local data = app.game.GameData.getCardsData()
    if data[showseat] then
        local gameHandCardNode = self._gamePlayerNodes[localseat]:getGameHandCardNode()       
        gameHandCardNode:resetHandCards()
        gameHandCardNode:createCards(data[showseat].cards)  

        self._gamePlayerNodes[localseat]:showImgCardType(true, data[showseat].type)
        self._gamePlayerNodes[localseat]:showImgCheck(false)
    end
end

--------------------------------------------
function GamePresenter:refreshUI()
    -- 单注
    local basebet = app.game.GameData.getBasebet() or 0
    self._ui:getInstance():showDanZhu(basebet)
    
    -- 轮数
    local round = app.game.GameData.getRound() or 0
    self._ui:getInstance():showLunShu(round, GE.ALLROUND)
    
    -- 总注 
    local jackpot = app.game.GameData.getJackpot() or 0
    self._ui:getInstance():showZongzhu(jackpot)
end

function GamePresenter:playBankerAction()
    local banker = app.game.GameData.getBanker()
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(banker) 
    if self._gamePlayerNodes[localSeat] then
        self._gamePlayerNodes[localSeat]:playBankAction()                     
    end
end

function GamePresenter:playBaseChipAction()
    local seats = app.game.GameData.getPlayerseat()    
    for k, i in ipairs(seats) do
        local player = app.game.PlayerData.getPlayerByServerSeat(i)
        if player then
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i) 
            self._ui:getInstance():showBaseChipAction(localSeat) 

            local base = app.game.GameConfig.getBase()
            local balance = app.game.PlayerData.reducePlayerRiches(i, base) 
            app.game.PlayerData.updatePlayerRiches(i, base)            
            self._gamePlayerNodes[localSeat]:showTxtBalance(true, balance)
            self._gamePlayerNodes[localSeat]:showImgBet(true,  player:getBet())            
        end            
    end    
end

function GamePresenter:playBiPaiPanel(flag1, flag2)
    -- 点击比牌按钮的黑背景
    self._ui:getInstance():showBiPaiPanel(flag1)
    
    if flag1 then        
        local heroseat = app.game.PlayerData.getHeroSeat()
        for i = 0, self._maxPlayerCnt - 1 do
            if heroseat ~= i then
                local player = app.game.PlayerData.getPlayerByServerSeat(i)
                if player and not player:isPlaying() then
                    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
                    self._gamePlayerNodes[localSeat]:showPnlPlayer(false)
                end
                if player and player:isPlaying() then
                    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
                    self._gamePlayerNodes[localSeat]:playBlinkAction()
                end
            end           
        end
    else        
        if flag2 then
            self:showOtherPlayer()
        end            
    end
end

function GamePresenter:playCompareAction(localSeat, otherSeat, loserSeat, isGzyz)       
    for i = 0, self._maxPlayerCnt - 1 do      
        if self._gamePlayerNodes[i] then
            self._gamePlayerNodes[i]:showPnlPlayer(false)
        end                          
    end
    
    self._ui:getInstance():showBiPaiEffect() 
    local handcards = app.game.GameData.getHandcards()
    
    local function callback()
        if localSeat == loserSeat then
            self._gamePlayerNodes[localSeat]:showPnlBlack(true)
            self._gamePlayerNodes[otherSeat]:showPnlBlack(false)
            self:showGaryCard(localSeat)
        elseif otherSeat == loserSeat then
            self._gamePlayerNodes[localSeat]:showPnlBlack(false)
            self._gamePlayerNodes[otherSeat]:showPnlBlack(true)
            self:showGaryCard(otherSeat)
        end
    end
    
    self._ui:getInstance():showCompareAction(localSeat, otherSeat, loserSeat, handcards, callback)    
    
    if isGzyz then
    	self._ui:getInstance():playGZYZeffect()
    end               
end

function GamePresenter:showOtherPlayer()
    for i = 0, self._maxPlayerCnt - 1 do
        local player = app.game.PlayerData.getPlayerByServerSeat(i)        
        if player then            
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
            if self._gamePlayerNodes[localSeat] then
                self._gamePlayerNodes[localSeat]:showPnlPlayer(true)
                self._gamePlayerNodes[localSeat]:stopBlinkAction()
            end
        end                        
    end
end

function GamePresenter:playQMLWAction(liveSeat, winnerSeat)
    for i, seat in ipairs(liveSeat) do
        local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat) 
        if seat ~= winnerSeat then
            self._gamePlayerNodes[localSeat]:playQMLWAction(false)
		else
            self._gamePlayerNodes[localSeat]:playQMLWAction(true)
		end
	end
end

function GamePresenter:playQMLWeffect()
    self._ui:getInstance():playQMLWeffect()
end

function GamePresenter:showGaryCard(localSeat, scale)
    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
    if gameHandCardNode:getCardID() == CV_BACK then
        gameHandCardNode:resetHandCards()
        gameHandCardNode:createCards({888,888,888}, scale)  
    end
end

function GamePresenter:setCardScale(scale, localSeat)
    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
    if gameHandCardNode and localSeat == 1 then
        gameHandCardNode:setCardScale(scale)
        gameHandCardNode:setCardPosition()
    end
end

function GamePresenter:checkButtonEnable(player)
    local round = app.game.GameData.getRound()
    local currseat = app.game.GameData.getCurrseat()
    local isallin = app.game.GameData.getAllIn()
    local seat = player:getSeat()
    local isshow = player:getIsshow()
    local isplaying = player:isPlaying()    
    local normal = {}
    local disable = {}
   
    if currseat ~= seat then
        table.insert(disable, "qp")
        table.insert(disable, "bp")
        table.insert(disable, "jz")
        table.insert(disable, "gz")                         
    else
        if isplaying then
            table.insert(normal, "qp")
                                  
            if isallin then
                table.insert(disable, "jz") 
                table.insert(disable, "bp")
            else
                if round <= 1 then
                    table.insert(disable, "bp")
                else
                    table.insert(normal, "bp")
                end
                              
                table.insert(normal, "jz")       
            end
            table.insert(normal, "gz")
        else
            table.insert(disable, "qp") 
            table.insert(disable, "bp") 
            table.insert(disable, "jz") 
            table.insert(disable, "gz")         
        end
    end
    
    return normal, disable
end

function GamePresenter:checkHeroWaiting()
    local hero = app.game.PlayerData.getHero()
    if hero and hero:isWaiting() then
    	return true
    end
    return false
end

function GamePresenter:checkBtnShowCard(flag)
    local hero = app.game.PlayerData.getHero()
    if not hero:getIsshow() and hero:isPlaying() and not self._gameOver then
        self._ui:getInstance():showBtnShowCard(flag)
    end
end

-- -----------------------------schedule------------------------------
-- 发牌
function GamePresenter:openSchedulerTakeFirst(callback)
    local cardbacks = {}             
    for i = 0, self._maxPlayerCnt - 1 do
        cardbacks[i] = cardbacks[i] or {}  
        for j=1, CARD_NUM do
            cardbacks[i][j] = CV_BACK
        end
    end
         
    local cardNum = 1
    local seats = {}
    if app.game.GameData then
        seats = app.game.GameData.getPlayerseat()
    end
    local function onInterval(dt)
        if cardNum <= CARD_NUM then
            for i, seat in ipairs(seats) do
                local localseat = app.game.PlayerData.serverSeatToLocalSeat(seat)
                if self._gamePlayerNodes[localseat] then
                    self._gamePlayerNodes[localseat]:onTakeFirst(cardbacks[localseat][cardNum])                     
                end
            end
            cardNum = cardNum + 1
        else
            self:closeSchedulerTakeFirst()
                
            if callback then
                callback()
            end
        end
    end

    self:closeSchedulerTakeFirst()
    
    self._schedulerTakeFirst = scheduler:scheduleScriptFunc(onInterval, 1/CARD_NUM, false)
end

function GamePresenter:closeSchedulerTakeFirst()
    if self._schedulerTakeFirst then
        scheduler:unscheduleScriptEntry(self._schedulerTakeFirst)
        self._schedulerTakeFirst = nil
    end
end

-- 时钟
function GamePresenter:openSchedulerClock(localSeat, time)
    local allTime = time
    local sound = false
    local function flipIt(dt)
        time = time - dt

        if time <= 0 then
            self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
        end
        
        if localSeat == HERO_LOCAL_SEAT then
            if time < 2 and not sound then
                self._ui:getInstance():playEffectByName("didi")
                sound = true
            end
        end
        
        self._gamePlayerNodes[localSeat]:showClockProgress(time / allTime * 100)
    end

    self:closeSchedulerClock(localSeat)
    
    self._schedulerClocks[localSeat] = scheduler:scheduleScriptFunc(flipIt, 0.05, false)
end

function GamePresenter:closeSchedulerClock(localSeat)
    if self._schedulerClocks[localSeat] then
        scheduler:unscheduleScriptEntry(self._schedulerClocks[localSeat])
        self._schedulerClocks[localSeat] = nil
    end
end

function GamePresenter:closeSchedulerClocks()    
	for i = 0, 4 do
	    if self._schedulerClocks[i] then
	        self:closeSchedulerClock(i)
	    end
	end   
end

-- 准备倒计时
function GamePresenter:openSchedulerPrepareClock(time)
    local allTime = time
    local first,second,third = false,false,false
    local function flipIt(dt)
        time = time - dt
        if time <= 0 then
            self._ui:getInstance():showPnlHint()
            self._gameBtnNode:showBetNode(false) 
            self:closeSchedulerPrepareClock()
        end
        local t = math.ceil(time) % allTime
        if t == 0 and not first then
            self:playCountDownEffect()
            first = true
        elseif t == 1 and not second then
            self:playCountDownEffect()
            second = true
        elseif t == 2 and not third then    
            self:playCountDownEffect()
            third = true
        end

        local strTime = string.format("%d", math.ceil(time))
        self._ui:getInstance():showClockPrepare(strTime)
    end

    self:closeSchedulerPrepareClock()
    self._schedulerPrepareClock = scheduler:scheduleScriptFunc(flipIt, 0.1, false)
end 

function GamePresenter:closeSchedulerPrepareClock()
    if self._schedulerPrepareClock then
        scheduler:unscheduleScriptEntry(self._schedulerPrepareClock)
        self._schedulerPrepareClock = nil
    end
end

function GamePresenter:openSchedulerRunLoading(txt)
    local function runLoading(dt)
        SCHEDULE_WAIT_TIME = SCHEDULE_WAIT_TIME + dt + 0.1
        local t = math.floor(SCHEDULE_WAIT_TIME) % 4
        if t == 0 then
            self._ui:getInstance():setTxtwait(" "..txt)
        elseif t == 1 then
            self._ui:getInstance():setTxtwait("  "..txt .. ".")
        elseif t == 2 then
            self._ui:getInstance():setTxtwait("   "..txt .. "..")
        elseif t == 3 then
            self._ui:getInstance():setTxtwait("    "..txt .. "...")
        end
    end
    self:closeSchedulerRunLoading()
    self._schedulerRunLoading = scheduler:scheduleScriptFunc(runLoading, 0.1, false)
end

function GamePresenter:closeSchedulerRunLoading()
    SCHEDULE_WAIT_TIME = 0
    if self._schedulerRunLoading then        
        scheduler:unscheduleScriptEntry(self._schedulerRunLoading)
        self._schedulerRunLoading = nil
    end
end

function GamePresenter:openScheduleSendReady(id)
    local function filt(dt)        
        self:sendAutoReady(id)
    end
    self:closeScheduleSendReady()
    self._schedulerAutoReady = scheduler:scheduleScriptFunc(filt, 1, false)
end

function GamePresenter:closeScheduleSendReady()
    if self._schedulerAutoReady then
        scheduler:unscheduleScriptEntry(self._schedulerAutoReady)
        self._schedulerAutoReady = nil
    end
end

-------------------------------ontouch-------------------------------
function GamePresenter:onTouchBtnQipai()
	self:sendQipai()
end

function GamePresenter:onTouchBtnBipai()
    if self._ui:getInstance():isBiPaiPanelVisible() then
        return
    end
    self:playBiPaiPanel(true)
end

function GamePresenter:onTouchPanelBiPai(localseat)
    if not self._ui:getInstance():isBiPaiPanelVisible() then
    	return
    end
    self:playBiPaiPanel(false, true)
    local seat = app.game.PlayerData.localSeatToServerSeat(localseat)
    self:sendBipai(seat)
end

function GamePresenter:onTouchBtnKanpai()    
    self:sendKanpai()
end

function GamePresenter:onTouchBtnGenzhu()   
    self:sendBetmult(-1)
end

function GamePresenter:onTouchBtnBetmult(index)
    local mult = 1
    if index < 6 then
        mult = index*2 
    elseif index == 6 then
        mult = 0           
    end    
    self:sendBetmult(mult) 
end

function GamePresenter:onTouchBtnEndshow()
     self:sendEndShow()	
end

function GamePresenter:onEventCbxGendaodi(flag)
	if flag then
        local curseat = app.game.GameData.getCurrseat()
        local heroseat = app.game.PlayerData.getHeroSeat()
        if curseat == heroseat then
            self:sendBetmult(-1) 
        end
	end	
end

-------------------------------request-------------------------------
function GamePresenter:sendLeaveRoom()
    local heroseat = app.game.PlayerData.getHeroSeat()
    local player = app.game.PlayerData.getPlayerByServerSeat(heroseat)    
    if player:isPlaying() then
        self:dealTxtHintStart("游戏中,暂无法离开！")            
    else
        local po = upconn.upconn:get_packet_obj()
        if po ~= nil then
            local sessionid = app.data.UserData.getSession() or 222
            po:writer_reset()
            po:write_int32(sessionid)  
            upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_LEAVE_ROOM_REQ)
        end 	
    end
end

-- 弃牌
function GamePresenter:sendQipai()
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
        po:write_int32(sessionid)  
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_GIVE_UP_REQ)
    end 
end

-- 比牌
function GamePresenter:sendBipai(seat)
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
        po:write_int16(seat) 
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_COMPARE_CARD_REQ)
    end 
end

-- 看牌
function GamePresenter:sendKanpai()
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
        po:write_int32(sessionid)  
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_SHOW_CARD_REQ)
    end 
end

-- 加注
function GamePresenter:sendBetmult(mult)
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()        
        po:write_int32(mult)
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_ANTE_UP_REQ)
    end 
end

-- 结束后亮牌
function GamePresenter:sendEndShow()
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        print("send end show")
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()        
        po:write_int32(sessionid)
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_ZJH_GAME_OVER_SHOW_REQ)
    end 
end

-- 准备
function GamePresenter:sendPlayerReady()
    if not app.game.GamePresenter then
        print("not in game")
        return
    end

    local ready = app.game.GameData.getHeroReady()
    if ready then
        print("have ready")
        return 
    end

    local hero = app.game.PlayerData.getHero()   
    if not hero then  
        print("no hero")     
        return
    end 
   
    local po = upconn.upconn:get_packet_obj()
    local limit = app.game.GameConfig.getLimit()    
    if hero and not hero:isLeave() and hero:getBalance() > limit and po then        
        print("hero send ready", hero:getTicketID())
        
        local sessionid = app.data.UserData.getSession() or 222        
        po:writer_reset()
        po:write_int64(sessionid)
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_READY_REQ)
    end    
end

-- 换桌
function GamePresenter:sendChangeTable()
    print("sendChangeTable")
    local heroseat = app.game.PlayerData.getHeroSeat()
    local player = app.game.PlayerData.getPlayerByServerSeat(heroseat)    
    if player:isPlaying() then
        self:dealTxtHintStart("游戏中,暂无法换桌！")            
    else
        local sessionid = app.data.UserData.getSession() or 222
        local po = upconn.upconn:get_packet_obj()
        po:writer_reset()
        po:write_int64(sessionid)
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_CHANGE_TABLE_REQ)
    end    
end

-------------------------------rule-------------------------------
function GamePresenter:getCardColor(id)
    if id ~= nil then
        return bit._rshift(bit._and(id, 0xf0), 4) 
    end   
end

function GamePresenter:getCardNum(id)
    if id ~= nil then
        return bit._and(id, 0x0f)
    end    
end

function GamePresenter:playGameMusic()
    app.util.SoundUtils.playMusic("game/zjh/sound/bgm_game2.mp3")
end

function GamePresenter:playCountDownEffect()
    app.util.SoundUtils.playEffect("game/zjh/sound/countdown.mp3")   
end

return GamePresenter