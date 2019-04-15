--[[
@brief  主场景管理类
]]

local MainPresenter = class("MainPresenter", app.base.BasePresenter)
local ToolUtils     = app.util.ToolUtils
local scheduler     = cc.Director:getInstance():getScheduler()
local socket        = require("socket")
-- UI
MainPresenter._ui   = require("app.lobby.MainScene")
local HEART_BEAT_TIMEOUT = 10
local receiveTime        = 0

function MainPresenter:ctor()
    MainPresenter.super.ctor(self)    
    self:createDispatcher()
    app.util.uuid.randomseed(socket.gettime()*10000)
end

function MainPresenter:init(gameid)
    self:initScene(gameid)
end

function MainPresenter:onEnter()
    scheduler:scheduleScriptFunc(handler(self,self.updateConn), 0.1, false)
    scheduler:scheduleScriptFunc(handler(self,self.reqHeartbeat), 10, false)
    scheduler:scheduleScriptFunc(handler(self,self.checkTimeout), 15, false)
       
    if app.data.UserData.getLoginState() ~= 1 then
        app.lobby.login.LoginPresenter:getInstance():start()
    end
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
    app.lobby.set.SetPresenter:getInstance():start("lobby")
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
	   hintTxt = "金币不足,请换个房间或者再补充点金币吧!"
    elseif code == zjh_defs.ErrorCode.ERR_NO_FREE_TABLE then
        hintTxt = "房间不足,请联系客服处理!"
    elseif code == zjh_defs.ErrorCode.ERR_ROOM_OR_TABLE_INVALID then
        hintTxt = "房间或桌子无效,请联系客服处理!"   
	end
    self:dealHintStart(hintTxt,
        function(bFlag)
            if bFlag then
                app.lobby.shop.ShopPresenter:getInstance():start()  
            end
        end
        , 1)
end

function MainPresenter:showSuccessMsg()
    self:dealLoadingHintExit()
end

function MainPresenter:checkTimeout()
	local nowTime = os.time()
    if nowTime - receiveTime > HEART_BEAT_TIMEOUT then
		print("die")
	else
	   print("beat ")	
	end
end

------------------------ request ------------------------
-- 请求加入房间
function MainPresenter:reqJoinRoom(gameid, index)
    local sessionid = app.data.UserData.getSession() or 222
    local plazainfo = app.data.PlazaData.getPlazaList(gameid)
    local roomid = plazainfo[index].roomid
    local base = plazainfo[index].base
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then   
        self:dealLoadingHintStart("正在加入房间")      
        app.game.GameEngine:getInstance():start(app.Game.GameID.ZJH, base)
    
        po:writer_reset()
        po:write_int32(sessionid)  
        po:write_int32(roomid)       
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_ENTER_ROOM_REQ)
    end 
end

function MainPresenter:reqHeartbeat()
    local po = upconn.upconn:get_packet_obj()
    local sessionid = app.data.UserData.getSession() or 222
    if po ~= nil then        
        po:writer_reset()
        po:write_int32(sessionid)                                     
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_HEART_BEAT_REQ)            
    end
end

function MainPresenter:respHeartbeat()    
    receiveTime = os.time()    
end

return MainPresenter