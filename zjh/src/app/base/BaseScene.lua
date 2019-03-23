--[[
@brief  场景基类
]]
local app       = app

local BaseScene = class("BaseScene")

---------------- 子类需配置项目 ---------------
-- csb路径
BaseScene.csbPath   = nil
-- 需注册按钮touch事件的列表
BaseScene.touchs    = nil
BaseScene.clicks    = nil
BaseScene.events    = nil
-----------------------------------------------

-- 单例
BaseScene._instance = nil

-- 场景根节点
BaseScene._rootNode = nil 

-- 子节点数据
BaseScene._children = {}  

-- 控制文件的实例
BaseScene._presenter = nil

--------------------------------
-- 声明静态单例 
-- @param self
-- @return _instance
function BaseScene:getInstance()
    if self._instance == nil then
        self._instance = self:create()
    end
    return self._instance
end

-- 构造函数
function BaseScene:ctor()
    self._rootNode = nil 
    self._children = {}
    self._presenter = nil
end
-- 打开界面
function BaseScene:start( presenter, ... )
    self:startScene(presenter)
    self:init( ... )
end

-- 初始化场景
function BaseScene:startScene(presenter)
    if self._rootNode then
        return
    end

    local scene = display.newScene(self.__cname)
    local layer = cc.Layer:create()
    scene:addChild(layer)

    -- 初始化Layer栈
    app.util.UIUtils.initLayerStack()
    app.util.UIUtils.initLayerZOrder()

    -- 安卓适配
    if device.platform == "android" then
        layer:setKeypadEnabled(true)
        local function onKeyReleased(keyCode, event)
            if keyCode == cc.KeyCode.KEY_BACK then
                local uiObject = app.util.UIUtils.topLayer()
                if uiObject ~= nil then
                    uiObject:exit()
                else
                    self:clickBack()
                end
            end
        end

        local listener = cc.EventListenerKeyboard:create()
        listener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
        local eventDispatcher = layer:getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)  
    end

    -- 加载csb文件
    if not self.csbPath then
        print(" csbPath are not configured. ")
    end
    print("BaseScene:startScene, scene name : ", self.__cname)
    self._rootNode = cc.CSLoader:createNodeWithVisibleSize(self.csbPath)
    layer:addChild(self._rootNode)

    -- 注册场景基础事件
    scene:registerScriptHandler(handler(self, self.nodeEvent))
    -- 切换场景
    display.runScene(scene)

    -- 注册按钮等事件
    self:registerEvent()

    -- 加载控制类
    self._presenter = presenter
end

-- 场景基础事件
function BaseScene:nodeEvent(event)
    if event == "enter" and self.onEnter ~= nil then
        self:onEnter()
    elseif event == "exit" and self.onExit ~= nil then
        self:onExit()
    elseif event == "enterTransitionFinish" and self.onEnterTransitionDidFinish ~= nil  then
        self:onEnterTransitionDidFinish()
    elseif event == "exitTransitionStart" and self.onExitTransitionDidStart ~= nil then
        self:onExitTransitionDidStart()
    elseif event == "cleanup" and self.onCleanup ~= nil then
        self:onCleanup()
    end
end

-- 退出场景
function BaseScene:exit()
    if self._rootNode then
        self._rootNode:removeFromParent(true)
        display.removeUnusedSpriteFrames()

        self._rootNode = nil
        self._children = {}
    end
end

-- 初始化
function BaseScene:init( ... )
    self:initData( ... )
    self:initUI( ... )
end

-- 初始化数据(由子类单独实现)
function BaseScene:initData( ... )
end

-- 初始化UI(由子类单独实现)
function BaseScene:initUI( ... )
end

-- 安卓返回按钮
function BaseScene:clickBack()
    self:exit()
end

-- 注册事件
function BaseScene:registerEvent()
    if self.touchs ~= nil then
        for k,v in pairs(self.touchs) do
            local btn = self:seekChildByName(v)
            if btn then
                btn:addTouchEventListener(handler(self, self.onTouch))
            end
        end
    end

    if self.clicks ~= nil then
        for k,v in pairs(self.clicks) do
            local btn = self:seekChildByName(v)
            if btn then
                btn:addClickEventListener(handler(self, self.onClick))
            end
        end
    end

    if self.events ~= nil then
        for k,v in pairs(self.events) do
            local widget = self:seekChildByName(v)
            if widget then
                widget:addEventListener(handler(self, self.onEvent))
            end
        end
    end
end

-- onTouch事件
function BaseScene:onTouch(sender, eventType)
    local originalScale = sender:getScale()
    local scaleMult = 0.95
    if eventType == ccui.TouchEventType.began then
        sender:setScale(originalScale*scaleMult)
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        sender:setScale(originalScale/scaleMult)
    elseif eventType == ccui.TouchEventType.canceled then
        sender:setScale(originalScale/scaleMult)
    end
end

function BaseScene:onClick(sender)    
end

function BaseScene:onEvent(sender, eventType)
end

-----------------------------------------
--  辅助函数
-----------------------------------------

-- 是否当前场景
function BaseScene:isCurrentUI()
    if self._rootNode and not tolua.isnull(self._rootNode) then
        return true
    end

    return false
end

function BaseScene:seekNodeByName(root, name)
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

-- 通过名称查找子节点
function BaseScene:seekChildByName(name)
    if not name or not self._rootNode then
        print("BaseScene:seekChildByName, name or rootNode is nil")
        return nil
    end

    if not self._children[name] then
        self._children[name] = self:seekNodeByName(self._rootNode, name)
    end
    return self._children[name]
end

-- 通过tag查找子节点
function BaseScene:seekChildByTag(tag)
    if not tag or not self._rootNode then
        print("BaseScene:seekChildByTag, tag or rootNode is nil")
        return nil
    end
    if not self._children[tag] then
        self._children[tag] = ccui.Helper:seekNodeByTag(self._rootNode, tag)
    end
    return self._children[tag]
end

-- 提供一个移除节点的方法
-- 若需要移除一个在cocosstudio中创建的节点且不确定之后是否还会再调用到该节点时，建议使用该方法
function BaseScene:removeChildByName(name)
    if not name then
        print("BaseScene:removeChildByName, name is nil")
        return
    end
    local child = self:seekChildByName(name)
    if not child then
        print("BaseScene:removeChildByName, child not found")
        return
    end
    child:removeFromParent()
    self._children[name] = nil
end

return BaseScene