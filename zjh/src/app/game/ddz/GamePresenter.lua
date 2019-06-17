--[[
@brief  游戏主场景控制基类
]]

local GamePlayerNode = requireDDZ("app.game.ddz.GamePlayerNode")
local GameBtnNode    = requireDDZ("app.game.ddz.GameBtnNode")
local GameMenuNode   = requireDDZ("app.game.ddz.GameMenuNode")

local GamePresenter  = class("GamePresenter", app.base.BasePresenter)

GamePresenter._ui    = requireDDZ("app.game.ddz.GameScene")

local scheduler = cc.Director:getInstance():getScheduler()

local GE   = app.game.GameEnum
local GECT = app.game.GameEnum.cardsType
local GEPS = app.game.GameEnum.playerStatus
local ST   = app.game.GameEnum.soundType

local HERO_LOCAL_SEAT   = 1
local CARD_NUM          = 4
local CV_BACK           = 0
local LAST_CARD         = 1
local TIME_START_EFFECT = 1
local TIME_MAKE_BANKER  = 1

local SCHEDULE_WAIT_TIME= 0

-- 初始化
function GamePresenter:init(...)
    print("enter ddz")
    self._maxPlayerCnt = app.game.PlayerData.getMaxPlayerCount() or 3
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
    
end

-- 退出界面
function GamePresenter:exit()
    GamePresenter.super.exit(self)
    
    self:closeSchedulerTakeFirst()
    self:closeSchedulerPrepareClock()
    self:closeSchedulerRunLoading()
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

-- 游戏准备
function GamePresenter:onGamePrepare()
    self._ui:getInstance():showPnlHint(1)
end

-- 玩家准备
function GamePresenter:onDDZPlayerReady(seat)
    local localseat = app.game.PlayerData.serverSeatToLocalSeat(seat)
    if localseat == HERO_LOCAL_SEAT then      
        self:closeScheduleSendReady()
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
    
    self:playEffectByName("e_start")
    
    -- 玩家开始
    for i = 0, self._maxPlayerCnt - 1 do
        if self._gamePlayerNodes[i] then
            self._gamePlayerNodes[i]:onGameStart()
            self._gamePlayerNodes[i]:showPlayerInfo()
        end
    end
    -- 开局动画    
    self._ui:getInstance():showStartEffect()
        
    self:performWithDelayGlobal(
        function()
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
        self:showTableBtn("banker")
        
        if self._ui:getInstance():isSelected("cbx_banker_test") then
            self:performWithDelayGlobal(function()
                self:onEventCbxBanker()
            end, 1)
        end       
    end      
    self:openSchedulerTakeFirst(callback)
end

-- 游戏结束
function GamePresenter:onNiuGameOver(players) 
    
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

    -- 将正在游戏的玩家状态设为默认
    for i = 0, self._maxPlayerCnt - 1 do 
        local player = app.game.PlayerData.getPlayerByServerSeat(i)
        if player and player:isPlaying() then
            app.game.PlayerData.updatePlayerStatus(i, 0) 
        end              
    end    
    
    -- 自动准备
    self:performWithDelayGlobal(function()
        self:sendPlayerReady()
    end, 3) 
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

-- ----------------------------onclick-------------------------------

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
    
    local cards = app.game.GameData.getHandCards()
    cardbacks[HERO_LOCAL_SEAT] = cards

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
-- 计算手牌位置
local SELECT_Y = 15
local HAND_CARD_DISTANCE_OTHER = 30
function GamePresenter:calHandCardPosition(index, cardSize, localSeat, bUp)
    local gameHandCardNode = self._gamePlayerNodes[localSeat]:getGameHandCardNode()
    local count = 5

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
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_C41_READY_REQ)
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