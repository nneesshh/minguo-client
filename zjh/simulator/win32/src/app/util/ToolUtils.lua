
--[[
@brief:������
]]

local ToolUtils = {}

--[[
@brief ���л��ַ���
]]--
function ToolUtils.serialize(obj)  
    local lua = ""  
    local t = type(obj)  
    if t == "number" then  
        lua = lua .. obj  
    elseif t == "boolean" then  
        lua = lua .. tostring(obj)  
    elseif t == "string" then  
        lua = lua .. string.format("%q", obj)  
    elseif t == "table" then  
        lua = lua .. "{"  
        for k, v in pairs(obj) do  
            lua = lua .. "[" .. ToolUtils.serialize(k) .. "]=" .. ToolUtils.serialize(v) .. ","  
        end  
        local metatable = getmetatable(obj)  
        if metatable ~= nil and type(metatable.__index) == "table" then  
            for k, v in pairs(metatable.__index) do  
                lua = lua .. "[" .. ToolUtils.serialize(k) .. "]=" .. ToolUtils.serialize(v) .. ","  
            end  
        end  
        lua = lua .. "}"  
    elseif t == "nil" then  
        return nil  
    else  
        error("can not serialize a " .. t .. " type.")  
    end  
    return lua  
end

--[[
@brief �����л��ַ���
]]--
function ToolUtils.unserialize(lua)  
    local t = type(lua)  
    if t == "nil" or lua == "" then  
        return nil  
    elseif t == "number" or t == "string" or t == "boolean" then  
        lua = tostring(lua)  
    else  
        error("can not unserialize a " .. t .. " type.")  
    end  
    lua = "return " .. lua  
    local func = loadstring(lua)  
    if func == nil then  
        return nil  
    end  
    return func()  
end

--[[
@brief�����ֿ����ڿ��ӷ�Χ����
]]--
function ToolUtils.nameToShort(nickName, maxLen)
    local tmpName = bf.SysFunc:UTF_8ToGB_18030_2000(nickName)
    local VaildUtils = app.util.VaildUtils
    local len = #tmpName
    local maxLen = maxLen or 8
    local tmpLen = 0
    local flag = false
    local lastIndex = 0
    local i = 1
    while true do
        local tmpChar = string.sub(tmpName,i,i)
        --���ĺ�W�Ӿ������������2��
        if VaildUtils.isChinese(tmpChar) or tmpChar=="W" then
            tmpLen = tmpLen + 2
            --��д��ĸ�����������1.5��
        elseif VaildUtils.isUpper(tmpChar) then
            tmpLen = tmpLen + 1.5
        else
            tmpLen = tmpLen + 1
        end
        if VaildUtils.isChinese(tmpChar) then
            i = i + 2
        else
            i = i + 1
        end
        if tmpLen <= maxLen+2 and i>len then
            flag = true
        end
        if tmpLen <= maxLen then
            lastIndex = i-1
        end
        if i>len then
            break
        end
    end
    if tmpLen > maxLen then
        if flag then
            return nickName
        else
            return string.sub(tmpName, 1, lastIndex) .. ".."
        end
    else
        return nickName
    end
end

-- --[[
-- @brief �������ֻ���,text��ʾ�軻�е�����,maxLen��ʾһ����󳤶�
-- ]]--
function ToolUtils.getLineBreakText(text,maxLen)
    local tmpName = bf.SysFunc:UTF_8ToGB_18030_2000(text)
    local VaildUtils = app.util.VaildUtils
    local len = #tmpName
    local maxLen = maxLen or 8
    local tmpLen = 0
    local firstIndex = 1
    local i = 1
    local returnTxt = ""
    while true do
        local tmpChar = string.sub(tmpName,i,i)
        if VaildUtils.isChinese(tmpChar) then
            tmpLen = tmpLen + 2
        elseif VaildUtils.isUpper(tmpChar) then
            tmpLen = tmpLen + 1.5
        else
            tmpLen = tmpLen + 1
        end
        if VaildUtils.isChinese(tmpChar) then
            i = i + 2
        else
            i = i + 1
        end
        if tmpLen >= maxLen then
            returnTxt = returnTxt .. string.sub(tmpName,firstIndex,i-1) .. "\n"
            firstIndex = i
            tmpLen = 0
        end
        if i>len then
            break
        end
    end
    returnTxt = returnTxt .. string.sub(tmpName,firstIndex,len)
    return bf.SysFunc:GB_18030_2000ToUTF_8(returnTxt)
end

--[[
������ʹ��������Ϊ��׺
-- num ԭʼ����
-- decimal ��ౣ����λС��
-- max ��ౣ�����ٸ�����
]]--
function ToolUtils.numConversionByDecimal(num, decimal, max)
    local numType = type(num)
    if numType ~= "string" and numType ~= "number" then
        return nil
    end
    num = tonumber(num)
    decimal = decimal or 2
    max = max or 6
    local suffix = ""
    local f = "%."..decimal.."f"
    if num >= 10000 and num < 100000000 then
        suffix = "��"
        num = tonumber(string.format(f, num/10000))
    elseif num >= 100000000 then
        suffix = "��"
        num = tonumber(string.format(f, num/100000000))
    end

    local strNum = tostring(num)
    if string.find(strNum, "%.") then
        local a = string.split(strNum, ".")
        if #a[1] + #a[2] >= max and #a[2] >= decimal and max - #a[1] > 0 then
            return a[1].."."..string.sub(a[2], 1, max-#a[1])..suffix
        elseif #a[1] + #a[2] >= max and max - #a[1] <= 0 then
            return a[1]..suffix
        end
    end
    return num..suffix
end

return ToolUtils