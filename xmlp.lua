local proto = {}
local util = {}
local xmlp = { util = util }

function xmlp.new(args)
    return setmetatable(args,{__index=proto})
end

function util.toxml(str)
    if str then
        return str:gsub('&', '&amp;')
                  :gsub('<', '&lt;')
                  :gsub('>', '&gt;')
                  :gsub('"', '&quot;')
                  :gsub("([^%w%&%;%p%\t% ])",
                        function (c)
                            return ("&#x%X;"):format(c:byte())
                        end)
    end
end

function util.fromxml(str)
    if str then
        return str:gsub("&#x([%x]+)%;",
                        function(h)
                            return string.char(tonumber(h,16))
                        end)
                  :gsub("&#([0-9]+)%;",
                        function(h)
                            return string.char(tonumber(h,10))
                        end)
                  :gsub('&quot;', '"')
                  :gsub('&apos;', "'")
                  :gsub('&gt;', '>')
                  :gsub('&lt;', '<')
                  :gsub('&amp;', '&')
                  :gsub('^%s+', '')
                  :gsub('%s+$', '')
    end
end

function util.parseattrs(s)
    local as = {}
    s:gsub("(%w+)=([\"'])(.-)%2", function(n, _, v)
        as[#as+1] = {name = n,  value = util.fromxml(v)}
    end)
    return as
end

local function mknode(name,attrs)
    return { name = name
           , attrs = attrs
           , children = {} }
end

function proto:parse(str)
    local top = mknode(nil,{})
    local tree = {top}

    local i = 1

    while true do
        local ni, j, c, label, xattr, empty = str:find("<(%/?)([%w:]+)(.-)(%/?)>", i)
        if not ni then break end

        local text = str:sub(i, ni-1)
        if not text:find "^%s*$" then
            local node = util.fromxml(text)
            if self.textnode then self.textnode(node) end
            top.children[#top.children+1] = node
        end
        if empty == '/' then
            local attrs = util.parseattrs(xattr)
            if self.node then self.node(label, attrs) end
            top.children[#top.children+1] = mknode(label, attrs)
            if self.endnode then self.endnode(label) end
        elseif c == '' then
            local attrs = util.parseattrs(xattr)
            if self.node then self.node(label, attrs) end
            top = mknode(label, attrs)
            tree[#tree+1] = top
        else
            if self.endnode then self.endnode(label) end
            local toclose = table.remove(tree)
            top = tree[#tree]
            if #tree < 1 then
                error("xmlp: malformed xml: unmatched </"..label..">")
            end
            if toclose.name ~= label then
                error("xmlp: malformed xml: unmatched <"..toclose.name..">, encountered </"..label..">")
            end
            top.children[#top.children+1] = toclose
        end
        i = j+1
    end
    local text = str:sub(i)
    if not text:find "^%s*$" then
        local node = util.fromxml(text)
        if self.textnode then self.textnode(node) end
        top.children[#top.children+1] = node
    end
    if #tree > 1 then
        error("xmlp: malformed xml: unclosed <"..tree[#tree].name..">")
    end
    return tree
end

function xmlp.parse(string)
    return proto:parse(string)
end

function proto:parsefile(filename)
    local f,err = io.open(filename,'r')
    if err then
        return nil, err
    else
        local xml = f:read('*a')
        f:close()
        return self:parse(xml)
    end
end

function xmlp.parsefile(filename)
    return proto:parsefile(filename)
end

local function dumpattrs(as)
    local fas = {}
    for _,a in ipairs(as) do
         fas[#fas+1] = ('%s "%s"'):format(a.name, a.value:gsub('"','\\"'))
    end
    return '{' .. table.concat(fas," ") .. '}'
end

local function dump(ns,d,lines)
    local tab = ' '
    for _,node in ipairs(ns) do
        if type(node) == 'string' then
            lines[#lines+1] = tab:rep(d)..'"'..node:gsub('"','\\"')..'"'
        else
            local name = node.name or '<root>'
            lines[#lines+1] = tab:rep(d)..'('..name
            d = d + 2
            if #node.attrs > 0 then
                lines[#lines+1] = tab:rep(d) .. dumpattrs(node.attrs)
            end
            if #node.children > 0 then
                dump(node.children,d,lines)
            end
            lines[#lines] = lines[#lines] .. ')'
        end
    end
    return lines
end

function util.dump(xml)
    return table.concat(dump(xml,0,{}),'\n')
end

return xmlp
