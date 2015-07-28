#!/bin/bash
# exit on any failure during install
set -e
# install packages for pdns, new relic and management (curl vim tmux)
echo "Getting the packages for our DNS setup"
apt-get install lua5.1 luarocks curl wget vim tmux make lighttpd ntp libssl-dev dnsutils -y
# luarocks manages library installs for lua, these three are necessary for redis and syslog
luarocks install luasocket
luarocks install json4lua
luarocks install redis-lua
echo "Adding pdns group and user, pulling latest recursor"
addgroup pdns
adduser pdns-svc --shell /bin/false --no-create-home --gecos PowerDNS --ingroup pdns --disabled-login --disabled-password
# installing latest jenkins build
echo "Installing latest pdns-recursor, checking for debian 32 or 64 bit"
MACHINE_TYPE=`uname -m`
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
	echo "64 bit detected"
	wget http://downloads.powerdns.com/releases/deb/pdns-recursor_3.6.1-1_amd64.deb
	dpkg -i pdns-recursor_3.6.1-1_amd64.deb
else		
	echo "32 bit detected"
	wget http://downloads.powerdns.com/releases/deb/pdns-recursor_3.6.1-1_i386.deb
	dpkg -i pdns-recursor_3.6.1-1_i386.deb
fi
# get rid of default config files to move in our own
echo "Removing default config files of rsyslog"
rm -f /etc/rsyslog.conf
# move config files & script for our installation
echo "Moving files over!"
mv files-pdns/lua/* /etc/powerdns/
mv files-pdns/recursor.conf /etc/powerdns/
mv files-pdns/rsyslog.conf /etc/
mv files-pdns/pdns.conf /etc/rsyslog.d/
mv files-pdns/rsyslog /etc/logrotate.d/
mv files-pdns/ntp.conf /etc/ntp.conf
echo "Permissions for pdns"
chown pdns-svc:pdns -R /etc/powerdns/
chown pdns-svc:pdns /usr/bin/rec_control
chown pdns-svc:pdns /etc/init.d/pdns-recursor
chown pdns-svc:pdns /usr/sbin/pdns_recursor
mkdir /var/run/pdns-rec
chown -R pdns-svc:pdns /var/run/pdns-rec
chmod 750 /var/run/pdns-rec
chmod 760 /usr/bin/rec_control
echo "Restarting services"
# restart everything
/etc/init.d/pdns-recursor start
/etc/init.d/rsyslog restart
echo "Cleanup"
# clean up
apt-get autoremove
# starting pdns-recursor
/etc/init.d/pdns-recursor start
