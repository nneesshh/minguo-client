--[[
@brief  游戏主场景控制基类
]]--

local GamePlayerNode   = requireDDZ("app.game.ddz.GamePlayerNode")
local GameBtnNode      = requireDDZ("app.game.ddz.GameBtnNode")
local GameMenuNode     = requireDDZ("app.game.ddz.GameMenuNode")
local GameBankCardNode = requireDDZ("app.game.ddz.GameBankCardNode")

local GamePresenter  = class("GamePresenter", app.base.BasePresenter)

GamePresenter._ui    = requireDDZ("app.game.ddz.GameScene")

local scheduler = cc.Director:getInstance():getScheduler()

local GE   = app.game.GameEnum
local GECT = app.game.GameEnum.cardsType
local GEPS = app.game.GameEnum.playerStatus
local ST   = app.game.GameEnum.soundType

local HERO_LOCAL_SEAT   = 1
local CARD_NUM          = 17
local CV_BACK           = app.game.CardRule.cards.CV_BACK 
local LAST_CARD         = 1
local TIME_START_EFFECT = 1
local TIME_MAKE_BANKER  = 1

local SCHEDULE_WAIT_TIME= 0

-- 初始化
function GamePresenter:init(...)
    print("enter ddz")
    self._maxPlayerCnt = app.game.PlayerData.getMaxPlayerCount() or 3
    self:createDispatcher()
    self:initRequire()
    self:playGameMusic()  
    self:initPlayerNode()
    self:initNodeBankCard()
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

function GamePresenter:initNodeBankCard()
    local nodeHand = self._ui:getInstance():seekChildByName("node_bank_card") 
    self._gameBankCardNode = GameBankCardNode:create(self, nodeHand)
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

function GamePresenter:initRequire()    
    self._runRule = requireDDZ("app.game.ddz.GameRunRule")
    app.game.GameResultPresenter = requireDDZ("app.game.ddz.GameResultPresenter")
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
    self:closeSchedulerPrepareClock()
    self:closeSchedulerRunLoading()
    self:closeScheduleSendReady()
    self:closeSchedulerClocks()
    
    app.lobby.notice.BroadCastNode:stopActions()
    app.game.GameResultPresenter = nil
    
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
        
        app.game.GameResultPresenter:getInstance():exit()
                
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
    if not localSeat or localSeat == -1 then
    	return
    end
    if self._gamePlayerNodes then
        self._gamePlayerNodes[localSeat]:onPlayerEnter() 
    end 
    
    if localSeat == HERO_LOCAL_SEAT then
        app.game.GameResultPresenter:getInstance():exit()
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

-- 游戏准备
function GamePresenter:onDdzGamePrepare()
    self._ui:getInstance():showPnlHint(1)
end

-- 玩家准备
function GamePresenter:onDdzPlayerReady(seat)
    local localseat = app.game.PlayerData.serverSeatToLocalSeat(seat)
    if localseat == HERO_LOCAL_SEAT then      
        self:closeScheduleSendReady()
    end         
end

-- 开始
function GamePresenter:onDdzGameStart(cards)   
    self._playing = true  
       
    self._ui:getInstance():showPnlHint()
    
    for i = 0, self._maxPlayerCnt - 1 do        
        app.game.PlayerData.updatePlayerStatus(i, 0)
    end
    
    local seats = app.game.GameData.getPlayerseat()   
    for k, i in ipairs(seats) do
        app.game.PlayerData.updatePlayerStatus(i, 3)        
    end
    
    app.game.GameResultPresenter:getInstance():exit()
    
    -- 重置数据
    app.game.GameData.restDataEx()
    
--    self:playEffectByName("e_start")
    
    -- 玩家开始
    for i = 0, self._maxPlayerCnt - 1 do
        if self._gamePlayerNodes[i] then
            self._gamePlayerNodes[i]:onGameStart()
            self._gamePlayerNodes[i]:showPlayerInfo()
        end
    end
    -- 开局动画    
    self._ui:getInstance():showStartEffect()
    
    -- cards
    local heroServerSeat = app.game.PlayerData.getHeroSeat()
    local otherCards = {}
    for i=0, 3 do
        if i ~= heroServerSeat then
            otherCards[i] = otherCards[i] or {}
            for j=1, 17 do
                otherCards[i][j] = CV_BACK
            end
            app.game.GameData.setHandCards(i, otherCards[i])
        else
            local tcard = self:serverTolocalCards(cards)
            local scards = self._runRule:getInstance():sortByWeight(tcard)
            app.game.GameData.setHandCards(heroServerSeat, scards)
        end
    end
  
    self:performWithDelayGlobal(function()
        for i = 0, self._maxPlayerCnt - 1 do
            if self._gamePlayerNodes[i] then                   
                self._gamePlayerNodes[i]:showPlayerInfo()
            end
        end            
        self:onTakeFirst()            
    end, TIME_START_EFFECT)
end

-- 发牌
function GamePresenter:onTakeFirst() 
    for i = 0, self._maxPlayerCnt - 1 do
        local gameHandCardNode = self._gamePlayerNodes[i]:getGameHandCardNode()
        gameHandCardNode:resetHandCards()  
    end

    local function callback()
        if app.game.GameData then
            local curseat = app.game.GameData.getCurrseat()           
            if curseat == app.game.PlayerData.getHeroSeat() then               
                self._gameBtnNode:showTableBtn("call")
                for i=0, 3 do
                	self._gameBtnNode:setCallBtnEnable(i,true)
                end                                
            end            
        end
    end     
     
    self:openSchedulerTakeFirst(callback)
end

-- 叫地主
function GamePresenter:onDdzBankerBid(info) 
    if info.bidstate == GE.bankBidState.DDZ_BANKER_BID_STATE_IDLE or info.bidstate == GE.bankBidState.DDZ_BANKER_BID_STATE_TURN then
        local localSeat = app.game.PlayerData.serverSeatToLocalSeat(info.seat) 
        local localCurrseat = app.game.PlayerData.serverSeatToLocalSeat(info.curseat)
        
        if self._gamePlayerNodes[localSeat] then
            self._gamePlayerNodes[localSeat]:showImgCallType(true, info.mult)
        end
        if localCurrseat == HERO_LOCAL_SEAT then
            self._gameBtnNode:showTableBtn("call")
            for i= 1, 3 do
                if i <= info.bankmult then
                    self._gameBtnNode:setCallBtnEnable(i,false)
                else
                    self._gameBtnNode:setCallBtnEnable(i,true)    
                end                
            end
        else
            self._gameBtnNode:showTableBtn()
    	end
    elseif info.bidstate == GE.bankBidState.DDZ_BANKER_BID_STATE_READY then
        local tcards = self:serverTolocalCards(info.cards)      
        self._gameBankCardNode:resetBankCards()        
        self._gameBankCardNode:createCards(tcards)
                
        app.game.GameData.setBanker(info.bankseat)

        local localbank = app.game.PlayerData.serverSeatToLocalSeat(info.bankseat) 
        -- 自己是庄
        if localbank == HERO_LOCAL_SEAT then
            self._gameBtnNode:showTableBtn()
            
            if self._gamePlayerNodes[localbank] then
                self._gamePlayerNodes[localbank]:showImgCallType(true, info.bankmult)
                self._gamePlayerNodes[localbank]:showImgBanker(true)               
            end
            
            local handCards = app.game.GameData.getHandCards(info.bankseat) 
            local tcards = self:serverTolocalCards(info.cards)
            local retCards = self._runRule:getInstance():addCards(handCards, tcards)
            local scards = self._runRule:getInstance():sortByWeight(retCards)
                                          
            app.game.GameData.setHandCards(info.bankseat, scards)

            local gameHandCardNode = self._gamePlayerNodes[localbank]:getGameHandCardNode()
            gameHandCardNode:resetHandCards()            
            gameHandCardNode:createCards(scards)  
            
--            self:setCardsUp(tcards)  
        else            
            self._gameBtnNode:showTableBtn("mult")
            
            if self._gamePlayerNodes[HERO_LOCAL_SEAT] then
                self._gamePlayerNodes[HERO_LOCAL_SEAT]:showImgCallType(false)
                self._gamePlayerNodes[HERO_LOCAL_SEAT]:showImgBanker(false)                
            end
 
            local handCards = app.game.GameData.getHandCards(info.bankseat)
            local cards = {}
            for i = 1,3 do
                cards[i] = CV_BACK
            end            
            local retCards = self._runRule:getInstance():addCards(handCards, cards)
            app.game.GameData.setHandCards(info.bankseat, retCards)
            self._gamePlayerNodes[localbank]:showFntHandCardCount(true, #retCards)            
        end
    elseif info.bidstate == GE.bankBidState.DDZ_BANKER_BID_STATE_READY then
        -- 重新发牌
        for i = 0, self._maxPlayerCnt - 1 do
        	self._gamePlayerNodes[i]:onGameStart()
        end
    end
end

-- 加倍
function GamePresenter:onDdzCompareBid(info)
    local banker = app.game.GameData.getBanker()
    local localbank = app.game.PlayerData.serverSeatToLocalSeat(banker) 
    local localseat = app.game.PlayerData.serverSeatToLocalSeat(info.seat) 
    
	if self._gamePlayerNodes[localbank] then
        self._gamePlayerNodes[localbank]:showMult(info.bankmult)
    end

    if self._gamePlayerNodes[localseat] then        
        if info.mult == 1 then
            self._gamePlayerNodes[localseat]:showMult(2)
            self._gamePlayerNodes[localseat]:showImgMult(true)
        else
            self._gamePlayerNodes[localseat]:showMult(1)
        end
    end
    
    if localseat == HERO_LOCAL_SEAT then
        self._gameBtnNode:showTableBtn()
    end     
end

-- 加倍结束
function GamePresenter:onDdzCompareBidOver(info, players) 
    local banker = app.game.GameData.getBanker()
    local localbank = app.game.PlayerData.serverSeatToLocalSeat(banker) 

    for i=1, #players do
        local localseat = app.game.PlayerData.serverSeatToLocalSeat(players[i].seat)
        if localseat ~= localbank then
            if self._gamePlayerNodes[localseat] then
                if players[i].mult == 1 then
                    self._gamePlayerNodes[localseat]:showMult(2)
                    self._gamePlayerNodes[localseat]:showImgMult(true)
                else
                    self._gamePlayerNodes[localseat]:showMult(1)
                end
            end
        else
            self._gamePlayerNodes[localseat]:showMult(info.bankmult)
        end
        
        app.game.PlayerData.updatePlayerRiches(players[i].seat, 0, players[i].balance)         
        self._gamePlayerNodes[localseat]:showTxtBalance(true, players[i].balance) 
    end
    
    if localbank == HERO_LOCAL_SEAT then
        self._gameBtnNode:showTableBtn("bankerplay")
        self:onClock(banker)
    else
        self._gameBtnNode:showTableBtn()
    end
end

-- 明牌
function GamePresenter:onDdzDisplay(info)
--    info.seat      = po:read_int16()
--    info.cards     = _readCards(po:read_string())
--    info.bankmult  = po:read_int32()
    
end

-- 托管
function GamePresenter:onDdzAutoHint()
    
end

-- 出牌
function GamePresenter:onDdzHitCard(info)
    local localseat = app.game.PlayerData.serverSeatToLocalSeat(info.seat) 
    
    local banker = app.game.GameData.getBanker()
    local localbank = app.game.PlayerData.serverSeatToLocalSeat(banker) 
    
    app.game.GameData.setLastComb(info.seat)
    
    self:dealOutCard(info.seat, info.cards, info.cardtype)
    
    if self._gamePlayerNodes[localseat] then        
        self._gamePlayerNodes[localseat]:showMult(info.mult)          
        self._gamePlayerNodes[localseat]:showImgCardType(true, info.cardtype)         
    end
    
    if self._gamePlayerNodes[localbank] then
        self._gamePlayerNodes[localbank]:showMult(info.bankmult)
    end
    
    local heroServerSeat = app.game.PlayerData.getHeroSeat()  
    
    print("out card", info.curseat)
                        
    if info.curseat ~= -1 then
        if heroServerSeat == info.curseat then
            if self:isFirstOutByServerSeat(info.curseat) then
                self._gameBtnNode:showTableBtn("firstplay")
            else
                self._gameBtnNode:showTableBtn("play")
            end
            
        else
            self._gameBtnNode:showTableBtn()
        end  
        
        self:onClock(info.curseat)      
    end    
end

-- 玩家出牌
function GamePresenter:dealOutCard(serverSeat, cards, cardtype)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(serverSeat)
    
    if localSeat == HERO_LOCAL_SEAT then
        self._gameBtnNode:showTableBtn()
    end
     
    if self._gamePlayerNodes[localSeat] then
        self._gamePlayerNodes[localSeat]:showImgCancelFlag(false)
        self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
    end    
--    local outComb = self._runRule:getInstance():testCardComb(cards, typeID, power)
    self:deleteHandCards(serverSeat, cards)

    local gameOutCardNode = self._gamePlayerNodes[localSeat]:getGameOutCardNode()
    local tcards = self:serverTolocalCards(cards)
    gameOutCardNode:resetOutCards()
    gameOutCardNode:createCards(tcards)
end

-- 过
function GamePresenter:onDdzPass(info)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(info.seat)

    self._gameBtnNode:showTableBtn()

    self._gamePlayerNodes[localSeat]:showPnlClockCircle(false)
    self._gamePlayerNodes[localSeat]:showImgCancelFlag(true)
    
    local heroServerSeat = app.game.PlayerData.getHeroSeat()                  
    if info.curseat ~= -1 then
        if heroServerSeat == info.curseat then
            if self:isFirstOutByServerSeat(info.curseat) then
                self._gameBtnNode:showTableBtn("firstplay")
            else
                self._gameBtnNode:showTableBtn("play")
            end
            
        else
            self._gameBtnNode:showTableBtn()
        end    
        self:onClock(info.curseat)    
    end    
end

-- 游戏结束
function GamePresenter:onDdzGameOver(players) 
     for i, player in ipairs(players) do
        local localSeat = app.game.PlayerData.serverSeatToLocalSeat(player.seat)               
        local gameOutCardNode = self._gamePlayerNodes[localSeat]:getGameOutCardNode()          
        local tcards = self:serverTolocalCards(player.cards)
        local scards = self._runRule:getInstance():sortByWeight(tcards)
        gameOutCardNode:resetOutCards()
        gameOutCardNode:createCards(scards)
    end
    
    local base = app.game.GameConfig.getBase()
    local banker = app.game.GameData.getBanker()    
    players.base = base
    players.banker = banker

    app.game.GameResultPresenter:getInstance():start(players)    
end

-- 断线重连
function GamePresenter:onRelinkEnter(data)
    self._playing = true
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

-- 时钟
function GamePresenter:onClock(serverSeat, time)
    print("onClock", serverSeat, time)
    
    time = 15
    
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(serverSeat)
    self._gamePlayerNodes[localSeat]:onClock(time)

    -- 所有人都不要的情况又轮到自己出牌,或接风（接风状态会在onPower中重置） 
    if self:isFirstOutByServerSeat(serverSeat) then                    
        for i = 0, self._maxPlayerCnt - 1 do
            self._gamePlayerNodes[i]:onClockEx()
        end
    end
end
-- ----------------------------onclick-------------------------------

function GamePresenter:onTouchBtnBankerMing()
    print("onTouchBtnBankerMing")
    self:sendDisplay()
end

function GamePresenter:onTouchBtnBankerHint()
    print("onTouchBtnBankerHint")    
end

function GamePresenter:onTouchBtnBankerOut()
    print("onTouchBtnBankerOut")    
    local upCards = self:getUpHandCards()
    self:sendHitCard(upCards)
end

function GamePresenter:onTouchBtnFirstHint()
    print("onTouchBtnFirstHint")

end

function GamePresenter:onTouchBtnFirstOut()
    print("onTouchBtnFirstOut")    
    local upCards = self:getUpHandCards()
    self:sendHitCard(upCards)
end

function GamePresenter:onTouchBtnPlayHint()
    print("onTouchBtnPlayHint")
end

function GamePresenter:onTouchBtnPlayOut()
    print("onTouchBtnPlayOut")
    
    local upCards = self:getUpHandCards()
    self:sendHitCard(upCards)
end

function GamePresenter:onTouchBtPlayCancel()
    print("onTouchBtPlayCancel")
    
    self:sendPass()
end

function GamePresenter:onTouchBtnCall(index)
    print("onTouchBtnOutHint",index)
    
    self:sendBankerBid(index)
end

function GamePresenter:onTouchBtnMult(index)
    print("onTouchBtnMult",index) 
    
    self:sendCompareBid(index)   
end

-- ------------------------------show ui------------------------------
function GamePresenter:showTableBtn(type)
    local hero = app.game.PlayerData.getHero()
    if hero and hero:isPlaying() then
        self._gameBtnNode:showTableBtn(type)
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
    
    local heroServerSeat = app.game.PlayerData.getHeroSeat()
    local cards = app.game.GameData.getHandCards(heroServerSeat)
    
    cardbacks[HERO_LOCAL_SEAT] = cards

    local cardNum = 1
    local function onInterval(dt)
        if cardNum <= CARD_NUM then            
            for localseat = 0, self._maxPlayerCnt - 1 do                
                if self._gamePlayerNodes[localseat] then                
                    self._gamePlayerNodes[localseat]:onTakeFirst(cardbacks[localseat][cardNum], cardNum)                     
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

    self._schedulerTakeFirst = scheduler:scheduleScriptFunc(onInterval, 2/CARD_NUM, false)
end

function GamePresenter:closeSchedulerTakeFirst()
    if self._schedulerTakeFirst then
        scheduler:unscheduleScriptEntry(self._schedulerTakeFirst)
        self._schedulerTakeFirst = nil
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
--                self._ui:getInstance():playEffectByName("didi")
                sound = true
            end
        end
        local strTime = string.format("%d", math.ceil(time))
        self._gamePlayerNodes[localSeat]:showClockProgress(strTime)
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

-- ---------------------------rule-----------------------------
-- 计算手牌位置
function GamePresenter:calHandCardPosition(index, cardSize, localSeat, bUp)
    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
    local count = gameHandCardNode:getHandCardCount()

    return self._runRule:getInstance():calHandCardPosition(index, cardSize, count, localSeat, bUp)
end

-- 计算出牌位置
function GamePresenter:calOutCardPosition(index, cardSize, localSeat)
    local gameOutCardNode = self._gamePlayerNodes[localSeat]:getGameOutCardNode()
    local count = gameOutCardNode:getOutCardCount()

    return self._runRule:getInstance():calOutCardPosition(index, cardSize, count, localSeat)
end

-- 计算底牌位置
function GamePresenter:calBankCardPosition(index, cardSize, localSeat)
    local count = self._gameBankCardNode:getBankCardCount()

    return self._runRule:getInstance():calBankCardPosition(index, cardSize, count)
end

function GamePresenter:setStartHintIndex(index)   
    app.game.GameData.setStartHintIndex(index)
end

function GamePresenter:sortNodeCardByWeight(nodeCards)   
    self._runRule:getInstance():sortNodeCardByWeight(nodeCards)
end

function GamePresenter:getCardNum(cardID)   
    return self._runRule:getInstance():getCardNum(cardID)
end

function GamePresenter:getCardColor(cardID)   
    return self._runRule:getInstance():getCardColor(cardID)
end

function GamePresenter:getCardWeight(cardID)   
    return self._runRule:getInstance():getCardWeight(cardID)
end

function GamePresenter:deleteHandCards(serverSeat, cards)
    local localSeat = app.game.PlayerData.serverSeatToLocalSeat(serverSeat)
    local heroServerSeat = app.game.PlayerData.getHeroSeat()

    local handCards = app.game.GameData.getHandCards(serverSeat)
    local tcards = self:serverTolocalCards(cards)
    
    self._runRule:getInstance():deleteHandCards(serverSeat, heroServerSeat, tcards, handCards)    
    app.game.GameData.setHandCards(serverSeat, handCards)

    if serverSeat == heroServerSeat then
        local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()        
        gameHandCardNode:deleteHandCards(tcards)
    end

    self._gamePlayerNodes[localSeat]:showPnlHandCard(true, #handCards)
end

-- 提示相关代码
function GamePresenter:initCanOutCombs(handCards, preComb)
    local tempPreComb = preComb or app.game.CardRule.CardComb:new()

    local combs, testCombFlag = self._runRule:getInstance():hintCards(handCards, tempPreComb)

    app.game.GameData.setHintComb(combs)
    app.game.GameData.setStartHintIndex(1)
end

function GamePresenter:getNextHintCards()
    local startHintIndex = app.game.GameData.getStartHintIndex()
    local hintComb = app.game.GameData.getHintComb()

    if startHintIndex > #hintComb then
        startHintIndex = startHintIndex - #hintComb
    end

    local nextCards = hintComb[startHintIndex].cards
    app.game.GameData.setStartHintIndex(startHintIndex + 1)

    return nextCards
end

function GamePresenter:checkOutBtnEnable(upCards)    
    local comb = app.game.CardRule.CardComb:new()
    local serverSeat = app.game.PlayerData.getHeroSeat()
    local preServerSeat, preComb = app.game.GameData.getLastComb()

--    if self:isFirstOutByServerSeat(serverSeat) then               
--        comb = self._runRule:getInstance():testMaxCardComb(upCards)
--    else
--        comb = self._runRule:getInstance():canOutFromMaxComb(upCards, preComb)
--    end
--
--    local flag = self._runRule:getInstance():checkComb(comb)
--
--    self._gameBtnNode:setOutBtnEnable(flag)   
end

function GamePresenter:dealSelectAutoUp()
    local upCards = self:getUpHandCards()

    local serverSeat = app.game.PlayerData.getHeroSeat()
    local handCards = app.game.GameData.getHandCards(serverSeat)

    if #upCards < 2 then 
        return 
    end

    local hintComb = app.game.GameData.getHintComb()
    if #hintComb == 0 then
        return
    end

    local tempHintComb = clone(hintComb)
    local needUpCards = self._runRule:getInstance():calSelectAutoUp(upCards, tempHintComb, handCards, self:isFirstOutByServerSeat(serverSeat))

    self:setNeedUpCardsAutoUp(needUpCards)
end

-- 联想手牌弹起
function GamePresenter:setNeedUpCardsAutoUp(cards)
    if cards == nil or #cards == 0 then
        return
    end

    local gameHandCardNode = self._gamePlayerNodes[HERO_LOCAL_SEAT]:getGameHandCardNode()
    gameHandCardNode:setNeedUpCardsAutoUp(cards)
end

-- 设置手牌弹起
function GamePresenter:setCardsUp(cards)
    if cards == nil or #cards == 0 then
        return
    end

    local gameHandCardNode = self._gamePlayerNodes[HERO_LOCAL_SEAT]:getGameHandCardNode()
    gameHandCardNode:setCardsUp(cards)
end

-- 是否首出
function GamePresenter:isFirstOutByServerSeat(serverSeat)                  
    local preServerSeat, preComb = app.game.GameData.getLastComb()
        
    if preServerSeat == -1 or preServerSeat == serverSeat  then
        return true
    else
        return false
    end
end

function GamePresenter:serverTolocalCards(cards)    
    local tcards = {}
    for i, card in ipairs(cards) do
        tcards[i] = app.game.CardRule.localCards[card]
    end
    
    return tcards
end

function GamePresenter:localToserverCards(cards)
    local tcards = {}
    for i, card in ipairs(cards) do
        tcards[i] = app.game.CardRule.serverCards[card]
    end

    return tcards
end

function GamePresenter:sortHandCard(localSeat, index)
    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
    gameHandCardNode:sortNodeCardByWeight(index)     
end

-- ----------------------------request-------------------------------
-- 退出房间
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

-- 换桌
function GamePresenter:sendChangeTable()
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

-- 准备
function GamePresenter:sendPlayerReady()
    if not app.game.GamePresenter then
        print("not in game")
        return
    end
    
    local hero = app.game.PlayerData.getHero()   
    if hero then       
        print("hero is leave", hero:isLeave())
    end 
    
    local po = upconn.upconn:get_packet_obj()
    local limit = app.game.GameConfig.getLimit()
    if hero and not hero:isLeave() and hero:getBalance() > limit and po then        
        print("send ready", hero:getSeat())
        local sessionid = app.data.UserData.getSession() or 222        
        po:writer_reset()
        po:write_int64(sessionid)
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_DDZ_READY_REQ)
    end    
end

-- 叫地主
function GamePresenter:sendBankerBid(mult)
    local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_int32(mult)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_DDZ_BANKER_BID_REQ)
end

-- 加倍
function GamePresenter:sendCompareBid(mult)
    local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_int32(mult)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_DDZ_COMPARE_BID_REQ)
end

-- 明牌
function GamePresenter:sendDisplay()
    local sessionid = app.data.UserData.getSession() or 222
    local heroseat = app.game.PlayerData.getHeroSeat()
     
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_int16(heroseat)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_DDZ_DISPLAY_REQ)
end

-- 托管
function GamePresenter:sendAutoHit(flag)
    local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_byte(flag)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_DDZ_AUTO_HIT_REQ)
end

-- 出牌 readString
function GamePresenter:sendHitCard(cards)
    if #cards == 0 then
    	print("card is 0")
    	return
    end
    local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    
    local tmp = self:localToserverCards(cards)
    local tcards = string.char(unpack(tmp))
    po:write_string(tcards)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_DDZ_HIT_CARD_REQ)
end

-- 过
function GamePresenter:sendPass()
    local sessionid = app.data.UserData.getSession() or 222
    local heroseat = app.game.PlayerData.getHeroSeat()
    
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_int16(heroseat)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_DDZ_PASS_REQ)
end

-- 音效相关
function GamePresenter:playGameMusic()
    app.util.SoundUtils.playMusic("game/qznn/sound/bgm_game.mp3")
end

function GamePresenter:playCountDownEffect()
    app.util.SoundUtils.playEffect("game/qznn/sound/countdown.mp3")   
end

function GamePresenter:playEffectByName(name)
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

return GamePresenter