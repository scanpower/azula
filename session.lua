local cookie = require 'scanpower/azula/cookie.lua'

local session = {}

function session:id()
    return crypto.hmac( 
        ("%s!!%s"):format(
            self.request.remote_addr,
            self.request.headers['X-Forwarded-For'] or '' ),
        self.request.headers['User-Agent'],
        crypto.sha256 ).hexdigest()
end

function session.new(key,request)
    return setmetatable({key=key,request=request},{__index=session})    
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
                    self:id(),
                    {   Domain = 'scanpower.webscript.io'
                    , Path   = '/'
                    , ['Max-Age'] = '86400' }
                ))
        }
    end
end

return session
