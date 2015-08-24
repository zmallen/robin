syslogcodes = {
	[1000] = "id:1000 STARTUP",
	[1001] = "id:1001 QUERY",
	[1002] = "id:1002 SHUTDOWN",
	[1003] = "id:1003 SYSLOGCONN",
    [1004] = "id:1004 NXDOMAIN",
	[2000] = "id:2000 SINKHOLE",
	[2001] = "id:2001 REDISFAILURE",
	[2999] = "id:2999 NOTFOUNDSYSLOGCODE",
	[3000] = "id:3000 PDNSREDISFAIL",
    [3500] = "id:3500 BLACKHOLE",
    [3501] = "id:3501 REFLECTION"
}
json = require("json")
function sendsyslog( code, details )
	local msg = syslogcodes[code]
	local prepend = "pdns_recursor"
	if not msg then
		code = 2999
		msg = syslogcodes[code]
	end
	if code >= 1000 and code <= 1999 then
        pdnslog(json.encode({app=prepend,id=msg,querydetails=details}), pdns.loglevels.Info)
	elseif code >= 2000 and code <= 2999 then
        pdnslog(json.encode({app=prepend,id=msg,querydetails=details}), pdns.loglevels.Warning)
	elseif code >= 3000 and code <= 3999 then
        pdnslog(json.encode({app=prepend,id=msg,querydetails=details}), pdns.loglevels.Critical)
	end
end
