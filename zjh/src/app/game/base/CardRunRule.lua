--[[
@brief 规则算法基类
]]--

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

return CardRunRule