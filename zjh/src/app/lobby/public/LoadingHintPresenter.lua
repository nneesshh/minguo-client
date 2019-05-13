--[[
@brief  加载提示界面管理
]]
local app                    = app

local LoadingHintPresenter   = class("LoadingHintPresenter", app.base.BasePresenter)

LoadingHintPresenter._ui  = requireLobby("app.lobby.public.LoadingHintLayer")

local DEFAULT_TIME_OUT = 15

--[[
缓冲提示，超时提示，超时时间
例.app.lobby.public.LoadingHintPresenter:getInstance():start("正在努力登录中","登录超时请重试哦！")
]]--
function LoadingHintPresenter:start(txt, timeoutTxt, timeout)
    txt = txt or ""
    if timeoutTxt == nil or timeoutTxt == "" then
        timeoutTxt = "连接超时，请检查手机网络"
    end
    timeout = timeout or DEFAULT_TIME_OUT
    
    self._ui:getInstance():start(self, txt, timeoutTxt, timeout)  
end

function LoadingHintPresenter:exit()
    self._ui:getInstance():exit()
end

function LoadingHintPresenter:showHint(timeoutTxt)
    app.lobby.public.HintPresenter:getInstance():start(timeoutTxt)
end

return LoadingHintPresenter