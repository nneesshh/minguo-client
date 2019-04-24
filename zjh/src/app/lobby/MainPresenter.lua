--[[
@brief  主场景管理类
]]

local MainPresenter = class("MainPresenter", app.base.BasePresenter)

local socket        = require("socket")
-- UI
MainPresenter._ui   = require("app.lobby.MainScene")
local HEART_BEAT_TIMEOUT = 10
local receiveTime        = 0

function MainPresenter:ctor()
    MainPresenter.super.ctor(self)
        
    app.util.uuid.randomseed(socket.gettime()*10000)
    self:createDispatcher()
end

function MainPresenter:init(gameid)
    self:initScene(gameid)
    
    
end

function MainPresenter:onEnter()
    if app.data.UserData.getLoginState() ~= 1 then
        app.lobby.login.LoginPresenter:getInstance():start()
    end
    --app.lobby.debug.DebugPresenter:getInstance():start()
end

function MainPresenter:createDispatcher()
   -- 大厅玩家数据
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_NICKNAME, handler(self, self.onNicknameUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_TICKETID, handler(self, self.onIDUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_AVATAR, handler(self, self.onAvatarUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BALANCE, handler(self, self.onBalanceUpdate))
end

function MainPresenter:initScene(gameid)
    self:reLoad()
    if gameid then
        self:showPlazaLists(gameid)
    end    
end

function MainPresenter:reLoad()
    self:onNicknameUpdate()
    self:onIDUpdate()
    self:onAvatarUpdate()
    self:onBalanceUpdate()
end 

------------------------ 信息更新 ------------------------
function MainPresenter:onIDUpdate()
    if not self:isCurrentUI() then
        return
    end

    local id = app.data.UserData.getTicketID()
    self._ui:getInstance():setID(id)
end

function MainPresenter:onNicknameUpdate()
    if not self:isCurrentUI() then
        return
    end

    local nickname = app.data.UserData.getNickname()
    self._ui:getInstance():setNickname(nickname)
end

function MainPresenter:onAvatarUpdate()
    if not self:isCurrentUI() then
        return
    end

    local avator = app.data.UserData.getAvatar()
    local gender = app.data.UserData.getGender()
    self._ui:getInstance():setAvatar(avator, gender)    
end

function MainPresenter:onBalanceUpdate()
    if not self:isCurrentUI() then
        return
    end

    local balance = app.data.UserData.getBalance()
    self._ui:getInstance():setBalance(balance)
end

-- 显示场列表
function MainPresenter:showPlazaLists(gameid)
    local plazainfo = app.data.PlazaData.getPlazaList(gameid)
    
    self._ui:getInstance():showPlazaPnl(true)
    self._ui:getInstance():loadPlazaList(gameid , plazainfo)    
end

-- 显示个人中心
function MainPresenter:showUserCenter()
    app.lobby.usercenter.UserCenterPresenter:getInstance():start()
end

-- 显示规则
function MainPresenter:showHelp()
    app.lobby.help.HelpPresenter:getInstance():start()
end

-- 显示设置
function MainPresenter:showSet()
    app.lobby.set.SetPresenter:getInstance():start(true)
end

-- 显示商城
function MainPresenter:showShop()
    app.lobby.shop.ShopPresenter:getInstance():start()
end

-- 安卓返回键
-- 在主场景时提示退出游戏
function MainPresenter:clickBack()
    self:dealHintStart("客官,您确定要离开吗？",
        function(bFlag)
            if bFlag then
                cc.Director:getInstance():endToLua()
            end
        end
        , 0)
end

function MainPresenter:showErrorMsg(code)
    self:dealLoadingHintExit()
    local hintTxt = ""
    if code == zjh_defs.ErrorCode.ERR_OUT_OF_LIMIT then
        hintTxt = "亲，你身上的金币不太多了噢~ 请换个房间或者再补充点金币吧！"
    elseif code == zjh_defs.ErrorCode.ERR_NO_FREE_TABLE then
        hintTxt = "未知错误，请联系客服处理！"
    elseif code == zjh_defs.ErrorCode.ERR_ROOM_OR_TABLE_INVALID then
        hintTxt = "未知错误，请联系客服处理！"   
	end
    self:dealHintStart(hintTxt,
        function(bFlag)
            if bFlag then
                app.lobby.shop.ShopPresenter:getInstance():start()  
            end
        end
        , 1)
end

function MainPresenter:loadingHintExit()
    self:dealLoadingHintExit()
end

------------------------ request ------------------------
-- 请求加入房间
function MainPresenter:reqJoinRoom(gameid, index)
    local sessionid = app.data.UserData.getSession() or 222
    local plazainfo = app.data.PlazaData.getPlazaList(gameid)
    local roomid = plazainfo[index].roomid
    local base = plazainfo[index].base
    local limit = plazainfo[index].lower
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil and roomid then   
        self:dealLoadingHintStart("正在加入房间")      
        app.game.GameEngine:getInstance():start(gameid, base, limit)
    
        po:writer_reset()
        po:write_int32(sessionid)  
        po:write_int32(roomid)     
        
        if gameid == app.Game.GameID.ZJH then
            upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_ENTER_ROOM_REQ)
        elseif gameid == app.Game.GameID.JDNN then	
            upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_ENTER_ROOM_REQ)
        end          
    end 
end

return MainPresenter