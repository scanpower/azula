require 'scanpower/azula/util.lua'

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

function proto:select(SelectExpression,ConsistentRead,NextToken)
    local url = self:url{
        Action = 'Select',
        SelectExpression = SelectExpression,
        ConsistentRead = ConsistentRead,
        NextToken = NextToken
    }
    return http.request({
        url = url
    }).content
end

return sdb
