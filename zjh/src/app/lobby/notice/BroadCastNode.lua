--[[
@brief  走马灯节点
                     走马灯直接加到当前场景最上层
]]
local app = cc.exports.gEnv.app
local BroadCastNode = class("BroadCastNode", app.base.BaseNode)

-- csb路径
BroadCastNode.csbPath = "lobby/csb/broadcast.csb"

BroadCastNode._msgList = {}

local TIMES = 2
local SPEED = 70

function BroadCastNode:initUI(tMsg,zorder)
    if #self._msgList == 0 then
        zorder = zorder or 1
        local scene = cc.Director:getInstance():getRunningScene()
        scene:addChild(self._rootNode, zorder)
        local screenSize = cc.Director:getInstance():getWinSize()
        self._rootNode:setPosition(screenSize.width*0.5, screenSize.height*0.86)
    end
    
    for i = 1,TIMES do
        table.insert(self._msgList, tMsg)
    end
    self:runActions()
end

function BroadCastNode:runActions()
    local pnl = self:seekChildByName("pnl_broadcast")
    local txt = self:seekChildByName("txt_broadcast")
    local pnlWidth = pnl:getContentSize().width

    local tmpTxt = self._msgList[1]
    local function nextAction()
        table.remove(self._msgList, 1)
        if #self._msgList > 0 then
            self:runActions()
        else
            self:exitAndCleanup()
        end
    end

    txt:stopAllActions()
    txt:setString(tmpTxt)
    txt:setPosition(pnlWidth, 18)
    local txtWidth = txt:getContentSize().width
    local time
    if txtWidth < pnlWidth then
        time = pnlWidth/SPEED
    else
        time = txtWidth/SPEED
    end
    local action = cc.MoveTo:create(time, cc.p(-txtWidth, 18))
    local sequence = cc.Sequence:create(action, cc.CallFunc:create(nextAction))
    txt:runAction(sequence)
end

function BroadCastNode:stopActions()
    self._msgList = {}
    self:exitAndCleanup()
end

return BroadCastNode