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
    print("SetData.isOpenMusic()",SetData.isOpenMusic())
    print("SetData.isOpenEffect()",SetData.isOpenEffect())
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
                app.lobby.login.LoginPresenter:getInstance():start()
                self:exit()
            end
        end
        ,0)
end

return SetPresenter