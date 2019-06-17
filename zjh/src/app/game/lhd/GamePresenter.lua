--[[
@brief  游戏主场景控制基类
]]

local GamePlayerNode = requireLHD("app.game.lhd.GamePlayerNode")
local GameBtnNode    = requireLHD("app.game.lhd.GameBtnNode")
local GameMenuNode   = requireLHD("app.game.lhd.GameMenuNode")

local GamePresenter  = class("GamePresenter", app.base.BasePresenter)

GamePresenter._ui    = requireLHD("app.game.lhd.GameScene")

local scheduler = cc.Director:getInstance():getScheduler()

local GE   = app.game.GameEnum
local GECT = app.game.GameEnum.cardsType
local ST   = app.game.GameEnum.soundType

local LOCAL_HERO_SEAT   = 7
local CV_BACK           = 0
local OTHER_SEAT        = 8
-- 初始化
function GamePresenter:init(...)
    self._maxPlayerCnt = app.game.PlayerData.getMaxPlayerCount() or 7
    self:createDispatcher()    
    self._selectBetIndex = -1
    self:playGameMusic()      
    self:initRequire()
    self:initPlayerNode()
    self:initBtnNode()
    self:initMenuNode()   
    self:initScheduler()   
    
    self:showBetBtnEnable() 
    
    self._playing = false  
    self._enter = false
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

function GamePresenter:initTouch()
    local gameBG = self._ui:getInstance():seekChildByName("background")
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(handler(self, self.onTouchBegin), cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(handler(self, self.onTouchMove), cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(handler(self, self.onTouchEnd), cc.Handler.EVENT_TOUCH_ENDED)

    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, gameBG)
end

function GamePresenter:initPlayerNode()
    -- serverseat 1 大富豪 2 神算子 3 本家 4-7 other
    self._gamePlayerNodes = {}
    for i = 1, self._maxPlayerCnt do
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
    self._schedulerAutoReady    = nil     -- 自动准备  
end

function GamePresenter:initRequire()
    app.game.GameTrendPresenter = requireLHD("app.game.lhd.GameTrendPresenter")
    app.game.GameListPresenter  = requireLHD("app.game.lhd.GameListPresenter")
end

-- 退出界面
function GamePresenter:exit()
    GamePresenter.super.exit(self)

    app.game.GameListPresenter = nil
    app.game.GameTrendPresenter = nil
    
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
--    if app.game.PlayerData.isHero(data.ticketid) then
--        local heroseat = app.game.PlayerData.getHeroSeat()
--        app.game.PlayerData.updatePlayerStatus(heroseat, data.status)
--    end

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
        print("self leave", numID) 
        for i = 1, self._maxPlayerCnt do
            if self._gamePlayerNodes[i] then
                self._gamePlayerNodes[i]:onResetTable()
            end
        end           
    end
end

-- 退出游戏区
function GamePresenter:onLeaveRoom()
    app.game.GameEngine:getInstance():exit()
end

-- 处理玩家进入
function GamePresenter:onPlayerEnter(player, k)
    if k < 0 or k > 6 or not player then
        print("player enter full")
        return
    end
    
    app.game.GameData.setSitplayers(k,player)

    self._gamePlayerNodes[k]:onPlayerEnter(player)

    -- 按钮触摸
    self:showBetBtnEnable()
    
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
            if not isIn and not self._enter then
                self._ui:getInstance():showHint("wait")
                self._enter = true            
            end         
        end           	
    end
end

function GamePresenter:onSelfPlayerEnter()
    local hero = app.game.PlayerData.getHero()
    self._gamePlayerNodes[LOCAL_HERO_SEAT]:onPlayerEnter(hero)
end

function GamePresenter:onLhdPlayerReady(seat)
    local heroseat = app.game.PlayerData.getHeroSeat()  
    if seat == heroseat then
    	app.game.GameData.setReady(true)
        self:closeScheduleSendReady()
    end
end

function GamePresenter:onPlayerSitdown(player) 
end

function GamePresenter:onChangeTable(flag)    
end

function GamePresenter:onLhdGamePrepare() 
    app.game.GameData.setTableStatus(zjh_defs.TableStatus.TS_PREPARE)
    self:sendPlayerReady()
end

-- 游戏开始
function GamePresenter:onLhdGameStart()   
    self._playing = true
    app.game.GameData.restDataEx()
    self._ui:getInstance():showHint()
    self._ui:getInstance():resetBetUI()
    self._ui:getInstance():resetLongHuCards(true)
    self._ui:getInstance():removeAllChip()
    self:showBetBtnEnable()
    
    self._ui:getInstance():showStartEffect()        
    
    self:playEffectByName("lh_vs")
    
    self:performWithDelayGlobal(
        function()
            self:playEffectByName("start")
            self._ui:getInstance():showClockEffect()
        end, 1)
        
        
    for i=1, 3 do        
        self:performWithDelayGlobal(function()
            if app.game.GamePresenter then
                self:playEffectByName("countdown")
            end 
        end, 7+i)            
    end    
end

-- 游戏结束
function GamePresenter:onLhdGameOver(overs, players)    
    self._playing = false 
    app.game.GameData.setTableStatus(zjh_defs.TableStatus.TS_ENDING)
    app.game.GameData.setReady(false)
    app.game.GameData.setHistory(overs.seqid, overs.cardtype, overs.cards)
    app.game.GameData.setPlayerLists(players)
    
    -- 停止下注
    self._ui:getInstance():showEndEffect() 
    self:playEffectByName("stop")      
    -- VS
    self._ui:getInstance():showVSEffect()
    
    -- 提示
    self._ui:getInstance():showHint()
    
    -- 飘金币
    local function goldFunc()
        -- 刷新列表
        self:updatePlayerList(players)
    
        local scorelist = {}         
        local count = 0
        for k, player in ipairs(players) do                               
            if k > 2 and player.seatinfo.ticketid == app.data.UserData.getTicketID() then
            else
                if player.longnum == 0 and player.hunum == 0 and player.henum == 0 then
                    count = count + 1        
                    scorelist[count] = -1
                else                
                    count = count + 1        
                    scorelist[count] = player.bouns   
                end                        
            end                      
        end
        
        if overs.longnum == 0 and overs.hunum == 0 and overs.henum == 0 then
            scorelist[LOCAL_HERO_SEAT] = -1
        else
            scorelist[LOCAL_HERO_SEAT] = overs.bouns  
        end
                                  
        self._ui:getInstance():showWinloseScore(scorelist)
        
        for k, score in pairs(scorelist) do
            if score and score > 0 then
                if self._gamePlayerNodes[k] then
                    self._gamePlayerNodes[k]:playWinEffect()
                end
            end
        end

        local history = app.game.GameData.getHistory()    
        self._ui:getInstance():addHistory(history)      
        if app.game.GameTrendPresenter:getInstance():isCurrentUI() then            
            app.game.GameTrendPresenter:getInstance():updateTrendOne(overs.cardtype, history) 
        end
        
        self:performWithDelayGlobal(function()            
            self._ui:getInstance():resetLongHuCards(false)  
            
            self._ui:getInstance():showSleepEffect()       
        end, 2)
    end
    
    local function lightFunc()
        self._ui:getInstance():showWinLight(overs.cardtype, goldFunc) 
        self:playEffectByName("win_" .. overs.cardtype)      
        self:playEffectByName("win_bet") 

        self:performWithDelayGlobal(function()
            self._ui:getInstance():showChipBackOtherAction()
            self._ui:getInstance():resetBetUI()            
        end, 1)
    end
    
    local function huFunc()
        self._ui:getInstance():createLongHuCard(overs.cards[2], 2, lightFunc)
    end
    
    self:performWithDelayGlobal(function()
        -- 龙牌
        self._ui:getInstance():createLongHuCard(overs.cards[1], 1, huFunc)
    end, 1.5)
    
    print("send ready 8") 
    -- 自动准备
    self:performWithDelayGlobal(function()               
        self:sendPlayerReady()
    end, 8) 
end

-- 历史数据 
function GamePresenter:onLhdHistory(lists) 
    app.game.GameData.setHisLists(lists)
    
    local types = app.game.GameData.getHistory()
    self._ui:getInstance():addHistory(types)
end

-- 玩家列表
function GamePresenter:onLhdTopSeat(players) 
    app.game.GameData.setPlayerLists(players)    
    
    self:updatePlayerList(players)
end

-- 押注
function GamePresenter:onLhdBet(bets)
    app.game.PlayerData.updatePlayerRiches(bets.seat, 0, bets.balance)     
    -- 按钮触摸性
    self:showBetBtnEnable()
    
    -- 更新所有下注的总额
    self._ui:getInstance():setLongTxt(bets.longsum)
    self._ui:getInstance():setHuTxt(bets.husum)
    self._ui:getInstance():setHeTxt(bets.hesum) 
    
    local chip_long = self:getChipIndex(bets.long)
    local chip_hu = self:getChipIndex(bets.hu)
    local chip_he = self:getChipIndex(bets.he)
    
    local heroseat = app.game.PlayerData.getHeroSeat() 
    local localSeat = app.game.GameData.getLocalseatByServerseat(bets.seat)

    -- 自己下注
    if heroseat == bets.seat then
        -- 更新自己下注的金额
        app.game.GameData.setBetLong(bets.long)
        app.game.GameData.setBetHu(bets.hu)
        app.game.GameData.setBetHe(bets.he)
        
        local selflong = app.game.GameData.getBetLong()
        local selfhu = app.game.GameData.getBetHu()
        local selfhe = app.game.GameData.getBetHe()
        
        self._ui:getInstance():setSelfLongTxt(selflong, true)
        self._ui:getInstance():setSelfHuTxt(selfhu, true)
        self._ui:getInstance():setSelfHeTxt(selfhe, true)
        
        local allbet = bets.long + bets.hu + bets.he  
        self._ui:getInstance():showChipAction(chip_long, GECT.LHD_LONG, LOCAL_HERO_SEAT) 
        self._ui:getInstance():showChipAction(chip_hu, GECT.LHD_HU, LOCAL_HERO_SEAT) 
        self._ui:getInstance():showChipAction(chip_he, GECT.LHD_HE, LOCAL_HERO_SEAT)

        self._ui:getInstance():movePlayerPnl(LOCAL_HERO_SEAT, allbet)         
        
        if localSeat ~= -1 then
            self._gamePlayerNodes[localSeat]:showTxtBalance(true, bets.balance)     
        end
        self._gamePlayerNodes[LOCAL_HERO_SEAT]:showTxtBalance(true, bets.balance)    
    -- 他人下注    
    else
        -- 其他玩家
        if localSeat == -1 then
            self._ui:getInstance():showChipAction(chip_long, GECT.LHD_LONG, OTHER_SEAT) 
            self._ui:getInstance():showChipAction(chip_hu, GECT.LHD_HU, OTHER_SEAT) 
            self._ui:getInstance():showChipAction(chip_he, GECT.LHD_HE, OTHER_SEAT)
            return 
        else
            local allbet = bets.long + bets.hu + bets.he    
            self._ui:getInstance():showChipAction(chip_long, GECT.LHD_LONG, localSeat) 
            self._ui:getInstance():showChipAction(chip_hu, GECT.LHD_HU, localSeat) 
            self._ui:getInstance():showChipAction(chip_he, GECT.LHD_HE, localSeat)
            self._ui:getInstance():movePlayerPnl(localSeat, allbet)     
            self._gamePlayerNodes[localSeat]:showTxtBalance(true, bets.balance)     
        end                        
    end
end

function GamePresenter:onLhdBetFull()    
    app.game.GameData.setFull(true)
    
    for i=1, 5 do
        self._gameBtnNode:setBetBtnEnable(i, false)
    end
    self._selectBetIndex = -1
    self._gameBtnNode:setBetBtnLight(self._selectBetIndex)           
    self._ui:getInstance():showHint("full")    
end

function GamePresenter:onRelinkEnter(player)
    print("onrelink enter")   
    self._playing = true
end
-- -----------------------------do----------------------------------
function GamePresenter:updatePlayerList(players)
    print("update player list")    
    for i=1, 7 do
        self._gamePlayerNodes[i]:onResetTable()
    end
    
    app.game.GameData.resetSitPlayers()
    
    local ids = {} 
    for i, player in ipairs(players) do
        if app.game.PlayerData then            
            app.game.PlayerData.onPlayerInfo(player.seatinfo)
            table.insert(ids, player.seatinfo.ticketid)
        end          
	end
		
    local count = 0
    for k, id in ipairs(ids) do   
        local player = app.game.PlayerData.getPlayerByNumID(id)                   
        if k > 2 and player:getTicketID() == app.data.UserData.getTicketID() then
        else                        
            count = count + 1        
            app.game.GamePresenter:getInstance():onPlayerEnter(player, count)            
        end                      
    end                
    app.game.GamePresenter:getInstance():onSelfPlayerEnter()			
end

function GamePresenter:showBetBtnEnable()    
    local balance = nil
    if app.game.PlayerData then
        local hero = app.game.PlayerData.getHero()
        if hero then
            balance = hero:getBalance()       
        end 
    end
    local enable = {}
    self._gameBtnNode:setTxtHint(false)
    local full = app.game.GameData.getFull()
    if not balance or full then
        enable = {false, false, false, false, false}
        self._selectBetIndex = -1
    else
        if balance < 5000 then
            enable = {false, false, false, false, false}
            self._selectBetIndex = -1
            self._gameBtnNode:setTxtHint(true)                       
        elseif balance < 10000 then
            enable = {true, true, true, false, false} 
            if self._selectBetIndex == -1 then
                self._selectBetIndex = 1   
            end            
        elseif balance < 50000 then
            enable = {true, true, true, true, false} 
            if self._selectBetIndex == -1 then
                self._selectBetIndex = 1   
            end           
        else
            enable = {true, true, true, true, true} 
            if self._selectBetIndex == -1 then
                self._selectBetIndex = 1   
            end       
        end
    end	

    for i, e in ipairs(enable) do
        self._gameBtnNode:setBetBtnEnable(i, e)
	end	
	
    self._gameBtnNode:setBetBtnLight(self._selectBetIndex)		
end

-- ----------------------------onclick-------------------------------
function GamePresenter:onTouchGoing()
    local history = app.game.GameData.getHistory()
    app.game.GameTrendPresenter:getInstance():start(history) 
end

function GamePresenter:onTouchOther()
    local list = app.game.GameData.getPlayerLists()
    
    local players = {}
    for i, var in ipairs(list) do
        players[i] = players[i] or {}  
              
        players[i].seqid     = i    
        players[i].avatar = var.seatinfo.avatar
        players[i].gender = var.seatinfo.gender
        players[i].balance = var.seatinfo.balance
        players[i].ticketid  = var.seatinfo.ticketid                   
        players[i].gamenum20 = var.gamenum20
        players[i].betnum20  = var.betnum20                         
    end
        
    app.game.GameListPresenter:getInstance():start(players)         
end

function GamePresenter:onTouchBet(bet)
	self._selectBetIndex = bet
    self._gameBtnNode:setBetBtnLight(bet)
end

function GamePresenter:onClickBetArea(type)
    print("onclick area",type)
    if not self._playing then
        print("not playing")
        return
    end
    
    if app.data.UserData.getBalance() < 5000 then   
        self._ui:getInstance():showHint("less")
        return
    end
    
    -- 压和 判断当前金币是否是押注金额的5倍
    if type == GE.cardsType.LHD_HE then
    	local hero = app.game.PlayerData.getHero()  
    	local balance = hero:getBalance()
    	
        local bet = self:getChipNumByIndex(self._selectBetIndex)
        if balance / bet < 5 then
            self._ui:getInstance():showHint("more")
            return
        end
    end
    
    local bet = self:getChipNumByIndex(self._selectBetIndex)    
    if type == GE.cardsType.LHD_LONG then
        self:sendPlayerBet(bet, 0, 0)
        
    elseif type == GE.cardsType.LHD_HU then	
        self:sendPlayerBet(0, bet, 0)
        
    elseif type == GE.cardsType.LHD_HE then 
        self:sendPlayerBet(0, 0, bet)    
    end     
end

-- ---------------------------schedule------------------------
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

function GamePresenter:getChipIndex(bet)
    local index = -1
    if bet == 100 then
        index = 1
    elseif bet == 1000 then
        index = 2
    elseif bet == 5000 then
        index = 3
    elseif bet == 10000 then
        index = 4
    elseif bet == 50000 then
        index = 5
    end	
    return index
end

function GamePresenter:getChipNumByIndex(index)
    local chip = -1
    if index == 1 then
        chip = 100
    elseif index == 2 then
        chip = 1000
    elseif index == 3 then
        chip = 5000
    elseif index == 4 then
        chip = 10000
    elseif index == 5 then
        chip = 50000
    end 
    
    return chip
end

-- ----------------------------request-------------------------------
-- 退出房间
function GamePresenter:sendLeaveRoom()
    print("send leave room")
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
        po:write_int32(sessionid)  
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_LEAVE_ROOM_REQ)  
    end
end

-- 准备
function GamePresenter:sendPlayerReady()
    if not app.game.GamePresenter then
        print("not in game")
        return
    end
    
    if app.game.GameData.getReady() then
    	print("have ready")
    	return
    end
    
    local tabInfo = app.game.GameData.getTableInfo()
    if tabInfo.status == zjh_defs.TableStatus.TS_IDLE 
        or tabInfo.status == zjh_defs.TableStatus.TS_PREPARE 
        or tabInfo.status == zjh_defs.TableStatus.TS_ENDING then                   
        
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
            upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_DRAGON_VS_TIGER_READY_REQ)
        end         
    else
        print("not ready table is busy")    
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

-- 下注
function GamePresenter:sendPlayerBet(long, hu, he)    
    local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_int32(long)
    po:write_int32(hu)
    po:write_int32(he)
    print("send bet",long, hu, he)
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_DRAGON_VS_TIGER_BET_REQ)    
end

-- 音效相关
function GamePresenter:playGameMusic()
    app.util.SoundUtils.playMusic("game/lhd/sound/bgm_lhd.mp3")
end

function GamePresenter:playEffectByName(name)
    local soundPath = "game/lhd/sound/"
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