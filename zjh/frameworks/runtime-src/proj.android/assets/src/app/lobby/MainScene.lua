--[[
@brief  主场景
]]

local scheduler = cc.Director:getInstance():getScheduler()

local MainScene = class("MainScene", app.base.BaseScene)

-- csb路径
MainScene.csbPath = "lobby/csb/lobby.csb"

MainScene.touchs = {
    "btn_head_info",
    "btn_gold_add_lobby",
    "btn_gold_add_plaza",
    "btn_notice",
    "btn_mail",
    "btn_set",
    "btn_qznn",
    "btn_psz",
    "btn_brnn",
    "btn_lhd",
    "btn_ddz",
    "btn_jdnn",
    "btn_rank",
    "btn_safe",
    "btn_shop",
    "btn_back",
    "btn_help",
    "btn_plaza_1",
    "btn_plaza_2",
    "btn_plaza_3",
    "btn_plaza_4"
}

function MainScene:onTouch(sender, eventType)
    MainScene.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        print("button name is:",name) 
        if name == "btn_back" then
            self:showPlazaPnl(false)           
        elseif name == "btn_psz" then
            self._presenter:showPlazaLists(4001)             
        elseif name == "btn_head_info" then
            self._presenter:showUserCenter()             
        elseif name == "btn_gold_add_lobby" then
            self._presenter:showShop()             
        elseif name == "btn_gold_add_plaza" then
            self._presenter:showShop()             
        elseif name == "btn_notice" then        
        elseif name == "btn_mail" then         
        elseif name == "btn_set" then      
            self._presenter:showSet()                     
        elseif name == "btn_rank" then              
        elseif name == "btn_safe" then              
        elseif name == "btn_shop" then      
            self._presenter:showShop()             
        elseif name == "btn_help" then      
            self._presenter:showHelp()
        elseif string.find(name, "btn_plaza_") then 
            local index = string.split(name, "btn_plaza_")[2]
            local gameid = sender:getTag()
            self._presenter:reqJoinRoom(gameid, tonumber(index))                       
        end 
    end
end

function MainScene:initUI(gameID, roomMode)
    local t = self:seekChildByName("txt_id_lobby"):getLocalZOrder()
    
    t = 100 /2/5
    
    for i=1,1 do
    	print("sssssssswwqeqwe",i)
    end
    
    print("zordersssssssssss",t)
    
    
end

function MainScene:onEnter()
    self._presenter:onEnter()
end

----------------------------------------ui更新----------------------------------------------

-- 更新用户ID
function MainScene:setID(name)
    local txtID1 = self:seekChildByName("txt_id_lobby")
    local txtID2 = self:seekChildByName("txt_id_plaza")
    
    txtID1:setString("ID:" .. name)
    txtID2:setString("ID:" .. name)
end

-- 更新昵称
function MainScene:setNickname(nickname)
    local txtNickname1 = self:seekChildByName("txt_name_lobby")
    local txtNickname2 = self:seekChildByName("txt_name_plaza")
    txtNickname1:setString(app.util.ToolUtils.nameToShort(nickname, 20))
    txtNickname2:setString(app.util.ToolUtils.nameToShort(nickname, 16))
end

--更新财富
function MainScene:setBalance(balance)
    local txtBalance1 = self:seekChildByName("txt_gold_lobby")
    local txtBalance2 = self:seekChildByName("txt_gold_plaza")
    txtBalance1:setString(app.util.ToolUtils.numConversionByDecimal(tostring(balance)))
    txtBalance2:setString(app.util.ToolUtils.numConversionByDecimal(tostring(balance)))
end

-- 显示隐藏场
function MainScene:showPlazaPnl(bFlag)
    if self._isRunAction then
        return
    end
    self._isRunAction = true
    local pnlLobbyTop = self:seekChildByName("lobby_top")
    local pnlPlazaTop = self:seekChildByName("plaza_top")
    local pnlLobby = self:seekChildByName("lobby")    
    local pnlPlaza = self:seekChildByName("plaza")
    local pnlBottom = self:seekChildByName("bottom")

    if bFlag then
        if not pnlPlazaTop:isVisible() then
            pnlLobbyTop:runAction(cc.Hide:create())
            pnlPlazaTop:runAction(cc.Sequence:create(cc.MoveBy:create(0.1,cc.p(0,120)), cc.Show:create(),cc.MoveBy:create(0.1,cc.p(0,-120))))
            pnlLobby:runAction(cc.Hide:create())
            pnlPlaza:runAction(cc.Sequence:create(self:commonActionMoveBy(),cc.CallFunc:create(function() self._isRunAction = false end)))
            pnlBottom:runAction(cc.Sequence:create(cc.MoveBy:create(0.1,cc.p(0.1,-150)),cc.Show:create(),cc.MoveBy:create(0.1,cc.p(0,150))))
        else
            self._isRunAction = false
        end
    else
        pnlLobbyTop:runAction(cc.Sequence:create(cc.MoveBy:create(0.1,cc.p(0,120)), cc.Show:create(),cc.MoveBy:create(0.1,cc.p(0,-120))))
        pnlPlazaTop:runAction(cc.Hide:create())        
        pnlLobby:runAction(self:commonActionMoveBy())       
        pnlPlaza:runAction(cc.Sequence:create(cc.Hide:create(),cc.CallFunc:create(function() self._isRunAction = false end)))
        pnlBottom:runAction(cc.Sequence:create(cc.MoveBy:create(0.1,cc.p(0.1,-150)),cc.Show:create(),cc.MoveBy:create(0.1,cc.p(0,150))))
    end
end

function MainScene:commonActionMoveBy()
    local Action = cc.Sequence:create(
        cc.MoveBy:create(0,cc.p(1334,0)),
        cc.Show:create(),
        cc.EaseSineOut:create(cc.MoveBy:create(0.2,cc.p(-1354,0))),
        cc.EaseSineOut:create(cc.MoveBy:create(0.05,cc.p(20,0)))
    )
    return Action
end

-- 加载场列表
function MainScene:loadPlazaList(gameid, plazainfos)
    if plazainfos == nil then
    	return
    end
    
    local pnlPlaza = self:seekChildByName("plaza")    
    local child = pnlPlaza:getChildren()        
    for i,btn in ipairs(child) do
        local base = btn:getChildByName("fnt_base")
        local lower = btn:getChildByName("txt_lower")
        if plazainfos[i] then
            base:setString(plazainfos[i].base .. "底分")
            lower:setString(plazainfos[i].lower)
            btn:setTag(gameid)
        end                
    end
end

return MainScene
