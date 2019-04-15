--[[
@brief  游戏主场景控制基类
]]

local GamePlayerNode = require("app.game.zjh.GamePlayerNode")
local GameBtnNode    = require("app.game.zjh.GameBtnNode")
local GameMenuNode   = require("app.game.zjh.GameMenuNode")

local GamePresenter  = class("GamePresenter", app.base.BasePresenter)

GamePresenter._ui    = require("app.game.zjh.GameScene")

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
    self._maxPlayerCnt = app.game.PlayerData.getMaxPlayerCount()
    self:playGameMusic()  
    self:initPlayerNode()
    self:initBtnNode()
    self:initMenuNode()
    self:initScheduler()    
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
    self:closeSchedulerAutoReady()
    self:closeSchedulerRunLoading()
    GamePresenter._instance = nil
end

function GamePresenter:performWithDelayGlobal(listener, time)
    local handle
    handle = scheduler:scheduleScriptFunc(
        function()
            scheduler:unscheduleScriptEntry(handle)
            listener()
        end, time, false)
    return handle
end

-- 处理玩家状态
function GamePresenter:onPlayerStatus(data)
    print("status is",data.status)
    if data.status == 7 then    -- 退出
        self:onLeaveNormal(data)
    elseif data.status == 8 or data.status == 9 then -- 服务踢出房间     
        self:onLeaveKick(data)                           
    end
end

function GamePresenter:onLeaveNormal(data)
    if app.game.PlayerData.isHero(data.ticketid) then 
        self:closeSchedulerAutoReady()
    end
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
    if app.game.PlayerData.isHero(data.ticketid) then 
        self:closeSchedulerAutoReady()
    end

    local numID = data.ticketid
    local player = app.game.PlayerData.getPlayerByNumID(numID)        
    if not player then               
        return
    end
    app.game.PlayerData.onPlayerLeave(numID)
    self:onPlayerLeave(player)

   
    local hint = ""
    if data.status == 8 then
        hint = "金币不足,请再补充点金币吧!"
    elseif data.status == 9 then        
        hint = "托管次数过多,已离开房间!" 
    end

    self:performWithDelayGlobal(
        function()
            if app.game.PlayerData.isHero(data.ticketid) then 
                self:dealHintStart(hint,
                    function(bFlag)
                        self:onLeaveRoom()
                    end, 0)
            end 
        end, 2)
end

-- 处理玩家进入
function GamePresenter:onPlayerEnter(player)    
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(player:getSeat()) 
    print("getSeat is",player:getSeat())
    
    if self._gamePlayerNodes then
        self._gamePlayerNodes[localSeat]:onPlayerEnter() 
    end 
    
    self._ui:getInstance():showBiPaiPanel(false)  
    
    if app.game.PlayerData.getPlayerCount() <= 1 then
        self._ui:getInstance():showPnlHint(2)
    end
end

function GamePresenter:onLeaveRoom()
    app.game.GameEngine:getInstance():exit()
end

-- 处理玩家离开
function GamePresenter:onPlayerLeave(player)
    local numID = player:getTicketID()
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
                self._gamePlayerNodes[HERO_LOCAL_SEAT]:onPlayerLeave()
            end
        end
    end
end

-- 玩家准备
function GamePresenter:onPlayerReady(seat)
	
end

-- 游戏准备
function GamePresenter:onGamePrepare()
    self._ui:getInstance():showPnlHint(1)
end

-- 开始
function GamePresenter:onGameStart()
    self._ui:getInstance():showPnlHint(3)
    print("self._maxPlayerCnt - 1",self._maxPlayerCnt - 1)
    for i = 0, self._maxPlayerCnt - 1 do        
        app.game.PlayerData.updatePlayerStatus(i, 3)
        app.game.PlayerData.updatePlayerIsshow(i, 0)
        app.game.PlayerData.resetPlayerBet(i)
    end
    app.game.GameData.setAllIn(false)
    -- 隐藏比牌
    self._ui:getInstance():showBiPaiPanel(false)
    
    -- 玩家开始
    for i = 0, self._maxPlayerCnt - 1 do
        if self._gamePlayerNodes[i] then
            self._gamePlayerNodes[i]:onGameStart()
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
            self:onTakeFirst()
        end, TIME_TAKE_FIRST)  
end

-- 发牌
function GamePresenter:onTakeFirst()
    local function callback()
        self._gameBtnNode:showBetNode(true)
        local banker = app.game.GameData.getBanker()
        self:onPlayerBet(banker, 0)
    end
    
    self:openSchedulerTakeFirst(callback)
end

-- 时钟
function GamePresenter:onClock(serverSeat)
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
    if seat == -1 then
        print("next is -1")
    	return
    end

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
        
    else
        local heroseat = app.game.PlayerData.getHeroSeat()
        local player = app.game.PlayerData.getPlayerByServerSeat(heroseat)    
        local normal, disable = self:checkButtonEnable(player)
        self._gameBtnNode:setEnableByName(normal, disable)     
    end

    self:onClock(seat)
    
    local heroseat = app.game.PlayerData.getHeroSeat()
    if seat == heroseat and self._gameBtnNode:isSelected() then
        self:performWithDelayGlobal(function()
            self:sendBetmult(-1) 
        end, 1)
    end
end

-- 弃牌
function GamePresenter:onPlayerGiveUp(now, next, round)
    app.game.PlayerData.updatePlayerStatus(now, 5)
    local basebet = app.game.GameData.getBasebet()
    local base = app.game.GameConfig.getBase()

    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(now)    
    self._gamePlayerNodes[localSeat]:showImgCheck(true, 1)
    self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)   
    self._gamePlayerNodes[localSeat]:playSpeakAction(3) 
    self:showGaryCard(localSeat)
    
    app.game.GameData.setCurrseat(next)
    
    local heroseat = app.game.PlayerData.getHeroSeat()
    if heroseat == now then
        local player = app.game.PlayerData.getPlayerByServerSeat(now)            
        local normal, disable = self:checkButtonEnable(player)
        self._gameBtnNode:setEnableByName(normal, disable)
        
        local gender = player:getGender() 
        if gender == 1 then
            self._gamePlayerNodes[localSeat]:playEffectByName("m_qp")   
        else
            self._gamePlayerNodes[localSeat]:playEffectByName("w_qp")       
        end  
    elseif heroseat == next then	
        local player = app.game.PlayerData.getPlayerByServerSeat(next)    
        local normal, disable = self:checkButtonEnable(player)
        self._gameBtnNode:setEnableByName(normal, disable) 
    else
        print("give up error!!")    
    end
    
    self:onPlayerBet(next, basebet / base)
end

-- 比牌
function GamePresenter:onPlayerCompareCard(data) 
    print("onPlayerCompareCard")  
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
    
    self:onPlayerBet(app.game.GameData.getCurrseat(), ib)   
end 

-- 看牌
function GamePresenter:onPlayerShowCard(seat, cards, cardtype)
    app.game.PlayerData.updatePlayerIsshow(seat, 1) 
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)
    local player = app.game.PlayerData.getPlayerByServerSeat(seat)
    local gender = player:getGender() 
    if gender == 1 then
        self._gamePlayerNodes[localSeat]:playEffectByName("m_kp")   
    else
        self._gamePlayerNodes[localSeat]:playEffectByName("w_kp")       
    end 
    if localSeat ~= 1 then
        self._gamePlayerNodes[localSeat]:showImgCheck(true, 0)
    end
    
    if localSeat == 1 then
        self._gamePlayerNodes[localSeat]:showImgCardType(true, cardtype)              
        local normal, disable = self:checkButtonEnable(player)
        self._gameBtnNode:setEnableByName(normal, disable) 
    end
    
    if cards then
        local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
        gameHandCardNode:resetHandCards()
        gameHandCardNode:createCards(cards)
    end    
end

-- 押注
function GamePresenter:onPlayerAnteUp(data)    
    if data.isAllIn == 1 then
        print("all in ante")
        self:onPlayerAnteUpAllIn(data)    	
    else
        print("normal ante")
        self:onPlayerAnteUpNormal(data)	
    end
end

-- 全压(其他玩家判断是否要进行跟注)
function GamePresenter:onPlayerAnteUpAllIn(data)
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
    self._gamePlayerNodes[localSeat]:showImgBet(true,  player:getBet())
   
    
    app.game.GameData.setBasebet(data.basebet)

    self:onPlayerAllIn(app.game.GameData.getCurrseat())
end

-- 按钮显示
function GamePresenter:onPlayerAllIn(seat)
    if seat == -1 then
        print("next is -1")
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
    if seat == heroseat and self._gameBtnNode:isSelected() then
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
    dump(data)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(data.playerSeat)
    self._ui:getInstance():showAllInChipAction(localSeat)
    print("LastBet count is",#data.otherSeat, localSeat)
    for i, seat in ipairs(data.otherSeat) do
        local otherSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)
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
        end, (i-1)*5)            
    end
        
    self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
        
    local basebet = app.game.GameData.getBasebet()
    local base = app.game.GameConfig.getBase()
    local index = basebet / base 

    self:onPlayerBet(app.game.GameData.getCurrseat(), index) 
end

-- 游戏结束
function GamePresenter:onGameOver(data, players)
    -- 清理时钟
    for seat = 0, self._maxPlayerCnt - 1 do
        if players[seat] then                      
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)                        
            self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)          
        end 
    end
    -- 暂停全压动画
    self._ui:getInstance():stopFireEffectLoop()
    -- 隐藏按钮
    self._gameBtnNode:showBetNode(false)
    -- 当前座位为-1
    app.game.GameData.setCurrseat(-1) 
    
    -- 是否全压
    local isallin = app.game.GameData.getAllIn()
    local round = app.game.GameData.getRound()
    print("isapp.Game.GameID.ZJH is",isallin)
    if isallin or round == GE.ALLROUND then
        --找出参与全压的人 
        dump(players)
        local liveSeat = {}   
        for seat = 0, self._maxPlayerCnt - 1 do
            local player = app.game.PlayerData.getPlayerByServerSeat(seat)
            if player then
                print("seat is play",player:isPlaying())
            end
            
            if players[seat] and player and player:isPlaying() then                      
                table.insert(liveSeat,seat)    
            end 
        end
        dump(liveSeat)
        if #liveSeat > 2 then
            -- 群魔乱舞动画
            self:playQMLWAction(liveSeat, data.winnerSeat)
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
        end

        -- 延时结算
        self:performWithDelayGlobal(function()
            self:onResult(data, players)
        end, 3)
    else
        -- 延时结算
        self:performWithDelayGlobal(function()
            self:onResult(data, players)
        end, 2)   	
    end
    
    -- 自动准备
    self:openSchedulerAutoReady(5)  
end

-- 结算
function GamePresenter:onResult(data, players)
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
    
    local chipBackseats = {}
    for i, winseat in ipairs(newWinseats) do
        local localSeat = app.game.PlayerData.serverSeatToLocalSeat(winseat)
        if localSeat >= 0 and localSeat <= self._maxPlayerCnt-1 then
            local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()            
            gameHandCardNode:resetHandCards()
            gameHandCardNode:createCards(players[winseat].cards)  

            self._gamePlayerNodes[localSeat]:showImgCardType(true, players[winseat].type)          
            self._gamePlayerNodes[localSeat]:showImgCheck(false)
            
            if players[winseat].type == GECT.zjh_shunjin then
                self._gamePlayerNodes[localSeat]:playEffectByName("shunjin")
            elseif players[winseat].type == GECT.zjh_baozi then
                self._gamePlayerNodes[localSeat]:playEffectByName("baozi")
            end
            
            self._gamePlayerNodes[localSeat]:playEffectByName("win")
            
            table.insert(chipBackseats, localSeat)
        end
    end
    
    self._ui:getInstance():showChipBackAction(chipBackseats)

    for seat = 0, self._maxPlayerCnt - 1 do
        if players[seat] then          
            app.game.PlayerData.updatePlayerRiches(seat, 0, players[seat].balance) 
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)            
            self._gamePlayerNodes[localSeat]:showWinloseScore(players[seat].score)            
            self._gamePlayerNodes[localSeat]:showTxtBalance(true, players[seat].balance)                                         
        end 
    end       
    
    -- 当前玩家状态设为默认
    for i = 0, self._maxPlayerCnt - 1 do        
        app.game.PlayerData.updatePlayerStatus(i, 0)       
    end    
end

function GamePresenter:onRelinkEnter(cards, cardtype)   
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
        self:onPlayerBet(currseat, basebet / base)
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
                self._gameBtnNode:showBetNode(true)
                self._gameBtnNode:setEnableByName(normal, disable)
                -- 手牌
                local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
                gameHandCardNode:resetHandCards()
                gameHandCardNode:createCards(cards)  
                -- 牌型
                self._gamePlayerNodes[localSeat]:showImgCardType(true, cardtype) 
                -- 是否看牌
                self._gamePlayerNodes[localSeat]:showImgCheck(isshow, 0)
                -- 是否弃牌
                if status == GEPS.zjh_giveup then   -- 弃牌
                    self._gamePlayerNodes[localSeat]:showPnlBlack(true)
                    self._gamePlayerNodes[localSeat]:showImgCheck(isshow, 1)
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
    for i = 0, self._maxPlayerCnt - 1 do
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

function GamePresenter:playBiPaiPanel(flag)
    if flag then
        self._ui:getInstance():showBiPaiPanel(true)
        local heroseat = app.game.PlayerData.getHeroSeat()
        for i = 0, self._maxPlayerCnt - 1 do
            if heroseat ~= i then
                local player = app.game.PlayerData.getPlayerByServerSeat(i)
                if player and not player:isPlaying() then
                    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
                    self._gamePlayerNodes[localSeat]:setLocalZOrder(-1)
                end
                if player and player:isPlaying() then
                    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
                    self._gamePlayerNodes[localSeat]:playBlinkAction()
                end
            end           
        end
    else
        self._ui:getInstance():showBiPaiPanel(false)
        for i = 0, self._maxPlayerCnt - 1 do
            if self._gamePlayerNodes[i] then
                self._gamePlayerNodes[i]:setLocalZOrder(1)
                self._gamePlayerNodes[i]:stopBlinkAction()
            end            
        end
    end
end

function GamePresenter:playCompareAction(localSeat, otherSeat, loserSeat, isGzyz)
    local flag = otherSeat == loserSeat
    local fx, fy = self._gamePlayerNodes[localSeat]:getPosition()
    local fm, fn = self._gamePlayerNodes[otherSeat]:getPosition() 
    local tl, tlm, trm, tr = self._ui:getInstance():getToPosition()
    
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
    self._ui:getInstance():showBiPaiEffect()
    self._gamePlayerNodes[localSeat]:playPanleAction(cc.p(fx, fy), posl, flag)  
    self._gamePlayerNodes[otherSeat]:playPanleAction(cc.p(fm, fn), posr, not flag)  
    
    if isGzyz then
    	self._ui:getInstance():playGZYZeffect()
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

function GamePresenter:showGaryCard(localSeat)
    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
    if gameHandCardNode:getCardID() == CV_BACK then
        gameHandCardNode:resetHandCards()
        gameHandCardNode:createCards({888,888,888})  
    end
end

function GamePresenter:setCardScale(scale, localSeat)
    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
    if gameHandCardNode and localSeat == 1 then
        gameHandCardNode:setCardScale(scale)
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
    print("seat is playing",isplaying, currseat, seat)
    if currseat ~= seat then
        table.insert(disable, "qp")
        table.insert(disable, "bp")
        table.insert(disable, "jz")
        table.insert(disable, "gz")
        if isplaying then
            if isshow then
                table.insert(disable, "kp")
            else                  
                table.insert(normal, "kp")  
            end
        else	
            table.insert(disable, "kp")        	
        end                  
    else
        if isplaying then
            table.insert(normal, "qp")
            if round <= 1 then
                table.insert(disable, "bp")
            else
                table.insert(normal, "bp")
            end  
            if isshow then
                table.insert(disable, "kp")  
            else            
                table.insert(normal, "kp")  
            end           
            if isallin then
                table.insert(disable, "jz")   
            else
                table.insert(normal, "jz")       
            end
            table.insert(normal, "gz")
        else
            table.insert(disable, "qp") 
            table.insert(disable, "bp") 
            table.insert(disable, "kp")
            table.insert(disable, "jz") 
            table.insert(disable, "gz")         
        end
    end
    
    return normal, disable
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
    local seats = app.game.GameData.getPlayerseat()
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
    
    local function flipIt(dt)
        time = time - dt

        if time <= 0 then
            self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
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
    for i = 0, self._maxPlayerCnt - 1 do
        if self._schedulerClocks[i] then
            self:closeSchedulerClock(i)
        end
    end
end

-- 准备倒计时
function GamePresenter:openSchedulerPrepareClock(time)
    local allTime = time

    local function flipIt(dt)
        time = time - dt

        if time <= 0 then
            self._ui:getInstance():showPnlHint(3)
            self:closeSchedulerPrepareClock()
        end
        local strTime = string.format("%d", math.ceil(time))
        self._ui:getInstance():showClockPrepare(strTime)
    end

    self:closeSchedulerPrepareClock()
    self:playCountDownEffect()
    self._schedulerPrepareClock = scheduler:scheduleScriptFunc(flipIt, 0.1, false)
end 

function GamePresenter:closeSchedulerPrepareClock()
    if self._schedulerPrepareClock then
        scheduler:unscheduleScriptEntry(self._schedulerPrepareClock)
        self._schedulerPrepareClock = nil
    end
end

-- 自动准备
function GamePresenter:openSchedulerAutoReady(time)
    local allTime = time
    local function flipIt(dt)
        time = time - dt
        if time <= 0 then            
            self:closeSchedulerAutoReady()
            print("ready timeout")
            self:sendPlayerReady()
        end               
    end

    self:closeSchedulerAutoReady()
    self._schedulerAutoReady = scheduler:scheduleScriptFunc(flipIt, 1, false)
end 

function GamePresenter:closeSchedulerAutoReady()
    if self._schedulerAutoReady then
        print("close AutoReady",app.game.PlayerData.getHeroSeat())
        scheduler:unscheduleScriptEntry(self._schedulerAutoReady)
        self._schedulerAutoReady = nil
    end
end

function GamePresenter:openSchedulerRunLoading()
    local function runLoading(dt)
        SCHEDULE_WAIT_TIME = SCHEDULE_WAIT_TIME + dt + 0.1
        local t = math.floor(SCHEDULE_WAIT_TIME) % 4
        local txt = "请耐心等待其他玩家"
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

-------------------------------ontouch-------------------------------
function GamePresenter:onTouchBtnQipai()
	self:sendQipai()
end

function GamePresenter:onTouchBtnBipai()
    self:playBiPaiPanel(true)
end

function GamePresenter:onTouchPanelBiPai(localseat)
    if not self._ui:getInstance():isBiPaiPanelVisible() then
    	return
    end
    self:playBiPaiPanel(false)
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
        self:dealHintStart("游戏中,暂无法离开!")            
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
        po:write_byte(seat) 
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

-- 准备
function GamePresenter:sendPlayerReady()
    print("auto ready!!!!!",app.game.PlayerData.getHeroSeat())
	local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_int64(sessionid)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_READY_REQ)
end

-- 换桌
function GamePresenter:sendChangeTable()
    print("sendChangeTable")
    local heroseat = app.game.PlayerData.getHeroSeat()
    local player = app.game.PlayerData.getPlayerByServerSeat(heroseat)    
    if player:isPlaying() then
        self:dealHintStart("游戏中,暂无法换桌!")            
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