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

local LOCAL_HERO_SEAT   = 3
local CV_BACK           = 0
local OTHER_SEAT        = 8
-- 初始化
function GamePresenter:init(...)
    self._maxPlayerCnt = app.game.PlayerData.getMaxPlayerCount() or 7
    self._selectBetIndex = -1
    
    self:playGameMusic()  
    self:initRequire()
    self:initPlayerNode()
    self:initBtnNode()
    self:initMenuNode()   
    self:initScheduler()   
    
    self:showBetBtnEnable() 
    
    self._playing = false  
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

end

function GamePresenter:initRequire()
    app.game.GameTrendPresenter = requireLHD("app.game.lhd.GameTrendPresenter.lua")
    app.game.GameListPresenter  = requireLHD("app.game.lhd.GameListPresenter.lua")
end

-- 退出界面
function GamePresenter:exit()
    GamePresenter.super.exit(self)

    app.game.GameListPresenter = nil
    app.game.GameTrendPresenter = nil
    
    GamePresenter._instance = nil
end

-- 处理玩家状态
function GamePresenter:onPlayerStatus(data)
    local player = app.game.PlayerData.getPlayerByNumID(data.ticketid)        
    if not player then
        print("on player status no player")
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
    app.game.GameData.removeSeatByTicketid(numID)
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
            app.game.GameData.removeSeatByTicketid(numID)
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
        for i = 1, self._maxPlayerCnt do
            if self._gamePlayerNodes[i] then
                self._gamePlayerNodes[i]:onResetTable()
            end
        end        
    -- 某个玩家离开将该节点隐藏
    else
        local localSeats = app.game.GameData.getSeatByTicketid(player:getTicketID())
        if localSeats == -1 then
            print("leave seat is not sit")
            return
        end 

        for i, seat in ipairs(localSeats) do
            if self._gamePlayerNodes and self._gamePlayerNodes[seat] then
                self._gamePlayerNodes[seat]:onPlayerLeave() 
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
    local localSeats = app.game.GameData.getSeatByTicketid(player:getTicketID())
    if localSeats == -1 then
    	print("enter seat is error")
    	return
    end 

    for i, seat in ipairs(localSeats) do
        if self._gamePlayerNodes and self._gamePlayerNodes[seat] then
            self._gamePlayerNodes[seat]:onPlayerEnter(player) 
        end 
    end   

--    local seats = app.game.GameData.getPlayerseat()
--    if #seats ~= 0 then
--        local isIn = false
--        for i, seat in ipairs(seats) do
--            if player:getSeat() == seat then
--                isIn = true
--            end
--        end
--        if not isIn then
--            if localSeats[1] == 3 then
--                self._ui:getInstance():showPnlHint(true, GE.hintType.LHD_WAIT)                 
--            end
--            app.game.PlayerData.updatePlayerStatus(player:getSeat(), 4)
--        end         
--    end
end

function GamePresenter:onPlayerSitdown(player) 
end

function GamePresenter:onChangeTable(flag)    
end

function GamePresenter:onLhdGamePrepare()    
end

-- 游戏开始
function GamePresenter:onLhdGameStart()   
    self._playing = true
    app.game.GameData.restDataEx()
    self._ui:getInstance():resetBetUI()
    self._ui:getInstance():resetLongHuCards()
    self._ui:getInstance():removeAllChip()
    self:showBetBtnEnable()
    
    self._ui:getInstance():showStartEffect()        
    
    self:performWithDelayGlobal(
        function()
            self._ui:getInstance():showClockEffect()
        end, 1)
end

-- 游戏结束
function GamePresenter:onLhdGameOver(overs, players)
    self._playing = false 
    app.game.GameData.setHistory(overs.seqid, overs.cardtype, overs.cards)
    app.game.GameData.setPlayerLists(players)
    -- 停止下注
    self._ui:getInstance():showEndEffect()   
    -- 刷新列表
    self:updatePlayerList(players)  
    -- VS
    self._ui:getInstance():showVSEffect()
    
    -- 飘金币
    local function goldFunc()
        local scorelist = {}
        local ids = {}    
        for i, player in ipairs(players) do
            if #scorelist < 2 then
                table.insert(scorelist, player.bouns) 
                table.insert(ids, player.ticketid)
            end          
        end    
        if #scorelist == 1 then
            scorelist[2] = -1
            ids[2] = -1
        end
        scorelist[3] = overs.bouns
        ids[3] = overs.ticketid

        -- 其他人
        for i, player in ipairs(players) do
            if player.ticketid ~= ids[1] and player.ticketid ~= ids[2] and player.ticketid ~= ids[3] and #scorelist < 7 then
                table.insert(scorelist, player.bouns)                                         
            end
        end

        self._ui:getInstance():showWinloseScore(scorelist)

        for i=1, #scorelist do
            if scorelist[i] > 0 then
                self._gamePlayerNodes[i]:playWinEffect()            
            end
        end
    end
    
    local function lightFunc()
        self._ui:getInstance():showWinLight(overs.cardtype, goldFunc) 
        
        -- 筹码返回
        local betdetail = app.game.GameData.getBetDetail()
        for localseat, detail in ipairs(betdetail) do        
            self._ui:getInstance():showChipBackAction(localseat, detail)            
        end

        self:performWithDelayGlobal(function()
            self._ui:getInstance():showChipBackOtherAction()
        end, 1)
    end
    
    local function huFunc()
        self._ui:getInstance():createLongHuCard(overs.cards[2], 2, lightFunc)
    end
    
    -- 龙牌
    self._ui:getInstance():createLongHuCard(overs.cards[1], 1, huFunc)
    
    local history = app.game.GameData.getHistory()    
    self._ui:getInstance():addHistory(history)      
    if app.game.GameTrendPresenter:isCurrentUI() then
        app.game.GameTrendPresenter:getInstance():updateTrendOne(overs.cardtype, history) 
    end
    
    -- 自动准备
    self:performWithDelayGlobal(function()
        print("send ready 10")

        self:sendPlayerReady()
    end, 10) 
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
    
    -- 更新所有下注的总额
    self._ui:getInstance():setLongTxt(bets.longsum)
    self._ui:getInstance():setHuTxt(bets.husum)
    self._ui:getInstance():setHeTxt(bets.hesum)     
        
    local numid = app.game.PlayerData.getNumIDBySeat(bets.seat)
    local localSeats = app.game.GameData.getSeatByTicketid(numid)
    
    print("bet seat is", bets.seat, numid)
    
    -- 按钮触摸性
    self:showBetBtnEnable()

    local chip_long = self:getChipIndex(bets.long)
    local chip_hu = self:getChipIndex(bets.hu)
    local chip_he = self:getChipIndex(bets.he)
        
    local heroseat = app.game.PlayerData.getHeroSeat()    
    if localSeats == -1 then 
        print("localseat",chip_long, chip_hu, chip_he)   
        self._ui:getInstance():showChipAction(chip_long, GECT.LHD_LONG, OTHER_SEAT) 
        self._ui:getInstance():showChipAction(chip_hu, GECT.LHD_HU, OTHER_SEAT) 
        self._ui:getInstance():showChipAction(chip_he, GECT.LHD_HE, OTHER_SEAT)
        
        return 
    else
        print("more than 1")
        dump(localSeats)
        for i, seat in ipairs(localSeats) do
            if chip_long ~= -1 then
                app.game.GameData.setBetDetail(seat, chip_long)
                self._ui:getInstance():showChipAction(chip_long, GECT.LHD_LONG, seat)       
            elseif chip_hu ~= -1 then
                app.game.GameData.setBetDetail(seat, chip_hu)
                self._ui:getInstance():showChipAction(chip_hu, GECT.LHD_HU, seat)
            elseif chip_he ~= -1 then
                app.game.GameData.setBetDetail(seat, chip_he)
                self._ui:getInstance():showChipAction(chip_he, GECT.LHD_HE, seat)
            end
        end
    end     
    
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
        
        self._gamePlayerNodes[LOCAL_HERO_SEAT]:showTxtBalance(true, bets.balance)    
    -- 他人下注    
    else
        for i, seat in ipairs(localSeats) do
            if self._gamePlayerNodes and self._gamePlayerNodes[seat] then
                self._gamePlayerNodes[seat]:showTxtBalance(true, bets.balance) 
            end 
        end                                
    end
end

-- -----------------------------do----------------------------------
function GamePresenter:updatePlayerList(players)
    local ids = {}
    for i, player in ipairs(players) do
        table.insert(ids, player.seatinfo.ticketid)
        
        if app.game.PlayerData then
            app.game.PlayerData.onPlayerInfo(player.seatinfo)
        end  
	end

    local newids = {}
    local selfid = app.data.UserData.getTicketID()
    -- 大富豪、神算子    
    if #ids >= 2 then
        for k, id in ipairs(ids) do
            if #newids < 2 then
                table.insert(newids,id)
            end
        end
    elseif #ids == 1 then
        newids[1] = ids[1] 
        newids[2] = -1 
    end
    
    -- 自己 
    newids[3] = selfid                               
    
    -- 其他人
    for k, id in ipairs(ids) do
        if id ~= newids[1] and id ~= newids[2] and id ~= newids[3] and #newids < 7 then
            table.insert(newids,id)                                         
        end
    end

    app.game.GameData.setSitplayers(newids)
    
    for k, id in ipairs(newids) do               
        local player = app.game.PlayerData.getPlayerByNumID(id)
        if player then                    
            app.game.GamePresenter:getInstance():onPlayerEnter(player)              
        end                    
    end
end

function GamePresenter:showBetBtnEnable()
    local balance = nil
    if app.game.PlayerData then
        local hero = app.game.PlayerData.getHero()
        if hero then
            balance = hero:getBalance()       
        end 
    end
    if not balance then
    	return
    end
	local enable = {}
    self._ui:getInstance():showPnlHint(false)  	
	if balance < 5000 then
        enable = {false, false, false, false, false}
        self._selectBetIndex = -1
        
        self._ui:getInstance():showPnlHint(true, GE.hintType.LHD_LESS)                       
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
    
    if self._selectBetIndex == -1 then
        self:dealTxtHintStart("请先选中筹码后在进行下注")  
        return
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

-- ------------------------------show ui------------------------------



-- -----------------------------schedule------------------------------



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
--    local heroseat = app.game.PlayerData.getHeroSeat()
--    local player = app.game.PlayerData.getPlayerByServerSeat(heroseat)    
--    if player:isPlaying() then
--        self:dealTxtHintStart("游戏中,暂无法离开！")            
--    else
        local po = upconn.upconn:get_packet_obj()
        if po ~= nil then
            local sessionid = app.data.UserData.getSession() or 222
            po:writer_reset()
            po:write_int32(sessionid)  
            upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_LEAVE_ROOM_REQ)
--        end     
    end
end

-- 准备
function GamePresenter:sendPlayerReady()
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