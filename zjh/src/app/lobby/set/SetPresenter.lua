--[[
@brief  设置管理类
]]
local app = cc.exports.gEnv.app
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local SetPresenter = class("SetPresenter", app.base.BasePresenter)

local SetData = app.data.SetData
local localVersion = app.Game.localVersion
local patchVersion = app.Game.patchVersion

-- UI
SetPresenter._ui = requireLobby("app.lobby.set.SetLayer")

function SetPresenter:init(flag, gameid)
    self:initSetData()    
    self:initVersion(flag, gameid)   
end

function SetPresenter:initSetData()
    self._ui:getInstance():setMusic(SetData.isOpenMusic())
    self._ui:getInstance():setEffect(SetData.isOpenEffect())    
end

function SetPresenter:initVersion(flag, gameid)
	local versions = self:getAllVersion()
    self._ui:getInstance():setLobbyVersion(versions[0], flag)
    self._ui:getInstance():setGameVersion(versions[gameid], not flag)   
end

function SetPresenter:setMusic(flag)
    if flag then
        app.util.SoundUtils.musicOn()
    else
        app.util.SoundUtils.musicOff()
    end
    SetData.setOpenMusic(flag)
end

function SetPresenter:setEffect(flag)
    if flag then
        app.util.SoundUtils.effectOn()
    else
        app.util.SoundUtils.effectOff()
    end
    SetData.setOpenEffect(flag)
end

function SetPresenter:dealChangeAccount()
    self:dealHintStart("你确定要退出到登录选择界面么？",
        function(bFlag)
            self:exit()
            if bFlag then                
                app.data.UserData.setLoginState(-1)
                app.connMgr.close()
                app.lobby.login.LoginPresenter:getInstance():start(true) 
                app.lobby.login.LoginPresenter:getInstance():dealAccountLogin()     
            end
        end
        ,0)
end

function SetPresenter:getAllVersion()    
    local versionList = {}    
    for k, gameid in pairs(app.Game.GameID) do  
        local patchVer = cc.FileUtils:getInstance():getWritablePath() .. patchVersion[gameid]
        local localVer = localVersion[gameid]
        if cc.FileUtils:getInstance():isFileExist(patchVer) then            
            local jsonData = cc.FileUtils:getInstance():getStringFromFile(patchVer)
            if jsonData ~= "" then
                local deData = json.decode(jsonData)            
                versionList[gameid] = deData.version
            end           
        else
            local jsonData = cc.FileUtils:getInstance():getStringFromFile(localVer)
            if jsonData ~= "" then
                local deData = json.decode(jsonData)            
                versionList[gameid] = deData.version
            end  
        end                        
    end
    
    return versionList
end

return SetPresenter