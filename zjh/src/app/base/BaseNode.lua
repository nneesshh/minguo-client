--[[
@brief  节点基类(需动态创建的节点)
]]
local BaseNode = class("BaseNode")

---------------- 子类需配置项目 ---------------
-- csb路径
BaseNode.csbPath    = nil
-- 需注册按钮touch事件的列表
BaseNode.touchs     = nil
BaseNode.clicks     = nil
BaseNode.events     = nil
-----------------------------------------------

-- 根节点
BaseNode._rootNode = nil

-- 子节点数据
BaseNode._children = {}

-- 控制文件的实例
BaseNode._presenter = nil

-- 构造函数
function BaseNode:ctor( presenter, ... )
    self._rootNode = nil
    self._children = {}
    self._presenter = nil

    self:createNode(presenter)
    self:init( ... )

    self._rootNode:setVisible(true)
end

-- 初始化场景，仅做初始化工作，具体操作及显示在init(...)中处理
function BaseNode:createNode(presenter)
    -- 加载csb文件
    if not self.csbPath then
        print(" csbPath are not configured. ")
    end
    if not self._rootNode then        
        self._rootNode = cc.CSLoader:createNode(self.csbPath)
        self._rootNode:setVisible(false)
    end

    -- 注册按钮等事件
    self:registerEvent()

    -- 加载控制类
    self._presenter = presenter

    -- 界面加载完毕
    self:onCreate()
end

function BaseNode:getRootNode()
    return self._rootNode
end

-- 退出场景
function BaseNode:exitAndCleanup()
    if self._rootNode then
        self._rootNode:removeFromParent(true)
        self._rootNode = nil
        self._children = {}
    end
end

-- 关闭界面
function BaseNode:show(visible)
    self._rootNode:setVisible(visible)
end

-- 界面加载完成后只加载一次的方法
function BaseNode:onCreate()
end

-- 初始化
function BaseNode:init( ... )
    self:initData( ... )
    self:initUI( ... )
end

-- 初始化数据(由子类单独实现)
function BaseNode:initData( ... )
end

-- 初始化UI(由子类单独实现)
function BaseNode:initUI( ... )
end

-- 播放节点动画
function BaseNode:runAction(startIndex, isLoop)
    if not self.csbPath then
        print(" csbPath are not configured. ")
        return
    end
    local startIndex = startIndex or 0
    local isLoop = isLoop or true
    local action = cc.CSLoader:createTimeline(self.csbPath)
    if action then
        self._rootNode:runAction(action)
        action:gotoFrameAndPlay(startIndex, isLoop)
    end
end

-- 注册事件
function BaseNode:registerEvent()
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
function BaseNode:onTouch(sender, eventType)
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

function BaseNode:onClick(sender)    
end

function BaseNode:onEvent(sender, eventType)
end

-----------------------------------------
--  辅助函数
-----------------------------------------

function BaseNode:seekNodeByName(root, name)
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
function BaseNode:seekChildByName(name)
    if not name or not self._rootNode then
        print("BaseNode:seekChildByName, name or rootNode is nil")
        return nil
    end
    if not self._children[name] then
        self._children[name] = self:seekNodeByName(self._rootNode, name)
    end
    return self._children[name]
end

-- 通过tag查找子节点
function BaseNode:seekChildByTag(tag)
    if not tag or not self._rootNode then
        print("BaseNode:seekChildByTag, tag or rootNode is nil")
        return nil
    end
    if not self._children[tag] then
        self._children[tag] = ccui.Helper:seekNodeByTag(self._rootNode, tag)
    end
    return self._children[tag]
end

-- 提供一个移除节点的方法
-- 若需要移除一个在cocosstudio中创建的节点且不确定之后是否还会再调用到该节点时，建议使用该方法
function BaseNode:removeChildByName(name)
    if not name then
        print("BaseNode:removeChildByName, name is nil")
        return
    end
    local child = self:seekChildByName(name)
    if not child then
        print("BaseNode:removeChildByName, child not found")
        return
    end
    child:removeFromParent()
    self._children[name] = nil
end

return BaseNode