ngx.req.read_body()
if  ngx.re.match(ngx.var.request_uri,whitelist,"isjo") then
    return
else
    -- check secure header
    if ngx.req.get_headers()['X-GNBinder-security'] == secureheader then
        -- check ok
    else
        log('GET','X-GNBinder-security:'..secureheader)
        ngx.exit(401)
    end

    if ngx.re.match(ngx.unescape_uri(ngx.var.request_uri),regex.."|"..get,"isjo") then
        log('GET',ngx.unescape_uri(ngx.var.request_uri))
        check()
--    elseif ngx.re.match(string.gsub(ngx.var.request_uri,"\\%",""),regex.."|"..get,"isjo") then
--        log('GET',ngx.var.request_uri)
--        check()
    elseif  ngx.re.match(ngx.var.request_uri,[[%00|%0b|%0d|%c0%ae|%0a]],"isjo") then
        check()
    elseif ngx.var.http_user_agent and ngx.re.match(ngx.var.http_user_agent,regex.."|"..agent,"isjo")  then
        log('USER-AGENT',ngx.unescape_uri(ngx.var.request_uri))
        check()
    elseif ngx.req.get_body_data() and  ngx.re.match(ngx.req.get_body_data(),[[Content-Disposition: form-data;(.*)filename=]],"isjo") ==nil and ngx.re.match(ngx.unescape_uri(ngx.req.get_body_data()),regex.."|"..post,"isjo") then
        log('POST',ngx.unescape_uri(ngx.var.request_uri),ngx.unescape_uri(ngx.req.get_body_data()))
            check()
    elseif string.len(filext) >0 then
        if ngx.req.get_body_data() and ngx.re.match(ngx.req.get_body_data(),"Content-Disposition: form-data;(.*)filename=\"(.*)."..filext.."\"","isjo") then
            check()
        end
--    elseif ngx.req.get_headers()["Cookie"] and ngx.re.match(ngx.unescape_uri(ngx.req.get_headers()["Cookie"]),regex,"isjo")then
--        log('COOKIE',ngx.unescape_uri(ngx.var.request_uri),ngx.unescape_uri(ngx.req.get_headers()["Cookie"]))
--        check()
    elseif ngx.req.get_headers()['Acunetix-Aspect']  then
        ngx.exit(400)
    elseif ngx.req.get_headers()['X-Scan-Memo'] then
        ngx.exit(400)
    else
        return
    end
end
