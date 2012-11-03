local cookie = {}

local cookie_meta = {
    __tostring = function(t)
        local str = {("%s=%s"):format(t.name,t.value)}
        for n,v in pairs(t.flags) do
            str[#str+1] = n
                .. (v=='' and '' or '='..v)
        end
        return table.concat(str,'; ')
    end
}

function cookie.new(name,value,flags)
    return setmetatable(
        { name = name, value = value, flags = flags },
        cookie_meta )
end

function cookie.parse(str)
    local name, value, fstr = str:match "%s*([^=;]+)=?([^;]*)(.*)"
    if name then
        local flags = {}
    for n, v in fstr:gmatch ";%s*([^=;]+)=?([^;]*)" do
      flags[n:lower()] = v
      end
    return cookie.new(name, value, flags)
    end
end

return cookie
