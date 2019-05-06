--[[
@brief  设置管理类
]]

local SetPresenter = class("SetPresenter", app.base.BasePresenter)

local SetData = app.data.SetData

-- UI
SetPresenter._ui = requireLobby("app.lobby.set.SetLayer")

function SetPresenter:init()
    self:initSetData()
end

function SetPresenter:initSetData()
    self._ui:getInstance():setMusic(SetData.isOpenMusic())
    self._ui:getInstance():setEffect(SetData.isOpenEffect())    
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
            if bFlag then
                self:exit()
                app.data.UserData.setLoginState(-1)
                app.Connect:getInstance():close()              
                app.lobby.login.LoginPresenter:getInstance():start(true) 
                app.lobby.login.LoginPresenter:getInstance():dealAccountLogin()     
            end
        end
        ,0)
end

return SetPresenter