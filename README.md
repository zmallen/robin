Robin
====

Robin runs a pdns-recursor server that talks to a redis backend server. The redis backend server provides DNS lookup information for specific domains that you want to block or sinkhole on. It then replaces the A/AAAA/CNAME/MX record of a query with the response that you want. This is similar to BIND redirect-zones, but provides more control to where you want to redirect DNS queries with a smaller amount of configuration. If the entry does not exist in redis, it performs an upstream query to the root servers pdns-recursor is configured to question.

This server also uses the new PDNS.DROP feature to stop basic DNS DDOS reflection attacks via the "." query. This action then alerts syslog to allow the network administrator/operator to react to the attack.

See the following graphic:

![Graphic](https://github.com/zmallen/Robin/blob/master/sinkhole.jpg?raw=true)

For example:

Admin wants A record requests "www.bad.com." to redirect to a sinkhole server for further analysis.

Admin adds "A:www.bad.com." to redis as a key, and the value as their sinkhole server "1.2.3.4" , where A is the record, : as a delimiter, and www.bad.com. as the FQDN

**NOTE** 
Domains MUST be fully qualified with the trailing . in redis, because this is how pdns-recursor parses the DNS packets.

One of their employees clicks on a bad attachment that dials out to www.bad.com for downloading additional malware.

The request turns into the question: ";www.bad.com. IN A" 

Before this resolves, the Robin server checks redis for "A:www.bad.com.", since this exists, it does not resolve the domain and instead returns the sinkhole server "1.2.3.4", and alerts the Admin via syslog. This is known as sinkholing, and happens before DNS resolution.

If further analysis for the domain is wanted, such as the records that "www.bad.com." returns, the Admin can add "www.bad.com." to a "blackhole" set in redis. This allows pdns-recursor to do a post-resolve hook, where it finds the records for "www.bad.com." from the upstream root servers, and before it returns these records to the user, it replaces the specific records with the blackhole address, and then sends a log of all the info about "www.bad.com." to syslog for further analysis.

To add this, add in redis:

1) SET "bh:A:www.bad.com." "1.2.3.4"

When the employee clicks on a bad attachment and dials out to "www.bad.com." for downloading additional malware, pdns-recursor will attempt to resolve information about the domain, log it, and replace all answers to the blackhole address.

LOGGING
===

Robin uses json logging for easily parsing and responding to specific codes. The format is as follows:

{
	"app" = "pdns_recursor"
	"id" = ID_OF_MESSAGE
	"querydetails" = { .. }
}

querydetails changes based on the type of code being sent such as:
	
	- a successful DNS query
	- a successful sinkhole
	- a successful blackhole
	- a blocked reflection attack
	- a redis error

These can be checked in the lua/ sub directory whenever sendsyslog is called

Included is a separate rsyslog.conf file, it *WILL* delete your current rsyslog.conf, so if you want to diff your rsyslog.conf with the one ported with this to add logging to a specific directory you can do that. Default logging goes to /var/log/pdns.log

LOGGING CODES
===

Current codes are as follows:

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

If you parse syslog and look for "id" = 1000 , you will find all syslog codes associated with startup messages, and so on.

Synopsis of codes:

- 1000 -> pdns-recursor started successfully

- 1001 -> Standard DNS query

- 1002 -> pdns-recursor is shutting down

- 1003 -> Robin is logging to syslog successfully

- 1004 -> pdns-recursor returned a record with an unknown domain

- 2000 -> Robin sunk a domain before it attempted to resolve it

- 2001 -> Robin cannot connect to a redis server

- 2999 -> an unknown syslog code was found

- 3000 -> Robin attempted to connect to all redis servers in lua-options.conf and failed

- 3500 -> Robin resolved a bad domain, replaced all the contents with the answer found in redis, and redirected the user

- 3501 -> Robin detected a DDoS reflection query and discarded it


DEPLOYMENT
===
1) git clone https://github.com/zmallen/Robin.git

2) sudo su

3) ./install-redis.sh

4) ./install-pdns.sh


REDIS
===

From www.redis.io .. "Redis is an open source, BSD licensed, advanced key-value store. It is often referred to as a data structure server since keys can contain strings, hashes, lists, sets and sorted sets."

Redis is used for the domain lookup because it is optimized for handling large amounts of data as a key/value store database. This makes the data structure manageable, unlike a long text file on the local server or a data type within the lua-script. This also allows for multiple Robins to point to a central redis master/slave and allow for changes in the redis master will propagate to slaves, making this deployable in a production architecture.

Open /etc/powerdns/lua-options.conf and set the redis-servers= option to a comma separated list of possible redis servers to connect to. Robin will attempt to go down the list starting from the first address until it finds a redis-server it can successfully connect to.

Adding mass values to redis:

If you want to add potentially hundreds, thousands or hundreds of thousands of addresses to sinkhole/blackhole on to redis, I suggest reading this:

http://redis.io/topics/mass-insert


TESTING
===
1) redis-cli

2) SET "A:www.tester321.com." "1.2.3.4"

3) exit

4) apt-get install dnsutils

5) dig A www.tester321.com @localhost

6) If it returns 1.2.3.4, you are good!

7) You can also tail -f /var/log/pdns.log to see syslog messages that the lua back-end generates

POTENTIAL USES
===
Provide an upstream, security based recursor to tens of thousands of users. Use the sinkhole capabilities to alert users based on known 'bad' domains trying to connect out to the internet. For a good list of known, bad domains/URLs, check open-source websites such as: phishtank, malwarepatrol, cleanmx

As a blackholing technology for honeypots/honeynets, trap outgoing malware phone homes and redirect them to a machine with an IDS/IPS (bro/snort). The malware will then send its initial outgoing network packets to your IDS/IPS to attempt to connect to it, because it thinks that its the C&C server.

You can point your rsyslog pdns.conf file to an external syslog server (I used Loggly free) to perform additional parsing of syslog messages. 

Robin also silently discards DNS reflection attacks and alerts via syslog when this recursor is being used to DDoS. 

Red-team environments can use this as an upstream malicious resolver for target Authoritative nameservers to poison DNS without generating noise on the target Authoritative nameserver