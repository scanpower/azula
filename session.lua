local cookie = require 'scanpower/azula/cookie.lua'

local session = {}

function session.id()
    return crypto.hmac( 
        ("%s!!%s"):format(
            request.remote_addr,
            request.headers['X-Forwarded-For'] or '' ),
        request.headers['User-Agent'],
        crypto.sha256 ).hexdigest()
end

function session.new(key)
    return setmetatable({key=key},{__index=session})    
end

function session:start()
    for k,v in pairs(request.headers) do
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
                    session.id(),
                    {   Domain = 'scanpower.webscript.io'
                    , Path   = '/'
                    , ['Max-Age'] = '86400' }
                ))
        }
    end
end

return session
