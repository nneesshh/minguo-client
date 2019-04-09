--[[
@brief 启动页
]]
local startup   = class("startup")

startup.csbPath = "lobby/csb/loading.csb"
startup._schedulerProgress = nil

local scheduler = cc.Director:getInstance():getScheduler()

function startup:start()
    local scene = display.newScene("startup")
    local layer = cc.Layer:create()
    scene:addChild(layer)

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
    
    self:openSchedulerProgress()
end

function startup:exit()
    if self._rootNode then
        self._rootNode:removeFromParent(true)
        display.removeUnusedSpriteFrames()
    
        self._rootNode = nil
        self._children = {}
        self:closeSchedulerProgress()
    end
end

function startup:seekNodeByName(root, name)
    if ( nil == root) then
        return nil
    end

    if (root:getName() == name) then
        return  root
    end

    local arrayRootChildren = root:getChildren()
    for i,v in pairs(arrayRootChildren) do
        if (nil ~= v) then
            local res = self:seekNodeByName(v,name)
            if (res ~= nil ) then
                return res
            end
        end
    end
end

function startup:showProgress(nPercent)
    if not nPercent or nPercent < 0 then return end
    local lbProcess = self:seekNodeByName(self._rootNode,"loadbar")
    local lbHint = self:seekNodeByName(self._rootNode,"txt_hint")
    if (not lbProcess) or (not lbHint) then return end 
    lbProcess:setPercent(nPercent)
    local strProcess = tostring(math.ceil(nPercent))
    lbHint:setString(strProcess .. "%")
end

function startup:startGame()
    self:exit()
  
    local start = require "app.start"
    start.init()
    start.start()
end

function startup:openSchedulerProgress()
    local alltime = 0.5
    local time = 0
    local function flipIt(dt)
        time = time + dt
        local percent = time / alltime * 100

        if time >= alltime or percent >= 100 then
            self:closeSchedulerProgress()
            self:startGame()
        end

        self:showProgress(percent)
    end
    self:closeSchedulerProgress()
    self._schedulerProgress = scheduler:scheduleScriptFunc(flipIt, 0.1, false)
end

function startup:closeSchedulerProgress()
    if self._schedulerProgress ~= nil then
        scheduler:unscheduleScriptEntry(self._schedulerProgress)
        self._schedulerProgress = nil
    end
end

return startup
