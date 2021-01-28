--[[
@brief 规则算法基类
]]--
local app = cc.exports.gEnv.app
local CardRunRule = class("CardRunRule")

local CR          = app.game.CardRule
local cardType    = CR.cardType
local cardNums    = CR.cardNums
local cardColours = CR.cardColours
local cards       = CR.cards
-- 单例
CardRunRule._instance = nil

function CardRunRule:getInstance()
    if self._instance == nil then
        self._instance = self.create()
        self._instance:init()
    end
    return self._instance
end

function CardRunRule:init()   
    self:initData()
end

function CardRunRule:exit()
    self:resetData()
    CardRunRule._instance = nil
end

function CardRunRule:initData()
    self._bombLevel            = 0    -- 炸弹的起始权重
    self._cardTypeIDs          = {}   -- 牌型ID
    self._cardTypeDatas        = {}   -- 牌型数据
    self._cardAtoms            = {}   -- 原子牌型
    self._cardForms            = {}   -- 组合牌型
    self._firstHintCount       = 0    -- 首出提示 
end

function CardRunRule:resetData()
    self._bombLevel            = 0    -- 炸弹的起始权重
    self._cardTypeIDs          = {}   -- 牌型ID
    self._cardTypeDatas        = {}   -- 牌型数据
    self._cardAtoms            = {}   -- 原子牌型
    self._cardForms            = {}   -- 组合牌型
    self._firstHintCount       = 0    -- 首出提示 
end

--[[
    定义牌型信息
    @param :    id                      - 牌型ID
    @param :    name                    - 牌型名称
    @param :    weight                  - 牌型权重(多用于判断炸弹线)
    @param :    minlen                  - 牌型要求的最小节数
        
    举例说明:   addCardType( CTID_YI_SHUN, "单顺", 10, 5 );       - 定义牌型单顺,权重为10,最小5节才成单顺
]]--
function CardRunRule:addCardType(id, name, weight, minLen)
    table.insert(self._cardTypeIDs, id)
    
    self._cardTypeDatas[id] = self._cardTypeDatas[id] or {}
    self._cardTypeDatas[id].id     = id
    self._cardTypeDatas[id].name   = name
    self._cardTypeDatas[id].weight = weight
    self._cardTypeDatas[id].minLen = minLen    
end

--[[
    为牌型ID添加原子牌
    @param :    id                      - 牌型ID
    @param :    from                    - 牌值起始
    @param :    to                      - 牌值结束
    @param :    count                   - 节数量
    @param :    len                     - 单节长度        
    举例说明:   addCardAtomFromTo(CTID_SAN_ZHANG, CN_3, CN_A, 3, 1, vals); --添加牌值为3到A的3张牌作为牌型CTID_SAN_ZHANG,
    权重自动设置,默认权值为3-A为3-14、2为19、小王为21、大王为22    
]]--
function CardRunRule:addCardAtomFromTo(id, from, to, count, len, vals)
    if from <= to then
        for i = from, to do
            local nums = {}
            for k = len-1, 0, -1 do
                for j = 0, count-1 do
                    table.insert(nums,i+k)
                end             
            end
            local power = self:getNumWeight(i + len - 1)
            self:addCardAtom(id, nums, power, count, len, 0, vals)
        end
    else        
        for i = from, to, -1 do
            local nums = {}
            for k = len-1, 0, -1 do
                for j = 0, count-1 do
                    table.insert(nums,i+k)
                end             
            end
            local power = self:getNumWeight(i)
            self:addCardAtom(id, nums, power, count, len, 0, vals)          
        end
    end 
end

--[[
    添加现有的原子牌型
    @param :    id                      - 牌型ID
    @param :    lowerA                  - 用于顺子,是否添加A起头顺子
    @param :    lower2                  - 用于顺子,是否添加B起头顺子
    
    举例说明:   addCardAtomByType(CTID_ER_SHUN); --添加二顺,现有的原子牌型可以参考枚举
]]--
function CardRunRule:addCardAtomByType(id, lowerA, lower2, vals)
    vals = vals or {}
    if id == cardType.CTID_YI_ZHANG or 
        id == cardType.CTID_ER_ZHANG or                      
        id == cardType.CTID_SAN_ZHANG or                       
        id == cardType.CTID_SI_ZHANG then

        local cnt = id
        self:addCardAtomFromTo(id, cardNums.CN_3, cardNums.CN_A, cnt, 1, vals)
        self:addCardAtomFromTo(id, cardNums.CN_2, cardNums.CN_2, cnt, 1, vals)
        self:addCardAtomFromTo(id, cardNums.CN_F, cardNums.CN_Z, cnt, 1, vals)

    elseif id == cardType.CTID_YI_SHUN or   
        id == cardType.CTID_ER_SHUN or 
        id == cardType.CTID_YI_SHUN or 
        id == cardType.CTID_SAN_SHUN then

        local cnt = id - cardType.CTID_YI_SHUN + 1
        local minlen = self:getCardTypeMinLen(id)
        for i = minlen, 12 do
            self:addCardAtomFromTo(id, cardNums.CN_3 , cardNums.CN_A - i + 1, cnt, i, vals)
        end

    elseif id == cardType.CTID_HUO_JIAN then
        local nums = {}
        table.insert(nums, cardNums.CN_Z)
        table.insert(nums, cardNums.CN_F)
        local power = self:getNumWeight(cardNums.CN_Z)
        local cnt = 1
        local len = 2
        self:addCardAtom(id, nums, power, cnt, len, 0, vals)
    end
end

--[[
    为牌型ID添加原子牌
    @param :    id                      - 牌型ID
    @param :    nums                    - 牌值数组
    @param :    power                   - 权重(用于比大小)
    @param :    count                   - 节数量
    @param :    len                     - 单节长度
    @param :    hint                    - 提示个数
    
    添加原子牌基础接口
]]
function CardRunRule:addCardAtom(id, nums, power, count, len, hint, vals)
    local atom = CR.CardAtom:new()
   
    atom.nums = nums
    atom.type = {}
    atom.type.id = id
    atom.type.power = power
    atom.type.count = count
    atom.type.len = len
    atom.type.hint = hint
    if vals then
    	atom.type.vals = vals
    end 

    self._cardAtoms[id] = self._cardAtoms[id] or {}
    table.insert(self._cardAtoms[id], atom)
end

--[[
    添加组合牌型
    @param :    form                    - 组合牌型结构体
    @param :    str                     - 组合牌型字符串
    
    举例说明:   addCardForm(CTID_SAN_DAI_YI, getFormatString("%d'1'0'3'1'0,%d'1'0'1'1'1", CTID_SAN_ZHANG, CTID_YI_ZHANG));
    所谓组合牌型就是该牌型所含的牌组全部由原子牌型组合而成。组合接口addform有2种形式:
    上述这种是用字符串的形式赋值，逗号(,)隔开2种牌型，单引号(‘)隔开每种牌型要传的值，按顺序分别代表如下表所列值：
    牌型ID    个数  添加的牌权值  每节张数    长度(顺子的节数)   提示的个数
    这里有2个参数需要解释一下，一个是添加的牌权值，设为非0,如为6，三张则只添加三个6，三顺则只添加444555666，
    如设为0，全部权值都添加，默认权值为3-A为3-14、2为19、小王为21、大王为22；
    另一个是提示的个数，该牌型组合提示的个数为这里设置的数，
    例如444555666带2个单张的提示，2个单张可以有许多组合，
    如果这里设置2，那就往容器放入2个牌组，提示就这2个循环提示，如果为0，那就所有可能的牌组都提示。
]]
function CardRunRule:addCardFormEx(id, form)
    self._cardForms[id] = self._cardForms[id] or {}    
    table.insert(self._cardForms[id], form)
end

function CardRunRule:addCardForm(id, str)
    local rules = self:strToFormRule(str)
    local form = CR.CardForm:new()
    form.type = {}
    form.type.id = id
    form.rules = rules
    
    self:addCardFormEx(id, form)
end

function CardRunRule:strToFormRule(str)
    local rule = {}
    local sp0 = ","
    local sp1 = "'"
    local vs = string.split(str, sp0)
    for i=1, #vs do
        local vn = string.split(vs[i], sp1)
        local tmp = CR.CardFormRule:new()
        tmp.type = {}
        tmp.type.id    = vn[1]
        tmp.count      = vn[2]
        tmp.type.power = vn[3]
        tmp.type.count = vn[4]
        tmp.type.len   = vn[5]
        tmp.type.hint  = vn[6]
       	
       	for j=7,#vn do
            table.insert(tmp.type.vals, vn[j])       		
       	end
       	
        table.insert(rule, tmp)
    end

    return rule
end

-- 设置炸弹起始权重,即牌型权重大于该值的牌型为炸弹
function CardRunRule:setBombLevel(level)
    self._bombLevel = level
end

function CardRunRule:getBombLevel()
    return self._bombLevel
end

function CardRunRule:getCardTypeMinLen(id)
    return self._cardTypeDatas[id].minLen
end

function CardRunRule:getNumWeight(num)
    if num == cardNums.CN_Z then
        return 22
    elseif num == cardNums.CN_F then
        return 21
    elseif num == cardNums.CN_2 then
        return 19
    else
        return num
    end
end

function CardRunRule:getCardWeight(card)
	return self:getNumWeight(self:getCardNum(card))
end

function CardRunRule:getCardColor(card)
    if card == cards.CV_BACK then
        return cardColours.CC_BACK

    elseif card == cards.CV_WANG_F or card == cards.CV_WANG_Z then
        return cardColours.CC_WANG

    elseif card >= cards.CV_FANG_A and card <= cards.CV_FANG_K then
        return cardColours.CC_FANG

    elseif card >= cards.CV_MEI_A and card <= cards.CV_MEI_K then
        return cardColours.CC_MEI

    elseif card >= cards.CV_HONG_A and card <= cards.CV_HONG_K then   
        return cardColours.CC_HONG
        
    elseif card >= cards.CV_HEI_A and card <= cards.CV_HEI_K then
        return cardColours.CC_HEI
        
    else
        return cardColours.CC_NULL
    end
end

function CardRunRule:getCardNum(card)
    if card == cards.CV_BACK then
        return cardNums.CN_B
        
    elseif card == cards.CV_WANG_F then
        return cardNums.CN_F
                
    elseif card == cards.CV_WANG_Z then
        return cardNums.CN_Z
                
    elseif card == cards.CV_FANG_A or card == cards.CV_MEI_A or card == cards.CV_HONG_A or card == cards.CV_HEI_A then
        return cardNums.CN_A           
        
    elseif card >= cards.CV_FANG_2 and card <= cards.CV_FANG_K then
        return cardNums.CN_2 + (card - cards.CV_FANG_2)
        
    elseif card >= cards.CV_MEI_2 and card <= cards.CV_MEI_K then
        return cardNums.CN_2 + (card - cards.CV_MEI_2)
        
    elseif card >= cards.CV_HONG_2 and card <= cards.CV_HONG_K then
        return cardNums.CN_2 + (card - cards.CV_HONG_2)
        
    elseif card >= cards.CV_HEI_2 and card <= cards.CV_HEI_K then
        return cardNums.CN_2 + (card - cards.CV_HEI_2)    
    
    else
        return cardNums.CN_NULL
	end	
end

function CardRunRule:getCard(color, num)
    if color == cardColours.CC_BACK then
        if num == cardNums.CN_B then
            return cards.CV_BACK
        end
        
    elseif color == cardColours.CC_WANG then
        if num == cardNums.CN_Z then
            return cards.CV_WANG_Z
        elseif num == cardNums.CN_F then
            return cards.CV_WANG_F
        end
        
    elseif color == cardColours.CC_FANG then
        if num == cardNums.CN_A then        
            return cards.CV_FANG_A        
        else        
            return cards.CV_FANG_2 + (num - cardNums.CN_2)
        end
     
    elseif color == cardColours.CC_MEI then
        if num == cardNums.CN_A then        
            return cards.CV_MEI_A        
        else        
            return cards.CV_MEI_2 + (num - cardNums.CN_2)
        end
        
    elseif color == cardColours.CC_HONG then
        if num == cardNums.CN_A then        
            return cards.CV_HONG_A       
        else        
            return cards.CV_HONG_2 + (num - cardNums.CN_2)
        end
        
    elseif color == cardColours.CC_HEI then
        if num == cardNums.CN_A then        
            return cards.CV_HEI_A      
        else        
            return cards.CV_HEI_2 + (num - cardNums.CN_2)
        end
    end   
    
    return cards.CV_NONE
end

function CardRunRule:isSameNumSubCards(cards1, cards2)
    if #cards2 == 0 then
		return true
	end
	
    local tmp1 = cards1    
    for i=1, #cards2 do
        if not self:delSameNumCard(tmp1, cards2[i]) then
    		return false
    	end
    end
	
	return true
end

function CardRunRule:delSameNumCard(cards, delCard)
    for i, card in ipairs(cards) do
        if self:getCardNum(card) == self:getCardNum(delCard) then
            table.remove(cards, i)
            return true
        end
    end

    return false	
end

function CardRunRule:addCards(cards, addCards)
	for i=1, #addCards do
        table.insert(cards, addCards[i])  
	end
    return cards
end

function CardRunRule:sortByWeight(cards)
	if #cards < 2 then
        return cards
	end
	
    for i=1, #cards do
        for j = i+1, #cards do
            if self:getCardWeight(cards[i]) < self:getCardWeight(cards[j]) or             
                (self:getCardWeight(cards[i]) == self:getCardWeight(cards[j]) and self:getCardColor(cards[i]) < self:getCardColor(cards[j])) then
                cards[i], cards[j] = cards[j], cards[i]
            end
        end
    end
	
    return cards
end

-- 查找能大过给定的牌组的牌，返回所有的可能牌组
function CardRunRule:hintCards(cards, preComb, retCombs, hintCount)
    hintCount = hintCount or 0
	retCombs = {}
    
	for i=1, #self._cardTypeIDs do
        local id = self._cardTypeIDs[i]
        local tmpCombs = {}
        local flag = false
        flag, tmpCombs = self:hintCards1(cards, id, preComb, tmpCombs)
        if flag then
            self:addcombs(retCombs, tmpCombs)                    
        end
	end
	
    return retCombs, #retCombs > 0
end

-- 查找能大过给定的牌组并且是给定牌型的牌，返回所有的可能牌组
function CardRunRule:hintCards1(cards, id, preComb, retCombs)
    retCombs = {}
    if self:isCardAtom(id) then                
        for i=1,#self._cardAtoms[id] do            
            local atom = self._cardAtoms[id][i]
            
            if self:canOutFilter(atom.type, preComb.type) then
                local tmpHand = {}
                local tmpSubCards = {}
                local flag, tmpHand = self:findCardsByNums(cards, atom.nums, tmpSubCards, tmpHand) 
                if flag then                    
                    local comb = CR.CardComb:new()
                    comb.cards = tmpHand
                    comb.nums = atom.nums
                    comb.type = atom.type
                    
                    if self:canOut(comb, preComb) then
                        if self:onHintFilter(preComb, comb) then
                            table.insert(retCombs, comb)              		
                    	end
                    end
                end
        	end
        end
	end
	
	if self:isCardForm(id) then  	   
		for i=1, #self._cardForms[id] do		     
            local form = self._cardForms[id][i]    
            if self:canOutFilter(form.type, preComb.type) then                
                local sfs = CR.CardSepForest:new()                                               
                local flag  
       
                flag, sfs = self:sepCards(form.rules, cards, sfs, #preComb.cards == 0, id, i)
        
                local shs = {}
                shs = self:sepForestToSepHands(sfs, shs,id,i)
                
                for j=1, #shs do
                    if #shs[j].combs > 0 then
                        local tmpComb = CR.CardComb:new()
                        tmpComb.cards = self:getSepCards(shs[j], tmpComb.cards)
                        tmpComb.nums = self:getSepNums(shs[j], tmpComb.nums)
                        
                        tmpComb.type = {}
                        tmpComb.type = shs[j].combs[1].type
                        tmpComb.type.id = id
                        
                        if self:canOut(tmpComb, preComb) then
                            if self:onHintFilter(preComb, tmpComb) then
                                table.insert(retCombs, tmpComb)                                                                                               
                        	end
                        end                        
                	end
                end                              
            end
		end
	end

    return #retCombs > 0, retCombs	
end

function CardRunRule:isCardAtom(id)
    for key, var in pairs(self._cardAtoms) do       
        if key == id then            
            return true
        end
    end
	return false
end

function CardRunRule:isCardForm(id)
    for key, var in pairs(self._cardForms) do
        if key == id then
            return true
        end
    end

    return false
end

function CardRunRule:addcombs(combs, adds)
    for i=1, #adds do
        table.insert(combs, adds[i])    	
    end	
end

function CardRunRule:getCardTypeWeight(id)
    for key, var in pairs(self._cardTypeDatas) do
        if key == id then
            return var.weight
        end
    end
    return 0
end

function CardRunRule:getFirstHintCount()
    return self._firstHintCount
end

function CardRunRule:findCardsByNums(cards, nums, subCards, retCards)    
	retCards = {}
	if #cards < #nums then
		return false
	end
	
    if #nums < #subCards then        
		return false
	end
    local tmpCards = clone(cards)
    local tmpSubCards = clone(subCards)
    if not self:delCards(tmpCards, tmpSubCards) then        
		return false
	end
    local normals = tmpCards
	for i=1, #nums do
		local fix = false
        for j, it in ipairs(tmpSubCards) do
			if self:getCardNum(it) == nums[i] then
                table.insert(retCards, it)
                table.remove(tmpSubCards, j)
                fix = true
                break
			end
		end
		
		if fix == false then
            for k, it in ipairs(normals) do
                if self:getCardNum(it) == nums[i] then
                    table.insert(retCards, it)
                    table.remove(normals, k)
                    fix = true
                    break
                end
            end
		end
		
        if fix == false then
			retCards = {}
			return false
		end
	end
	
    return true, retCards
end

function CardRunRule:delCards(cards, delCards)
	for i=1, #delCards do
        if self:delCard(cards, delCards[i]) == false then
			return false
		end
	end
	return true
end

function CardRunRule:delCard(cards, delCard)
    for i, card in ipairs(cards) do
        if card == delCard then
            table.remove(cards, i)
            return true
		end
	end
    return false
end


-- 判断一个牌组是否大过另一个牌组的提前过滤，注：不能过滤全部，即通过这个接口的，不一定能通过canout接口，起优化算法的作用
function CardRunRule:canOutFilter(outType, preType)    
    if preType.id == 0 then
        if outType.id > 0  then
            return true
        end
    else
        if outType.id == 0 then
            return false
        end
                
        local outWeight = self:getCardTypeWeight(outType.id)
        local preWeight = self:getCardTypeWeight(preType.id)
        
        if outWeight == 0 or preWeight == 0 then
        	return false
        end
        
        if outWeight > self._bombLevel then
            if preWeight < self._bombLevel then
        		return true
        	end
            if outWeight > preWeight then
        		return true
            elseif outWeight == preWeight then 
                if outType.len > preType.len then
                	return true
                elseif outType.len == preType.len then
                    if outType.count > preType.count then
                    	return true
                    elseif outType.count == preType.count then
                        if outType.power > preType.power then
                        	return true
                        end	
                    end	
                end
        	end
        	return false
        end
        
        if outWeight == preWeight then
        	return true
        end        
    end
    return false
end

function CardRunRule:canOut(outComb, preComb)
	local outType = outComb.type
    local preType = preComb.type
    
    local outWeight = self:getCardTypeWeight(outType.id)
    if preType.id == 0 then
        if outType.id > 0 then
    		return true
    	end
    	
    else
        
        if outType.id == 0 then
        	return false
        end
        
        local outWeight = self:getCardTypeWeight(outType.id)
        local preWeight = self:getCardTypeWeight(preType.id)
        
        if outWeight == 0 or preWeight == 0 then
        	return false
        end
        
        if outWeight > self._bombLevel then
            if preWeight < self._bombLevel then
            	return true
            end
            
            if outWeight > preWeight then
            	return true            	
            elseif outWeight == preWeight then
                if outType.len > preType.len then
                	return true
                
                elseif outType.len == preType.len then
                    if outType.count > preType.count then
                    	return true
                    elseif outType.count == preType.count then
                        if outType.power > preType.power then                        
                            return true
                        end
                    end
                end
            end
            
        	return false
        end
        
        if #outComb.cards ~= #preComb.cards then
            return false	   
        end
        
        if outWeight == preWeight then
        	if outType.len == preType.len and outType.count == preType.count and outType.power > preType.power then
        		return true
        	end
        end 	
    end
    return false
end

function CardRunRule:onHintFilter(preComb, comb)
	if not self:onCardCombFilter(comb) then
		return false
	end
	
	for i=1, #comb.cards do
		if self:getCardNum(comb.cards[i]) ~= comb.nums[i] then
			return false
		end
	end
	
	return true
end

function CardRunRule:onCardCombFilter(retComb)
    if #retComb.cards == #retComb.nums then
		for i=1, #retComb.cards do
            if retComb.nums[i] == cardNums.CN_Z then
                if retComb.cards[i] == cards.CV_WANG_F then
					return false
				end
			end
		end
	end
	return true
end

function CardRunRule:sepCards(rules, cards, forest, first, id, index)
    forest.rules = {}
    forest.trees = {}
    
    if #rules == 0 then
		return true
	end
	
    forest.rules = rules
    local tmpRules = clone(rules)
    local tmpCards = clone(cards)
    local tmpType = CR.CardType:new()
    local flag, tmpType = self:sepFirstType(tmpRules, tmpType)  
  
    if flag then
        local bfalg
        local tmpCombs = {}
        bfalg, tmpCombs = self:sepCards1(tmpType, tmpCards, tmpCombs, first, id, index)
        
        if bfalg then                     
            for i=1, #tmpCombs do                                
                local tmpSubRules = clone(tmpRules)
                local tmpSubCards = clone(tmpCards)

                self:delCards(tmpSubCards, tmpCombs[i].cards)
                
                local subTree = CR.CardSepTree:new()                
                subTree.comb = tmpCombs[i]
                subTree._children = {}
                local cflag
                cflag, subTree = self:sepCards2(tmpSubRules, tmpSubCards, subTree, first, id, index)  
                if cflag then
                    table.insert(forest.trees, subTree)
                end
            end    		
        end    	
    end

    return #forest.trees > 0, forest    
end

function CardRunRule:sepFirstType(rules, type)
    if #rules == 0 then
		return false
	end
	
    local it = rules[1]
    it.count = tonumber(it.count)
    if it.count == 0 then
		return false
	end

    if it.count > 1 then
        type = it.type
        it.count = it.count - 1
        return true, type
    end

    type = it.type
    table.remove(rules, 1)
	
    return true, type 
end

function CardRunRule:sepCards1(type, cards, retCombs, first, id, index)
	retCombs = {}    
    type.id = tonumber(type.id)
    if self:isCardAtom(type.id) == false then
		return false      
	end
    
    for i=1, #self._cardAtoms[type.id] do                
        local tmpComb = CR.CardComb:new()
        local atom = self._cardAtoms[type.id][i]       

        type.power = tonumber(type.power)
        atom.type.power = tonumber(atom.type.power)
        
        type.count = tonumber(type.count)
        atom.type.count = tonumber(atom.type.count)

        type.len = tonumber(type.len )
        atom.type.len = tonumber(atom.type.len)
        
        local enter = true
        if type.power ~= 0 and type.power ~= atom.type.power then
            enter = false         
        end    
        if type.count ~= 0 and type.count ~= atom.type.count then
            enter = false
        end                  
        if type.len ~= 0 and type.len ~= atom.type.len then           
            enter = false  
        end
        
        if enter then
            local tmpSubCards = {} 
            local _tmpcards = {} 
            local flag = false 
            dump(cards)     
            flag, _tmpcards = self:findCardsByNums(cards, atom.nums, tmpSubCards, _tmpcards)

            if flag then     
                tmpComb.cards = _tmpcards
                tmpComb.nums = atom.nums
                tmpComb.type = atom.type                
                table.insert(retCombs, tmpComb)
            end    
        end       
    end

    return #retCombs > 0, retCombs
end

function CardRunRule:sepCards2(rules, cards, tree, first, id, index)    
    if #rules == 0 then
        return true, tree
    end

    local tmpRules = clone(rules)
    local tmpCards = clone(cards)
    local tmpType = CR.CardType:new()
    local flag
    
    flag, tmpType = self:sepFirstType(tmpRules, tmpType)  
    if flag then
        local tmpCombs = {}
        local bflag 

        bflag, tmpCombs = self:sepCards1(tmpType, tmpCards, tmpCombs, first, id) 
 
        if bflag then          
        	for i=1, #tmpCombs do
                local tmpSubRules = clone(tmpRules)                
                local tmpSubCards = clone(tmpCards)             
                self:delCards(tmpSubCards, tmpCombs[i].cards)                 
                local subTree = CR.CardSepTree:new()
                subTree.comb = tmpCombs[i]                         
                local cflag
                cflag, subTree = self:sepCards2(tmpSubRules, tmpSubCards, subTree, first)            
                if cflag then                                                           
                    table.insert(tree._children, subTree) 
                end                   		
        	end
        end    
    end
    
    return #tree._children > 0, tree
end

function CardRunRule:sepForestToSepHands(forest, hands,id,index)
	hands = {}
	for i=1, #forest.trees do
        local tmpCombs = {}
        local tmpHands = {}
        tmpHands = self:sepTreeToSepHands(forest.trees[i], forest.rules, tmpCombs, tmpHands, id, index)
		
		for j=1, #tmpHands do
            table.insert(hands, tmpHands[j])
		end		
	end

    return hands		
end

function CardRunRule:sepTreeToSepHands(tree, rules, combs, hands, id, index)         
    if #tree._children == 0 then  
        local tmpCombs = {}         
        table.insert(tmpCombs, tree.comb)
    
        local tmpHand = CR.CardSepHand:new()
        tmpHand.rules = rules
        tmpHand.combs = tmpCombs
        table.insert(hands, tmpHand)        
        return true
    end

    local tmpCombs = {} 
    table.insert(tmpCombs, tree.comb)
        
    if rules[2] then
        local otherNum = tonumber(rules[2].count) or 0
        if otherNum == 1 then
            for k, it in ipairs(tree._children) do
                -- 去掉炸弹当作三带一的情况333 3
                if id == CR.cardType.CTID_SAN_DAI_YI then 
                    if tree.comb.nums[1] ~= it.comb.nums[1] then
                        local _tmp = clone(tmpCombs)
                        table.insert(_tmp, it.comb)

                        local tmpHand = CR.CardSepHand:new()
                        tmpHand.rules = rules
                        tmpHand.combs = _tmp
                        table.insert(hands, tmpHand)          
                	end
                else
                    local _tmp = clone(tmpCombs)
                    table.insert(_tmp, it.comb)

                    local tmpHand = CR.CardSepHand:new()
                    tmpHand.rules = rules
                    tmpHand.combs = _tmp
                    table.insert(hands, tmpHand)                	
                end
            end
        elseif otherNum > 1 then
            if #tree._children >=  otherNum then
                local _tmp = clone(tmpCombs)
                for i=1, otherNum do
                    table.insert(_tmp, tree._children[i].comb)
                end
                
                local tmpHand = CR.CardSepHand:new()
                tmpHand.rules = rules
                tmpHand.combs = _tmp
                table.insert(hands, tmpHand)
            end
        end
    end

    return hands
end

function CardRunRule:getSepCards(hand, cards)
	cards = {}
	for i=1, #hand.combs do
        self:addCards(cards, hand.combs[i].cards)
	end
	
    return cards
end

function CardRunRule:getSepNums(hand, nums)
	nums = {}
	for i=1, #hand.combs do
        self:addCards(nums, hand.combs[i].nums)
	end
    return nums
end


-- 检测一手牌，并限定这手牌的属性，返回对应的完整的牌组
function CardRunRule:testCardComb(cards, tid, power, retComb)
    local maxcomb = CR.CardComb:new()
    local flag, combs = self:testCardCombs(cards)    
    if flag then
    	for i=1, #combs do
    		if combs[i].type.id == tid 
                and combs[i].type.power == power 
                and #combs[i].nums == #cards
                and combs[i].type.len > maxcomb.type.len then
    			
                maxcomb = combs[i]                
    		end
    	end
        if #maxcomb.cards == 0 then
    		for i=1, #combs do
    			if combs[i].type.id == tid 
                    and combs[i].type.power == power 
                    and #combs[i].nums == #cards then
                    
                    maxcomb = combs[i]
    			end
    		end
    	end
    	
        if #maxcomb.cards == 0 then
            for i=1, #combs do
                if combs[i].type.id == tid then
                
                    maxcomb = combs[i]
                end
            end
        end    	
    end
    
    return maxcomb
end

-- 检测一手牌，返回这手牌的所有可能牌组
function CardRunRule:testCardCombs(cards)
    local retCombs = {}

    for i=1, #self._cardTypeIDs do
        local id = self._cardTypeIDs[i]
    	local flag1, tmpcombs1 = self:testCardAtomCombs(cards, id)
    	if flag1 then
            self:addcombs(retCombs, tmpcombs1)
    	end
    	
        local flag2, tmpcombs2 = self:testCardFormCombs(cards, id)
        if flag2 then
            self:addcombs(retCombs, tmpcombs2)
        end
    end
    
    return #retCombs > 0, retCombs
end

-- 检测一手牌，返回这手牌在指定原子牌型下的可能牌组
function CardRunRule:testCardAtomCombs(cards, id)
    local retCombs = {}
    id = tonumber(id)
    if self:isCardAtom(id) == false then
        return false, retCombs
	end
	
    local tmpcards = clone(cards)
	local atoms = self._cardAtoms[id]
	
	for j=1, #atoms do
        local atom = atoms[j]
        local flag = true
        
        local countCards = atom.type.count * atom.type.len        
        if countCards > #cards then
            flag = false
        elseif countCards < #cards then
            if #atom.type.vals == 0 then  
                flag = false          	
            end            	
        end
        
        if flag then
        	if #atom.nums == 0 and #atom.type.vals > 0 then
                local fixs = {}
        		local fixnums = {}
                local lefts = clone(cards)
                
                local bflag, tmpcombs = self:onTestAtomCombs(atom.type, fixnums, fixs, lefts)
                if bflag then
                    self:addcombs(retCombs, tmpcombs)
                end
            else
                local tmphand = {}
                local tmpsubcards = {}
                local cflag, tmphand = self:findCardsByNums(cards, atom.nums, tmpsubcards, tmphand)                 
                if cflag then
                    if #atom.type.vals > 0 then
                        local lefts = clone(cards)
                        self:delCards(lefts, tmphand)
                		
                        local bflag, tmpcombs = self:onTestAtomCombs(atom.type, atom.nums, tmphand, lefts)
                        if bflag then
                            self:addcombs(retCombs, tmpcombs)
                        end
                    else
                        if #cards == #atom.nums then
                            local comb = CR.CardComb:new()
                            comb.cards = tmphand
                            comb.type = atom.type
                            comb.nums = atom.nums
                            if self:onCardCombFilter(comb) then
                                table.insert(retCombs, comb)
                            end
                        end                            
                	end
                end            
        	end
        end
	end
    return #retCombs > 0, retCombs
end

-- 自检测原子牌型
function CardRunRule:onTestAtomCombs(type, fixnums, fixs, lefts, retCombs)
	retCombs = {}	
	if #fixnums < 2 or #fixs < 2 or #fixnums ~= #fixs then
        return false
	end
	
	for i=1, #lefts do
        if not self:isSameNumSubCard(fixs, lefts[i]) then
			return false
		end		
	end
	
    local tmplefts = clone(lefts)
    local comb = CR.CardComb:new()
    
    local precard = fixs[1]
    local prenum = fixnums[1]
    
    table.insert(comb.cards, precard)
    table.insert(comb.nums, prenum)
    
    for i=2, #fixs do
        local nowcard = fixs[i]
        local nownum = fixnums[i]
        
        if nownum ~= prenum then
            local temps = {}
            for j=1, #tmplefts do
                local left = tmplefts[j]
                local leftnum = self:getCardNum(left)
                
                if leftnum == prenum then
                    table.insert(comb.cards, left)
                    table.insert(comb.nums, prenum)
                else
                    table.insert(temps, left)    
                end                
            end            
            tmplefts = temps
        end
        
        table.insert(comb.cards, nowcard)
        table.insert(comb.nums, nownum)  
        
        precard = nowcard
        prenum = nownum     
    end
    
    if #tmplefts ~= 0 then
    	for j=1, #tmplefts do
            local left = tmplefts[j]    	
            local leftnum = self:getCardNum(left)
            if leftnum == prenum then
                table.insert(comb.cards, left)
                table.insert(comb.nums, prenum)  
            end
    	end
    end
    
    comb.type = type
    local fixsones, leftsones
    self:somesToOnes(fixs, fixsones)
    self:somesToOnes(lefts, leftsones)
    if #fixsones <= #leftsones then
        print("somes false")
    	return false
    end
    
    table.insert(retCombs, comb)
    
    return true
end

function CardRunRule:isSameNumSubCard(cards, card)
	for i=1, #cards do
        if self:getCardNum(cards[i]) == self:getCardNum(card) then
			return true
		end
	end
	return false
end

function CardRunRule:somesToOnes(somes, ones)
	ones = {}
	local tmps = {}
	for i=1, #somes do
        local key = self:getCardNum(somes[i])
        if not tmps[key] then
            tmps[key] = somes[i]
            table.insert(ones, somes[i])    
        end        	
	end
	
	return true
end
 
-- 检测一手牌，返回这手牌在指定组合牌型下的可能牌组
function CardRunRule:testCardFormCombs(cards, id)
    local retCombs = {}
    if self:isCardForm(id) == false then
        return false      	
    end
    
    for i=1, #self._cardForms[id] do
        local form = self._cardForms[id][i]
        
        local sfs = CR.CardSepForest:new()                                               
        local flag                
        flag, sfs = self:sepCards(form.rules, cards, sfs)            
        local shs = {}
        shs = self:sepForestToSepHands(sfs, shs)

        for j=1, #shs do
            if #shs[j].combs > 0 then
                local tmpComb = CR.CardComb:new()
                tmpComb.cards = self:getSepCards(shs[j], tmpComb.cards)
                tmpComb.nums = self:getSepNums(shs[j], tmpComb.nums)

                tmpComb.type = {}
                tmpComb.type = shs[j].combs[1].type
                tmpComb.type.id = id

                if #tmpComb.cards == #cards then
                    if self:onCardCombFilter(tmpComb) then
                        table.insert(retCombs, tmpComb)
                    end
                end                        
            end
        end                              
    end
        
    return #retCombs > 0, retCombs     
end

-- 检测一手牌，返回这手牌的最大权重牌组
function CardRunRule:testMaxCardComb(cards)
    local retComb = {}	
    local flag, combs = self:testCardCombs(cards)   
    if flag then
        local bflag, retComb
        bflag, retComb = self:maxComb(combs, retComb)
        if bflag then
            return retComb
		end
	end
	retComb = {}
    return retComb		
end

-- 从一系列牌组中找出最大权重的牌组
function CardRunRule:maxComb(combs, retComb)
    if #combs == 0 then
    	return false
    end
    if #combs == 1 then
        retComb = combs[1]
        return true, retComb
    end	
    
    local cnt = #combs
    retComb = combs[cnt]
    
    for i = cnt-1, 1 do
        if self:getCardTypeWeight(retComb.type.id) < self:getCardTypeWeight(combs[i].type.id) then
            retComb = combs[i]
        elseif self:getCardTypeWeight(retComb.type.id) == self:getCardTypeWeight(combs[i].type.id) then
            if retComb.type.power < combs[i].type.power then
                retComb = combs[i]
            end            
    	end
    end
    
    return true, retComb         
end

-- 判断一手牌是否大过给定的牌组，并返回最大的牌组
function CardRunRule:canOutFromMaxComb(outs, preComb)
    local retMaxComb = {}
    local flag,combs = self:canOutCombs(outs, preComb)    
    if flag then
        local retMaxComb = {}
        local bflag, retMaxComb = self:maxComb(combs, retMaxComb)
        if bflag then
            return retMaxComb
    	end
    end
    retMaxComb = {}
    return retMaxComb       
end

function CardRunRule:canOutCombs(outs, preComb)
	local retCombs = {}	
    if #outs == 0 then
		return false
	end

    local flag, combs = self:testCardCombs(outs) 
    if flag then
    	for i=1, #combs do
            if self:canOut(combs[i], preComb) then
                table.insert(retCombs, combs[i])
    		end
    	end
    end
    
    return #retCombs > 0, retCombs  
end

return CardRunRule