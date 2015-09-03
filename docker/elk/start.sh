#!/bin/bash
# Check our environment out for a syslog server
: ${REDIS_HOST:=redis}

if [ ! -z ${SYSLOG_HOST+x} ]; then
    cat >> /etc/rsyslog.conf << EOF
    *.* @$SYSLOG_HOST:514
EOF
fi
cat /etc/rsyslog.conf
rsyslogd 
pdns_recursor --daemon=no
