--[[
    @brief 斗地主游戏规则
]]--

local GameRunRule = class("GameRunRule", app.game.CardRunRule)

local CR = app.game.CardRule
local cardType   = CR.cardType
local cardNums   = CR.cardNums
local cardsValue = CR.cards

function GameRunRule:exit()
    GameRunRule.super.exit(self)
    
    GameRunRule._instance = nil
end

function GameRunRule:initData()
    GameRunRule.super.initData(self)
end

function GameRunRule:resetData()
    GameRunRule.super.resetData(self)
end

function GameRunRule:init()
    GameRunRule.super.init(self)
    
    --添加牌型
    self:addCardType(cardType.CTID_YI_ZHANG, "单张", 1, 1) 
    self:addCardType(cardType.CTID_ER_ZHANG, "对子", 2, 1) 
    self:addCardType(cardType.CTID_SAN_ZHANG, "三张", 3, 1) 
    self:addCardType(cardType.CTID_YI_SHUN, "单顺", 10, 5) 
    self:addCardType(cardType.CTID_ER_SHUN, "双顺", 11, 3)
    self:addCardType(cardType.CTID_SAN_SHUN, "三顺", 12, 2)
    self:addCardType(cardType.CTID_SAN_DAI_YI, "三带一", 20, 1) 
    self:addCardType(cardType.CTID_SAN_DAI_ER, "三带二", 30, 1) 
    self:addCardType(cardType.CTID_FEI_JI, "飞机带翅膀", 40, 2) 
    self:addCardType(cardType.CTID_SI_DAI_ER, "四带二", 50, 1)
    self:addCardType(cardType.CTID_SI_ZHANG, "炸弹", 110, 1) 
    self:addCardType(cardType.CTID_HUO_JIAN, "火箭", 120, 1)
    --设置炸弹线
    self:setBombLevel(100)

    self:addCardAtomByType(cardType.CTID_YI_ZHANG)
    self:addCardAtomByType(cardType.CTID_ER_ZHANG)
    self:addCardAtomByType(cardType.CTID_SAN_ZHANG)
    self:addCardAtomByType(cardType.CTID_SI_ZHANG)
    
    self:addCardAtomByType(cardType.CTID_YI_SHUN)
    self:addCardAtomByType(cardType.CTID_ER_SHUN)
    self:addCardAtomByType(cardType.CTID_SAN_SHUN)
    
    self:addCardAtomByType(cardType.CTID_HUO_JIAN)
    
    self:addCardForm(cardType.CTID_SAN_DAI_YI, string.format("%d'1'0'3'1'0,%d'1'0'1'1'1", cardType.CTID_SAN_ZHANG, cardType.CTID_YI_ZHANG));
    self:addCardForm(cardType.CTID_SAN_DAI_ER, string.format("%d'1'0'3'1'0,%d'1'0'2'1'1", cardType.CTID_SAN_ZHANG, cardType.CTID_ER_ZHANG));
    self:addCardForm(cardType.CTID_SI_DAI_ER, string.format("%d'1'0'4'1'0,%d'2'0'1'1'1", cardType.CTID_SI_ZHANG, cardType.CTID_YI_ZHANG));
    self:addCardForm(cardType.CTID_SI_DAI_ER, string.format("%d'1'0'4'1'0,%d'2'0'2'1'1", cardType.CTID_SI_ZHANG, cardType.CTID_ER_ZHANG));

    for i = 2,5 do
        self:addCardForm(cardType.CTID_FEI_JI, string.format("%d'1'0'3'%d'0,%d'%d'0'1'1'1", cardType.CTID_SAN_SHUN, i, cardType.CTID_YI_ZHANG, i));
        self:addCardForm(cardType.CTID_FEI_JI, string.format("%d'1'0'3'%d'0,%d'%d'0'2'1'1", cardType.CTID_SAN_SHUN, i, cardType.CTID_ER_ZHANG, i));
    end

    return true
end

--[[
排序
]]--
function GameRunRule:sortCardsByType(handCards)
    --cardNum是17个牌点对应的数量[CN_NULL=0----CN_B=17]
    local sort_table = {}
    local sortHandCards={}
    for i=1,16 do
        sort_table[i] = {0,0,0,0,0}
    end
    --sort_table[点数][花色]
    for i=1,#handCards  do
        local cardnum = self:getCardNum(handCards[i])
        local cardcolor = self:getCardColor(handCards[i])
        sort_table[cardnum][cardcolor] = sort_table[cardnum][cardcolor]+1
    end

    --大王
    for i=1,sort_table[16][5] do
        table.insert(sortHandCards,54)--大王
    end

    --小王
    for i=1,sort_table[15][5] do
        table.insert(sortHandCards,53)--大王
    end

    --排序规则 1.同牌点数量 2.牌大小
    --numCard_count={ [1]={cardNum=牌点,cardCount=牌数量}}
    local numCard_count = {}
    for i=1,14 do
        local temp = {cardNum=0,cardCount=0}
        local count = 0
        for j=1,4 do
            --numCard_count[1] = numCard_count[1] + sort_table[i][j]
            count = count + sort_table[i][j]
        end
        temp.cardNum,temp.cardCount = i,count
        table.insert(numCard_count,temp)
    end

    --冒泡下沉=>同牌型张数多的往下沉[注因为2是最大的除王的单牌,但点数是最小,在排序的时候取巧为它的数量+1,让它到出现在最左边]
    for j=1,#numCard_count do
        for i = 1 ,#numCard_count - j do
            local count = numCard_count[i].cardCount
            local nextCount = numCard_count[i+1].cardCount
            if numCard_count[i].cardNum == 2 then
                count = count + 1
            end
            if count > nextCount then
                numCard_count[i+1],numCard_count[i] = numCard_count[i],numCard_count[i+1]
            end
        end
    end

    --整合手牌
    for i=14,1,-1  do
        local card_num = numCard_count[i].cardNum
        --花色顺序 黑=>红=>梅=>方
        local heitao   = 4
        local hongfang = 3
        local meihua   = 2
        local fang     = 1
        for i =1,sort_table[card_num][heitao]  do
            table.insert(sortHandCards,self:getCard(heitao,card_num))
        end

        for i = 1,sort_table[card_num][hongfang] do
            table.insert(sortHandCards,self:getCard(hongfang,card_num))
        end

        for i=1,sort_table[card_num][meihua] do
            table.insert(sortHandCards,self:getCard(meihua,card_num))
        end

        for i=1,sort_table[card_num][fang] do
            table.insert(sortHandCards,self:getCard(fang,card_num))
        end
    end

    return sortHandCards
end

function GameRunRule:resetData()
    self._canOutCombs = {}
    self._perComb = app.game.CardRule.CardComb:new()
    self._hintComb = {}
    self._startHintIndex = 1
end

--牌组是否有效
function GameRunRule:checkComb(comb)
    if (comb == nil) then
        return false
    end

    if (type(comb) ~= "table") then
        return false
    end

    if (#comb.cards == 0) then
        return false
    end

    return true
end

-- 是否需要自动过牌(上家出的牌比你的手牌还要多,并且你的手牌小于等于两张 不可能为炸弹)
function GameRunRule:isNeedAutoPass(preOutCards,HandCards)
    if #HandCards<=2 and #preOutCards > #HandCards then
        return true
    else
        return false
    end
end

-- 把一手牌从手牌中删除
function GameRunRule:delCardsFromHand(cards,handCards)
    local tLeftHandCards = {} 
    local hasMatchedList = {}
    for i=1,#cards do
        for j=1,#handCards do
            if handCards[j] == cards[i] and hasMatchedList[j]==nil then
                hasMatchedList[j] = 1
                break
            end
        end
    end
    for i=1,#handCards do
        if hasMatchedList[i] == nil then
            table.insert(tLeftHandCards,handCards[i])
        end
    end
    if #tLeftHandCards + #cards ~= #handCards then
        return nil
    end
    tLeftHandCards = self:sortByWeight(tLeftHandCards,1)
    return tLeftHandCards
end

-- 提示相关代码
function GameRunRule:initCanOutCombs(handCards,preComb)
    self._canOutCombs = {}
    self._perComb = preComb or app.game.CardRule.CardComb:new()
    
    local combs,testCombFlag = self:hintCards(handCards, self._perComb)
    self._hintComb = combs
    self._startHintIndex = 1
    if not testCombFlag then
        return nil
    end

    for _,comb in pairs(combs) do
        local len = #comb.cards 
        self._canOutCombs[len] = self._canOutCombs[len] or {}
        table.insert(self._canOutCombs[len],comb)
    end 
    return self._hintComb
end

function GameRunRule:getNextHintCards()
    if self._startHintIndex > #self._hintComb then
        self._startHintIndex = self._startHintIndex - #self._hintComb
    end
    local nextCards = self._hintComb[self._startHintIndex].cards
    self._startHintIndex = self._startHintIndex + 1
    return nextCards
end

-- 获取需要弹起的牌
-- 弹起的牌、手牌、之前的牌
function GameRunRule:getCardsBySelectCard(upCards)
    -- 获取公共子集
    if #upCards == 0 then
        return nil
    end
    local function getCommonSubset(cards1,cards2)
        local matchList = {}
        local commonCards = {}
        for i=1,#cards1 do
            local num_i = self:getCardNum(cards1[i])
            for j=1,#cards2 do
                if num_i == self:getCardNum(cards2[j]) and matchList[j]==nil then
                    matchList[j] = 1
                    table.insert(commonCards,cards2[j])
                    break
                end
            end
        end
        return commonCards
    end

    local function delCardAndNum(upCards,retCards)  -- 找出公共牌，将非公共牌合并到upCards中
        local matchUp= {}
        local matchRet= {}
        for i=1,#upCards do             -- 先标记相同的手牌
            for j=1,#retCards do
                if upCards[i] == retCards[j] and matchUp[i]== nil and matchRet[j] == nil then
                    matchUp[i] = 1
                    matchRet[j] = 1
                    break
                end
        end
        end

        local cards = {}
        for i=1,#upCards do             -- 再标记相同的牌点
            local num_i = self:getCardNum(upCards[i])
            for j=1,#retCards do
                if num_i == self:getCardNum(retCards[j]) and matchUp[i]== nil and matchRet[j] == nil then
                    matchUp[i] = 1
                    matchRet[j] = 1
                    break
                end
            end
        end

        for i=1,#retCards do
            if matchRet[i] ~= 1 then
                table.insert(cards,retCards[i])
            end
        end
        return cards
    end

    local retCards = {}
    for i=#upCards,28 do
        if self._canOutCombs[i] then
            for _,comb in pairs(self._canOutCombs[i]) do
                local cards = clone(comb.cards)
                local flag = false
                for _,v in ipairs(cards) do
                    if v == cardsValue.CV_WANG_F or v == cardsValue.CV_WANG_Z then          --单点出牌，去掉有关王的联想
                        flag = true
                        break
                    end
                end
                if not flag then
                    if self:isSameNumSubCards(cards,upCards) then
                        if #retCards ~= 0 then
                            retCards = getCommonSubset(retCards,cards)
                        else
                            retCards = cards
                        end
                    end
                end        
            end
        end
        if #retCards == upCards then
            return nil
        end    
    end

    if #retCards == 0 then
        return nil
    end

    return delCardAndNum(upCards,retCards)      
end

local SELECT_Y = 15
local HAND_CARD_DISTANCE_NO_SELF = 20
local HERO_LOCAL_SEAT = 1

function GameRunRule:calHandCardPosition(index, cardSize, count, localSeat, bUp)
    local screenSize = cc.Director:getInstance():getWinSize()

    local posX = 0
    local posY = 0

    index = index - 1
    if localSeat == HERO_LOCAL_SEAT then
        if count == 1 then
            posX = posX - cardSize.width / 2
        else
            local width = (screenSize.width - 200 - cardSize.width) / (count - 1) 
            if width > (cardSize.width - cardSize.width/5) then
                width = cardSize.width / 2
            end

            local handCardsLength = (count - 1) * width + cardSize.width
            posX = posX + index * width - handCardsLength / 2       
        end

        if bUp then
            posY = posY + SELECT_Y
        end
    elseif localSeat == HERO_LOCAL_SEAT + 1 then
        local WIDTH = HAND_CARD_DISTANCE_NO_SELF
        local handCardsLength = (count - 1) * WIDTH + cardSize.width
        posX = posX + index * WIDTH - handCardsLength        
    else
        local WIDTH = HAND_CARD_DISTANCE_NO_SELF
        posX = posX + index * WIDTH        
    end

    return cc.p(posX, posY)
end

-- 底牌
function GameRunRule:calBankCardPosition(index, cardSize, count)
	local posX = 0
    local posY = 0

    local WIDTH = cardSize.width 
    local outCardsLength = (count - 1) * WIDTH + cardSize.width
    local beginPosX = 0    
    beginPosX = beginPosX - outCardsLength / 2

    local index = index - 1
    posX = beginPosX + index * WIDTH
    
    return cc.p(posX, posY)
end 

-- 出牌
local OUT_CARD_DISTANCE       = 30         -- 出牌牌间距
local LINE_CARD_NUM_DUI_JIA   = 10
function GameRunRule:calOutCardPosition(index, cardSize, count, localSeat)   
    local posX = 0
    local posY = 0

    local WIDTH = OUT_CARD_DISTANCE 
    

    local beginPosX = 0
    index = index - 1

    if localSeat == HERO_LOCAL_SEAT then
        local outCardsLength = (count - 1) * WIDTH + cardSize.width

        beginPosX = beginPosX - outCardsLength / 2

        posX = beginPosX + index * WIDTH
       
    else
        if localSeat == HERO_LOCAL_SEAT - 1 then
            beginPosX = 0
            if count <= LINE_CARD_NUM_DUI_JIA then
                posX = beginPosX + index * WIDTH
                
            else
                if index <= LINE_CARD_NUM_DUI_JIA - 1 then
                    posX = beginPosX + index * WIDTH
                    
                else
                    posX = beginPosX + (index - LINE_CARD_NUM_DUI_JIA) * WIDTH
                    posY = posY - cardSize.height / 5 * 2
                end
            end
        else
            if count <= LINE_CARD_NUM_DUI_JIA then
                local outCardsLength = (count - 1) * WIDTH + cardSize.width
                beginPosX = beginPosX - outCardsLength

                posX = beginPosX + index * WIDTH
              
            else
                local outCardsLength = (LINE_CARD_NUM_DUI_JIA - 1) * WIDTH + cardSize.width
                beginPosX = beginPosX - outCardsLength

                if index <= LINE_CARD_NUM_DUI_JIA - 1 then
                    posX = beginPosX + index * WIDTH
                    
                else
                    posX = beginPosX + (index - LINE_CARD_NUM_DUI_JIA) * WIDTH
                    posY = posY - cardSize.height / 5 * 2
                end
            end
        end
    end
    return cc.p(posX, posY)
end

function GameRunRule:calBankCardPosition(index, cardSize, count)
	local posX = 0
    local posY = 0

    local WIDTH = cardSize.width 
    local outCardsLength = (count - 1) * WIDTH + cardSize.width
    local beginPosX = 0    
    beginPosX = beginPosX - outCardsLength / 2

    local index = index - 1
    posX = beginPosX + index * WIDTH
    
    return cc.p(posX, posY)
end 

-- 牌node大小排序
function GameRunRule:sortNodeCardByWeight(nodeCards)
    if #nodeCards < 2 then
        return true
    end

    for i = 1, #nodeCards - 1 do
        for j = i + 1, #nodeCards do
            if nodeCards[i]:isVisible() and nodeCards[j]:isVisible() then
                if nodeCards[i]:getCardWeight() < nodeCards[j]:getCardWeight() or
                    ( nodeCards[i]:getCardWeight() == nodeCards[j]:getCardWeight() and nodeCards[i]:getCardColor() < nodeCards[j]:getCardColor() ) then
                    nodeCards[i], nodeCards[j] = nodeCards[j], nodeCards[i]
                    nodeCards[i]:setCardIndex(i)
                    nodeCards[j]:setCardIndex(j)
                end
            elseif not nodeCards[i]:isVisible() and nodeCards[j]:isVisible() then
                nodeCards[i], nodeCards[j] = nodeCards[j], nodeCards[i]
                nodeCards[i]:setCardIndex(i)
                nodeCards[j]:setCardIndex(j)
            end
        end
    end
end

function GameRunRule:deleteHandCards(serverSeat, heroServerSeat, cards, handCards)
    if #handCards == 0 then
        return
    end

    if serverSeat ~= heroServerSeat then
        if handCards[1] ~= cardsValue.CV_BACK then
            for i = 1, #cards do
                for j = 1, #handCards do 
                    if cards[i] == handCards[j] then
                        table.remove(handCards, j)
                        break
                    end
                end
            end
        else
            for i = 1, #cards do
                table.remove(handCards, 1)
            end
        end
    else
        for i = 1, #cards do
            for j = 1, #handCards do 
                if cards[i] == handCards[j] then
                    table.remove(handCards, j)
                    break
                end
            end
        end
    end
end

-- 判断玩家是否为首出
function GameRunRule:isFirstOut(serverseat, lastCombSeat, waitFollowSeat, followTurn)
    if lastCombSeat == -1 or 
        lastCombSeat == serverseat or 
        (waitFollowSeat == serverseat and followTurn == 1)  then
        return true
    else
        return false
    end
end

-- 检查炸弹，确保提示出的牌为炸弹时不留下剩牌
function GameRunRule:checkBoom(needUpCards, handCards, isFirstOut)
    local len = #needUpCards
    if len == nil or len == 0 then 
        return needUpCards 
    end

    if handCards == nil or #handCards == 0 then 
        return needUpCards 
    end

    local start_num = self:getCardNum(needUpCards[1])
    local end_num =  self:getCardNum(needUpCards[len])

    local flag = false
    if len >= 4 then 
        flag = true
    else
        if isFirstOut then 
            flag = true 
        end
    end

    if flag and start_num == end_num then
        needUpCards = {}
        for _, v in pairs(handCards) do
            local temp_num = self:getCardNum(v)
            if temp_num == end_num then
                table.insert(needUpCards, v)
            end
        end
    end

    return needUpCards
end

function GameRunRule:calSelectAutoUp(upCards, hintComb, handCards, isFirstOut)
    local tempHintComb = {}

    -- 把包含弹起牌提示牌记录到tempHintComb
    self:calHintCombWithUpCards(upCards, hintComb, tempHintComb)

    -- 计算所有需要弹起的牌
    local needUpCards = self:calNeedUpCards(tempHintComb, handCards, isFirstOut)

    -- 出去已弹起的牌
    self:calNeedUpCardsWithoutUp(upCards, needUpCards)

    return needUpCards
end

function GameRunRule:calHintCombWithUpCards(upCards, hintComb, tempHintComb)
    local layUp = {}
    self:initLayNum(layUp)

    for i = 1, #upCards do
        local num = self:getCardNum(upCards[i])
        layUp[num] = layUp[num] + 1
    end

    -- 手牌有王不联想
    if layUp[cardNums.CN_F] > 0 or layUp[cardNums.CN_Z] > 0 then
        return
    end

    local layHint = {}
    for i = 1, #hintComb do
        self:initLayNum(layHint)

        local hintCards = hintComb[i].cards

        for i = 1, #hintCards do
            local num = self:getCardNum(hintCards[i])
            layHint[num] = layHint[num] + 1
        end

        -- 提示牌有王不联想
        if layHint[cardNums.CN_F] > 0 or layHint[cardNums.CN_Z] > 0 then
        else
            local bInComb = true
            for i = cardNums.CN_1, cardNums.CN_B do
                if layUp[i] > layHint[i] then
                    bInComb = false
                    break
                end
            end

            if bInComb then
                table.insert(tempHintComb, hintComb[i])
            end
        end
    end
end

function GameRunRule:calNeedUpCards(hintComb, handCards, isFirstOut)
    local needUpCards = {}

    if #hintComb == 0 then
        return needUpCards
    end

    -- 单顺
    needUpCards = self:calNeedUpCards_Shun(hintComb, handCards, isFirstOut, 1)
    if #needUpCards > 0 then
        return needUpCards
    end

    -- 双顺
    needUpCards = self:calNeedUpCards_Shun(hintComb, handCards, isFirstOut, 2)
    if #needUpCards > 0 then
        return needUpCards
    end

    -- 三顺
    needUpCards = self:calNeedUpCards_Shun(hintComb, handCards, isFirstOut, 3)
    if #needUpCards > 0 then
        return needUpCards
    end

    -- 其他
    needUpCards = self:calNeedUpCards_Other(hintComb)
    if #needUpCards > 0 then
        return needUpCards
    end

    return needUpCards
end

function GameRunRule:calNeedUpCards_Shun(hintComb, handCards, isFirstOut, index)
    local needUpCards = {}

    local layHand = {}
    self:initLayNum(layHand)

    for i = 1, #handCards do
        local num = self:getCardNum(handCards[i])
        layHand[num] = layHand[num] + 1
    end

    local TYPE_ID = cardType.CTID_NONE
    if index == 1 then
        TYPE_ID = cardType.CTID_YI_SHUN
    elseif index == 2 then
        TYPE_ID = cardType.CTID_ER_SHUN
    elseif index == 3 then
        TYPE_ID = cardType.CTID_SAN_SHUN
    else
        return needUpCards
    end

    local tempTypeID    = 0
    local tempTypeLen   = 0
    local tempTypePower = 0
    for i = 1, #hintComb do
        local typeID    = hintComb[i].type.id
        local typeLen   = hintComb[i].type.len
        local typePower = hintComb[i].type.power

        local hintCards = hintComb[i].cards

        if typeID == TYPE_ID then
            -- 首家出牌联想牌不拆牌
            if self:isCanAutoUp(layHand, hintCards, isFirstOut) then
                if tempTypeID == 0 then
                    tempTypeID    = typeID
                    tempTypeLen   = typeLen
                    tempTypePower = typePower

                    needUpCards = hintCards
                else
                    if tempTypeLen < typeLen or
                        ( tempTypeLen == typeLen and tempTypePower < typePower ) then
                        tempTypeID    = typeID
                        tempTypeLen   = typeLen
                        tempTypePower = typePower

                        needUpCards = hintCards
                    end
                end
            end
        end
    end

    return needUpCards
end

function GameRunRule:isCanAutoUp(layHand, hintCards, isFirstOut)
    local layHint = {}
    self:initLayNum(layHint)

    for i = 1, #hintCards do
        local num = self:getCardNum(hintCards[i])
        layHint[num] = layHint[num] + 1
    end

    local bAll = true
    for i = cardNums.CN_1, cardNums.CN_B do
        if layHint[i] > 0 then
            if layHand[i] > layHint[i] then
                bAll = false
                break
            end
        end
    end

    if not isFirstOut or
        (isFirstOut and bAll) then
        return true
    end

    return false
end

function GameRunRule:calNeedUpCards_Other(hintComb)
    local needUpCards = {}

    local tempTypeID    = 0
    local tempTypeCount = 0
    local tempTypePower = 0

    for i = 1, #hintComb do
        local typeID    = hintComb[i].type.id
        local typeCount = hintComb[i].type.count
        local typePower = hintComb[i].type.power

        local hintCards = hintComb[i].cards

        if typeID == cardType.CTID_ER_ZHANG or
            typeID == cardType.CTID_SAN_ZHANG or
            typeID == cardType.CTID_SI_ZHANG or
            typeID == cardType.CTID_WU_ZHANG or
            typeID == cardType.CTID_LIU_ZHANG or
            typeID == cardType.CTID_QI_ZHANG or
            typeID == cardType.CTID_BA_ZHANG then
            if tempTypeID == 0 then
                tempTypeID    = typeID
                tempTypeCount = typeCount
                tempTypePower = typePower

                needUpCards = hintCards
            else
                if tempTypeCount < typeCount then
                    tempTypeID    = typeID
                    tempTypeCount = typeCount
                    tempTypePower = typePower

                    needUpCards = hintCards
                end
            end
        end
    end

    return needUpCards
end

function GameRunRule:calNeedUpCardsWithoutUp(upCards, needUpCards)
    local tempUpCards     = clone(upCards)

    if #tempUpCards > #needUpCards then
        for i = #needUpCards, 1, -1 do
            table.remove(needUpCards, i)
        end

        return 
    end

    -- 先比较ID, 将已提起的手牌去掉
    for i = #tempUpCards, 1, -1 do
        for j = #needUpCards, 1, -1 do
            if tempUpCards[i] == needUpCards[j] then 
                table.remove(tempUpCards, i)
                table.remove(needUpCards, j)

                break
            end
        end
    end

    -- 已提起的手牌不在联想牌中， 则按点数num去掉
    if #tempUpCards > 0 then
        for i = #tempUpCards, 1, -1 do
            for j = #needUpCards, 1, -1 do
                local numUp     = self:getCardNum(tempUpCards[i])
                local numNeedUp = self:getCardNum(needUpCards[j])
                if numUp == numNeedUp then 
                    table.remove(tempUpCards, i)
                    table.remove(needUpCards, j)

                    break
                end
            end
        end
    end
end

function GameRunRule:initLayNum(lay)
    for i = cardNums.CN_1, cardNums.CN_B do
        lay[i] = 0
    end
end

function GameRunRule:initLayID(lay)
    for i = cardsValue.CV_FANG_A, cardsValue.CV_WANG_Z do
        lay[i] = 0
    end
end

return GameRunRule