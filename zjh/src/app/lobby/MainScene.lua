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
            self._presenter:showPlazaLists(app.Game.GameID.ZJH)   
            --self._presenter:reqHotpatch(app.Game.GameID.ZJH)  
        elseif name == "btn_jdnn" then
            self._presenter:showPlazaLists(app.Game.GameID.JDNN)   
            --self._presenter:reqHotpatch(app.Game.GameID.JDNN)                             
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
            local gameid = sender:getTag()    
            self._presenter:showHelp(gameid)
        elseif string.find(name, "btn_plaza_") then 
            local index = string.split(name, "btn_plaza_")[2]
            local gameid = sender:getTag()            
            print("gameid is",gameid)
            self._presenter:reqJoinRoom(gameid, tonumber(index))                                
        end 
    end
end

function MainScene:initUI(gameID, roomMode)
    self._isRunAction = false   
    
    self:initEffect()   
end

function MainScene:onEnter()
    self._presenter:onEnter()
end

-- --------------------------------------ui更新-----------------------------------------
-- 更新用户ID
function MainScene:setID(name)
    local txtID1 = self:seekChildByName("txt_id_lobby")
    local txtID2 = self:seekChildByName("txt_id_plaza")
    
    txtID1:setString("ID:" .. name)
    txtID2:setString("ID:" .. name)
end

-- 头像
function MainScene:setAvatar(avator, gender)
    local btnHead = self:seekChildByName("btn_head_info")
    local resPath = string.format("lobby/image/head/img_head_%d_%d.png", gender, avator)
    btnHead:loadTextures(resPath, resPath, resPath, ccui.TextureResType.plistType)
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
      
    local resPath = string.format("lobby/image/plaza/img_game_%d.png", gameid)
    local imgtitle = self:seekChildByName("img_game_title") 
    imgtitle:ignoreContentAdaptWithSize(true)
    imgtitle:loadTexture(resPath, ccui.TextureResType.plistType)
    
    local btnhelp = self:seekChildByName("btn_help") 
    btnhelp:setTag(gameid)
    
    local pnlPlaza = self:seekChildByName("plaza")  
    local childs = pnlPlaza:getChildren()  
    for i,btn in ipairs(childs) do
        btn:setVisible(false)
    end
    
    local psize = pnlPlaza:getContentSize()
    local isize = childs[1]:getContentSize()
    local border = (psize.width - isize.width*#plazainfos) / (#plazainfos+1)
          
    for i, info in ipairs(plazainfos) do
        if i <= 4 then
            childs[i]:setVisible(true)
            childs[i]:setPositionX((border+isize.width/2)*i + (i-1)*isize.width/2)
            local base = childs[i]:getChildByName("fnt_base")
            local lower = childs[i]:getChildByName("txt_lower")
            base:setString(info.base .. "底分")
            lower:setString(info.lower)
            childs[i]:setTag(gameid)
            
            local btnPath = string.format("lobby/image/plaza/plaza_%d_%d.png", gameid, i)
            childs[i]:loadTextures(btnPath, btnPath, btnPath, ccui.TextureResType.plistType) 
        end        
    end
end

-- 显示热更进度
function MainScene:showHotpatchProgress(visible, percent, gameid)
	local btnname = {
        [app.Game.GameID.ZJH] = "btn_psz",
        [app.Game.GameID.JDNN] = "btn_jdnn"
	} 
	
    local btn = self:seekChildByName(btnname[gameid]) 
	if btn then
        local hotpnl = btn:getChildByName("hotpatch_pnl")        
        local circle = hotpnl:getChildByName("img_circle")
        local perfnt = hotpnl:getChildByName("fnt_percent")        
        if visible then 
            hotpnl:setVisible(true)           
            circle:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, 180)))
            perfnt:setString(string.format("%d%%", percent))
        else
            hotpnl:setVisible(false)
            circle:stopAllActions()
        end
	end	
end

-- 加载人物动画
function MainScene:initEffect()
    local node = self:seekChildByName("node_character")  
    node:removeAllChildren()
    node:stopAllActions()
    local effect = app.util.UIUtils.runEffect("lobby/effect","ggdh", 0, 0)
    node:addChild(effect)    
end

return MainScene
