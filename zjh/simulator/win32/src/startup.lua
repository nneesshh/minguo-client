--[[
@brief 启动页
]]
local startup   = class("startup")

startup.csbPath = "csb/loading.csb"
startup._schedulerProgress = nil
startup._time = 0

local scheduler = cc.Director:getInstance():getScheduler()

function startup:start()
    local scene = display.newScene("startup")
    local layer = cc.Layer:create()
    scene:addChild(layer)

    -- 加载csb文件
    if not self.csbPath then
        print(" csbPath are not configured. ")
    end

    self._rootNode = cc.CSLoader:createNodeWithVisibleSize(self.csbPath)
    layer:addChild(self._rootNode)
    
    local director = cc.Director:getInstance()
    if director:getRunningScene() then
        director:replaceScene(scene)
    else
        director:runWithScene(scene)
    end
    
    -- 加载假进度条
    self:openSchedulerProgress()
end

function startup:exit()
    if self._rootNode then
        print("strtup exit")
        self._rootNode:removeFromParent(true)
        display.removeUnusedSpriteFrames()
    
        self._rootNode = nil
        self._children = {}
        self:closeSchedulerProgress()
    end
end

function startup:showProgress(nPercent)
--    if not nPercent or nPercent < 0 then return end
--    local lbProcess = ccui.Helper:seekNodeByName(self._rootNode,"loadbar")
--    local lbHint = ccui.Helper:seekNodeByName(self._rootNode,"txt_hint")
--    if (not lbProcess) or (not lbHint) then return end 
--    lbProcess:setPercent(nPercent)
--    local strProcess = tostring(math.ceil(nPercent))
--    lbHint:setString(strProcess .. "%")
end

function startup:startGame()
    self:exit()
    require("start")
end

function startup:flipIt(dt)
    local allTime = 2
    print("2222222")
    self._time = self._time + dt
    local percent = self._time / allTime * 100
    
    print("percent is",percent)
    
    if self._time >= allTime or percent >= 100 then
        self:closeSchedulerProgress()
        self:startGame()
    end
    
    self:showProgress(percent)
end

function startup:openSchedulerProgress()
    self:closeSchedulerProgress()
    self._schedulerProgress = scheduler:scheduleScriptFunc(handler(self,self.flipIt), 0.05, false)
end

function startup:closeSchedulerProgress()
    self._time = 0
    if self._schedulerProgress ~= nil then
        scheduler:unscheduleScriptEntry(self._schedulerProgress)
        self._schedulerProgress = nil
    end
end

return startup
