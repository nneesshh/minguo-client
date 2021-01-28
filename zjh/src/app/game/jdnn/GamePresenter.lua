--[[
@brief  游戏主场景控制基类
]]
local app = cc.exports.gEnv.app
local zjh_defs = cc.exports.gEnv.misc_defs.zjh_defs
local requireJDNN = cc.exports.gEnv.HotpatchRequire.requireJDNN

local GamePlayerNode = requireJDNN("app.game.jdnn.GamePlayerNode")
local GameBtnNode    = requireJDNN("app.game.jdnn.GameBtnNode")
local GameMenuNode   = requireJDNN("app.game.jdnn.GameMenuNode")

local GamePresenter  = class("GamePresenter", app.base.BasePresenter)

GamePresenter._ui    = requireJDNN("app.game.jdnn.GameScene")

local scheduler = cc.Director:getInstance():getScheduler()

local GE   = app.game.GameEnum
local GECT = app.game.GameEnum.cardsType
local GEPS = app.game.GameEnum.playerStatus
local ST   = app.game.GameEnum.soundType

local HERO_LOCAL_SEAT   = 1
local CARD_NUM          = 5
local CV_BACK           = 0

local TIME_START_EFFECT = 0
local TIME_MAKE_BANKER  = 1

local SCHEDULE_WAIT_TIME= 0

-- 初始化
function GamePresenter:init(...)
    self._maxPlayerCnt = app.game.PlayerData.getMaxPlayerCount() or 5
    self:createDispatcher()
    self:playGameMusic()  
    self:initPlayerNode()
    self:initBtnNode()
    self:initMenuNode()
    self:initTouch()
    self:initScheduler()  
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

function GamePresenter:initTouch()
    local gameBG = self._ui:getInstance():seekChildByName("background")
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(handler(self, self.onTouchBegin), cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(handler(self, self.onTouchMove), cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(handler(self, self.onTouchEnd), cc.Handler.EVENT_TOUCH_ENDED)

    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, gameBG)
end

function GamePresenter:onTouchBegin(touch, event)  
    self:showJdnnHelp(false)
    
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
    self:closeScheduleSendReady()
    
    app.lobby.notice.BroadCastNode:stopActions()
    
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

    if self._gamePlayerNodes then
        self._gamePlayerNodes[localSeat]:onPlayerEnter() 
    end 

    if app.game.PlayerData.getPlayerCount() <= 1 then
        if not self._ischangeTable then
            self._ui:getInstance():showPnlHint(2)                      
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
                    app.game.PlayerData.updatePlayerStatus(player:getSeat(), 4)             
                end         
            end         
        end    
    end
end

-- 处理玩家坐下
function GamePresenter:onPlayerSitdown(player)     
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(player:getSeat()) 

    if self._gamePlayerNodes then
        self._gamePlayerNodes[localSeat]:onPlayerEnter() 
    end 

    if app.game.PlayerData.getPlayerCount() <= 1 then
        if not self._ischangeTable then
            self._ui:getInstance():showPnlHint(2)                      
        end  
    else
        if not app.game.PlayerData.getHero():isWaiting() then
            self._ui:getInstance():showPnlHint(5)
        end 
    end
end

-- 玩家准备
function GamePresenter:onNiuPlayerReady(seat)
    local localseat = app.game.PlayerData.serverSeatToLocalSeat(seat)
    if localseat == HERO_LOCAL_SEAT then
        app.game.GameData.setReady(true)                  
        self:closeScheduleSendReady()
    end         
end

-- 游戏准备
function GamePresenter:onGamePrepare()    
    app.game.GameData.setTableStatus(zjh_defs.TableStatus.TS_PREPARE)
    
    self._ui:getInstance():showPnlHint(1)

    if not app.game.GameData.getReady() then
        self:sendPlayerReady()
    end
end

-- 开始
function GamePresenter:onGameStart()    
    self._playing = true  
    
    self._ui:getInstance():showPnlHint()
    
    for i = 0, self._maxPlayerCnt - 1 do        
        app.game.PlayerData.updatePlayerStatus(i, 0)
    end
    
    local seats = app.game.GameData.getPlayerseat()   
    for k, i in ipairs(seats) do
        app.game.PlayerData.updatePlayerStatus(i, 3)        
    end
    
    -- 重置数据
    app.game.GameData.restDataEx()
    
    -- 玩家开始
    for i = 0, self._maxPlayerCnt - 1 do
        if self._gamePlayerNodes[i] then
            self._gamePlayerNodes[i]:onGameStart()
            self._gamePlayerNodes[i]:showPlayerInfo()
        end
    end
    
    self:playEffectByName("e_start")
    
    -- 开局动画    
    self:performWithDelayGlobal(
        function()
            for i = 0, self._maxPlayerCnt - 1 do
                if self._gamePlayerNodes[i] then                   
                    self._gamePlayerNodes[i]:showPlayerInfo()
                end
            end
        
            self._ui:getInstance():showStartEffect()
        end, TIME_START_EFFECT)
    
    -- 抢庄加倍
    self:performWithDelayGlobal(
        function()
            self:showTableBtn("banker")
            
            if self._ui:getInstance():isSelected("cbx_banker_test") then
                self:performWithDelayGlobal(function()
                    self:onEventCbxBanker()
                end, 1)
            end
        end, TIME_MAKE_BANKER)  
end

-- 抢庄加倍结束
function GamePresenter:onNiuConfirmBanker(banker, players)
    app.game.GameData.setPbanker(true)
    
    -- 隐藏UI
    self._gameBtnNode:showBankerPanel(false)
    
    -- 设置庄家
    app.game.GameData.setBanker(banker.banker)
          
    local function showchoose(flag)        
        local mult = app.game.GameData.getBankerMult()
        for i, player in ipairs(players) do
            local playerObj = app.game.PlayerData.getPlayerByServerSeat(player.seat)
            if playerObj and player.seat ~= banker.banker and playerObj:isPlaying() then            
                local localseat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)
                self._gamePlayerNodes[localseat]:showImgChoose(flag, mult[player.seat])
            end     
        end
    end
    
    -- 显示其他玩家的选择
    showchoose(true)
    
    -- 与庄家相同倍数的座位 2次
    local sameSeats = {}
    for i=1, 2 do
        for _, player in ipairs(players) do
            if player.mult == banker.bankerMult then
                table.insert(sameSeats, player.seat)
            end
        end
    end
    
    -- 均不枪
    if #sameSeats == 0 then
        for i=1, 2 do
            for _, player in ipairs(players) do
                table.insert(sameSeats, player.seat)
            end
        end
    end
       
    -- 隐藏
    local function callback()
        showchoose(false)
        -- 显示抢庄倍数
        local localbanker = app.game.PlayerData.serverSeatToLocalSeat(banker.banker)
        self._gamePlayerNodes[localbanker]:showImgChoose(true, banker.bankerMult)
        
        local heroseat = app.game.PlayerData.getHeroSeat()
        if heroseat ~= banker.banker then
            self:showTableBtn("bet")

            if self._ui:getInstance():isSelected("cbx_mult_test") then
                self:performWithDelayGlobal(function()
                    self:onEventCbxMult()
                end, 1)
            end
        end    
    end
    
    -- 定庄动画
    self:playBankerAction(sameSeats, banker.banker, callback)       
end

-- 闲家加倍结束
function GamePresenter:onNiuConfirmMult(hero, players)
    app.game.GameData.setPmult(true)
    
    -- 隐藏UI
    self._gameBtnNode:showBetPanel(false)

    -- 设置本家手牌,牌型,牌的倍数
    app.game.GameData.setHeroCards(hero.cards, hero.cardtype, hero.cardmult)
    local banker = app.game.GameData.getBanker()
    for i, player in ipairs(players) do        
        local localseat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)
        local playerObj = app.game.PlayerData.getPlayerByServerSeat(player.seat)
        if player.seat ~= banker and playerObj:isPlaying() then
            self._gamePlayerNodes[localseat]:showImgChoose(true, player.mult)         
        end               
    end
    
    self:onTakeFirst()
end

-- 发牌
function GamePresenter:onTakeFirst() 
    for i = 0, self._maxPlayerCnt - 1 do
        local gameHandCardNode = self._gamePlayerNodes[i]:getGameHandCardNode()
        gameHandCardNode:resetHandCards()  
    end

    local function callback()
        self:showTableBtn("cal")
        
        if self._ui:getInstance():isSelected("cbx_cal_test") then
            self:performWithDelayGlobal(function()
                self:onEventCbxCal()
            end, 1)
        end
        
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
    
    if localseat == HERO_LOCAL_SEAT then
    	app.game.GameData.setPbanker(true)
    end
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
    
    if localseat == HERO_LOCAL_SEAT then
        app.game.GameData.setPmult(true)
    end
end

-- 摊牌
function GamePresenter:onNiuCompareCard(player)
    local localseat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)
    local playerObj = app.game.PlayerData.getPlayerByServerSeat(player.seat)
    
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
    
    -- 牌型音效
    local gender = playerObj:getGender()
    local sound = ""
    if gender == 1 then
        sound = string.format("m_niu_%d", player.cardtype)
    else
        sound = string.format("w_niu_%d", player.cardtype)
    end
    self._gamePlayerNodes[localseat]:playEffectByName(sound)
    
    app.game.GameData.setGroup(player.seat, 1)
    
    if localseat == HERO_LOCAL_SEAT then
        app.game.GameData.setPgroup(true)
    end
end

-- 游戏结束
function GamePresenter:onNiuGameOver(players) 
    self._playing = false
    app.game.GameData.setTableStatus(zjh_defs.TableStatus.TS_ENDING)
    app.game.GameData.setReady(false)
    app.game.GameData.setPgroup(true)
    
    -- 隐藏ui
    self:showTableBtn()
    
    -- 隐藏选择
    for i = 0, 4 do
        self._gamePlayerNodes[i]:showImgChoose(false)    	
    end

    -- 展示手牌 牌型 音效
    self:onShowCard(players)
    
    -- 输赢动画
    self:performWithDelayGlobal(function()
        self:onWinloseEffect(players)
    end, 0.5) 
    
    -- 飞金币   
    self:performWithDelayGlobal(function()
        self:onPlayFlyGoldAction(players) 
    end, 2)    
end

-- 与庄家比找出输赢玩家
function GamePresenter:calWinloseWithBanker(players)    
    local win, lose = {}, {}
    local banker = app.game.GameData.getBanker()
    local localbanker = app.game.PlayerData.serverSeatToLocalSeat(banker)
    local bankerwin = false
    local herowin   = false
    local heroseat = app.game.PlayerData.getHeroSeat()
    for i, player in ipairs(players) do
        if player.seat ~= banker then
            local localseat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)
            if player.score > 0 then 
                table.insert(win, localseat)
            else
                table.insert(lose, localseat)
            end
        else
            bankerwin = player.score >= 0    
        end
        
        if player.seat == heroseat then       
            herowin = player.score >= 0    
        end
    end
    
    return win, lose, bankerwin, herowin 
end

function GamePresenter:onTestShowCard()
    local players = {
        [1] = {
            seat = 0,
            score = 1000,
            cards = {0x01,0x02,0x03,0x04,0x05},
            cardtype = 1,
            balance = 1000
        },
        [2] = {
            seat = 1,
            score = 1000,
            cards = {0x01,0x02,0x03,0x04,0x05},
            cardtype = 1,
            balance = 1000
        },
        [3] = {
            seat = 2,
            score = 1000,
            cards = {0x01,0x02,0x03,0x04,0x05},
            cardtype = 1,
            balance = 1000
        },
        [4] = {
            seat = 3,
            score = 1000,
            cards = {0x01,0x02,0x03,0x04,0x05},
            cardtype = 1,
            balance = 1000
        },
        [5] = {
            seat = 4,
            score = 1000,
            cards = {0x01,0x02,0x03,0x04,0x05},
            cardtype = 1,
            balance = 1000
        }    
    }
    
    for index=0,4 do
    	self._gamePlayerNodes[index]:showPnlPlayer(true)
    end
    
    for i, player in ipairs(players) do
        local gameHandCardNode = self._gamePlayerNodes[player.seat]:getGameHandCardNode()            
        gameHandCardNode:resetHandCards()
        
        if player.seat ~= 1 then
            gameHandCardNode:createCards(player.cards)
        else
            local gameOutCardNode = self._gamePlayerNodes[HERO_LOCAL_SEAT]:getGameOutCardNode()
            gameOutCardNode:resetOutCards()
            gameOutCardNode:createCards(player.cards)    
        end
        self._gamePlayerNodes[player.seat]:showImgCardtype(true, player.cardtype)        
    end
end

-- 展示手牌及牌型
function GamePresenter:onShowCard(players) 
    local group = app.game.GameData.getGroup()      
    for i, player in ipairs(players) do
        local localseat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)
        if self._gamePlayerNodes[localseat] then
            if localseat >= 0 and localseat <= self._maxPlayerCnt-1 then
                local playerObj = app.game.PlayerData.getPlayerByServerSeat(player.seat)
                -- 手牌        
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
                
                -- 牌型音效
                if group[player.seat] == 0 then
                    local gender = playerObj:getGender()
                    local sound = ""
                    if gender == 1 then
                        sound = string.format("m_niu_%d", player.cardtype)
                    else
                        sound = string.format("w_niu_%d", player.cardtype)
                    end
                    
                    self._gamePlayerNodes[localseat]:playEffectByName(sound)	
                end                                
            end
        end        
    end
end

function GamePresenter:onWinloseEffect(players)
    local win, lose, bankerwin, herowin = self:calWinloseWithBanker(players)
    local banker = app.game.GameData.getBanker()
    local localbanker = app.game.PlayerData.serverSeatToLocalSeat(banker)
    
    local maxtype = GECT.NIU_TYPE_NIU_WU
    for i, player in ipairs(players) do
        if player.cardtype > maxtype then
            maxtype = player.cardtype            
    	end    	
    end
    
    local hero = app.game.PlayerData.getHero()
    if hero and hero:isPlaying() then
        --庄家通杀
        if #win == 0 and #players > 2 and bankerwin then
            self._ui:getInstance():showTongShaEffect()
            -- 特殊牌型 
        elseif maxtype >= GECT.NIU_TYPE_BOMB and maxtype <= GECT.NIU_TYPE_FIVE_LITTLE then
            self._ui:getInstance():showSpecialNiuType(maxtype)
            -- 普通牌型
        else             
            self._ui:getInstance():showWinloseEffect(herowin)    
        end 
    end
end

-- 飞金币
function GamePresenter:onPlayFlyGoldAction(players)
    local win, lose, bankerwin, herowin = self:calWinloseWithBanker(players)
    local banker = app.game.GameData.getBanker()
    local localbanker = app.game.PlayerData.serverSeatToLocalSeat(banker) 
    
    -- 结算
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
	
    losefly()
end

-- 结算
function GamePresenter:onResult(players)
    print("enter onrseult")
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

    -- 将正在游戏的玩家状态设为默认
    for i = 0, self._maxPlayerCnt - 1 do 
        local player = app.game.PlayerData.getPlayerByServerSeat(i)
        if player and player:isPlaying() then
            app.game.PlayerData.updatePlayerStatus(i, 0) 
        end              
    end    
    
    -- 自动准备
    self:performWithDelayGlobal(function()
        print("send ready 5")
        
        self:sendPlayerReady()
    end, 3) 
end

-- 断线重连
function GamePresenter:onRelinkEnter(data) 
    self._playing = true
    print("relink")
    -- 展示玩家信息
    for i = 0, self._maxPlayerCnt - 1 do
        if self._gamePlayerNodes[i] then            
            self._gamePlayerNodes[i]:showPlayerInfo()
        end
    end
    
    if data.cards[1] ~= CV_BACK then
        app.game.GameData.setHeroCards(data.cards, data.cardtype, 1)
    end

    -- 庄家
    local banker = app.game.GameData.getBanker()
    local heroseat = app.game.PlayerData.getHeroSeat()
    local localBanker = app.game.PlayerData.serverSeatToLocalSeat(banker) 
    if localBanker >= 0 and localBanker <= 4 and self._gamePlayerNodes[localBanker] then
        self._gamePlayerNodes[localBanker]:showImgBanker(true)                     
    end 
    
    -- 游戏流程    
    for i = 0, self._maxPlayerCnt - 1 do
        local player = app.game.PlayerData.getPlayerByServerSeat(i)
        if player and player:isPlaying() then
            local localseat = app.game.PlayerData.serverSeatToLocalSeat(i) 
            local bankermult = player:getBankerMult()
            local mult = player:getMult()
            local bet = player:getBet()
            
            if i == heroseat then
                print("relink self", bankermult, mult, bet)
            end
                        
            -- 抢庄倍数
            if i == banker and bankermult >= 0 then
                self._gamePlayerNodes[localseat]:showImgChoose(true, bankermult)    
            -- 闲家倍数    
            elseif i ~= banker and mult >= 0 then 
                self._gamePlayerNodes[localseat]:showImgChoose(true, mult)    
        	end
        	        
            if i == heroseat then
                -- 抢庄
                if bankermult < 0 then
                    self:showTableBtn("banker")
                -- 闲家加倍
                elseif bankermult >= 0 and mult < 0 then
                    app.game.GameData.setPbanker(true)
                    -- 自己是庄家
                    if heroseat == banker then
                        self:showTableBtn()
                    else
                    -- 自己是闲家
                        self:showTableBtn("bet")
                    end
                -- 算牌    
                elseif bankermult >= 0 and mult >= 0 then 
                    app.game.GameData.setPbanker(true)
                    app.game.GameData.setPmult(true) 
                    -- 已摊牌   
                    if bet == 1 then                    
                        app.game.GameData.setPgroup(true)
                        
                        self:showTableBtn()
                        
                        if data.cards[1] ~= CV_BACK then
                            local gameOutCardNode = self._gamePlayerNodes[HERO_LOCAL_SEAT]:getGameOutCardNode()
                            gameOutCardNode:resetOutCards()
                            gameOutCardNode:createCards(data.cards)

                            self._gamePlayerNodes[HERO_LOCAL_SEAT]:showImgCardtype(true, data.cardtype)
                        end                                            
                    -- 未摊牌    
                    else
                        self:showTableBtn("cal")
                        
                        if data.cards[1] ~= CV_BACK then
                            local gameHandCardNode = self._gamePlayerNodes[localseat]:getGameHandCardNode()
                            gameHandCardNode:resetHandCards()
                            gameHandCardNode:createCards(data.cards)  
                        end
                    end                   	
                end
            else
                if bankermult >= 0 and mult >= 0 then
                    local gameHandCardNode = self._gamePlayerNodes[localseat]:getGameHandCardNode()
                    gameHandCardNode:resetHandCards()
                    gameHandCardNode:createCards({CV_BACK, CV_BACK, CV_BACK, CV_BACK, CV_BACK})
                end                
            end
        end
    end
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
    local niuCards, numCards = self:divideCards(data.handcards, data.cardtype)
    local strNiu = string.char(unpack(niuCards))
    local strNum = string.char(unpack(numCards))     
    self:sendCalCard(strNiu, strNum)         
end

function GamePresenter:onEventCbxBanker()
    local hero = app.game.PlayerData.getHero()
    if hero and hero:isPlaying() then
        self:sendBankerMult(1)
    end
end

function GamePresenter:onEventCbxMult()
    local hero = app.game.PlayerData.getHero()
    if hero and hero:isPlaying() then
        self:sendMult(5)
    end
end

function GamePresenter:onEventCbxCal()
    local hero = app.game.PlayerData.getHero()
    if hero and hero:isPlaying() then
        local data = app.game.GameData.getHeroCards()
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

function GamePresenter:playBankerAction(sameSeats, banker, callback)
    local actiontime = 2
    -- 单人1次播放动画时长
    local pertime = actiontime / #sameSeats / 2
    
    local function call()
        local localBanker = app.game.PlayerData.serverSeatToLocalSeat(banker)
        self._gamePlayerNodes[localBanker]:playBankAction(callback)  
        self._gamePlayerNodes[localBanker]:playEffectByName("banker")  
    end   
    
    for i, seat in ipairs(sameSeats) do
        if i <= #sameSeats / 2 then
            local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)
            self._gamePlayerNodes[localSeat]:resetLightOpacity()
        end
    end 
     
    for i, seat in ipairs(sameSeats) do
        local localSeat = app.game.PlayerData.serverSeatToLocalSeat(seat)
        self:performWithDelayGlobal(function()
            if i == #sameSeats then
                self._gamePlayerNodes[localSeat]:playLightAction(pertime, call) 
            else
                self._gamePlayerNodes[localSeat]:playLightAction(pertime) 
            end
            
        end, (i-1)*pertime)
    end
     
end

function GamePresenter:showJdnnHelp(flag)
    self._ui:getInstance():showJdnnHelp(flag)
end


-- -----------------------------schedule------------------------------
-- 准备倒计时
function GamePresenter:openSchedulerPrepareClock(time)
    local allTime = time
    local first,second,third = false,false,false
    local function flipIt(dt)
        time = time - dt
        if time <= 0 then
            self._ui:getInstance():showPnlHint()
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
        self._gameBtnNode:showCalTime(strTime, time)
    end

    self:closeSchedulerCalClock()
    self._gameBtnNode:showCalTime(time, time)
    self._schedulerCalClock = scheduler:scheduleScriptFunc(flipIt, 0.1, false)
end

function GamePresenter:closeSchedulerCalClock()
    if self._schedulerCalClock then
        scheduler:unscheduleScriptEntry(self._schedulerCalClock)
        self._schedulerCalClock = nil
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
local HAND_CARD_DISTANCE_OTHER = 30
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
local OUT_CARD_DISTANCE = 30
function GamePresenter:calOutCardPosition(index, cardSize, localSeat)
    local gameOutCardNode = self._gamePlayerNodes[localSeat]:getGameOutCardNode()
    local count = gameOutCardNode:getOutCardCount()

    local posX, posY = 0, 0
    index = index - 1
    
    local width = OUT_CARD_DISTANCE 
    local handCardsLength = (count - 1) * width + cardSize.width
    posX = posX + index * width - handCardsLength / 2 + width / 2

    return cc.p(posX, posY)
end

-- ----------------------------request-------------------------------
-- 退出房间
function GamePresenter:sendLeaveRoom()
    local gameStream = app.connMgr.getGameStream()

    local heroseat = app.game.PlayerData.getHeroSeat()
    local player = app.game.PlayerData.getPlayerByServerSeat(heroseat)    
    if player:isPlaying() then
        self:dealTxtHintStart("游戏中,暂无法离开！")            
    else
        local po = gameStream:get_packet_obj()
        if po ~= nil then
            local sessionid = app.data.UserData.getSession() or 222
            po:writer_reset()
            po:write_int32(sessionid)  
            gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_LEAVE_ROOM_REQ)
        end     
    end
end

-- 准备
function GamePresenter:sendPlayerReady()
    local gameStream = app.connMgr.getGameStream()

    if not app.game.GamePresenter then
        print("not in game")
        return
    end
    
    if app.game.GameData.getReady() then
        print("have ready")
        return
    end
    
    local hero = app.game.PlayerData.getHero()   
    local po = gameStream:get_packet_obj()
    local limit = app.game.GameConfig.getLimit()
    if hero and not hero:isLeave() and hero:getBalance() > limit and po then        
        print("send ready", hero:getSeat())
        local sessionid = app.data.UserData.getSession() or 222        
        po:writer_reset()
        po:write_int64(sessionid)
        gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_READY_REQ)
    end    
end

-- 换桌
function GamePresenter:sendChangeTable()
    local gameStream = app.connMgr.getGameStream()

    local heroseat = app.game.PlayerData.getHeroSeat()
    local player = app.game.PlayerData.getPlayerByServerSeat(heroseat)    
    if player:isPlaying() then
        self:dealTxtHintStart("游戏中,暂无法换桌！")            
    else
        local sessionid = app.data.UserData.getSession() or 222
        local po = gameStream:get_packet_obj()
        po:writer_reset()
        po:write_int64(sessionid)
        gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_CHANGE_TABLE_REQ)
    end    
end

-- 抢庄倍数
function GamePresenter:sendBankerMult(index)
    local gameStream = app.connMgr.getGameStream()

    if app.game.GameData.getPbanker() then
    	print("send banker too much return")
    	return
    end
    print("banker mult index",index)
    local sessionid = app.data.UserData.getSession() or 222
    local po = gameStream:get_packet_obj()
    po:writer_reset()
    po:write_int32(index)
    gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_BANKER_BID_REQ)
end

-- 押注倍数
function GamePresenter:sendMult(index)
    local gameStream = app.connMgr.getGameStream()

    if not app.game.GameData.getPbanker() or app.game.GameData.getPmult() then
        print("send mult too much or no banker")
        return
    end
    local sessionid = app.data.UserData.getSession() or 222
    local po = gameStream:get_packet_obj()
    po:writer_reset()
    po:write_int32(index)
    gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_COMPARE_BID_REQ)  
end

-- 组牌
function GamePresenter:sendCalCard(niuCards, numCards)
    local gameStream = app.connMgr.getGameStream()

    if not app.game.GameData.getPbanker() or not app.game.GameData.getPmult() or app.game.GameData.getPgroup() then
        print("send cal too much return or no banker or no mult")
        return
    end
      
    local sessionid = app.data.UserData.getSession() or 222
    local po = gameStream:get_packet_obj()
    po:writer_reset()
    po:write_string(niuCards)
    po:write_string(numCards)
    gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_COMPARE_CARD_REQ)   
end

-- 音效相关
function GamePresenter:playGameMusic()
    app.util.SoundUtils.playMusic("game/jdnn/sound/bgm_game.mp3")
end

function GamePresenter:playCountDownEffect()
    app.util.SoundUtils.playEffect("game/jdnn/sound/countdown.mp3")   
end

function GamePresenter:playEffectByName(name)
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

return GamePresenter