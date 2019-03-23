--[[
@brief  ��������
]]
local app       = app

local BaseScene = class("BaseScene")

---------------- ������������Ŀ ---------------
-- csb·��
BaseScene.csbPath   = nil
-- ��ע�ᰴťtouch�¼����б�
BaseScene.touchs    = nil
BaseScene.clicks    = nil
BaseScene.events    = nil
-----------------------------------------------

-- ����
BaseScene._instance = nil

-- �������ڵ�
BaseScene._rootNode = nil 

-- �ӽڵ�����
BaseScene._children = {}  

-- �����ļ���ʵ��
BaseScene._presenter = nil

--------------------------------
-- ������̬���� 
-- @param self
-- @return _instance
function BaseScene:getInstance()
    if self._instance == nil then
        self._instance = self:create()
    end
    return self._instance
end

-- ���캯��
function BaseScene:ctor()
    self._rootNode = nil 
    self._children = {}
    self._presenter = nil
end
-- �򿪽���
function BaseScene:start( presenter, ... )
    self:startScene(presenter)
    self:init( ... )
end

-- ��ʼ������
function BaseScene:startScene(presenter)
    if self._rootNode then
        return
    end

    local scene = display.newScene(self.__cname)
    local layer = cc.Layer:create()
    scene:addChild(layer)

    -- ��ʼ��Layerջ
    app.util.UIUtils.initLayerStack()
    app.util.UIUtils.initLayerZOrder()

    -- ��׿����
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

    -- ����csb�ļ�
    if not self.csbPath then
        print(" csbPath are not configured. ")
    end
    print("BaseScene:startScene, scene name : ", self.__cname)
    self._rootNode = cc.CSLoader:createNodeWithVisibleSize(self.csbPath)
    layer:addChild(self._rootNode)

    -- ע�᳡�������¼�
    scene:registerScriptHandler(handler(self, self.nodeEvent))
    -- �л�����
    display.runScene(scene)

    -- ע�ᰴť���¼�
    self:registerEvent()

    -- ���ؿ�����
    self._presenter = presenter
end

-- ���������¼�
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

-- �˳�����
function BaseScene:exit()
    if self._rootNode then
        self._rootNode:removeFromParent(true)
        display.removeUnusedSpriteFrames()

        self._rootNode = nil
        self._children = {}
    end
end

-- ��ʼ��
function BaseScene:init( ... )
    self:initData( ... )
    self:initUI( ... )
end

-- ��ʼ������(�����൥��ʵ��)
function BaseScene:initData( ... )
end

-- ��ʼ��UI(�����൥��ʵ��)
function BaseScene:initUI( ... )
end

-- ��׿���ذ�ť
function BaseScene:clickBack()
    self:exit()
end

-- ע���¼�
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

-- onTouch�¼�
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
--  ��������
-----------------------------------------

-- �Ƿ�ǰ����
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

-- ͨ�����Ʋ����ӽڵ�
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

-- ͨ��tag�����ӽڵ�
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

-- �ṩһ���Ƴ��ڵ�ķ���
-- ����Ҫ�Ƴ�һ����cocosstudio�д����Ľڵ��Ҳ�ȷ��֮���Ƿ񻹻��ٵ��õ��ýڵ�ʱ������ʹ�ø÷���
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