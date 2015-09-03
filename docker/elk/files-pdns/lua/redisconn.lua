-- parse the redis servers array and attempt to connect to at least one, send to syslog if it errors out and quit
function getredis( servers )
	redis = require 'redis'
	local redisparams = {
		host = 'nothing',
		port = 6379
	}
	for i = 1, #servers do
		redisparams["host"] = servers[i]
		local ok, tclient = pcall(redis.connect, redisparams)
		if(ok) then
			sendsyslog(1000, servers[i])
			client = tclient
			client:select(0)
			break
		else
			sendsyslog(2001, servers[i])
		end
	end
	if client == nil then
		sendsyslog(3000, table.concat(servers, ","))
		error("Cannot connect to redis!")
	end
end
-- build the redis request to find keys associated with a blackhole domain
function buildbhreq( domain, qtype )
    local qtypeStr = translateQtype( qtype )
    -- lua doesnt support regex alternation (AAAA|A|CNAME|MX) so have to do a long conditional here..
    if qtypeStr ~= "AAAA" and qtypeStr ~= "A" and qtypeStr ~= "CNAME" and qtypeStr ~= "MX"
    then
        return nil
    else
        -- prepend "bh" to look up the domain, doesnt matter if its AAAA or A
        return "bh:" .. qtypeStr .. ":" .. tostring(domain)
    end

end
-- build the redis request to find keys associated with a specific sink
function buildsinkreq( ifaceip, domain, qtype )
    local qtypeStr = translateQtype( qtype )
    -- lua doesnt support regex alternation (AAAA|A|CNAME|MX) so have to do a long conditional here..
    if qtypeStr ~= "AAAA" and qtypeStr ~= "A" and qtypeStr ~= "CNAME" and qtypeStr ~= "MX"
    then
        return nil 
    else
        -- this one is used for targeted DNS, which takes into account the interface ip
        return qtypeStr .. ":" .. tostring(domain)
    end
end
-- tables and lookup functions -- 
do
    local qtt = {
        [1]     = "A",
        [28]    = "AAAA",
        [18]    = "AFSDB",
        [42]    = "APL",
        [37]    = "CERT",
        [5]     = "CNAME",
        [49]    = "DHCID",
        [32769] = "DLV",
        [39]    = "DNAME",
        [48]    = "DNSKEY",
        [43]    = "DS",
        [55]    = "HIP",
        [45]    = "IPSECKEY",
        [25]    = "KEY",
        [36]    = "KX",
        [29]    = "LOC",
        [15]    = "MX",
        [35]    = "NAPTR",
        [2]     = "NS",
        [47]    = "NSEC",
        [50]    = "NSEC3",
        [51]    = "NSEC3PARAM",
        [12]    = "PTR",
        [46]    = "RRSIG",
        [17]    = "RP",
        [24]    = "SIG",
        [6]     = "SOA",
        [99]    = "SPF",
        [33]    = "SRV",
        [44]    = "SSHFP",
        [32768] = "TA",
        [249]   = "TKEY",
        [250]   = "TSIG",
        [16]    = "TXT" }

    function translateQtype( qtype )
        local str = qtt[qtype]
        if str then
            return str
        else
            return nil
        end
    end
end
