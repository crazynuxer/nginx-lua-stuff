#!/usr/bin/env lua

local json          = require("cjson")

local math_floor    = math.floor
local string_char   = string.char
local string_byte   = string.byte
local string_rep    = string.rep
local string_sub    = string.sub
local debug_getinfo = debug.getinfo

local vars = require("yagami.vars")
module('yagami.util', package.seeall)

function read_all(filename)
    local file = io.open(filename, "r")
    local data = ((file and file:read("*a")) or nil)
    if file then
        file:close()
    end
    return data
end


function setup_app_env(ygm_home, app_name, app_path, global)
    global['YAGAMI_HOME']=ygm_home
    global['YAGAMI_APP']=appname
    global['YAGAMI_APP_PATH']=app_path
    
    package.path = ygm_home .. '/lualibs/?.lua;' .. package.path
    package.path = app_path .. '/app/?.lua;' .. package.path
    
    
    local request=require("yagami.request")
    local response=require("yagami.response")
    
    global['YAGAMI_MODULES']={}
    global['YAGAMI_MODULES']['request']=request
    global['YAGAMI_MODULES']['response']=response
end

--load var from lua file
function loadvars(file)
    local env = setmetatable({}, {__index=_G})
    assert(pcall(setfenv(assert(loadfile(file)), env)))
    setmetatable(env, nil)
    return env
end

--get configuration setting
function get_config(key, default)
    if key == nil then return nil end
    local issub, subname = is_subapp(3)
    
    if not issub then -- main app
        local ret = ngx.var[key]
        if ret then return ret end
        local app_conf=vars.get(ngx.ctx.YAGAMI_APP_NAME,"APP_CONFIG")
        return app_conf[key] or default
    end

    -- sub app
    if not subname then return default end
    local subapps=vars.get(ngx.ctx.YAGAMI_APP_NAME,"APP_CONFIG").subapps or {}
    local subconfig=subapps[subname].config or {}
    return subconfig[key] or default
    
end

function _strify(o, tab, act, logged)
    local v = tostring(o)
    if logged[o] then return v end
    if string_sub(v,0,6) == "table:" then
        logged[o] = true
        act = "\n" .. string_rep("|    ",tab) .. "{ [".. tostring(o) .. ", "
        act = act .. table_real_length(o) .." item(s)]"
        for k, v in pairs(o) do
            act = act .."\n" .. string_rep("|    ", tab)
            act = act .. "|   *".. k .. "\t=>\t" .. _strify(v, tab+1, act, logged)
        end
        act = act .. "\n" .. string_rep("|    ",tab) .. "}"
        return act
    else
        return v
    end
end

function strify(o) return _strify(o, 1, "", {}) end

function table_print(t)
    local s1="\n* Table String:"
    local s2="\n* End Table"
    return s1 .. strify(t) .. s2
end

function table_real_length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function is_subapp(__call_frame_level)
    if not __call_frame_level then __call_frame_level = 2 end
    local caller = debug_getinfo(__call_frame_level,'S').source
    local main_app = ngx.var.YAGAMI_APP_PATH
    
    local is_mainapp = (main_app == (string_sub(caller, 2, #main_app+1)))
    if is_mainapp then return false, nil end -- main app
    
    local subapps = vars.get(ngx.ctx.YAGAMI_APP_NAME, "APP_CONFIG").subapps or {}
    for k, v in pairs(subapps) do
        local spath = v.path
        local is_this_subapp = (spath == (string_sub(caller, 2, #spath+1)))
        if is_this_subapp then return true, k end -- sub app
    end
    
    return false, nil -- not main/sub app, maybe call in yagami!
end

function parseNetInt(bytes)
    local a, b, c, d = string_byte(bytes, 1, 4)
    return a * 256 ^ 3 + b * 256 ^ 2 + c * 256 + d
end

function toNetInt(n)
    -- NOTE: for little endian machine only!!!
    local d = n % 256
    n = math_floor(n / 256)
    local c = n % 256
    n = math_floor(n / 256)
    local b = n % 256
    n = math_floor(n / 256)
    local a = n
    return string_char(a) .. string_char(b) .. string_char(c) .. string_char(d)
end

function write_jsonresponse(sock, s)
    if type(s) == 'table' then
        s = json.encode(s)
    end
    local l = toNetInt(#s)
    sock:send(l .. s)
end

function read_jsonresponse(sock)
    local r, err = sock:receive(4)
    if not r then
        logger:warn('Error when receiving from socket: %s', err)
        return
    end
    local len = parseNetInt(r)
    data, err = sock:receive(len)
    if not data then
        logger:error('Error when receiving from socket: %s', err)
        return
    end
    return json.decode(data)
end


--------------------------------
function map(func, t)
    local new_t = {}
    for i,v in ipairs(t) do
        table_insert(new_t, func(v, i))
    end
    return new_t
end

function timestamp()
    return ngx.time()
end

function isNull(v)
    return (v==nil or v==ngx.null)
end

function isNotNull(v)
    return not isNull(v)
end

function isNotEmptyString(...)
    local args = {...}
    local v = nil
    for i=1,table.maxn(args) do
        v = args[i]
        if v==nil or v==ngx.null or type(v)~='string' or string.len(v)==0 then
            return false
        end
    end
    return true
end

--explode then random return one
function splitString(inputstr,sep)
    if sep == nil then 
        sep = "%s"
    end
    
    t = {}; i=1
    for str in string.gmatch(inputstr,"([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end


function splitSlave(inputstr,sep)
    if sep == nil then 
        sep = "%s"
    end
    
    t = {}; r ={}; i=1
    for str in string.gmatch(inputstr,"([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    local one = 1

    if i>1 then 
        math.randomseed(os.time())
        one = math.random(1,i-1)
    end

    z=1
    for str in string.gmatch(t[one],"([^:]+)") do
        r[z] = str
        z = z+1
    end
    return r[1],r[2]
end



-- traceback function , log debug
function traceback()
    logger:e(require("debug").traceback())
end

function table_print(t)
    local s1="\n* Table String:"
    local s2="\n* End Table"
    logger:e(s1 .. strify(t) .. s2)
end
