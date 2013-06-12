#!/usr/bin/env lua
-- -*- lua -*-
-- copyright: 2012 Appwill Inc.
-- author : KDr2
--


module("d2_test",package.seeall)

local JSON = require("cjson")

function hello(req, resp, name)
    if req.method=='GET' then
        -- resp:writeln('Host: ' .. req.host)
        -- resp:writeln('Hello, ' .. ngx.unescape_uri(name))
        -- resp:writeln('name, ' .. req.uri_args['name'])
        resp.headers['Content-Type'] = 'application/json'
        resp:write("in demo2\n")
        resp:write(JSON.encode(req.uri_args))
    elseif req.method=='POST' then
        -- resp:writeln('POST to Host: ' .. req.host)
        req:read_body()
        resp.headers['Content-Type'] = 'application/json'
        resp:writeln(JSON.encode(req.post_args))
    end 
end


function ltp(req,resp,...)
    __logger:debug("test logger in demo2")
    resp:ltp('d2_ltp.html',{v=222})
end


