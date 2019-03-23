--[[
@brief  �����
]]
local app       = app

local BaseLayer = class("BaseLayer")

---------------- ������������Ŀ ---------------
-- csb·��
BaseLayer.csbPath   = nil
-- ��ע�ᰴťtouch�¼����б�
BaseLayer.touchs    = nil
BaseLayer.clicks    = nil
BaseLayer.events    = nil
-----------------------------------------------

-- ����
BaseLayer._instance = nil

-- ���ڵ�
BaseLayer._rootNode = nil

-- zOrderֵ
BaseLayer._zOrder = 0

-- ��׿�豸Ĭ�Ͽ���Ӧ���ؼ������ó�falseʱ���ذ�ť������Ч
BaseLayer._canBack = true

-- ���ڵ�����
BaseLayer._parent = nil

-- �ӽڵ�����
BaseLayer._children = {}

-- �����ļ���ʵ��
BaseLayer._presenter = nil

--------------------------------
-- ������̬���� 
-- @param self
-- @return _instance
function BaseLayer:getInstance()
    if self._instance == nil then
        self._instance = self:create()
    end
    return self._instance
end

-- ���캯��
function BaseLayer:ctor()
    self._rootNode = nil
    self._parent = nil
    self._children = {}
    self._presenter = nil
end

-- �򿪽���
function BaseLayer:start( presenter, ... )
    self:startLayer(presenter)
    -- ����zOrder
    self._zOrder = app.util.UIUtils.resetZOrder(self._rootNode)
    if device.platform == "android" and self._canBack and not self._rootNode:isVisible() then
        app.util.UIUtils.pushLayer(self)
    end
    self:init( ... )
    self._rootNode:setVisible(true)
end

-- ��ʼ��������������ʼ�������������������ʾ��show(...)�д���
function BaseLayer:startLayer(presenter)
    local scene = cc.Director:getInstance():getRunningScene()
    if not scene then
        print(self.__cname, " init error, no running scene.")
        return
    end

    -- ��ֹ�л��������ȡ��ԭ����
    if self._rootNode and self._parent == scene then
        return
    end

    -- ����csb�ļ�
    if not self.csbPath then
        print(" csbPath are not configured. ")
    end
    print("BaseLayer:startLayer, layer name : ", self.__cname)
    self._rootNode = cc.CSLoader:createNodeWithVisibleSize(self.csbPath)
    scene:addChild(self._rootNode)
    self._rootNode:setVisible(false)
    self._parent = scene
    self._children = {}

    -- ע�ᰴť���¼�
    self:registerEvent()

    -- ���ؿ�����
    self._presenter = presenter

    -- ����������
    self:onCreate()
end

-- �˳�
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

-- �رս���
function BaseLayer:exit()
    if device.platform == "android" and self._canBack and self._rootNode and self._rootNode:isVisible() then
        app.util.UIUtils.popLayer()
    end

    if self._rootNode then
        self._rootNode:setVisible(false)
    end
end

-- ���������ɺ�ֻ����һ�εķ���
-- (eg. layer��node���贴��һ��)
function BaseLayer:onCreate()
end

-- ��ʼ��
function BaseLayer:init( ... )
    self:initData( ... )
    self:initUI( ... )
end

-- ��ʼ������(�����൥��ʵ��)
function BaseLayer:initData( ... )
end

-- ��ʼ��UI(�����൥��ʵ��)
function BaseLayer:initUI( ... )
end

-- ע���¼�
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

-- onTouch�¼�
function BaseLayer:onTouch(sender, eventType)
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

function BaseLayer:onClick(sender)
    
end

function BaseLayer:onEvent(sender, eventType)
end

-----------------------------------------
--  ��������
-----------------------------------------

-- �Ƿ�ǰlayer
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

-- ͨ�����Ʋ����ӽڵ�
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

-- ͨ��tag�����ӽڵ�
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

-- �ṩһ���Ƴ��ڵ�ķ���
-- ����Ҫ�Ƴ�һ����cocosstudio�д����Ľڵ��Ҳ�ȷ��֮���Ƿ񻹻��ٵ��õ��ýڵ�ʱ������ʹ�ø÷���
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

-- list�н�Ŀ�겻�ɵ��
function BaseLayer:setRedioShow(keyList, showKey)
    for _,v in pairs(keyList) do
        self:seekChildByName(v):setEnabled(not (v == showKey))
    end
end

-- list�н�Ŀ��ɼ�
function BaseLayer:setOnlyVisible(keyList, showKey)
    for _,v in pairs(keyList) do
        self:seekChildByName(v):setVisible(v == showKey)
    end
end

return BaseLayer