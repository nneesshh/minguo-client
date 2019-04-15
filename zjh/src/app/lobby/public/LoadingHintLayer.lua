--[[
@brief  加载提示界面
]]

local LoadingHintLayer = class("LoadingHintLayer", app.base.BaseLayer)

LoadingHintLayer.csbPath = "lobby/csb/hintload.csb"
LoadingHintLayer.canBack = false

local scheduler = cc.Director:getInstance():getScheduler()

local _schedulerTimeOut = nil
local _schedulerLoading = nil
local _waitTime = 0

local function unAllScheduler()
    _waitTime = 0
    
    if _schedulerTimeOut then
        scheduler:unscheduleScriptEntry(_schedulerTimeOut)
        _schedulerTimeOut = nil        
    end
    
    if _schedulerLoading then
        scheduler:unscheduleScriptEntry(_schedulerLoading)
        _schedulerLoading = nil        
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

function LoadingHintLayer:initUI(txt, timeoutTxt, timeout)    
    -- 播放动画
    local node = self:seekChildByName("hint_node_effect")
    app.util.UIUtils.runEffectLoop(node, "jz", "lobby/effect","jiazhai", 0, 0, true)    

    -- 超时处理
    unAllScheduler()    
    
    if txt ~= "" then
        local hint = self:seekChildByName("hint_load_txt")
        local function runLoading(dt)
            _waitTime = _waitTime + dt + 0.1
            local t = math.floor(_waitTime) % 3

            if t == 0 then
                hint:setString(" "..txt..".")
            elseif t == 1 then
                hint:setString("  "..txt.."..")
            elseif t == 2 then
                hint:setString("   "..txt.."...")
            end
        end
        _schedulerLoading = scheduler:scheduleScriptFunc(runLoading, 0.1, false)
    end
        
    local function timeOutCallBack()
        self._presenter:showHint(timeoutTxt)
        _schedulerTimeOut = nil
        self:exit()
    end
    _schedulerTimeOut = self:performWithDelayGlobal(timeOutCallBack, timeout)
end

function LoadingHintLayer:exit()
    unAllScheduler()
    if not self:isCurrentUI() then
        return
    end

    LoadingHintLayer.super.exit(self)
end

return LoadingHintLayer