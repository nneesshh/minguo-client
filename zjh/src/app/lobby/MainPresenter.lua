--[[
@brief  主场景管理类
]]
local MainPresenter = class("MainPresenter", app.base.BasePresenter)

local socket        = require("socket")
-- UI
MainPresenter._ui   = requireLobby("app.lobby.MainScene")

local isHotpatch         = false

function MainPresenter:ctor()
    MainPresenter.super.ctor(self)
        
    app.util.uuid.randomseed(socket.gettime()*10000)
    self:createDispatcher()
end

function MainPresenter:init(gameid)
    self:initScene(gameid)
    self:playGameMusic()   
end

function MainPresenter:onEnter()
    if app.data.UserData.getLoginState() ~= 1 then
        app.lobby.login.LoginPresenter:getInstance():start()      
        
        if CC_AUTO_LOGIN then
            app.lobby.login.LoginPresenter:getInstance():dealAutoLogin() 
        end        
    end
    if CC_SHOW_LOGIN_DEBUG then
        app.lobby.debug.DebugPresenter:getInstance():start()
    end
end

function MainPresenter:createDispatcher()
   -- 大厅玩家数据
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_NICKNAME, handler(self, self.onNicknameUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_TICKETID, handler(self, self.onIDUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_AVATAR, handler(self, self.onAvatarUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BALANCE, handler(self, self.onBalanceUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BROADCAST, handler(self, self.onBroadCast))
end

function MainPresenter:initScene(gameid)
    isHotpatch = false
    self:reLoad()
    self:initDownload()
    if gameid and gameid ~= 4 then
        self:showPlazaLists(gameid)
    end    
end

function MainPresenter:reLoad()
    self:onNicknameUpdate()
    self:onIDUpdate()
    self:onAvatarUpdate()
    self:onBalanceUpdate()
end 

function MainPresenter:initDownload()
    local patch = {}    
    for k, gameid in pairs(app.Game.GameID) do
        if gameid == 1 or gameid == 2 or gameid == 3 then
            if not cc.FileUtils:getInstance():isFileExist(
                cc.FileUtils:getInstance():getWritablePath() .. app.Game.patchManifest[gameid]) then
                table.insert(patch, gameid)
            end
        end                
    end
    
    self._ui:getInstance():showImgDownload(patch)
end

-- 退出界面
function MainPresenter:exit()
    isHotpatch = false
    self._ui:getInstance():exit()
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

function MainPresenter:onBroadCast(text)
    if not self:isCurrentUI() then
        return
    end

    app.lobby.notice.BroadCastNode:create(self, text)
end

-- 显示场列表
function MainPresenter:showPlazaLists(gameid)
    local plazainfo = app.data.PlazaData.getPlazaList(gameid)
    
    if gameid ~= app.Game.GameID.LHD then
        self._ui:getInstance():showPlazaPnl(true)
        self._ui:getInstance():loadPlazaList(gameid , plazainfo)
    -- 直接进房间
    else
        self:reqJoinRoom(gameid, 1)            
    end       
end

-- 展示大厅
function MainPresenter:showLobby()
	self._ui:getInstance():showLobby()
end

-- 显示个人中心
function MainPresenter:showUserCenter()
    app.lobby.usercenter.UserCenterPresenter:getInstance():start()
end

-- 显示规则
function MainPresenter:showHelp(gameid)
    app.lobby.help.HelpPresenter:getInstance():start(gameid)
end

-- 显示设置
function MainPresenter:showSet()
    app.lobby.set.SetPresenter:getInstance():start(true)
end

-- 显示商城
function MainPresenter:showShop()
    app.lobby.shop.ShopPresenter:getInstance():start()
end

-- 显示邮件
function MainPresenter:showMail()
    app.lobby.mail.MailPresenter:getInstance():start()
end

function MainPresenter:showNotice()
    app.lobby.notice.NoticePresenter:getInstance():start()
end

function MainPresenter:showRank()
    app.lobby.rank.RankPresenter:getInstance():start()   
end

function MainPresenter:showSafe()
    app.lobby.safe.SafePresenter:getInstance():start()
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

function MainPresenter:reqHotpatch(gameid)    
    if CC_HOTPATCH then   
        if isHotpatch then
        	self:dealTxtHintStart("请耐心等待当前游戏更新完成再进行操作")
        	return
        end     
        local projManifest, savePath = "", ""
        if gameid == app.Game.GameID.ZJH then
            projManifest = "lobby/manifest/mf_zjh/project.manifest"
            savePath = "patch_zjh"
        elseif gameid == app.Game.GameID.JDNN then
            projManifest = "lobby/manifest/mf_jdnn/project.manifest"
            savePath = "patch_jdnn"
        elseif gameid == app.Game.GameID.QZNN then
            projManifest = "lobby/manifest/mf_qznn/project.manifest"
            savePath = "patch_qznn"     
        end

        if projManifest ~= "" and savePath ~= "" then
            -- 隐藏下载图标
            self._ui:getInstance():hideImgDownload(gameid)
            
            hcGame = HotpatchController:new(projManifest, savePath)
            hcGame:init(handler(self, self.onHotpatch))
            hcGame:doUpdate()
        else
            print("manifest is nil")    
        end 
    else
        self._ui:getInstance():hideImgDownload(gameid)
        self:showPlazaLists(gameid)         
    end
end

function MainPresenter:onHotpatch(info)
    -- 热更完成    
    if cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED == info.code then
        print("热更新完成")        
        isHotpatch = false
        if info.gameid == app.Game.GameID.ZJH then
            HotpatchRequire.reloadZJH()    
        elseif info.gameid == app.Game.GameID.JDNN then
            HotpatchRequire.reloadJDNN()   
        end
        self._ui:getInstance():showHotpatchProgress(false, info.percent, info.gameid)
        if info.gameid >= app.Game.GameID.ZJH then
            self:showPlazaLists(info.gameid)
        end        
    -- 已最新               
    elseif cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE == info.code then
        print("已经是最新啦")
        isHotpatch = false
        self._ui:getInstance():showHotpatchProgress(false, info.percent, info.gameid)
        self:showPlazaLists(info.gameid)
    -- 热更中    
    elseif cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION == info.code or
        cc.EventAssetsManagerEx.EventCode.ASSET_UPDATED == info.code then       
        self._ui:getInstance():showHotpatchProgress(true, info.percent, info.gameid)
    -- 发现新版本    
    elseif cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND == info.code then   
        isHotpatch = true 
    -- 热更出错       
    else
        isHotpatch = false
        self._ui:getInstance():showHotpatchProgress(false, info.percent, info.gameid)
        self:dealHintStart(info.tips)
    end
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
        po:write_int32(gameid) 
        po:write_int32(roomid)     

        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_ENTER_ROOM_REQ)     
    end 
end

function MainPresenter:playGameMusic()
    app.util.SoundUtils.playMusic("lobby/sound/lobbyBack.mp3")
end

return MainPresenter