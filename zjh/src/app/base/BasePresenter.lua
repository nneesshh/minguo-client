--[[
@brief  管理基类
]]
local app           = app

local BasePresenter = class("BasePresenter")
local scheduler = cc.Director:getInstance():getScheduler()
---------------- 子类需配置项目 ---------------
-- UI单例
BasePresenter._ui   = nil
----------------------------------------------

-- 单例
BasePresenter._instance      = nil

-- 声明静态单例 
-- @param self
-- @return _instance
function BasePresenter:getInstance()
    if self._instance == nil then
        self._instance = self:create()
    end

    return self._instance
end

-- 初始化 
function BasePresenter:ctor()
end

-- 启动UI
function BasePresenter:start( ... )
    self:startUI( ... )
    self:init( ... )
end

-- 打开界面
function BasePresenter:startUI( ... )
    self._ui:getInstance():start( self, ... )
end

-- 初始化(由子类单独实现)
function BasePresenter:init( ... )
end

-- 退出界面
function BasePresenter:exit()
    self._ui:getInstance():exit()
end

-- 判断是否当前界面
function BasePresenter:isCurrentUI()
    return self._ui:getInstance():isCurrentUI()
end

-- 打开提示框
function BasePresenter:dealHintStart(...)
    app.lobby.public.HintPresenter:getInstance():start(...)
end

-- 关闭提示框
function BasePresenter:dealHintExit()
    app.lobby.public.HintPresenter:getInstance():exit()
end

-- 打开loading提示框
function BasePresenter:dealLoadingHintStart(...)
   app.lobby.public.LoadingHintPresenter:getInstance():start(...)
end

-- 关闭loading提示框
function BasePresenter:dealLoadingHintExit()
    app.lobby.public.LoadingHintPresenter:getInstance():exit()
end

function BasePresenter:dealTxtHintStart(...)
    app.lobby.public.TextHintPresenter:getInstance():start(...)
end

function BasePresenter:performWithDelayGlobal(listener, time)
    local handle
    handle = scheduler:scheduleScriptFunc(
        function()
            scheduler:unscheduleScriptEntry(handle)
            listener()
        end, time, false)
    return handle
end

return BasePresenter
