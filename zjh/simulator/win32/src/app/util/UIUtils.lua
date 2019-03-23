--[[
@brief  UI����������
]]
local UIUtils = {}

-----------------------------------------
--  �����ϵ�Layerջ  
-----------------------------------------
UIUtils._stack = {}

function UIUtils.initLayerStack()
    UIUtils._stack = {}
end

--[[
--��һ���Ի������ջ��
--@param uiobject �Ի���
]]
function UIUtils.pushLayer(uiObject)
    UIUtils._stack[#UIUtils._stack+1] = uiObject
end

--[[
--��ջ���Ի��򵯳�ջ��,��ɾ������ջ����Ԫ�ط���nil
--return uiobject
]]
function UIUtils.popLayer()
    local uiObject = UIUtils._stack[#UIUtils._stack]
    UIUtils._stack[#UIUtils._stack] = nil
    return uiObject
end

--[[
--��ջ����ȡջ��Ԫ�أ����Ƴ�,��ջ����Ԫ�ط���nil
--return uiobject
]]
function UIUtils.topLayer()
    local uiObject = UIUtils._stack[#UIUtils._stack]
    return uiObject
end

-----------------------------------------
--  �����ϵ�Layer�㼶
-----------------------------------------
UIUtils._maxZOrder = 0

function UIUtils.initLayerZOrder()
    UIUtils._maxZOrder = 0
end

--[[
--���ýڵ��z������
--return ���ú��z������
]]
function UIUtils.resetZOrder(node)
    UIUtils._maxZOrder = UIUtils._maxZOrder + 1
    node:setLocalZOrder(UIUtils._maxZOrder)
    return UIUtils._maxZOrder
end

-- --------------------------------------�˴�����UI��������������---------------------------------------
-- ���Ŷ���������Ч��
function UIUtils.runEffect(dir, name, posX, posY, flag)
    flag = flag or true
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(dir.."/Effect/"..name.."/"..name..".ExportJson")
    local effect = ccs.Armature:create(name)
    effect:setPosition(cc.p(posX, posY))
    if flag then
        effect:getAnimation():playWithIndex(0)
    end
    return effect
end

-- ���Ŷ���������Ч��
function UIUtils.runEffectEx(type, name, posX, posY, flag)
    flag = flag or true
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("Game/Public/Effect/"..type.."/"..name.."/"..name..".ExportJson")
    local effect = ccs.Armature:create(name)
    effect:setPosition(cc.p(posX, posY))
    if flag then
        effect:getAnimation():playWithIndex(0)
    end
    return effect
end

-- ����ֻ����time��,������ɺ���Զ�ɾ���ڵ�,û��timeĬ�ϲ���1��
function UIUtils.runEffectOne(type, name, posX, posY, flag, callback, time)
    time = time or 1
    flag = flag or true

    local count = 0

    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("Game/Public/Effect/"..type.."/"..name.."/"..name..".ExportJson")

    local effect = ccs.Armature:create(name)
    effect:setPosition(cc.p(posX, posY))

    if flag then
        effect:getAnimation():playWithIndex(0)
    end

    local function onFrameEvent(action, movementType, movementID)
        if movementType == ccs.MovementEventType.loopComplete then 
            count = count + 1
            if count == time then
                effect:removeSelf()
                effect = nil
                if callback ~= nil then
                    callback()
                end
            end
        end
    end

    effect:getAnimation():setMovementEventCallFunc(onFrameEvent)

    return effect
end

-- ͷ�����
function UIUtils.runHeadClipper(head, posX, posY, scale)
    local spriteClipper = cc.Sprite:createWithSpriteFrameName("Lobby/Images/Public/Img/Head/img_head_bg2.png")
    spriteClipper:setPosition(posX, posY)
    spriteClipper:setScale(scale)

    local clipper = cc.ClippingNode:create(spriteClipper)
    clipper:setAlphaThreshold(0.1)
    clipper:addChild(head)

    return clipper
end

return UIUtils