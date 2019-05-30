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
     
    self:countResult()
    self:countProgress()
end

function GameTrendLayer:updateTrendOne(result, list)
    if not list then return end

    self:addHistory(list) 
    self:addHistoryLeftOne(result, list)      
    self:addHistoryRight(list) 
    
    self:countResult()
    self:countProgress()
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
        clone:setTag(list[k])
        pnl:addChild(clone)            
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
        clone:setTag(list[index])   	          
        pnl:addChild(clone) 
        clone:setPosition(cc.p((col-1)*(cell+border)+cell/2, (6-i)*(cell+inter)+cell/2))
    end
   
    for i=1,col do
        for j=1,6 do
        	local index = (i-1)*6 + j
            local clone = self:cloneResult(list[index]) 
            clone:setTag(list[index])            
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
        clone:setTag(result) 
        clone:setPosition(cc.p(7*(cell+border)+cell/2, 5*(cell+inter)+cell/2))                             
    else
        local clone = self:cloneResult(result) 
        clone:setTag(result)              
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

-- 统计近48局结果
function GameTrendLayer:countResult()
    local panel = self:seekChildByName("pnl_detail_left")
    local childs = panel:getChildren()
    local c_long, c_hu, c_he = 0, 0, 0
    for k, v in ipairs(childs) do
        if v:getTag() == 1 then
            c_long = c_long + 1
        elseif v:getTag() == 2 then
            c_hu = c_hu + 1
        elseif v:getTag() == 3 then
            c_he = c_he + 1
        end    	
    end
    
    local txtlong = self:seekChildByName("txt_total_long")  
    local txthu = self:seekChildByName("txt_total_hu")  
    local txthe = self:seekChildByName("txt_total_he")  
    local round = self:seekChildByName("txt_total_round")
    txtlong:setString(c_long)
    txthu:setString(c_hu)
    txthe:setString(c_he)
    round:setString("局数：" ..  #childs)      
end

function GameTrendLayer:countProgress()
    local panel = self:seekChildByName("pnl_record")
    local childs = panel:getChildren()
    
    dump(childs)
    print("childs",#childs)
    
    local c_long, c_hu, c_he = 0, 0, 0
    for k, v in ipairs(childs) do
        print("pro is", v:getTag())
        if v:getTag() == 1 then
            c_long = c_long + 1
        elseif v:getTag() == 2 then
            c_hu = c_hu + 1
        elseif v:getTag() == 3 then
            c_he = c_he + 1
        end     
    end
    local perl, perh = 0, 0 
    if c_long == 0 and c_hu == 0 then
    else
        perl = math.ceil(100 * c_long / (c_long + c_hu))
        perh = 100 - perl
    end
    
    print("perl",perl)
    print("perh",perh)
    
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
    
    long:setContentSize(cc.size(len *perl/100, 34))
    hu:setContentSize(cc.size(len *perh/100, 34))
    txtl:setPositionX(len *perl/100-30)        
    img20:setPositionX(len *perl/100 + 15.5)        
    txth:setPositionX(size.width-len *perh/100 + 30)  
    txtl:setString(perl .. "%")
    txth:setString(perh .. "%")
end

return GameTrendLayer