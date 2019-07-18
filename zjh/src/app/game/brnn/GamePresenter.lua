--[[
@brief  游戏主场景控制基类
]]

local app = app

local GamePlayerNode   = requireBRNN("app.game.brnn.GamePlayerNode")
local GameBtnNode      = requireBRNN("app.game.brnn.GameBtnNode")
local GameMenuNode     = requireBRNN("app.game.brnn.GameMenuNode")
local GameHandCardNode = requireBRNN("app.game.brnn.GameHandCardNode")

local GamePresenter  = class("GamePresenter", app.base.BasePresenter)

GamePresenter._ui    = requireBRNN("app.game.brnn.GameScene")

local scheduler = cc.Director:getInstance():getScheduler()

local GE   = app.game.GameEnum
local GECT = app.game.GameEnum.cardsType
local ST   = app.game.GameEnum.soundType

local LOCAL_BANKER_SEAT = 7
local LOCAL_HERO_SEAT   = 8

local CV_BACK           = 0
local OTHER_SEAT        = 9
local SYSTEMID          = 9999999
-- 初始化
function GamePresenter:init(...)
    self._maxPlayerCnt = app.game.PlayerData.getMaxPlayerCount() or 8
    self:createDispatcher()    
    self._selectBetIndex = -1
    self:playGameMusic()      
    self:initRequire()
    self:initPlayerNode()
    self:initNodeHandCard()
    self:initBtnNode()
    self:initMenuNode()   
    self:initScheduler()   

    self._playing = false  
    self._enter = false
    
    self:initScene()
end

-- 走马灯
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
    for i = 1, self._maxPlayerCnt do
        local pnlPlayer = self._ui:getInstance():seekChildByName("pnl_player_"..i) 
        self._gamePlayerNodes[i] = GamePlayerNode:create(self, pnlPlayer, i)
    end    
end

function GamePresenter:initNodeHandCard()
    self._gameHandCardNode = {}    
    for i = 1, 5 do
        local nodeHand = self._ui:getInstance():seekChildByName("node_handcard_"..i) 
        self._gameHandCardNode[i] = GameHandCardNode:create(self, nodeHand, i)
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
    self._schedulerBankBtnCD    = nil     -- 上庄按钮    
    self._schedulerTakeFirst    = nil     -- 发牌  
end

function GamePresenter:initRequire()
    app.game.GameTrendPresenter  = requireBRNN("app.game.brnn.GameTrendPresenter")
    app.game.GameListPresenter   = requireBRNN("app.game.brnn.GameListPresenter")
    app.game.GameBankerPresenter = requireBRNN("app.game.brnn.GameBankerPresenter")
end

-- 退出界面
function GamePresenter:exit()
    GamePresenter.super.exit(self)

    app.game.GameListPresenter = nil
    app.game.GameTrendPresenter = nil
    app.game.GameBankerPresenter = nil
    
    self:closeScheduleSendReady()
    self:closeSchedulerBankBtnCD()
    self:closeSchedulerTakeFirst()
    
    app.lobby.notice.BroadCastNode:stopActions()
    
    GamePresenter._instance = nil
end

-- 初始化UI
function GamePresenter:initScene()
    for i = 1, 5 do
        if self._gameHandCardNode[i] then
            self._gameHandCardNode[i]:resetHandCards()
            self._ui:getInstance():showImgNiuType(i, false)         
        end         
    end
    self:showBetBtnEnable() 
end

-- 处理玩家状态
function GamePresenter:onPlayerStatus(data)
    local player = app.game.PlayerData.getPlayerByNumID(data.ticketid)        
    if not player then        
        return
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
end

function GamePresenter:onSelfPlayerEnter()
    local hero = app.game.PlayerData.getHero()
    self._gamePlayerNodes[LOCAL_HERO_SEAT]:onPlayerEnter(hero)
    
    local heroseat = app.game.PlayerData.getHeroSeat()      
    local seats = app.game.GameData.getPlayerseat()
    if #seats ~= 0 then
        local isIn = false
        for i, seat in ipairs(seats) do
            if heroseat == seat then
                isIn = true
            end
        end
        if not isIn and not self._enter then
            self._ui:getInstance():showHint("wait")
            self._enter = true            
        end         
    end             
end

function GamePresenter:onSystemBankerEnter()   
    self._gamePlayerNodes[LOCAL_BANKER_SEAT]:onSystemBankerEnter()
end

function GamePresenter:onNiuPlayerReady(seat)
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

function GamePresenter:onNiuGamePrepare() 
    app.game.GameData.setTableStatus(zjh_defs.TableStatus.TS_PREPARE)
    
    if not app.game.GameData.getReady() then
        self:sendPlayerReady()
    end
end

-- 游戏开始
function GamePresenter:onNiuGameStart()   
    self._playing = true
    app.game.GameData.restDataEx()
    self._ui:getInstance():showHint()
    self._ui:getInstance():resetBetUI()    
    self._ui:getInstance():removeAllChip()
    for i = 1, 5 do
        if self._gameHandCardNode[i] then
            self._gameHandCardNode[i]:resetHandCards()
            self._ui:getInstance():showImgNiuType(i, false) 
        end         
    end

    self:showBetBtnEnable()
    
    self._ui:getInstance():showStartEffect()        
    
    self:playEffectByName("start")
    
    self:performWithDelayGlobal(
        function()            
            self._ui:getInstance():showClockEffect()
        end, 1)
                
    for i=1, 3 do        
        self:performWithDelayGlobal(function()
            if app.game.GamePresenter then
                self:playEffectByName("countdown")
            end            
        end, 9+i)            
    end
    self:playEffectByName("e_start")      
end


-- 发牌
function GamePresenter:onTakeFirst(callback)
    for i = 1, 5 do
        if self._gameHandCardNode[i] then
            self._gameHandCardNode[i]:resetHandCards() 
        end
    end
    self:openSchedulerTakeFirst(callback)
end


-- 游戏结束
function GamePresenter:onNiuGameOver(overs, players) 
    self._playing = false 
    app.game.GameData.setTableStatus(zjh_defs.TableStatus.TS_ENDING)
    app.game.GameData.setReady(false)
    app.game.GameData.setHistory(overs.winlose1, overs.winlose2, overs.winlose3, overs.winlose4)
    app.game.GameData.setPlayerLists(players)
    
    -- 停止下注
    self._ui:getInstance():showEndEffect() 
    self:playEffectByName("stop")          
    -- 提示
    self._ui:getInstance():showHint()
       
    local function takefirst()
        self:performWithDelayGlobal(function()
            local backcards = {}        
            for k, card in ipairs(overs.areacards) do
                if k <= 5  then
                    backcards[1] = backcards[1] or {}
                    table.insert(backcards[1], card)
                elseif k <= 10 then
                    backcards[2] = backcards[2] or {}
                    table.insert(backcards[2], card)
                elseif k <= 15 then
                    backcards[3] = backcards[3] or {}
                    table.insert(backcards[3], card)
                else
                    backcards[4] = backcards[4] or {}
                    table.insert(backcards[4], card)
                end
            end

            for key, cards in ipairs(backcards) do
                cards[4] = CV_BACK
            end

            local bcards = {}
            for key, var in ipairs(overs.bcards) do
                bcards[key] = var
            end
            bcards[4] = CV_BACK

            if self._gameHandCardNode[5] then
                self._gameHandCardNode[5]:resetHandCards()
                self._gameHandCardNode[5]:createCards(bcards)                
            end 
            for i=1, 4 do                          
                self:createNiuCards(i, backcards[i], -1)                            
            end
        end, 0.25)   
    end
    
    self:performWithDelayGlobal(function()
        self:onTakeFirst(takefirst)  
    end, 1.1)

    -- 飘金币
    local function goldFunc()
        -- 刷新列表
        self:updatePlayerList(players)
        
        local bankerObj = app.game.PlayerData.getPlayerByNumID(app.game.GameData.getBankerID())  
        self._gamePlayerNodes[LOCAL_BANKER_SEAT]:onPlayerEnter(bankerObj)
        
        local scorelist = {}         
        local b_score = 0
        local count = 0        
        for k, player in ipairs(players) do                               
            if player.seatinfo.ticketid == app.data.UserData.getTicketID() or player.seatinfo.ticketid == app.game.GameData.getBankerID() then
            else
                if player.area1 == 0 and player.area2 == 0 and player.area3 == 0 and player.area4 == 0 then
                    count = count + 1        
                    scorelist[count] = -1
                else                
                    count = count + 1        
                    scorelist[count] = player.bouns   
                end                        
            end
            
            if player.seatinfo.ticketid == app.game.GameData.getBankerID() then
                scorelist[LOCAL_BANKER_SEAT] = player.bouns                    
            end                      
        end
        
        if overs.area1 == 0 and overs.area2 == 0 and overs.area3 == 0 and overs.area4 == 0 then
            scorelist[LOCAL_HERO_SEAT] = -1
        else
            scorelist[LOCAL_HERO_SEAT] = overs.bouns  
        end
        if overs.bouns ~= 0 then
            if overs.bouns > 0 then
                self:playEffectByName("win")       
            else
                self:playEffectByName("lose")       
            end
        end
                                  
        self._ui:getInstance():showWinloseScore(scorelist)
        
        for k, score in pairs(scorelist) do
            if score and score > 0 then
                if self._gamePlayerNodes[k] then
                    self._gamePlayerNodes[k]:playWinEffect()
                end
            end
        end
        
        local history = app.game.GameData.getHisLists()       
        if app.game.GameTrendPresenter:isCurrentUI() then            
            app.game.GameTrendPresenter:getInstance():init(history) 
        end                
        
        self:performWithDelayGlobal(function()            
            self._ui:getInstance():resetBetUI()
            for i = 1, 5 do
                if self._gameHandCardNode[i] then
                    self._gameHandCardNode[i]:resetHandCards()
                    self._ui:getInstance():showImgNiuType(i, false) 
                end 
                
                self._ui:getInstance():showPnlFntMultVisible(i, false)
                self._ui:getInstance():showImgNobetVisible(i, false)           
            end
                      
            self._ui:getInstance():showSleepEffect()       
        end, 2)
    end
    
    -- 赢的区域
    local function lightFunc()
        local winlist = {}
        if overs.winlose1 == 1 then
            table.insert(winlist,1)
        end
        if overs.winlose2 == 1 then
            table.insert(winlist,2)
        end
        if overs.winlose3 == 1 then
            table.insert(winlist,3)
        end
        if overs.winlose4 == 1 then
            table.insert(winlist,4)            
        end
        if #winlist == 0 then
            self:playEffectByName("winall")          
        end
        if #winlist > 0 then
            for k, area in ipairs(winlist) do
                if k == #winlist then
                    self._ui:getInstance():showImgTouchAreaLight(area, goldFunc) 
                else
                    self._ui:getInstance():showImgTouchAreaLight(area) 
                end                
            end
        else
           goldFunc()                    
        end
        
        self:performWithDelayGlobal(function()            
            self._ui:getInstance():showChipBackOtherAction()
            self._ui:getInstance():resetBetUI()            
        end, 1)
    end
    -- 亮牌
    local function cardFunc()
        local areacards = {}        
        for k, card in ipairs(overs.areacards) do
            if k <= 5  then
                areacards[1] = areacards[1] or {}
                table.insert(areacards[1], card)
            elseif k <= 10 then
                areacards[2] = areacards[2] or {}
                table.insert(areacards[2], card)
            elseif k <= 15 then
                areacards[3] = areacards[3] or {}
                table.insert(areacards[3], card)
            else
                areacards[4] = areacards[4] or {}
                table.insert(areacards[4], card)
            end
        end
        
        local areatype = {
            [1] = overs.area1type,
            [2] = overs.area2type,
            [3] = overs.area3type,
            [4] = overs.area4type
        }  
        
        for i=1, 4 do
            areacards[i] = self:divideCards(areacards[i], areatype[i]) 
        end
        
        local areamult = {
            [1] = overs.mult1,
            [2] = overs.mult2,
            [3] = overs.mult3,
            [4] = overs.mult4
        }
        
        local areabet = {
            [1] = overs.area1,
            [2] = overs.area2,
            [3] = overs.area3,
            [4] = overs.area4
        }
        
        local areawin = {
            [1] = overs.winlose1,
            [2] = overs.winlose2,
            [3] = overs.winlose3,
            [4] = overs.winlose4
        }
    
        for i=1, 4 do           
            self:performWithDelayGlobal(function()
                if i<4 then
                    self:createNiuCards(i, areacards[i], areatype[i]) 
                else
                    self:createNiuCards(i, areacards[i], areatype[i], lightFunc()) 
                end
                
                self._ui:getInstance():showFntMultScore(i, areabet[i], areamult[i], areawin[i])            
            end, i*0.8)            
        end
    end
    
    self:performWithDelayGlobal(function()
        overs.bcards = self:divideCards(overs.bcards, overs.bcardtype) 
        self:createNiuCards(5, overs.bcards, overs.bcardtype, cardFunc)              
    end, 4.5)
    
    print("send ready 8") 
    -- 自动准备
    self:performWithDelayGlobal(function()               
        self:sendPlayerReady()
    end, 11) 
end

function GamePresenter:onNiuBankerBid(lists, info)    
    if #lists == nil then
    	return
    end
    app.game.GameData.setBankerLists(lists)     
    if lists[1].isSys == 0 then
        app.game.GameData.setBankerID(lists[1].seatinfo.ticketid)
        
        local player = app.game.PlayerData.getPlayerByNumID(lists[1].seatinfo.ticketid)
        self._gamePlayerNodes[LOCAL_BANKER_SEAT]:onPlayerEnter(player)    
                
        if lists[1].seatinfo.ticketid == app.data.UserData.getTicketID() and lists[1].bankernum == 0 then
        	self._ui:getInstance():showHint("banker")
            app.game.GameBankerPresenter:getInstance():showHint("banker")
        end              
    else
        app.game.GameData.setBankerID(SYSTEMID)
        
        self:onSystemBankerEnter()             
    end   
    
    if app.game.GameBankerPresenter:getInstance():isCurrentUI() then
        local players = {}    
        for i, var in ipairs(lists) do
            players[i] = players[i] or {}
            if lists[i].isSys == 0 then 
                players[i].seqid     = i    
                players[i].avatar    = var.seatinfo.avatar
                players[i].gender    = var.seatinfo.gender
                players[i].balance   = var.seatinfo.balance
                players[i].ticketid  = var.seatinfo.ticketid                        
                players[i].bankernum = var.bankernum         
            else
                players[i].seqid     = 1    
                players[i].avatar    = 1
                players[i].gender    = 0
                players[i].balance   = 10000000
                players[i].ticketid  = "系统庄家"               
                players[i].bankernum = -1   
            end                       
        end
        app.game.GameBankerPresenter:getInstance():init(players,self._schedulerBankBtnCD)
    end
        
    local players = app.game.GameData.getPlayerLists()        
    self:updatePlayerList(players)
    
    local isbanker = app.game.GameData.isHeroBanker()
    
    if isbanker then
        self._gameBtnNode:setBankerBtn()
    else
        self._gameBtnNode:setTxtHint(false,"banker")    
    end
    
    if info.ticketid == app.data.UserData.getTicketID() then
        if info.tipid == zjh_defs.NiuStatus.NIU100_BANKER_BID_TIPS_UP then
            app.game.GameBankerPresenter:getInstance():showHint("up")
            
        elseif info.tipid == zjh_defs.NiuStatus.NIU100_BANKER_BID_TIPS_DOWN then
            local bankerlist = app.game.GameData.getBankerLists()
            local flag = false
            if bankerlist[1].isSys == 0 then
                if bankerlist[1].seatinfo.ticketid == app.data.UserData.getTicketID() then
                    app.game.GameBankerPresenter:getInstance():showHint("dsuccess")
                    self._ui:getInstance():showHint("dsuccess")
                    flag = true
                end              
            end

            if not flag then
                app.game.GameBankerPresenter:getInstance():showHint("cancel")
            end
            self:openScheduleBankBtnCD(30)              
        elseif info.tipid == zjh_defs.NiuStatus.NIU100_BANKER_BID_TIPS_QUIT_ACTIVE then
            self._ui:getInstance():showHint("dsuccess")
            app.game.GameBankerPresenter:getInstance():showHint("dsuccess")    
        elseif info.tipid == zjh_defs.NiuStatus.NIU100_BANKER_BID_TIPS_BALANCE_NOT_ENOUGH then
            self._ui:getInstance():showHint("dless")
            app.game.GameBankerPresenter:getInstance():showHint("dless")
        elseif info.tipid == zjh_defs.NiuStatus.NIU100_BANKER_BID_TIPS_BANKED_TOO_MANY_TIMES then
            self._ui:getInstance():showHint("10")
            app.game.GameBankerPresenter:getInstance():showHint("10")
    	end
    end
end

function GamePresenter:onNiuBetFull()    
    app.game.GameData.setFull(true)

    for i=1, 6 do
        self._gameBtnNode:setBetBtnEnable(i, false)
    end
    self._selectBetIndex = -1
    self._gameBtnNode:setBetBtnLight(self._selectBetIndex)           
    self._ui:getInstance():showHint("full")    
end

-- 历史数据 
function GamePresenter:onNiuHistory(lists)     
    local winlose = {}
    for i=1, #lists do
        winlose[i] = winlose[i] or {}
        table.insert(winlose[i], lists[i].winlose1)
        table.insert(winlose[i], lists[i].winlose2)
        table.insert(winlose[i], lists[i].winlose3)
        table.insert(winlose[i], lists[i].winlose4)
    end
    
    app.game.GameData.setHisLists(winlose)
end

-- 玩家列表
function GamePresenter:onNiuTopSeat(players) 
    dump(players)
    app.game.GameData.setPlayerLists(players)    
    
    self:updatePlayerList(players)
end

-- 押注
function GamePresenter:onNiuBet(bets)
    app.game.PlayerData.updatePlayerRiches(bets.seat, 0, bets.balance)     
    
    local chip_1 = self:getChipIndex(bets.betarea1)
    local chip_2 = self:getChipIndex(bets.betarea2)
    local chip_3 = self:getChipIndex(bets.betarea3)
    local chip_4 = self:getChipIndex(bets.betarea4)
    
    local heroseat = app.game.PlayerData.getHeroSeat() 
    local localSeat = app.game.GameData.getLocalseatByServerseat(bets.seat)

    -- 自己下注
    if heroseat == bets.seat then
        -- 更新自己下注的金额
        app.game.GameData.setBetArea1(bets.betarea1)
        app.game.GameData.setBetArea2(bets.betarea2)
        app.game.GameData.setBetArea3(bets.betarea3)
        app.game.GameData.setBetArea4(bets.betarea4)
        
        local selfbet1 = app.game.GameData.getBetArea1()
        local selfbet2 = app.game.GameData.getBetArea2()
        local selfbet3 = app.game.GameData.getBetArea3()
        local selfbet4 = app.game.GameData.getBetArea4()
        
        -- 更新所有下注的总额
        self._ui:getInstance():showTxtTouchAreaBet(1, selfbet1, bets.sumarea1)
        self._ui:getInstance():showTxtTouchAreaBet(2, selfbet2, bets.sumarea2)
        self._ui:getInstance():showTxtTouchAreaBet(3, selfbet3, bets.sumarea3)
        self._ui:getInstance():showTxtTouchAreaBet(4, selfbet4, bets.sumarea4)
        
        local allbet = bets.betarea1 + bets.betarea2 + bets.betarea3 + bets.betarea4 
        self._ui:getInstance():showChipAction(chip_1, 1, LOCAL_HERO_SEAT) 
        self._ui:getInstance():showChipAction(chip_2, 2, LOCAL_HERO_SEAT) 
        self._ui:getInstance():showChipAction(chip_3, 3, LOCAL_HERO_SEAT)
        self._ui:getInstance():showChipAction(chip_4, 4, LOCAL_HERO_SEAT)

        self._ui:getInstance():movePlayerPnl(LOCAL_HERO_SEAT, allbet)         
        
--        if localSeat ~= -1 then
--            self._gamePlayerNodes[localSeat]:showTxtBalance(true, bets.balance)     
--        end
        self._gamePlayerNodes[LOCAL_HERO_SEAT]:showTxtBalance(true, bets.balance)    
    -- 他人下注    
    else
        -- 其他玩家
        if localSeat == -1 then
            self._ui:getInstance():showChipAction(chip_1, 1, OTHER_SEAT) 
            self._ui:getInstance():showChipAction(chip_2, 2, OTHER_SEAT) 
            self._ui:getInstance():showChipAction(chip_3, 3, OTHER_SEAT)
            self._ui:getInstance():showChipAction(chip_4, 4, OTHER_SEAT)           
            return 
        else
            local allbet = bets.betarea1 + bets.betarea2 + bets.betarea3 + bets.betarea4             
            self._ui:getInstance():showChipAction(chip_1, 1, localSeat) 
            self._ui:getInstance():showChipAction(chip_2, 2, localSeat) 
            self._ui:getInstance():showChipAction(chip_3, 3, localSeat)
            self._ui:getInstance():showChipAction(chip_4, 4, localSeat)
            
            self._ui:getInstance():movePlayerPnl(localSeat, allbet)     
            
            self._gamePlayerNodes[localSeat]:showTxtBalance(true, bets.balance)     
        end                        
    end
    
    -- 按钮触摸性
    self:showBetBtnEnable()
end

function GamePresenter:onRelinkEnter(player)
    print("onrelink enter")   
    self._playing = true
end

function GamePresenter:onNiuBankerResp(resp)
    local flag = false
    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        
    else
        print(resp.errorMsg)   
	end	
end
-- -----------------------------do----------------------------------
function GamePresenter:createNiuCards(area, cards, cardtype, callback)
    if self._gameHandCardNode[area] then
        self._gameHandCardNode[area]:resetHandCards()
        self._gameHandCardNode[area]:createCards(cards)
    end
    self._ui:getInstance():showImgNiuType(area, true, cardtype)    
    self:playEffectByName("w_niu_" .. cardtype)           
    if callback then
    	callback()
    end
end

function GamePresenter:updatePlayerList(players)
    print("update player list")    
    for i=1, 6 do
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
        if player:getTicketID() == app.data.UserData.getTicketID() or player:getTicketID() == app.game.GameData.getBankerID() then
        else                        
            count = count + 1        
            app.game.GamePresenter:getInstance():onPlayerEnter(player, count)            
        end                      
    end                
    app.game.GamePresenter:getInstance():onSelfPlayerEnter()			
end

function GamePresenter:showBetBtnEnable()        
    local isbanker = app.game.GameData.isHeroBanker()
    if isbanker then
    	self._gameBtnNode:setBankerBtn()
    	return
    else
        self._gameBtnNode:setTxtHint(false, "banker")
    end
    
    local balance = app.data.UserData.getBalance()    
    local enable = {}
    self._gameBtnNode:setTxtHint(false, "less")
    local full = app.game.GameData.getFull()
    if full then
        enable = {false, false, false, false, false, false}
    else
        if balance < 5000 then
            enable = {false, false, false, false, false, false}
            self._selectBetIndex = -1
            self._gameBtnNode:setTxtHint(true, "less")                       
        elseif balance < 10000 then
            enable = {true, true, true, true, false, false} 
            if self._selectBetIndex == -1 then
                self._selectBetIndex = 1   
            end            
        elseif balance < 50000 then
            enable = {true, true, true, true, true, false} 
            if self._selectBetIndex == -1 then
                self._selectBetIndex = 1   
            end           
        else
            enable = {true, true, true, true, true, true} 
            if self._selectBetIndex == -1 then
                self._selectBetIndex = 1   
            end       
        end
    end	
    
    for i, e in ipairs(enable) do
        self._gameBtnNode:setBetBtnEnable(i, e)
	end	
	
    self._gameBtnNode:setBetBtnLight(self._selectBetIndex)	
    
    self:showBtnEnableByBet()	
end

function GamePresenter:showBtnEnableByBet()
    local isbanker = app.game.GameData.isHeroBanker()
    if isbanker then
        self._gameBtnNode:setBankerBtn()
        return
    else
        self._gameBtnNode:setTxtHint(false,"banker")
    end
    
    local mult = app.game.GameConfig.getRoomID() * 5
    local balance = app.data.UserData.getBalance()
    local bet1 = app.game.GameData.getBetArea1()
    local bet2 = app.game.GameData.getBetArea2()
    local bet3 = app.game.GameData.getBetArea3()
    local bet4 = app.game.GameData.getBetArea4()
    
    local total = balance + bet1 + bet2 + bet3 + bet4
    local bet = bet1 + bet2 + bet3 + bet4
    
    local maxbet = total / mult
    local canbet = maxbet - bet
    local enable = {}
    
    if balance >= 5000 then
        local index = self:getChipIndexByBet(canbet)       
        if index == -1 then
            enable = {false, false, false, false, false, false}
            self._selectBetIndex = -1
            self._ui:getInstance():showHint("more")
        else            
        	for i=1,6 do
        		if i <= index then
        			enable[i] = true
        		else
                    enable[i] = false
        		end
        	end
            if self._selectBetIndex > index then
        		self._selectBetIndex = 1
        	end
        end
    else
        self._selectBetIndex = -1  
    end
    for i, e in ipairs(enable) do
        self._gameBtnNode:setBetBtnEnable(i, e)
    end
    self._gameBtnNode:setBetBtnLight(self._selectBetIndex)      
end

-- ----------------------------onclick-------------------------------
function GamePresenter:onTouchGoing()
    local history = app.game.GameData.getHisLists()
    app.game.GameTrendPresenter:getInstance():start(history) 
end

function GamePresenter:onTouchOther()
    local list = app.game.GameData.getPlayerLists()
    
    local players = {}
    for i, var in ipairs(list) do
        players[i] = players[i] or {}  
              
        players[i].seqid     = i    
        players[i].avatar    = var.seatinfo.avatar
        players[i].gender    = var.seatinfo.gender
        players[i].balance   = var.seatinfo.balance
        players[i].ticketid  = var.seatinfo.ticketid                   
        players[i].gamenum20 = var.gamenum20
        players[i].betnum20  = var.betnum20                         
    end
       
    app.game.GameListPresenter:getInstance():start(players)    
end

function GamePresenter:onTouchGoBanker()
    local list = app.game.GameData.getBankerLists()        
    local players = {}    
    for i, var in ipairs(list) do
        players[i] = players[i] or {}
        if list[i].isSys == 0 then 
            players[i].seqid     = i    
            players[i].avatar    = var.seatinfo.avatar
            players[i].gender    = var.seatinfo.gender
            players[i].balance   = var.seatinfo.balance
            players[i].ticketid  = var.seatinfo.ticketid                        
            players[i].bankernum = var.bankernum         
        else
            players[i].seqid     = 1    
            players[i].avatar    = 1
            players[i].gender    = 0
            players[i].balance   = 10000000
            players[i].ticketid  = "系统庄家"               
            players[i].bankernum = -1   
        end                       
    end
    
    app.game.GameBankerPresenter:getInstance():start(players, self._schedulerBankBtnCD)
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
    
    local full = app.game.GameData.getFull()
    if full then
        self._ui:getInstance():showHint("full")
        return
    end
    
    if app.data.UserData.getBalance() < 5000 then   
        self._ui:getInstance():showHint("less")
        return
    end
    
    -- 判断是否还有剩余押注
    local mult = app.game.GameConfig.getRoomID() * 5
    local balance = app.data.UserData.getBalance()
    local bet1 = app.game.GameData.getBetArea1()
    local bet2 = app.game.GameData.getBetArea2()
    local bet3 = app.game.GameData.getBetArea3()
    local bet4 = app.game.GameData.getBetArea4()

    local total = balance + bet1 + bet2 + bet3 + bet4
    local havebet = bet1 + bet2 + bet3 + bet4

    local maxbet = total / mult
    local canbet = maxbet - havebet
    
    if canbet < 100 then
        self._ui:getInstance():showHint("more")
        return
    end
    
    -- 发送押注
    local bet = self:getChipNumByIndex(self._selectBetIndex)  
    if type == 1 then
        self:sendPlayerBet(bet, 0, 0, 0)
        
    elseif type == 2 then	
        self:sendPlayerBet(0, bet, 0, 0)
        
    elseif type == 3 then 
        self:sendPlayerBet(0, 0, bet, 0)
        
    elseif type == 4 then 
        self:sendPlayerBet(0, 0, 0, bet)     
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

function GamePresenter:openScheduleBankBtnCD(time)
    local allTime = time
    
    local function flipIt(dt)
        time = time - dt
        if time <= 0 then
            -- 上庄按钮         
            app.game.GameBankerPresenter:getInstance():showBtnBankerEx()
            self:closeSchedulerBankBtnCD()                
            return        
        end
        
        local strTime = string.format("%d", math.ceil(time))        
        app.game.GameBankerPresenter:getInstance():showBtnCdTime(strTime)        
    end

    self:closeSchedulerBankBtnCD()
    self._schedulerBankBtnCD = scheduler:scheduleScriptFunc(flipIt, 0.1, false)
end 

function GamePresenter:closeSchedulerBankBtnCD()
    if self._schedulerBankBtnCD then
        scheduler:unscheduleScriptEntry(self._schedulerBankBtnCD)
        self._schedulerBankBtnCD = nil
    end
end

-- 发牌
local CARD_NUM = 5
function GamePresenter:openSchedulerTakeFirst(callback)
    local cards = {}             
    for i = 1, 5 do
        cards[i] = cards[i] or {}  
        for j=1, 37 do
            cards[i][j] = CV_BACK
        end
    end
    
    local seat = 5
    local cardNum = 1
    local f1,f2,f3,f4,f5 = false,false,false,false,false
            
    local function onInterval(dt)       	
        if cardNum <= 37 then
            if seat == 5 and not f5 then
                self:playEffectByName("send")
                f5 = true
            end                
            if self._gameHandCardNode[seat] then
                if (cardNum >= 6 and cardNum <= 8) or 
                    (cardNum >= 14 and cardNum <= 16) or 
                    (cardNum >= 22 and cardNum <= 24) or 
                    (cardNum >= 30 and cardNum <= 32) then
                else
                    self._gameHandCardNode[seat]:onTakeFirst(cards[seat][cardNum])
                end              
            end                
            cardNum = cardNum + 1
            if cardNum == 9 then
            	seat = 1
                if not f1 then
                    self:playEffectByName("send")
                    f1 = true
                end
            elseif cardNum == 17 then
                seat = 2                
                if not f2 then
                    self:playEffectByName("send")
                    f2 = true
                end
            elseif cardNum == 25 then 
                seat = 3
                if not f3 then
                    self:playEffectByName("send")
                    f3 = true
                end
            elseif cardNum == 33 then  
                seat = 4	
                if not f4 then
                    self:playEffectByName("send")
                    f4 = true
                end
            end
        else
            self:closeSchedulerTakeFirst()   
            for i=1,5 do
                self._gameHandCardNode[i]:playSortAction()                  
            end             
            if callback then                                
                callback()
            end       
        end           	
    end

    self:closeSchedulerTakeFirst()
    self._schedulerTakeFirst = scheduler:scheduleScriptFunc(onInterval, 0.05, false)
end

function GamePresenter:closeSchedulerTakeFirst()
    if self._schedulerTakeFirst then
        scheduler:unscheduleScriptEntry(self._schedulerTakeFirst)
        self._schedulerTakeFirst = nil
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
    elseif bet == 500 then
        index = 2
    elseif bet == 1000 then
        index = 3
    elseif bet == 5000 then
        index = 4
    elseif bet == 10000 then
        index = 5
    elseif bet == 50000 then
        index = 6
    end	
    return index
end

function GamePresenter:getChipIndexByBet(bet)
    local index = -1
    if bet < 100 then
        index = -1
    elseif bet < 500 then
        index = 1
    elseif bet < 1000 then
        index = 2
    elseif bet < 5000 then
        index = 3
    elseif bet < 10000 then
        index = 4
    elseif bet < 50000 then
        index = 5
    else
        index = 6    
    end 
    return index
end

function GamePresenter:getChipNumByIndex(index)
    local chip = -1
    if index == 1 then
        chip = 100
    elseif index == 2 then
        chip = 500
    elseif index == 3 then
        chip = 1000
    elseif index == 4 then
        chip = 5000
    elseif index == 5 then
        chip = 10000
    elseif index == 6 then
        chip = 50000     
    end 
    
    return chip
end

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
    
    
    for k, v in ipairs(numTab) do
        niuTab[#niuTab+k] = v
    end

    return niuTab
end

function GamePresenter:getCardNiuNum(id)
    local num = self:getCardNum(id)
    if num >= 10 then
        num = 10
    end
    return num   
end

-- ----------------------------request-------------------------------
-- 退出房间
function GamePresenter:sendLeaveRoom()
    local gameStream = app.connMgr.getGameStream()

    print("send leave room")
    local po = gameStream:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
        po:write_int32(sessionid)  
        gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_LEAVE_ROOM_REQ)  
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
    
    local tabInfo = app.game.GameData.getTableInfo()
    if tabInfo.status == zjh_defs.TableStatus.TS_IDLE 
        or tabInfo.status == zjh_defs.TableStatus.TS_PREPARE 
        or tabInfo.status == zjh_defs.TableStatus.TS_ENDING then                   
        
        local hero = app.game.PlayerData.getHero()   
        if hero then       
            print("hero is leave", hero:isLeave())
        end 
        local po = gameStream:get_packet_obj()
        local limit = app.game.GameConfig.getLimit()
        if hero and not hero:isLeave() and hero:getBalance() > limit and po then        
            print("send ready", hero:getSeat())
            local sessionid = app.data.UserData.getSession() or 222        
            po:writer_reset()
            po:write_int64(sessionid)
            gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU100_READY_REQ)
        end         
    else
        print("not ready table is busy")    
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

-- 下注
function GamePresenter:sendPlayerBet(area1, area2, area3, area4)
    local gameStream = app.connMgr.getGameStream()

    local isbanker = app.game.GameData.isHeroBanker()
    if isbanker then
    	print("return hero is banker")
    	return
    end
    print("send bet1111111",area1, area2, area3, area4)  
    local sessionid = app.data.UserData.getSession() or 222
    local po = gameStream:get_packet_obj()
    po:writer_reset()
    po:write_int32(area1)
    po:write_int32(area2)
    po:write_int32(area3)
    po:write_int32(area4)
    
    gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU100_BET_REQ)    
end

-- 上庄 1上2下
function GamePresenter:sendPlayerBanker(type)
    local gameStream = app.connMgr.getGameStream()

    local sessionid = app.data.UserData.getSession() or 222
    local po = gameStream:get_packet_obj()
    po:writer_reset()
    po:write_int32(type)
   
    gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU100_BANKER_BID_REQ)    
end

-- 音效相关
function GamePresenter:playGameMusic()
    app.util.SoundUtils.playMusic("game/brnn/sound/bgm_game.mp3")
end

function GamePresenter:playEffectByName(name)    
    local soundPath = "game/brnn/sound/"
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