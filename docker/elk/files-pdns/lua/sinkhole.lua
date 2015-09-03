package.path = package.path .. ";/etc/powerdns/?.lua" 
pcall(require, "luarocks.require")
redis = require 'redis'
require "tester"
require "syslog"
require "redisconn"

-- PDNS Functions -- 
function nxdomain( ip, domain, qtype )
        if qtype == pdns.A or qtype == pdns.AAAA then
            sendsyslog(1004, {requestingip=ip,thedomain=domain,querytype=translateQtype(qtype)})
            return 0, {{ qtype=pdns.CNAME, content="8.8.8.8" }}
        end
        return pdns.PASS, {}
end
function postresolve( ip, domain, qtype, records, origrcode )
    local recordstr = ""
    local req = buildbhreq( domain, qtype )
    if req ~= nil
    then
        local blackhole_domain = client:get(req)
        if blackhole_domain ~= nil
        then
            for k,v in pairs (records)
            do
                for kk,vv in pairs(v) do
                    recordstr = recordstr .. "record:" .. kk .. "->" .. vv .. ","
                    if string.find(kk, "content")
                    then
                        records[k][kk] = blackhole_domain
                    end
                end
            end
            -- send to syslog that we are hitting a blackhole domain with all the relevant info 
            sendsyslog(3500, {remoteip=ip,thedomain=domain,querytype=translateQtype(qtype),resolveinfo=tostring(recordstr),rcode=tostring(origrcode)})
            -- edit the response and send it back for the sinkhole
            return origrcode, records
        end
    end
    return pdns.PASS, {}
end
function preresolve( requestorip,  domain, qtype )
  -- check for DDoS reflection
  if domain == "."
  then
    sendsyslog(3501, {thedomain=domain,requestingip=tostring(requestorip),querytype=translateQtype(qtype),localaddr=tostring(getlocaladdress())})
    return pdns.DROP, {}
  end
  -- build the request to redis
  local req = buildsinkreq( getlocaladdress(), domain, qtype )
  if req ~= nil
  then
    sendsyslog(1001, {thedomain=domain,requestingip=tostring(requestorip),querytype=translateQtype(qtype),localaddr=tostring(getlocaladdress())})
    -- check if the domain is on the redis blacklist
    local blacklist_domain = client:get(req)
    if blacklist_domain ~= nil
    then 
        sendsyslog(2000, {thedomain=domain,requestingip=tostring(requestorip),querytype=translateQtype(qtype),localaddr=tostring(getlocaladdress())})
        -- return record type with the IP of sinkhole
        return 0, { {qtype=qtype, content=blacklist_domain} }
    end
  end
  -- req = nil or not on blacklist, perform dns resolution normally 
  return pdns.PASS, {}
end


-- parse options file to make sure the correct data is loaded
local options = get_options()
-- pass in the syslog-servers array to connect to potential syslog servers
-- pass in the redis-servers array to connect to potential redis servers
getredis(options["redis-servers"])
