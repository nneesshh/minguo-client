
--[[
@brief  帮助管理类
]]
local app = cc.exports.gEnv.app
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local DebugPresenter = class("DebugPresenter", app.base.BasePresenter)

-- UI
DebugPresenter._ui = requireLobby("app.lobby.debug.DebugLayer")

function DebugPresenter:init()
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_CONNECT_STATE, handler(self, self.onState))
end



function DebugPresenter:onState()       
    if not self:isCurrentUI() then
        return
    end

    local state = app.connMgr.getState()
    self._ui:getInstance():updateState(state)
end

return DebugPresenter