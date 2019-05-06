--[[
@brief  层基类
]]
local app       = app

local BaseLayer = class("BaseLayer")

---------------- 子类需配置项目 ---------------
-- csb路径
BaseLayer.csbPath   = nil
-- 需注册按钮touch事件的列表
BaseLayer.touchs    = nil
BaseLayer.clicks    = nil
BaseLayer.events    = nil
-----------------------------------------------

-- 单例
BaseLayer._instance = nil

-- 根节点
BaseLayer._rootNode = nil

-- zOrder值
BaseLayer._zOrder = 0

-- 安卓设备默认可响应返回键，设置成false时返回按钮操作无效
BaseLayer._canBack = true

-- 父节点数据
BaseLayer._parent = nil

-- 子节点数据
BaseLayer._children = {}

-- 控制文件的实例
BaseLayer._presenter = nil

--------------------------------
-- 声明静态单例 
-- @param self
-- @return _instance
function BaseLayer:getInstance()
    if self._instance == nil then
        self._instance = self:create()
    end
    return self._instance
end

-- 构造函数
function BaseLayer:ctor()
    self._rootNode = nil
    self._parent = nil
    self._children = {}
    self._presenter = nil
end

-- 打开界面
function BaseLayer:start( presenter, ... )
    self:startLayer(presenter)
    -- 设置zOrder
    self._zOrder = app.util.UIUtils.resetZOrder(self._rootNode)
    if device.platform == "android" and self._canBack and not self._rootNode:isVisible() then
        app.util.UIUtils.pushLayer(self)
    end
    self:init( ... )
    self._rootNode:setVisible(true)
end

-- 初始化场景，仅做初始化工作，具体操作及显示在show(...)中处理
function BaseLayer:startLayer(presenter)
    local scene = cc.Director:getInstance():getRunningScene()
    if not scene then
        print(self.__cname, " init error, no running scene.")
        return
    end

    -- 防止切换场景后获取到原数据
    if self._rootNode and self._parent == scene then
        return
    end

    -- 加载csb文件
    if not self.csbPath then
        print(" csbPath are not configured. ")
    end
    print("BaseLayer:startLayer, layer name : ", self.__cname)
    self._rootNode = cc.CSLoader:createNodeWithVisibleSize(self.csbPath)
    scene:addChild(self._rootNode)
    self._rootNode:setVisible(false)
    self._parent = scene
    self._children = {}

    -- 注册按钮等事件
    self:registerEvent()

    -- 加载控制类
    self._presenter = presenter

    -- 界面加载完毕
    self:onCreate()
end

-- 退出
function BaseLayer:exitAndCleanup()
    if device.platform == "android" and self._canBack and self._rootNode and self._rootNode:isVisible() then
        app.util.UIUtils.popLayer()
    end
    if self._rootNode then
        self._rootNode:removeFromParent(true)
        self._rootNode = nil
        self._parent = nil
        self._children = {}
    end
end

-- 关闭界面
function BaseLayer:exit()
    if device.platform == "android" and self._canBack and self._rootNode and self._rootNode:isVisible() then
        app.util.UIUtils.popLayer()
    end

    if self._rootNode then
        self._rootNode:setVisible(false)
    end
end

-- 界面加载完成后只加载一次的方法
-- (eg. layer上node仅需创建一次)
function BaseLayer:onCreate()
end

-- 初始化
function BaseLayer:init( ... )
    self:initData( ... )
    self:initUI( ... )
end

-- 初始化数据(由子类单独实现)
function BaseLayer:initData( ... )
end

-- 初始化UI(由子类单独实现)
function BaseLayer:initUI( ... )
end

-- 注册事件
function BaseLayer:registerEvent()
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
function BaseLayer:onTouch(sender, eventType)
    local originalScale = sender:getScale()
    local scaleMult = 0.95
    if eventType == ccui.TouchEventType.began then
        sender:setScale(originalScale*scaleMult)
    elseif eventType == ccui.TouchEventType.moved then
    elseif eventType == ccui.TouchEventType.ended then
        sender:setScale(originalScale/scaleMult)        
        if app.Connect then
            
            app.Connect:getInstance():reConnect()
        end         
    elseif eventType == ccui.TouchEventType.canceled then
        sender:setScale(originalScale/scaleMult)
    end
end

function BaseLayer:onClick(sender)
    if app.Connect then
        app.Connect:getInstance():reConnect()
    end
end

function BaseLayer:onEvent(sender, eventType)
end

-----------------------------------------
--  辅助函数
-----------------------------------------

-- 是否当前layer
function BaseLayer:isCurrentUI()
    if self._rootNode and not tolua.isnull(self._rootNode) and self._rootNode:isVisible() then
        return true
    end

    return false
end

function BaseLayer:seekNodeByName(root, name)
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
function BaseLayer:seekChildByName(name)
    if not name or not self._rootNode then
        print("BaseLayer:seekChildByName, name or rootNode is nil")
        return nil
    end

    if not self._children[name] then
        self._children[name] = self:seekNodeByName(self._rootNode, name)
    end
    return self._children[name]
end

-- 通过tag查找子节点
function BaseLayer:seekChildByTag(tag)
    if not tag or not self._rootNode then
        print("BaseLayer:seekChildByTag, tag or rootNode is nil")
        return nil
    end
    if not self._children[tag] then
        self._children[tag] = ccui.Helper:seekNodeByTag(self._rootNode, tag)
    end
    return self._children[tag]
end

-- 提供一个移除节点的方法
-- 若需要移除一个在cocosstudio中创建的节点且不确定之后是否还会再调用到该节点时，建议使用该方法
function BaseLayer:removeChildByName(name)
    if not name then
        print("BaseLayer:removeChildByName, name is nil")
        return
    end
    local child = self:seekChildByName(name)
    if not child then
        print("BaseLayer:removeChildByName, child not found")
        return
    end
    child:removeFromParent()
    self._children[name] = nil
end

-- list中仅目标不可点击
function BaseLayer:setRedioShow(keyList, showKey)
    for _,v in pairs(keyList) do
        self:seekChildByName(v):setEnabled(not (v == showKey))
    end
end

-- list中仅目标可见
function BaseLayer:setOnlyVisible(keyList, showKey)
    for _,v in pairs(keyList) do
        self:seekChildByName(v):setVisible(v == showKey)
    end
end

return BaseLayer