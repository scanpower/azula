local function iso8601(d)
    return os.date('%Y-%m-%dT%H:%M:%S%z',d)
end

local function urlencode(str)
    if str then
        return tostring(str):gsub('\n', '\r\n')
            :gsub("([^-%w_])", function(c)
                return ("%%%02X"):format(c:byte())
            end)
    end
end

local function params_to_string(params)
    local query = {}
    for _,param in ipairs(params) do
        query[#query+1] = tostring(param.k) .. '=' .. urlencode(param.v)
    end
    return table.concat(query,'&')
end

local function signed_url(key,host,path,params)
    params.SignatureVersion = 2
    params.SignatureMethod = 'HmacSHA256'
    params.Timestamp = iso8601()

    path = path or '/'
    params = params or {}

    local ordered = {}
    for k,v in pairs(params) do
        if v ~= nil then
            ordered[#ordered+1] = { k = k, v = v }
        end
    end
    table.sort(ordered,function(a,b) return a.k < b.k end)

    local query = params_to_string(ordered)
    local data = ("GET\n%s\n%s\n%s"):format(host,path,query)
    local signature = base64.encode( crypto.hmac( key, data, crypto.sha256 ).digest() )

    if query then query = query .. '&' end
    query = query .. 'Signature=' .. urlencode(signature)

    return ("https://%s%s?%s"):format(host,path,query)
end

return {
    iso8601 = iso8601,
    urlencode = urlencode,
    signed_url = signed_url,
}
