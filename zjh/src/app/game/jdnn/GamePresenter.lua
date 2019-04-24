--[[
@brief  游戏主场景控制基类
]]

local GamePlayerNode = require("app.game.jdnn.GamePlayerNode")
local GameBtnNode    = require("app.game.jdnn.GameBtnNode")
local GameMenuNode   = require("app.game.jdnn.GameMenuNode")

local GamePresenter  = class("GamePresenter", app.base.BasePresenter)

GamePresenter._ui    = require("app.game.jdnn.GameScene")

local scheduler = cc.Director:getInstance():getScheduler()

local GE   = app.game.GameEnum
local GECT = app.game.GameEnum.cardsType
local GEPS = app.game.GameEnum.playerStatus

local HERO_LOCAL_SEAT   = 1
local CARD_NUM          = 5
local CV_BACK           = 0

local TIME_START_EFFECT = 0
local TIME_MAKE_BANKER  = 1

local SCHEDULE_WAIT_TIME= 0

-- 初始化
function GamePresenter:init(...)
    self._maxPlayerCnt = app.game.PlayerData.getMaxPlayerCount()
    --self:playGameMusic()  
    self:initPlayerNode()
    self:initBtnNode()
    self:initMenuNode()
    self:initTouch()
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

function GamePresenter:initTouch()
    local gameBG = self._ui:getInstance():seekChildByName("background")
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(handler(self, self.onTouchBegin), cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(handler(self, self.onTouchMove), cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(handler(self, self.onTouchEnd), cc.Handler.EVENT_TOUCH_ENDED)

    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, gameBG)
end

function GamePresenter:onTouchBegin(touch, event)  
    local gameHandCardNode = self._gamePlayerNodes[HERO_LOCAL_SEAT]:getGameHandCardNode()
    return gameHandCardNode:onTouchBegin(touch, event)
end

function GamePresenter:onTouchMove(touch, event)
    local gameHandCardNode = self._gamePlayerNodes[HERO_LOCAL_SEAT]:getGameHandCardNode()
    gameHandCardNode:onTouchMove(touch, event)
end

function GamePresenter:onTouchEnd(touch, event)
    local gameHandCardNode = self._gamePlayerNodes[HERO_LOCAL_SEAT]:getGameHandCardNode()
    gameHandCardNode:onTouchEnd(touch, event)
end

function GamePresenter:initScheduler()      
    self._schedulerTakeFirst    = nil     -- 发牌    
    self._schedulerPrepareClock = nil     -- 倒计时
    self._schedulerAutoReady    = nil     -- 自动准备  
    self._schedulerRunLoading   = nil     -- 等待...
    self._schedulerBankerClock  = nil
    self._schedulerBetClock     = nil
    self._schedulerCalClock     = nil
end

-- 退出界面
function GamePresenter:exit()
    GamePresenter.super.exit(self)
    
    self:closeSchedulerTakeFirst()
    self:closeSchedulerPrepareClock()
    self:closeSchedulerRunLoading()
    self:closeSchedulerBankerClock()
    self:closeSchedulerBetClock()
    self:closeSchedulerCalClock()
    
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

function GamePresenter:onLeaveRoom()
    app.game.GameEngine:getInstance():exit()
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
                        self._ui:getInstance():showPnlHint(2)
                        self._gamePlayerNodes[HERO_LOCAL_SEAT]:onResetTable()
                    end, 5)
            end
        end
    end
end

-- 处理玩家进入
function GamePresenter:onPlayerEnter(player)     
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(player:getSeat()) 

    if self._gamePlayerNodes then
        self._gamePlayerNodes[localSeat]:onPlayerEnter() 
    end 

    if app.game.PlayerData.getPlayerCount() <= 1 then
        if not self._ischangeTable  then
            self._ui:getInstance():showPnlHint(2)
        end    
    end

    local seats = app.game.GameData.getPlayerseat()
    if #seats ~= 0 then
        local isIn = false
        for i, seat in ipairs(seats) do
            if player:getSeat() == seat then
                isIn = true
            end
        end
        if not isIn then
            if localSeat == 1 then
                self._ui:getInstance():showPnlHint(4)                 
            end
            app.game.PlayerData.updatePlayerStatus(player:getSeat(), 4)
        end         
    end
end

-- 游戏准备
function GamePresenter:onGamePrepare()
    self._ui:getInstance():showPnlHint(1)
end

-- 开始
function GamePresenter:onGameStart()      
    self._ui:getInstance():showPnlHint()
    
    for i = 0, self._maxPlayerCnt - 1 do        
        app.game.PlayerData.updatePlayerStatus(i, 0)
    end
    
    local seats = app.game.GameData.getPlayerseat()  
    dump(seats) 
    for k, i in ipairs(seats) do
        app.game.PlayerData.updatePlayerStatus(i, 3)        
    end
    
    -- 重置数据
    app.game.GameData.restDataEx()
    
    -- 玩家开始
    for i = 0, self._maxPlayerCnt - 1 do
        if self._gamePlayerNodes[i] then
            self._gamePlayerNodes[i]:onGameStart()
        end
    end
    
    -- 开局动画    
    self:performWithDelayGlobal(
        function()
            self._ui:getInstance():showStartEffect()
        end, TIME_START_EFFECT)
    
    -- 抢庄加倍
    self:performWithDelayGlobal(
        function()
            self:showTableBtn("banker")
        end, TIME_MAKE_BANKER)  
end

-- 抢庄加倍结束
function GamePresenter:onNiuConfirmBanker(banker, players)
    -- 隐藏UI
    self._gameBtnNode:showBankerPanel(false)
    
    -- 设置庄家
    app.game.GameData.setBanker(banker.banker)
    
    -- 显示抢庄倍数
    local localbanker = app.game.PlayerData.serverSeatToLocalSeat(banker.banker)
    self._gamePlayerNodes[localbanker]:showImgChoose(true, banker.bankerMult)
    
    local function showchoose(flag)
        local mult = app.game.GameData.getBankerMult()
        for i, player in ipairs(players) do
            local playerObj = app.game.PlayerData.getPlayerByServerSeat(player.seat)
            if player.seat ~= banker.banker and playerObj:isPlaying() then            
                local localseat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)
                self._gamePlayerNodes[localseat]:showImgChoose(flag, mult[player.seat])
            end     
        end
    end
    -- 显示其他玩家的选择
    showchoose(true)
    
    -- 隐藏
    local function hide()
        showchoose(false)
    end
    
    self:playBankerAction(hide)
    
    local heroseat = app.game.PlayerData.getHeroSeat()
    if heroseat ~= banker.banker then
        self:showTableBtn("bet")
    end    
end

-- 闲家加倍结束
function GamePresenter:onNiuConfirmMult(hero, players)
    -- 隐藏UI
    self._gameBtnNode:showBetPanel(false)

    -- 设置本家手牌,牌型,牌的倍数
    app.game.GameData.setHeroCards(hero.cards, hero.cardtype, hero.cardmult)
    local banker = app.game.GameData.getBanker()
    for i, player in ipairs(players) do        
        local localseat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)
        if player.seat ~= banker then
            self._gamePlayerNodes[localseat]:showImgChoose(true, player.mult)         
        end               
    end
    
    self:onTakeFirst()
end

-- 发牌
function GamePresenter:onTakeFirst() 
    local function callback()
        self:showTableBtn("cal")
    end      
    self:openSchedulerTakeFirst(callback)
end

-- 抢庄加倍
function GamePresenter:onNiuBankerBid(seat, mult)
    local localseat = app.game.PlayerData.serverSeatToLocalSeat(seat)
    if self._gamePlayerNodes[localseat] then
        self._gamePlayerNodes[localseat]:showImgChoose(true, mult)
        if localseat == HERO_LOCAL_SEAT then
            self._gameBtnNode:showBankerPanel(false)
        end
    end
    app.game.GameData.setBankerMult(seat, mult)
end

-- 闲家加倍
function GamePresenter:onNiuCompareBid(seat, mult)
    local localseat = app.game.PlayerData.serverSeatToLocalSeat(seat)
    if self._gamePlayerNodes[localseat] then
        self._gamePlayerNodes[localseat]:showImgChoose(true, mult)
        if localseat == HERO_LOCAL_SEAT then
            self._gameBtnNode:showBetPanel(false)
        end
    end
end

-- 摊牌
function GamePresenter:onNiuCompareCard(player)
    local localseat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)
    
    if localseat == HERO_LOCAL_SEAT then
        self._gameBtnNode:showCalPanel(false)
    end
    
    local niu, num = self:divideCards(player.cards, player.cardtype)
    for k, v in ipairs(num) do
    	niu[#niu+k] = v
    end
    
    local gameHandCardNode = self._gamePlayerNodes[localseat]:getGameHandCardNode()
    gameHandCardNode:resetHandCards()     
    if localseat ~= HERO_LOCAL_SEAT then                   
        gameHandCardNode:createCards(niu)
    else            
        local gameOutCardNode = self._gamePlayerNodes[HERO_LOCAL_SEAT]:getGameOutCardNode()
        gameOutCardNode:resetOutCards()
        gameOutCardNode:createCards(niu)
    end
    
    self._gamePlayerNodes[localseat]:showImgCardtype(true, player.cardtype)
end

-- 游戏结束
function GamePresenter:onNiuGameOver(players) 
    -- 隐藏ui
    self:showTableBtn()
    
    -- 隐藏选择
    for i = 0, 4 do
        self._gamePlayerNodes[i]:showImgChoose(false)    	
    end
    
    -- 展示手牌及牌型
    self:onShowCard(players)

    -- 找出输赢玩家
    local win, lose = {}, {}
    local banker = app.game.GameData.getBanker()
    local localbanker = app.game.PlayerData.serverSeatToLocalSeat(banker)
    for i, player in ipairs(players) do
        if player.seat ~= banker then
            local localseat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)
            if player.score > 0 then 
                table.insert(win, localseat)
            else
                table.insert(lose, localseat)
            end 
        end
    end
    
    local function result()        
        self:onResult(players)
    end
    
    -- 庄家往赢家飞金币
    local function winfly()
        if #win > 0 then           
            for i, localseat in ipairs(win) do
                if i == #win then                    
                    self._ui:getInstance():playFlyGoldAction(localbanker, localseat, result)
                else
                    self._ui:getInstance():playFlyGoldAction(localbanker, localseat)
                end
            end
        else
             result()  
        end        
    end
    
    -- 输家往庄家飞金币
    local function losefly()
        if #lose > 0 then            
            for i, localseat in ipairs(lose) do
                if i == #lose then                    
                    self._ui:getInstance():playFlyGoldAction(localseat, localbanker, winfly)
                else
                    self._ui:getInstance():playFlyGoldAction(localseat, localbanker)
                end
            end
        else            
            winfly()
        end        
    end

    -- 飞金币
    self:performWithDelayGlobal(function()
        losefly() 
    end, 0.5)      
end

-- 展示手牌及牌型
function GamePresenter:onShowCard(players)    
    for i, player in ipairs(players) do
        local localseat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)
        if self._gamePlayerNodes[localseat] then
            if localseat >= 0 and localseat <= self._maxPlayerCnt-1 then
                local gameHandCardNode = self._gamePlayerNodes[localseat]:getGameHandCardNode()            
                gameHandCardNode:resetHandCards()

                local niu, num = self:divideCards(player.cards, player.cardtype)
                for k, v in ipairs(num) do
                    niu[#niu+k] = v
                end

                if localseat ~= HERO_LOCAL_SEAT then
                    gameHandCardNode:createCards(niu)
                else
                    local gameOutCardNode = self._gamePlayerNodes[HERO_LOCAL_SEAT]:getGameOutCardNode()
                    gameOutCardNode:resetOutCards()
                    gameOutCardNode:createCards(niu)    
                end
                self._gamePlayerNodes[localseat]:showImgCardtype(true, player.cardtype)
            end
        end        
    end
end

-- 结算
function GamePresenter:onResult(players)
    for i, player in ipairs(players) do
        local localseat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)
        if self._gamePlayerNodes[localseat] then
            if localseat >= 0 and localseat <= self._maxPlayerCnt-1 then
                app.game.PlayerData.updatePlayerRiches(player.seat, 0, player.balance)

                self._gamePlayerNodes[localseat]:showWinloseScore(player.score)            
                self._gamePlayerNodes[localseat]:showTxtBalance(true, player.balance) 
            end
        end        
    end

    -- 当前玩家状态设为默认
    for i = 0, self._maxPlayerCnt - 1 do        
        app.game.PlayerData.updatePlayerStatus(i, 0)       
    end 
    
    -- 自动准备
    self:performWithDelayGlobal(function()
        self:sendPlayerReady()
    end, 3) 
end

-- 断线重连
function GamePresenter:onRelinkEnter()   
    
end

-- 换桌成功
function GamePresenter:onChangeTable(flag)
    self._ischangeTable = true    
    self._ui:getInstance():showPnlHint(3)
    self:performWithDelayGlobal(
        function()
            if app.game.PlayerData.getPlayerCount() <= 1 then
                self._ischangeTable = false  
                self._ui:getInstance():showPnlHint(2)
            end
        end, 2)
end

-- ----------------------------onclick-------------------------------
function GamePresenter:onTouchBankerMult(index)
    self:sendBankerMult(index)
end

function GamePresenter:onTouchMult(index)
    self:sendMult(index)
end

function GamePresenter:onTouchCalCard()   
    local data = app.game.GameData.getHeroCards()
    if #data.handcards == 5 then
        local niuCards, numCards = self:divideCards(data.handcards, data.cardtype)
        local strNiu = string.char(unpack(niuCards))
        local strNum = string.char(unpack(numCards))     
        self:sendCalCard(strNiu, strNum)
    end        
end

-- ------------------------------show ui------------------------------
function GamePresenter:showTableBtn(type)
    local hero = app.game.PlayerData.getHero()
    if hero and hero:isPlaying() then
        self._gameBtnNode:showTableBtn(type)
    end
end

function GamePresenter:resetCalculatorNums()
    for i=1, 4 do        
        self._gameBtnNode:showCalNum(i, " ")
    end
end

function GamePresenter:onClickCard(index)
    local upCards = self:getUpHandCards()
    if #upCards > 3 then
        return
    end

    local cnt = 0    

    for i=1,#upCards do
        local point = self:getCardNum(upCards[i])
        if point >= 10 then point = 10 end
        cnt = cnt + point
        self._gameBtnNode:showCalNum(i, tostring(point))
    end

    for i=#upCards+1,3 do
        self._gameBtnNode:showCalNum(i, "")
    end
    
    if #upCards == 0 then
        self._gameBtnNode:showCalNum(4, "")
    else
        self._gameBtnNode:showCalNum(4, tostring(cnt))    
    end    
end

function GamePresenter:getUpHandCards()
    local gameHandCardNode = self._gamePlayerNodes[HERO_LOCAL_SEAT]:getGameHandCardNode()
    return gameHandCardNode:getUpHandCards()
end

function GamePresenter:downAllHandCards()
    local gameHandCardNode = self._gamePlayerNodes[HERO_LOCAL_SEAT]:getGameHandCardNode()
    return gameHandCardNode:downAllHandCards()
end

function GamePresenter:playBankerAction(callback)
    local banker = app.game.GameData.getBanker()
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(banker)
    self._gamePlayerNodes[localSeat]:playBankAction(callback)    
end

-- -----------------------------schedule------------------------------
-- 准备倒计时
function GamePresenter:openSchedulerPrepareClock(time)
    local allTime = time

    local function flipIt(dt)
        time = time - dt

        if time <= 0 then
            self._ui:getInstance():showPnlHint()
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

-- 等待
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

-- 发牌
function GamePresenter:openSchedulerTakeFirst(callback)
    print("on take first")
    local cardbacks = {}             
    for i = 0, self._maxPlayerCnt - 1 do
        cardbacks[i] = cardbacks[i] or {}  
        for j=1, CARD_NUM do
            cardbacks[i][j] = CV_BACK
        end
    end
        
    local cards = app.game.GameData.getHeroCards()
    local herocards = cards.handcards
    cardbacks[HERO_LOCAL_SEAT] = herocards

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

-- 抢庄时钟
function GamePresenter:openSchedulerBankerClock(time)
    local function flipIt(dt)
        time = time - dt
        
        if time <= 0 then
            self._gameBtnNode:showBankerPanel(false)
        end
        local strTime = string.format("%d", math.ceil(time))
        self._gameBtnNode:showBankerTime(strTime)
    end

    self:closeSchedulerBankerClock()
    self._schedulerBankerClock = scheduler:scheduleScriptFunc(flipIt, 0.1, false)
end

function GamePresenter:closeSchedulerBankerClock()
    if self._schedulerBankerClock then
        scheduler:unscheduleScriptEntry(self._schedulerBankerClock)
        self._schedulerBankerClock = nil
    end
end

-- 下注时钟
function GamePresenter:openSchedulerBetClock(time)
    local function flipIt(dt)
        time = time - dt

        if time <= 0 then
            self._gameBtnNode:showBetPanel(false)
        end
        local strTime = string.format("%d", math.ceil(time))
        self._gameBtnNode:showBetTime(strTime)
    end

    self:closeSchedulerBetClock()
    self._schedulerBetClock = scheduler:scheduleScriptFunc(flipIt, 0.1, false)
end

function GamePresenter:closeSchedulerBetClock()
    if self._schedulerBetClock then
        scheduler:unscheduleScriptEntry(self._schedulerBetClock)
        self._schedulerBetClock = nil
    end
end

-- 组牌时钟
function GamePresenter:openSchedulerCalClock(time)
    local function flipIt(dt)
        time = time - dt

        if time <= 0 then
            self._gameBtnNode:showCalPanel(false)
        end
        local strTime = string.format("%d", math.ceil(time))
        self._gameBtnNode:showCalTime(strTime)
    end

    self:closeSchedulerCalClock()
    self._schedulerCalClock = scheduler:scheduleScriptFunc(flipIt, 0.1, false)
end

function GamePresenter:closeSchedulerCalClock()
    if self._schedulerCalClock then
        scheduler:unscheduleScriptEntry(self._schedulerCalClock)
        self._schedulerCalClock = nil
    end
end

-- ---------------------------rule-----------------------------
-- 根据牌型对手牌分组
function GamePresenter:divideCards(cards, cardtype)
    local niuTab = {}
    local numTab = {}
    -- 炸弹牛
    if cardtype == GECT.NIU_TYPE_BOMB then
        local temp_num = 0 
        for i, a in ipairs(cards) do
            local a_num = self:getCardNiuNum(a)
            for j, b in ipairs(cards) do
                local b_num = self:getCardNiuNum(b)      
                if i ~= j and a_num == b_num then
                    temp_num = a_num
            		break
            	end
            end
        end        
        for i, card in ipairs(cards) do
            local c_num = self:getCardNiuNum(card)
            if c_num == temp_num and #niuTab < 3 then
                table.insert(niuTab, card)
            else
                table.insert(numTab, card)   
            end               
        end
    -- 没牛-牛牛
    elseif cardtype > GECT.NIU_TYPE_NIU_WU and cardtype <= GECT.NIU_TYPE_NIU_NIU then    
        for i, a in ipairs(cards) do
            local a_num = self:getCardNiuNum(a)
            for j, b in ipairs(cards) do
                local b_num = self:getCardNiuNum(b)                
                if i ~= j and (a_num + b_num) % 10 == (cardtype % 10) and #numTab == 0 then                
                    table.insert(numTab, a)
                    table.insert(numTab, b)
                    break   
                end
            end
        end
        for i, card in ipairs(cards) do
            if card ~= numTab[1] and card ~= numTab[2] then
                table.insert(niuTab, card)                
            end
        end        
    else 
        for i, card in ipairs(cards) do
            if i <= 3 then
                table.insert(niuTab, card)     
            else
                table.insert(numTab, card)  
            end
        end
    end
    
    return niuTab, numTab
end

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

function GamePresenter:getCardNiuNum(id)
    local num = self:getCardNum(id)
    if num >= 10 then
    	num = 10
    end
    return num   
end

-- 计算手牌位置
local SELECT_Y = 15
local HAND_CARD_DISTANCE_OTHER = 25
function GamePresenter:calHandCardPosition(index, cardSize, localSeat, bUp)
    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
    local count = gameHandCardNode:getHandCardCount()

    local screenSize = cc.Director:getInstance():getWinSize()
    local posX = 0
    local posY = 0

    index = index - 1
    if localSeat == HERO_LOCAL_SEAT then
        local width = (screenSize.width - 200 - cardSize.width) / (count - 1) 
            
        if width > cardSize.width then
            width = cardSize.width + 5
        end

        local handCardsLength = (count - 1) * width + cardSize.width
        posX = posX + index * width - handCardsLength / 2
        posY = posY - 40
        if bUp then
            posY = posY + SELECT_Y
        end
    elseif localSeat == HERO_LOCAL_SEAT + 1 then
        local WIDTH = HAND_CARD_DISTANCE_OTHER        
        local handCardsLength = 0--(count - 1) * WIDTH + cardSize.width
        posX = posX + index * WIDTH - handCardsLength   
    else 
        local WIDTH = HAND_CARD_DISTANCE_OTHER
        posX = posX + index * WIDTH
    end

    return cc.p(posX, posY)
end

-- 计算出牌位置
local OUT_CARD_DISTANCE = 25
function GamePresenter:calOutCardPosition(index, cardSize, localSeat)
    local gameOutCardNode = self._gamePlayerNodes[localSeat]:getGameOutCardNode()
    local count = gameOutCardNode:getOutCardCount()

    local posX, posY = 0, 0

    local WIDTH = OUT_CARD_DISTANCE 
    local handCardsLength = (count - 1) * WIDTH + cardSize.width
    posX = posX + index * WIDTH - handCardsLength / 2

    return cc.p(posX, posY)
end

-- ----------------------------request-------------------------------
-- 退出房间
function GamePresenter:sendLeaveRoom()
    local heroseat = app.game.PlayerData.getHeroSeat()
    local player = app.game.PlayerData.getPlayerByServerSeat(heroseat)    
    if player:isPlaying() then
        self:dealHintStart("游戏中,暂无法离开！")            
    else
        local po = upconn.upconn:get_packet_obj()
        if po ~= nil then
            local sessionid = app.data.UserData.getSession() or 222
            po:writer_reset()
            po:write_int32(sessionid)  
            upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_LEAVE_ROOM_REQ)
        end     
    end
end

-- 准备
function GamePresenter:sendPlayerReady()
    local hero = app.game.PlayerData.getHero()   
    if hero then       
        print("hero is leave", hero:isLeave())
    end 
    local limit = app.game.GameConfig.getLimit()
    if hero and not hero:isLeave() and hero:getBalance() > limit then        
        print("send ready", hero:getSeat())
        local sessionid = app.data.UserData.getSession() or 222
        local po = upconn.upconn:get_packet_obj()
        po:writer_reset()
        po:write_int64(sessionid)
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_READY_REQ)
    end    
end

-- 换桌
function GamePresenter:sendChangeTable()
    local heroseat = app.game.PlayerData.getHeroSeat()
    local player = app.game.PlayerData.getPlayerByServerSeat(heroseat)    
    if player:isPlaying() then
        self:dealHintStart("游戏中,暂无法换桌！")            
    else
        local sessionid = app.data.UserData.getSession() or 222
        local po = upconn.upconn:get_packet_obj()
        po:writer_reset()
        po:write_int64(sessionid)
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_CHANGE_TABLE_REQ)
    end    
end

-- 抢庄倍数
function GamePresenter:sendBankerMult(index)
    print("banker mult index",index)
    local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_int32(index)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_BANKER_BID_REQ)
end

-- 押注倍数
function GamePresenter:sendMult(index)
    print("mult index",index)
    local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_int32(index)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_COMPARE_BID_REQ)  
end

-- 组牌
function GamePresenter:sendCalCard(niuCards, numCards)    
    local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_string(niuCards)
    po:write_string(numCards)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_COMPARE_CARD_REQ)   
end

return GamePresenter