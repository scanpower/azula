local util = require 'scanpower/azula/util.lua'

local lom = require 'lxp.lom'
local xpath = require 'xpath'

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
    return util.signed_url(self.secret_access_key,
                      self.endpoint or default.endpoint,
                      nil, param)
end

local function parseSelectResponse(xmlstr)
    local xml = lom.parse(xmlstr)
    local items = xpath.selectNodes(xml, '//SelectResult/Item')

    if #items > 0 then
        local rows = {}
        for _,item in ipairs(items) do
            local row = {
                ['itemName()'] = xpath.selectNodes(item, '//Name/text()')[1] 
            }
            for _,attr in ipairs(xpath.selectNodes(item, '//Attribute')) do
                row[xpath.selectNodes(attr, '//Name/text()' )[1]] =
                    xpath.selectNodes(attr, '//Value/text()')[1]
            end
            rows[#rows+1] = row
        end
        return rows
    end
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
