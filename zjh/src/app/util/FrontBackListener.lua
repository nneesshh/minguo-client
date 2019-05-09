--[[
@brief  FrontBackListener 前后台切换监听
]]

local FrontBackListener = class("FrontBackListener")

FrontBackListener._instance  = nil
FrontBackListener._eventDispatcher = nil

function FrontBackListener:getInstance()
    if self._instance == nil then
        self._instance = self:create()
    end
    return self._instance
end

function FrontBackListener:start()
    self:initListener()
end

function FrontBackListener:initListener()
    print("init front back")
    self._eventDispatcher = cc.Director:getInstance():getEventDispatcher()

    local customListenerBg = cc.EventListenerCustom:create("event_did_enter_background", handler(self, self.backGroundCallFunc))
    self._eventDispatcher:addEventListenerWithFixedPriority(customListenerBg, 1)
    local customListenerFg = cc.EventListenerCustom:create("event_will_enter_foreground", handler(self, self.frontGroundCallFunc))
    self._eventDispatcher:addEventListenerWithFixedPriority(customListenerFg, 1)
end

-- 切换到后台时响应函数
function FrontBackListener:backGroundCallFunc()
    print("切换到后台")
end

-- 切换到前台时响应函数
function FrontBackListener:frontGroundCallFunc()
    print("切换到前台")
	app.util.SoundUtils.resetMusicVolume()
	app.util.SoundUtils.resetEffectVolume()
end

return FrontBackListener