#!/usr/bin/env lua
-- -*- lua -*-
-- copyright: 2012 Appwill Inc.
-- author : KDr2
--


mch_router=require('mch.router')
mch_router.setup()


logger:error("haha")

-----------------------------------------------
-- 1.simple function mapping
map('^/1/hello%?name=(.*)',"d1_test.hello")

-- map('^/1/NO_hello%?name=(.*)',"no_exist.hello")

if get_config("ltp") then
    map('^/1/ltp$',"d1_test.ltp")
end

-- 2.mch controller mapping
map('^/1/hello_v2%?name=(.*)',"d1_test_v2.ctller_v2")
map('^/1/ltp_v2',"d1_test_v2.ctller_ltpv2")

-----------------------------------------------



