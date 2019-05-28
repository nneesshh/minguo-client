--[[
    @brief  游戏结果趋势ui
]]--

local GameTrendLayer    = class("GameTrendLayer", app.base.BaseLayer)

GameTrendLayer.csbPath = "game/lhd/csb/trend.csb"

--local GameEnum = app.game.GameEnum 
local GameEnum = {}
GameEnum.HISTORY_NUM = 20
GameEnum.MAX_NUM     = 48

local cell           = 60
local border         = 1
local inter          = 2

GameTrendLayer.touchs = {    
    "btn_close",
}

function GameTrendLayer:onTouch(sender, eventType)
    GameTrendLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then            
            self:exit()
        end
    end
end

function GameTrendLayer:updateTrend(list)
    if not list then return end

    self:addHistory(list) 
    self:addHistoryLeft(list)      
    self:addHistoryRight(list) 
    self:countResult(list) 
end

function GameTrendLayer:updateTrendOne(result, list)
    if not list then return end

    self:addHistory(list) 
    self:addHistoryLeftOne(result, list)      
    self:addHistoryRight(list) 
end

-- 添加一排
function GameTrendLayer:addHistory(tlist)
    local pnl = self:seekChildByName("pnl_record")
    pnl:removeAllChildren() 

    local item = self:seekChildByName("img_hu_clone")

    local pnlsize = pnl:getContentSize()
    local itmsize = item:getContentSize()    

    local list = self._presenter:calRecordForTop(tlist)
    
    local count = #list
    for k = count, 1, -1 do
        local clone = self:cloneResult(list[k])        
        clone:setPosition(cc.p(((GameEnum.HISTORY_NUM - 1)-(count-k))*itmsize.width, pnlsize.height/2))
        pnl:addChild(clone)            
    end     
end

function GameTrendLayer:addHistoryOne(result)
    local pnl = self:seekChildByName("pnl_record")
    local item = self:seekChildByName("img_hu_clone")
    local itmsize = item:getContentSize()

    local childs = pnl:getChildren()
    for i, child in ipairs(childs) do
        local posX = child:getPositionX()
        child:setPositionX(posX - itmsize.width)
    end        

    local add = self:cloneResult(result)
    local pnlsize = pnl:getContentSize()
    add:setPosition(cc.p((GameEnum.HISTORY_NUM - 1)*itmsize.width, pnlsize.height/2))
    pnl:addChild(add)
    
    local newchild = pnl:getChildren()
    if #newchild > GameEnum.HISTORY_NUM then
        for i=1, #newchild - GameEnum.HISTORY_NUM do
            newchild[i]:removeFromParent(true)
        end      
    end  
end

-- 左侧记录
function GameTrendLayer:addHistoryLeft(tlist)
    local pnl = self:seekChildByName("pnl_detail_left")
    local item = self:seekChildByName("img_hu_clone")
    local pnlsize = pnl:getContentSize()
    local itmsize = item:getContentSize()
    pnl:removeAllChildren()    
    local list = self._presenter:calRecordForLeft(tlist)          
    local count = #list      
    local row = count % 6
    local col = math.ceil(count / 6)     

    for i=1,row do
        local index = (col-1)*6+i 
        local clone = self:cloneResult(list[index])   	          
        pnl:addChild(clone) 
        clone:setPosition(cc.p((col-1)*(cell+border)+cell/2, (6-i)*(cell+inter)+cell/2))
    end
   
    for i=1,col do
        for j=1,6 do
        	local index = (i-1)*6 + j
            local clone = self:cloneResult(list[index])            
            pnl:addChild(clone) 
            clone:setPosition(cc.p((i-1)*(cell+border)+cell/2, (6-j)*(cell+inter)+cell/2))        	
        end        
    end
end

function GameTrendLayer:addHistoryLeftOne(result)
    local pnl = self:seekChildByName("pnl_detail_left")
    local item = self:seekChildByName("img_hu_clone")
    local itmsize = item:getContentSize()
    local pnlsize = pnl:getContentSize()
    
    local childs = pnl:getChildren()
    if #childs >= GameEnum.MAX_NUM then
        for i=1, 6 do
            childs[i]:removeFromParent(true)
        end
        
        local newchilds = pnl:getChildren()
        for i=1, 7 do
            for j=1,6 do
                local index = (i-1)*6 + j
                newchilds[index]:setPosition(cc.p((i-1)*(cell+border)+cell/2, (6-j)*(cell+inter)+cell/2))            
            end
        end    
        
        local clone = self:cloneResult(result)              
        pnl:addChild(clone) 
        clone:setPosition(cc.p(7*(cell+border)+cell/2, 5*(cell+inter)+cell/2))                             
    else
        local clone = self:cloneResult(result)              
        pnl:addChild(clone) 
        
        local childs = pnl:getChildren()  
        for i=1, 8 do
        	for j=1,6 do
        		local index = (i-1)*6 + j
                if index <= #childs then
                    childs[index]:setPosition(cc.p((i-1)*(cell+border)+cell/2, (6-j)*(cell+inter)+cell/2))   
        		end        		
        	end
        end         
    end
end

-- 右侧记录
function GameTrendLayer:addHistoryRight(data)
    local pnl = self:seekChildByName("pnl_detail_right")
    local item = self:seekChildByName("img_long_clone")
    local pnlsize = pnl:getContentSize()
    local itmsize = item:getContentSize()
    pnl:removeAllChildren()
    
    local cellx = pnlsize.width / 14
    local celly = pnlsize.height / 10

    local ktype = self._presenter:calRecordForRight(data)
  
    local mark = 0
    for i = #ktype, 1, -1 do
        mark = mark + 1
        if mark <= 14 then
            local num = 0
            local _i,_j = 0, 0
            for j, val in ipairs(ktype[i]) do                     
                if type(val) == "table" then
                    local temp = pnl:getChildByTag(_i*998 + _j*99)    
                    if temp then
                        local txt = temp:getChildByName("txt_result_long_count")
                        if txt then      
                            txt:setVisible(true)
                            txt:setString(#val)
                        end                           
                    end
                else
                    num = num + 1
                    local clone = self:cloneResult(val, val)                
                    clone:setTag(i*998+num*99) 
                    clone:setPosition(cc.p((14 - mark)*cellx+cellx/2, (10-num)*celly+celly/2)) 
                    pnl:addChild(clone)

                    _i,_j = i,num                 
                end
            end
        end        
    end     
end

function GameTrendLayer:cloneResult(result, circle)
    local item, res, i

    if circle then
        item = self:seekChildByName("img_long_clone")
               
        if result == 3 then
            res = string.format("game/lhd/image/img_result_%d_%d.png", circle, 1)   
        else
            res = string.format("game/lhd/image/img_result_%d_%d.png", result, 1)   
        end        
    else
        item = self:seekChildByName("img_hu_clone") 
        res = string.format("game/lhd/image/img_result_%d.png", result)   
    end
    
    i = item:clone()
    i:setAnchorPoint(cc.p(0.5, 0.5))
    i:ignoreContentAdaptWithSize(true)    
    i:loadTexture(res, ccui.TextureResType.plistType)            
    return i
end

-- 统计近20局结果
function GameTrendLayer:countResult(list)
    local long, hu, he, perl, perh = self._presenter:calPercent(list)
        
    local txtlong = self:seekChildByName("txt_total_long")  
    local txthu = self:seekChildByName("txt_total_hu")  
    local txthe = self:seekChildByName("txt_total_he")  
    local round = self:seekChildByName("txt_total_round")
    local txtl = self:seekChildByName("txt_long_rate") 
    local txth = self:seekChildByName("txt_hu_rate") 
    
	txtlong:setString(#long)
	txthu:setString(#hu)
    txthe:setString(#he)
    round:setString("局数：" ..  #long + #hu + #he)		
    txtl:setString(perl .. "%")
    txth:setString(perh .. "%")
    self:updateProgress(perl, perh)
end

function GameTrendLayer:updateProgress(perl, perh)
    local back = self:seekChildByName("img_back")    
    local long = self:seekChildByName("img_long_blue")
    local hu = self:seekChildByName("img_hu_red")
    local img20 = self:seekChildByName("img_win_20")
    local txtl = self:seekChildByName("txt_long_rate") 
    local txth = self:seekChildByName("txt_hu_rate") 
    
    local size = back:getContentSize()  
    local i20size = img20:getContentSize()  
    
    local len = size.width - i20size.width - 31
    
    if perl == 0 and perh == 0 then
        perl, perh = 50, 50 
    else    
        if perl < 20 then
            perl = 20
            perh = 80
        end
        if perh < 20 then
            perl = 80
            perh = 20
        end    
    end
    print(perl, perh)
        
    long:setContentSize(cc.size(len *perl/100, 34))
    hu:setContentSize(cc.size(len *perh/100, 34))
    txtl:setPositionX(len *perl/100-30)  
      
    img20:setPositionX(len *perl/100 + 15.5) 
       
    txth:setPositionX(size.width-len *perh/100 + 30)    
end

return GameTrendLayer