--[[
@brief  游戏主场景控制基类
]]

local GamePlayerNode = require("app.game.zjh.GamePlayerNode")
local GameBtnNode    = require("app.game.zjh.GameBtnNode")
local GameMenuNode   = require("app.game.zjh.GameMenuNode")

local GamePresenter  = class("GamePresenter", app.base.BasePresenter)

GamePresenter._ui    = require("app.game.zjh.GameScene")

local scheduler = cc.Director:getInstance():getScheduler()

local HERO_LOCAL_SEAT   = 1
local CARD_NUM          = 3
local CV_BACK           = 0

local TIME_START_EFFECT = 0
local TIME_MAKE_BANKER  = 0.5
local TIME_THROW_CHIP   = 1.5
local TIME_TAKE_FIRST   = 2

local TIME_PLAYER_BET   = 15

-- 初始化
function GamePresenter:init(...)
    self._maxPlayerCnt = app.game.PlayerData.getMaxPlayerCount()  
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
    self._schedulerClocks      = {}      -- 时钟    
    self._schedulerTakeFirst   = nil     -- 发牌    
    self._schedulerPrepareClock = nil    -- 倒计时
end

-- 退出界面
function GamePresenter:exit()
    GamePresenter.super.exit(self)
    
    self:closeSchedulerTakeFirst()
    self:closeSchedulerClocks()
    self:closeSchedulerPrepareClock()
    
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
    if data.status == 7 then    -- 退出
        local numID = data.ticketid
        local player = app.game.PlayerData.getPlayerByNumID(numID)        

        if not player then
            return
        end

        app.game.PlayerData.onPlayerLeave(numID)
        self:onPlayerLeave(player)
    end
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
        self._gameBtnNode:showBetBtns(true)
        self._gameBtnNode:setSelected(false)
        self:onBankerBet()
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

-- 开始押注(庄家)
function GamePresenter:onBankerBet()
    local banker = app.game.GameData.getBanker()
    if app.game.PlayerData.getHeroSeat() == banker then
        local round = app.game.GameData.getRound() 
        self._gameBtnNode:showBetBtnEnable(true, round)
        
        self._gameBtnNode:setDisableByIndex(1)
    else
        self._gameBtnNode:showBetBtnEnable(false)    
    end
    
    self:onClock(banker)
    
    local heroseat = app.game.PlayerData.getHeroSeat()
    if banker == heroseat and self._gameBtnNode:isSelected() then
        self:performWithDelayGlobal(function()
            self:sendBetmult(1) 
        end, 1)
    end
end

-- 玩家押注
function GamePresenter:onPlayerBet(seat, index)
    if seat == -1 then
        print("next is -1")
    	return
    end
    if app.game.PlayerData.getHeroSeat() == seat then
        local round = app.game.GameData.getRound() 
        self._gameBtnNode:showBetBtnEnable(true, round)
        -- index之后的按钮可点击
        self._gameBtnNode:setDisableByIndex(index)
    else
        self._gameBtnNode:showBetBtnEnable(false)    
    end

    self:onClock(seat)
    
    local heroseat = app.game.PlayerData.getHeroSeat()
    if seat == heroseat and self._gameBtnNode:isSelected() then
        self:performWithDelayGlobal(function()
            self:sendBetmult(1) 
        end, 1)
    end
end

-- 弃牌
function GamePresenter:onPlayerGiveUp(now, next, round)
    app.game.PlayerData.updatePlayerStatus(now, 5)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(now)
    
    self._gamePlayerNodes[localSeat]:showImgCheck(true, 1)
    self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)   
    self._gamePlayerNodes[localSeat]:playSpeakAction(3) 
    self:showGaryCard(localSeat)
    
    if app.game.PlayerData.getHeroSeat() == now then
        self._gameBtnNode:showBetBtnEnable(false)
    end

    local basebet = app.game.GameData.getBasebet()
    local base = app.game.GameConfig.getBase()
    local index = basebet / base 
    self:onPlayerBet(next, index)
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
    local count = 1
    if isshow then
        playerbet = playerbet / 2
        count = 2
    end             
    local ib = playerbet / base / 2  -- 玩家跟注的筹码index
   
    self:refreshUI()    
    self._ui:getInstance():showChipAction(ib, count, localSeat)
    self:playCompareAction(localSeat, otherSeat, loserSeat)
    
    self._gamePlayerNodes[localSeat]:showTxtBalance(true, data.playerBalance)    
    self._gamePlayerNodes[localSeat]:showImgBet(true,  player:getBet())
    self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
    
    app.game.GameData.setBasebet(data.basebet)
    
    self:onPlayerBet(app.game.GameData.getCurrseat(), ib)   
end 

-- 看牌
function GamePresenter:onPlayerShowCard(seat, cards, cardtype)
    app.game.PlayerData.updatePlayerIsshow(seat, 1) 
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)
           
    if localSeat ~= 1 then
        self._gamePlayerNodes[localSeat]:showImgCheck(true, 0)
    end
    
    if localSeat == 1 then
        self._gamePlayerNodes[localSeat]:showImgCardType(true, cardtype)
    end
    
    if cards then
        local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
        gameHandCardNode:resetHandCards()
        gameHandCardNode:createCards(cards)
    end    
end

-- 押注
function GamePresenter:onPlayerAnteUp(data)  
    print("wwwwssssa", data.playerSeat, data.playerBet)     
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
        
    if playerbet / basebet == 1 then
        self._gamePlayerNodes[localSeat]:playSpeakAction(1)    
    else
        self._gamePlayerNodes[localSeat]:playSpeakAction(2)        
    end
      
    app.game.GameData.setBasebet(data.basebet)
    
    self:onPlayerBet(app.game.GameData.getCurrseat(), ib) 
end

function GamePresenter:onGameOver(data, players)
    local function delay()
        local winseat = data.winnerSeat
        local localSeat = app.game.PlayerData.serverSeatToLocalSeat(winseat)    
        local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()            
        gameHandCardNode:resetHandCards()
        
        print("gameover cards is")
        dump(players[winseat].cards)
      
        gameHandCardNode:createCards(players[winseat].cards)  

        self._gamePlayerNodes[localSeat]:showImgCardType(true, players[winseat].type)          
        self._gamePlayerNodes[localSeat]:showImgCheck(false)
        
        self._ui:getInstance():showChipBackAction({localSeat})

        for seat = 0, self._maxPlayerCnt - 1 do
            if players[seat] then          
                app.game.PlayerData.updatePlayerRiches(seat, 0, players[seat].balance) 

                local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)            
                self._gamePlayerNodes[localSeat]:showWinloseScore(players[seat].score)            
                self._gamePlayerNodes[localSeat]:showTxtBalance(true, players[seat].balance)                                         
            end 
        end

        self._gameBtnNode:showBetBtns(false)
        app.game.GameData.setCurrseat(-1)

        self._ui:getInstance():showPnlHint(1)

        self:performWithDelayGlobal(function()
            self:sendPlayerReady()
        end, 4) 
    end
    
    for seat = 0, self._maxPlayerCnt - 1 do
        if players[seat] then                      
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)                        
            self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)          
        end 
    end
    
    -- 延时结算
    self:performWithDelayGlobal(function()
        delay()
    end, 3) 
    
end

function GamePresenter:test()
    local gameHandCardNode = self._gamePlayerNodes[1]:getGameHandCardNode()            
    gameHandCardNode:resetHandCards()

    gameHandCardNode:createCards({30,43,18}) 
end

function GamePresenter:onRelinkEnter(cards)   
    -- 是否轮到自己
    local seat = app.game.GameData.setCurrseat()
    local heroseat = app.game.PlayerData.getHeroSeat()
    if seat == heroseat then
        local basebet = app.game.GameData.getBasebet()
        local base = app.game.GameConfig.getBase()
        local index = basebet / base 
        self:onPlayerBet(seat, index)
    end
    
    -- 庄家
    local banker = app.game.GameData.getBanker()
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(banker) 
    if self._gamePlayerNodes[localSeat] then
        self._gamePlayerNodes[localSeat]:showImgBanker()                     
    end
    
    local handcards = {
        [0] = {0,0,0},
        [1] = cards,
        [2] = {0,0,0},
        [3] = {0,0,0},
        [4] = {0,0,0},
    }
    for i = 0, self._maxPlayerCnt - 1 do
        local player = app.game.PlayerData.getPlayerByServerSeat(i)
        if player then
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(i)
            local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
            gameHandCardNode:resetHandCards()
            gameHandCardNode:createCards(handcards[localSeat])
            
            self._gamePlayerNodes[localSeat]:showImgBet(true, player:getBet() )
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
    self._ui:getInstance():showLunShu(round)
    
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
            self._gamePlayerNodes[localSeat]:showTxtBalance(true, balance)
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

function GamePresenter:playCompareAction(localSeat, otherSeat, loserSeat)
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
    self._gamePlayerNodes[localSeat]:playPanleAction(0, cc.p(fx, fy), posl, flag)  
    self._gamePlayerNodes[otherSeat]:playPanleAction(1, cc.p(fm, fn), posr, not flag)                 
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
    local function onInterval(dt)
        if cardNum <= CARD_NUM then
            for i = 0, self._maxPlayerCnt - 1 do                
                if self._gamePlayerNodes[i] then
                    self._gamePlayerNodes[i]:onTakeFirst(cardbacks[i][cardNum])                     
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

-- 准备
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
    self._schedulerPrepareClock = scheduler:scheduleScriptFunc(flipIt, 0.1, false)
end 

function GamePresenter:closeSchedulerPrepareClock()
    if self._schedulerPrepareClock then
        scheduler:unscheduleScriptEntry(self._schedulerPrepareClock)
        self._schedulerPrepareClock = nil
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
    self:sendBetmult(1)
end

function GamePresenter:onTouchBtnBetmult(index)
    local mult = 1
    if index < 6 then
        mult = index*2        
    end    
    self:sendBetmult(mult) 
end

function GamePresenter:onEventCbxGendaodi(flag)
	if flag then
        local curseat = app.game.GameData.getCurrseat()
        local heroseat = app.game.PlayerData.getHeroSeat()
        if curseat == heroseat then
            self:sendBetmult(1) 
        end
	end	
end

-------------------------------request-------------------------------
function GamePresenter:sendLeaveRoom()
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
        po:write_int32(sessionid)  
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_LEAVE_ROOM_REQ)
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

function GamePresenter:sendPlayerReady()
	print("auto ready!!!!!")
	local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_int64(sessionid)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_READY_REQ)
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

return GamePresenter