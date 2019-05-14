--[[
@brief  商城管理类
]]

local SafePresenter = class("SafePresenter",app.base.BasePresenter)
SafePresenter._ui = requireLobby("app.lobby.safe.SafeLayer")

function SafePresenter:init()
    self:createDispatcher()

    self:initBankInfo()
end

function SafePresenter:createDispatcher()
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BANK, handler(self, self.onBankUpdate))    
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BALANCE, handler(self, self.onBalanceUpdate))
end

function SafePresenter:initBankInfo()
    self:onBankUpdate()
    self:onBalanceUpdate()	
end

function SafePresenter:onBankUpdate()
    if not self:isCurrentUI() then
        return
    end

    local bank = app.data.UserData.getBank()
    self._ui:getInstance():setBank(bank)
end

function SafePresenter:onBalanceUpdate()
    if not self:isCurrentUI() then
        return
    end

    local balance = app.data.UserData.getBalance()
    self._ui:getInstance():setBalance(balance)
end

function SafePresenter:getMaxGold(type)
	if type == "put" then
        return app.data.UserData.getBalance()
	elseif type == "out" then
        return app.data.UserData.getBank()	
	end
end

-- send
function SafePresenter:reqPut(num)
    self:performWithDelayGlobal(
        function()
            local po = upconn.upconn:get_packet_obj()
            if po ~= nil then
                po:writer_reset()
                po:write_int64(num)                  
                local sessionid = app.data.UserData.getSession() or 222
                upconn.upconn:send_packet(sessionId, zjh_defs.MsgId.MSGID_REGISTER_REQ)                       
            end              
        end, 0.2)
end

function SafePresenter:onPutCallback(data)
    if data.errcode == zjh_defs.ErrorCode.ERR_SUCCESS then
        app.data.UserData.setSafeBalance(data.safebalance)
        app.data.UserData.setBalance(data.balance)
        
        self._ui:getInstance():resetEnterNum()
    else
        self:dealTxtHintStart("存入失败")
	end
end

function SafePresenter:reqOut(num)
    self:performWithDelayGlobal(
        function()
            local po = upconn.upconn:get_packet_obj()
            if po ~= nil then
                po:writer_reset()
                po:write_int64(-num)                  
                local sessionid = app.data.UserData.getSession() or 222
                upconn.upconn:send_packet(sessionId, zjh_defs.MsgId.MSGID_REGISTER_REQ)                       
            end              
        end, 0.2)
end

function SafePresenter:onOutCallback(data)
    if data.errcode == zjh_defs.ErrorCode.ERR_SUCCESS then
        app.data.UserData.setSafeBalance(data.safebalance)
        app.data.UserData.setBalance(data.balance)
        
        self._ui:getInstance():resetEnterNum()
    else
        self:dealTxtHintStart("取出失败")
    end
end
    
return SafePresenter