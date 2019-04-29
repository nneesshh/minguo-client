--[[
@brief  VaildUtils 校验函数
]]

local VaildUtils = {}

--[[
--字符串中是否全部是数字
--@param str 需要判断的字符串
--@return bool
]]
function VaildUtils.isDigit(str)
    if(string.find(str,"%D") == nil) then
        return true
    else
        return false
    end 
end

--[[
--字符串中是否全部是字母
--@param str 需要判断的字符串
--@return bool
]]
function VaildUtils.isAlpha(str)
    if(string.find(str,"%A") == nil) then
        return true
    else
        return false
    end 
end

--[[
--字符串中是否全部是数字或字母
--@param str 需要判断的字符串
--@return bool
]]
function VaildUtils.isAlNum(str)
    if(string.find(str,"%W") == nil) then
        return true
    else
        return false
    end 
end

--[[
--字符串中是否全部是小写字母
--@param str 需要判断的字符串
--@return bool
]]
function VaildUtils.isLower(str)
    if(string.find(str,"%L") == nil) then
        return true
    else
        return false
    end
end

--[[
--字符串中是否全部是大写字母
--@param str 需要判断的字符串
--@return bool
]]
function VaildUtils.isUpper(str)
    if(string.find(str,"%U") == nil) then
        return true
    else
        return false
    end 
end 

--[[
--字符串中是否全部是中文
--@param str 需要判断的字符串
--@return bool
]]
function VaildUtils.isChinese(str)
    if(string.find(str,"[\1-\127]+") == nil) then
        return true
    else
        return false
    end 
end

return VaildUtils