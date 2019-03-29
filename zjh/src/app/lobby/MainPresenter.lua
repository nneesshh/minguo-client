--[[
@brief  主场景管理类
]]

local MainPresenter = class("MainPresenter", app.base.BasePresenter)
local ToolUtils     = app.util.ToolUtils
local scheduler     = cc.Director:getInstance():getScheduler()

-- UI
MainPresenter._ui   = require("app.lobby.MainScene")

function MainPresenter:ctor()
    MainPresenter.super.ctor(self)

    self:createDispatcher()
end

function MainPresenter:init(gameid)
    self:initScene(gameid)
end

function MainPresenter:createDispatcher()
   -- 大厅玩家数据
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_NICKNAME, handler(self, self.onNicknameUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_TICKETID, handler(self, self.onIDUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_AVATAR, handler(self, self.onAvatarUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BALANCE, handler(self, self.onBalanceUpdate))
end

function MainPresenter:updateConn(dt)
	upconn.update()
end

function MainPresenter:onEnter()
    scheduler:scheduleScriptFunc(handler(self,self.updateConn), 0.1, false)

    if app.data.UserData.getLoginState() ~= 1 then
        app.lobby.login.LoginPresenter:getInstance():start()
    end
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
    app.lobby.set.SetPresenter:getInstance():start()
end

-- 显示商城
function MainPresenter:showShop()
    app.lobby.shop.ShopPresenter:getInstance():start()
end

------------------------ request ------------------------

-- 请求加入房间
function MainPresenter:reqJoinRoom(gameid, index)
    local sessionid = app.data.UserData.getSession() or 222
    local plazainfo = app.data.PlazaData.getPlazaList(gameid)
    local roomid = plazainfo[index].roomid
    
    local po = upconn.upconn:get_packet_obj()
    if po == nil then
        print("po is nil")
    else
    
        app.game.GameEngine:getInstance():start(gameid)
    
        print("req",sessionid,roomid)
        po:writer_reset()
        po:write_int32(sessionid)  
        po:write_int32(roomid)       
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_ENTER_ROOM_REQ)
    end 
end

return MainPresenter