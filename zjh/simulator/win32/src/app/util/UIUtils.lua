--[[
@brief  UI操作工具类
]]
local UIUtils = {}

-----------------------------------------
--  场景上的Layer栈  
-----------------------------------------
UIUtils._stack = {}

function UIUtils.initLayerStack()
    UIUtils._stack = {}
end

--[[
--将一个对话框加入栈中
--@param uiobject 对话框
]]
function UIUtils.pushLayer(uiObject)
    UIUtils._stack[#UIUtils._stack+1] = uiObject
end

--[[
--将栈顶对话框弹出栈中,并删除。若栈顶无元素返回nil
--return uiobject
]]
function UIUtils.popLayer()
    local uiObject = UIUtils._stack[#UIUtils._stack]
    UIUtils._stack[#UIUtils._stack] = nil
    return uiObject
end

--[[
--将栈顶获取栈顶元素，不移除,若栈顶无元素返回nil
--return uiobject
]]
function UIUtils.topLayer()
    local uiObject = UIUtils._stack[#UIUtils._stack]
    return uiObject
end

-----------------------------------------
--  场景上的Layer层级
-----------------------------------------
UIUtils._maxZOrder = 0

function UIUtils.initLayerZOrder()
    UIUtils._maxZOrder = 0
end

--[[
--重置节点的z轴坐标
--return 重置后的z轴坐标
]]
function UIUtils.resetZOrder(node)
    UIUtils._maxZOrder = UIUtils._maxZOrder + 1
    node:setLocalZOrder(UIUtils._maxZOrder)
    return UIUtils._maxZOrder
end

-- --------------------------------------此处处理UI的其他帮助函数---------------------------------------
-- 播放动画及粒子效果
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

-- 播放动画及粒子效果
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

-- 动画只播放time次,播放完成后会自动删除节点,没有time默认播放1次
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

-- 头像裁切
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