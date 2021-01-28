--[[
@brief 启动页
]]
local HotpatchController = require("hotpatch.HotpatchController")
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
    
    local btn = self:seekNodeByName(self._rootNode, "btn_hint_ok")
    if btn then
        btn:addTouchEventListener(handler(self, self.onTouch))
    end
    
    hcLobby = HotpatchController:new("patch/lobby/project.manifest", "patch_lobby")
    hcLobby:init(handler(self, self.onHotUpdate))
    hcLobby:doUpdate()
end

function startup:exit()
    if self._rootNode then
        self._rootNode:removeFromParent(true)
        display.removeUnusedSpriteFrames()
    
        self._rootNode = nil
        self._children = {}
        self:closeSchedulerProgress()
        
        hcLobby = nil
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

-- onTouch事件
function startup:onTouch(sender, eventType)
    local originalScale = sender:getScale()
    local scaleMult = 0.95
    if eventType == ccui.TouchEventType.began then
        sender:setScale(originalScale*scaleMult)
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        sender:setScale(originalScale/scaleMult)
        cc.Director:getInstance():endToLua()        
    elseif eventType == ccui.TouchEventType.canceled then
        sender:setScale(originalScale/scaleMult)
    end
end

function startup:showProgress(nPercent)
    if not nPercent or nPercent < 0 then return end
    local lbProcess = self:seekNodeByName(self._rootNode, "loadbar")
    local lbHint = self:seekNodeByName(self._rootNode, "txt_hint")
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

function startup:showErrorHint(txt, visible)
    local pnl = self:seekNodeByName(self._rootNode, "pnl_error_hint")
    if visible then
        local txt_hint = self:seekNodeByName(self._rootNode, "txt_error_hint")
        txt_hint:setString(txt)		
	end
    pnl:setVisible(visible)
end

function startup:onHotUpdate(info)
    if self._rootNode then
        self:showErrorHint("", false)
        if cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED == info.code then              
            self:reload()            
            self:startGame()  
        elseif cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE == info.code then
            self:startGame()  
        elseif cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION == info.code or
               cc.EventAssetsManagerEx.EventCode.ASSET_UPDATED == info.code then
            self:showProgress(info.percent)
        elseif cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND == info.code then           
        else
            self:showErrorHint(info.tips, true)
        end        
    end
end

function startup:reloadRequire(name)
    if package.loaded[name] then
        package.loaded[name] = nil
        return require(name)
    end 
end

function startup:reload()
    self:reloadRequire("config")   
    self:reloadRequire("startup")   
    HotpatchController = self:reloadRequire("hotpatch.HotpatchController")
    if HotpatchRequire then
        print("is not nil")
        HotpatchRequire.reloadLobby()
    else
        print("HotpatchRequire is not nil")  
    end
end

return startup