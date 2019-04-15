--[[
@brief  加载提示界面
]]

local LoadingHintLayer = class("LoadingHintLayer", app.base.BaseLayer)

LoadingHintLayer.csbPath = "lobby/csb/hintload.csb"
LoadingHintLayer.canBack = false

local scheduler = cc.Director:getInstance():getScheduler()

local _schedulerTimeOut = nil

local function closeSchedulerTimeOut()
	if _schedulerTimeOut then
        scheduler:unscheduleScriptEntry(_schedulerTimeOut)
        _schedulerTimeOut = nil        
    end
end

function LoadingHintLayer:performWithDelayGlobal(listener, time)
    local handle
    handle = scheduler:scheduleScriptFunc(
        function()
            scheduler:unscheduleScriptEntry(handle)
            listener()
        end, time, false)
    return handle
end

function LoadingHintLayer:initUI(timeoutTxt, timeout)    
    -- 播放动画
    local node = self:seekChildByName("hint_node_effect")
    app.util.UIUtils.runEffectLoop(node, "jz", "lobby/effect","jiazhai", 0, 0, true)    

    -- 超时处理
    local function timeOutCallBack()
        self._presenter:showHint(timeoutTxt)
        _schedulerTimeOut = nil
        self:exit()
    end
    closeSchedulerTimeOut()
    _schedulerTimeOut = self:performWithDelayGlobal(timeOutCallBack, timeout)
end

function LoadingHintLayer:exit()
    closeSchedulerTimeOut()
    if not self:isCurrentUI() then
        return
    end
--    local node = self:seekChildByName("hint_node_effect")
--    node:stopAllActions()
--    node:removeAllChildren()
    LoadingHintLayer.super.exit(self)
end

return LoadingHintLayer