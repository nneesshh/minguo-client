--[[
@brief 加载资源场景
]]
local LoadScene   = class("LoadScene")

LoadScene.csbPath = "csb/loading.csb"
LoadScene._schedulerProgress = nil
LoadScene._time = 0

local scheduler = cc.Director:getInstance():getScheduler()

function LoadScene:start()
    local scene = display.newScene("SceneLoad")
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

function LoadScene:exit()
    if self._rootNode then
        self._rootNode:removeFromParent(true)
        display.removeUnusedSpriteFrames()
    
        self._rootNode = nil
        self._children = {}
        self:closeSchedulerProgress()
    end
end

function LoadScene:showProgress(nPercent)
--    if not nPercent or nPercent < 0 then return end
--    local lbProcess = ccui.Helper:seekNodeByName(self._rootNode,"loadbar")
--    local lbHint = ccui.Helper:seekNodeByName(self._rootNode,"txt_hint")
--    if (not lbProcess) or (not lbHint) then return end 
--    lbProcess:setPercent(nPercent)
--    local strProcess = tostring(math.ceil(nPercent))
--    lbHint:setString(strProcess .. "%")
end

function LoadScene:startGame()
    self:exit()
    require("Start")
end

function LoadScene:flipIt(dt)
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

function LoadScene:openSchedulerProgress()
    self:closeSchedulerProgress()
    self._schedulerProgress = scheduler:scheduleScriptFunc(handler(self,self.flipIt), 0.05, false)
end

function LoadScene:closeSchedulerProgress()
    self._time = 0
    if self._schedulerProgress ~= nil then
        scheduler:unscheduleScriptEntry(self._schedulerProgress)
        self._schedulerProgress = nil
    end
end

return LoadScene
