--[[
@brief 枚举
]]--
local CardRule = {}

CardRule.cardColours = {
    CC_NULL  = 0,
    CC_FANG  = 1,        --方块
    CC_MEI   = 2,        --梅花
    CC_HONG  = 3,        --红桃
    CC_HEI   = 4,        --黑桃
    CC_WANG  = 5,        --王
    CC_BACK  = 6,        --背
    CC_COUNT = 7        --花色数量
} 

CardRule.cardNums = {
    CN_NULL = 0,
    CN_1    = 1,
    CN_2    = 2,
    CN_3    = 3,
    CN_4    = 4,
    CN_5    = 5,
    CN_6    = 6,
    CN_7    = 7,
    CN_8    = 8,
    CN_9    = 9,
    CN_10   = 10,
    CN_J    = 11,
    CN_Q    = 12,
    CN_K    = 13,
    CN_A    = 14,
    CN_F    = 15,    --小王
    CN_Z    = 16,    --大王
    CN_B    = 17,
}

CardRule.cards = {
    CV_NONE     = 0,
    CV_FANG_A   = 1,
    CV_FANG_2   = 2,
    CV_FANG_3   = 3,
    CV_FANG_4   = 4,
    CV_FANG_5   = 5,
    CV_FANG_6   = 6,
    CV_FANG_7   = 7,
    CV_FANG_8   = 8,
    CV_FANG_9   = 9,
    CV_FANG_10  = 10,
    CV_FANG_J   = 11,
    CV_FANG_Q   = 12,
    CV_FANG_K   = 13,
    CV_MEI_A    = 14,
    CV_MEI_2    = 15,
    CV_MEI_3    = 16,
    CV_MEI_4    = 17,
    CV_MEI_5    = 18,
    CV_MEI_6    = 19,
    CV_MEI_7    = 20,
    CV_MEI_8    = 21,
    CV_MEI_9    = 22,
    CV_MEI_10   = 23,
    CV_MEI_J    = 24,
    CV_MEI_Q    = 25,
    CV_MEI_K    = 26,
    CV_HONG_A   = 27,
    CV_HONG_2   = 28,
    CV_HONG_3   = 29,
    CV_HONG_4   = 30,
    CV_HONG_5   = 31,
    CV_HONG_6   = 32,
    CV_HONG_7   = 33,
    CV_HONG_8   = 34,
    CV_HONG_9   = 35,
    CV_HONG_10  = 36,
    CV_HONG_J   = 37,
    CV_HONG_Q   = 38,
    CV_HONG_K   = 39,
    CV_HEI_A    = 40,
    CV_HEI_2    = 41,
    CV_HEI_3    = 42,
    CV_HEI_4    = 43,
    CV_HEI_5    = 44,
    CV_HEI_6    = 45,
    CV_HEI_7    = 46,
    CV_HEI_8    = 47,
    CV_HEI_9    = 48,
    CV_HEI_10   = 49,
    CV_HEI_J    = 50,
    CV_HEI_Q    = 51,
    CV_HEI_K    = 52,
    CV_WANG_F   = 53,
    CV_WANG_Z   = 54,
    CV_BACK     = 55,
    CV_FACE     = 56,
    CV_JOKER    = 57,   
}

-- 牌转换(斗地主)
CardRule.repCards = {
    [0]      = CardRule.cards.CV_BACK,
    [0x03]   = CardRule.cards.CV_FANG_3,
    [0x04]   = CardRule.cards.CV_FANG_4,
    [0x05]   = CardRule.cards.CV_FANG_5,
    [0x06]   = CardRule.cards.CV_FANG_6,
    [0x07]   = CardRule.cards.CV_FANG_7,
    [0x08]   = CardRule.cards.CV_FANG_8,
    [0x09]   = CardRule.cards.CV_FANG_9,
    [0x0a]   = CardRule.cards.CV_FANG_10,
    [0x0b]   = CardRule.cards.CV_FANG_J,
    [0x0c]   = CardRule.cards.CV_FANG_Q,
    [0x0d]   = CardRule.cards.CV_FANG_K,
    [0x0e]   = CardRule.cards.CV_FANG_A,
    [0x12]   = CardRule.cards.CV_FANG_2,
    
    [0x23]   = CardRule.cards.CV_MEI_3,
    [0x24]   = CardRule.cards.CV_MEI_4,
    [0x25]   = CardRule.cards.CV_MEI_5,
    [0x26]   = CardRule.cards.CV_MEI_6,
    [0x27]   = CardRule.cards.CV_MEI_7,
    [0x28]   = CardRule.cards.CV_MEI_8,
    [0x29]   = CardRule.cards.CV_MEI_9,
    [0x2a]   = CardRule.cards.CV_MEI_10,
    [0x2b]   = CardRule.cards.CV_MEI_J,
    [0x2c]   = CardRule.cards.CV_MEI_Q,
    [0x2d]   = CardRule.cards.CV_MEI_K,
    [0x2e]   = CardRule.cards.CV_MEI_A,
    [0x32]   = CardRule.cards.CV_MEI_2,
    
    [0x43]   = CardRule.cards.CV_HONG_3,
    [0x44]   = CardRule.cards.CV_HONG_4,
    [0x45]   = CardRule.cards.CV_HONG_5,
    [0x46]   = CardRule.cards.CV_HONG_6,
    [0x47]   = CardRule.cards.CV_HONG_7,
    [0x48]   = CardRule.cards.CV_HONG_8,
    [0x49]   = CardRule.cards.CV_HONG_9,
    [0x4a]   = CardRule.cards.CV_HONG_10,
    [0x4b]   = CardRule.cards.CV_HONG_J,
    [0x4c]   = CardRule.cards.CV_HONG_Q,
    [0x4d]   = CardRule.cards.CV_HONG_K,
    [0x4e]   = CardRule.cards.CV_HONG_A,
    [0x52]   = CardRule.cards.CV_HONG_2,
    
    [0x63]   = CardRule.cards.CV_HEI_3,
    [0x64]   = CardRule.cards.CV_HEI_4,
    [0x65]   = CardRule.cards.CV_HEI_5,
    [0x66]   = CardRule.cards.CV_HEI_6,
    [0x67]   = CardRule.cards.CV_HEI_7,
    [0x68]   = CardRule.cards.CV_HEI_8,
    [0x69]   = CardRule.cards.CV_HEI_9,
    [0x6a]   = CardRule.cards.CV_HEI_10,
    [0x6b]   = CardRule.cards.CV_HEI_J,
    [0x6c]   = CardRule.cards.CV_HEI_Q,
    [0x6d]   = CardRule.cards.CV_HEI_K,
    [0x6e]   = CardRule.cards.CV_HEI_A,
    [0x72]   = CardRule.cards.CV_HEI_2,
    
    [0x93]   = CardRule.cards.CV_WANG_F,
    [0x94]   = CardRule.cards.CV_WANG_Z
}

CardRule.cardType = {
    CTID_NONE        = 0,    --无
    CTID_YI_ZHANG    = 1,    --单张
    CTID_ER_ZHANG    = 2,    --对子
    CTID_SAN_ZHANG   = 3,    --三张
    CTID_SI_ZHANG    = 4,    --四张
    CTID_WU_ZHANG    = 5,    --五张
    CTID_LIU_ZHANG   = 6,    --六张
    CTID_QI_ZHANG    = 7,    --七张
    CTID_BA_ZHANG    = 8,    --八张
    CTID_YI_SHUN    = 9,     --单顺
    CTID_ER_SHUN    = 10,     --双顺
    CTID_SAN_SHUN   = 11,     --三顺
    CTID_SI_SHUN    = 12,     --四顺
    CTID_WU_SHUN    = 13,     --五顺
    CTID_LIU_SHUN   = 14,     --六顺
    CTID_QI_SHUN    = 15,     --七顺
    CTID_BA_SHUN    = 16,     --八顺
    CTID_HUO_JIAN   = 17,     --火箭
    CTID_FEI_JI     = 18,    --飞机带翅膀
    CTID_SAN_DAI_YI = 19,    --三带一
    CTID_SI_DAI_ER  = 20,    --四带二
}

CardRule.cardAtomScore = {
    cardAtom = {},
    score = 0,
    
    new = function (self, o)
        local o = o or {}
        setmetatable(o, {__index = CardRule.cardAtomScore})
        return o
    end
}

CardRule.CardTypeData = {
    id = 0,
    name = "",
    weight = 0,
    minLen = 1,
    
    new = function (self, o)
        local o = o or {}
        setmetatable(o, {__index = CardRule.CardTypeData})
        return o
    end
}

CardRule.CardType = {
    id = 0,
    power = 0,
    count = 0,
    len = 0,
    hint = 0,
    vals = {},
    
    new = function (self, o)
        local o = o or {}
        setmetatable(o, {__index = CardRule.CardType})
        return o
    end,
    
    countCards = function(self)
        return self.count * self.len;
    end,
    
     equal = function (self, type)
        if ( type.id ~= self.id or type.power ~= self.power or type.count ~= self.count 
            or type.len ~= self.len or type.hint ~= self.hint ) then
            return false;
        end
        
        if ( #type.vals ~= #self.vals) then
            return false;
        end
        
        return true;
    end
}

CardRule.CardAtom = {
     nums = {},
     type = CardRule.CardType:new(),
     
     new = function (self, o)
        local o = o or {}
        setmetatable(o, {__index = CardRule.CardAtom})
        return o
     end,
    
    countCards = function(self)
        return self.type:countCards();
    end
}

CardRule.CardFormRule = {
    count = 0,
    type = CardRule.CardType:new(),

    new = function (self, o)
        local o = o or {}
        setmetatable(o, {__index = CardRule.CardFormRule})
        return o
    end,

    countCards = function(self)
        return self.type:countCards() * self.count
    end
}

CardRule.CardForm = {
    rules = {},
    type = CardRule.CardType:new(),

    new = function (self, o)
        local o = o or {}
        setmetatable(o, {__index = CardRule.CardForm})
        return o
    end,
    
    countCards = function(self)
        local count = 0;
        for i = 1, #self.rules do
            count = count + self.rules[i].countCards();
        end
        
        return count
    end
}

CardRule.CardComb = {
    cards = {},
    nums = {},
    type = CardRule.CardType:new(),

    new = function (self, o)
        local o = o or {}
        setmetatable(o, {__index = CardRule.CardComb})
        return o
    end
}

CardRule.CardSepTree = {
    comb = CardRule.CardComb:new(),
    _children = {},
    
    new = function (self, o)
        local o = o or {}
        setmetatable(o, {__index = CardRule.CardSepTree})
        return o
    end
}

CardRule.CardSepForest = {
    rules = {},
    trees = {},
    
    new = function (self, o)
        local o = o or {}
        setmetatable(o, {__index = CardRule.CardSepForest})
        return o
    end
}

CardRule.CardSepHand = {
    rules = {},
    combs = {},
    
    new = function (self, o)
        local o = o or {}
        setmetatable(o, {__index = CardRule.CardSepHand})
        return o
    end
}

return CardRule