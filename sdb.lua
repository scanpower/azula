require 'scanpower/azula/util.lua'
require 'scanpower/azula/xmlp.lua'

local default = {
    region = 'us-east-1',
    endpoint = 'sdb.amazonaws.com',
}

local proto = {}
local meta  = {__index=proto}
local sdb   = {
    connect = function(access_key,secret_access_key,opts)
        local opts = opts or {}
        opts.access_key = opts.access_key or access_key
        opts.secret_access_key = opts.secret_access_key or secret_access_key
        return setmetatable(opts,meta)
    end,
    version = '0.1',
    apiversion = '2009-04-15'
}

function proto:url(param)
    param.AWSAccessKeyId = self.access_key
    param.Version = sdb.apiversion
    return signed_url(self.secret_access_key,
                      self.endpoint or default.endpoint,
                      nil, param)
end

local function parseSelectResponse(xmlstr)
    local xml = xmlp.parse(xmlstr)
    local rows = {}
    if #xml > 0 and xml[1].children then
        for _,node in ipairs(xml[1].children) do
            if type(node) == 'table' and node.name == 'SelectResponse' then
                for _,response in ipairs(node.children) do
                    if response.name == 'SelectResult' then
                        for _,item in ipairs(response.children) do
                            if item.name == 'Item' then
                                local row = {}
                                for _,attr in ipairs(item.children) do
                                    if attr.name == 'Name' then
                                        log('itemName()')
                                        row['itemName()'] = table.concat(attr.children,'')
                                    elseif attr.name == 'Attribute' then
                                        local cname, cval
                                        for _,n in ipairs(attr.children) do
                                            if n.name == 'Name' then cname = table.concat(n.children,'') end
                                            if n.name == 'Value' then cval = table.concat(n.children,'') end
                                        end
                                        if cname and cval then
                                            row[cname] = cval
                                        end
                                    end -- attr.name
                                end -- item.children
                                rows[#rows+1] = row
                            end -- Item
                        end -- response.children
                    end -- SelectResult
                end -- node.children
            end -- SelectResponse
        end -- xml.children
    end
    return rows
end

function proto:select(SelectExpression,ConsistentRead,NextToken)
    if not SelectExpression:lower():find '^%s*select' then
        SelectExpression = 'select ' .. SelectExpression
    end

    local url = self:url{
        Action = 'Select',
        SelectExpression = SelectExpression,
        ConsistentRead = ConsistentRead,
        NextToken = NextToken
    }
    return parseSelectResponse( http.request({
        url = url
    }).content )
end

return sdb
