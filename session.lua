local cookie = require 'scanpower/azula/cookie.lua'

local session = {}

local keys = {
    key = {},
    storage = {}
}

local function storage_key(t,k)
    return (' session-%s/%s'):format(rawget(t,keys.key),k)
end

local vars = {
    __index = function(t,k)
        return rawget(t,keys.storage)[storage_key(t,k)]
    end,
    __newindex = function(t,k,v)
        rawget(t,keys.storage)[storage_key(t,k)] = v
    end
}

local function session_id(request,crypto)
    return crypto.hmac(
        ("%s!!%s"):format(
            request.remote_addr,
            request.headers['X-Forwarded-For'] or '' ),
        request.headers['User-Agent'],
        crypto.sha256 ).hexdigest()
end

function session.new(key,storage,request,crypto)
    local id = session_id(request,crypto)
    local key = crypto.hmac( key, id, crypto.sha256 ).hexdigest()
    return setmetatable({id=id,vars=setmetatable({keys.key=key,keys.storage=storage},vars)},{__index=session})
end

function session:start()
    for k,v in pairs(self.request.headers) do
        if k == 'Cookie' then
            local c = cookie.parse(v)
            if c.name == 'azula-session' then
                self.cookie = c
            end
        end
    end

    if not self.cookie then
        self.headers = {
            ['Set-Cookie'] = tostring(
                cookie.new('azula-session',
                    self.id,
                    { Secure = true
                    , HttpOnly = true }
                ))
        }
    end
    return self
end

return session
