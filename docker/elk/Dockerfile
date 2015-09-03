FROM ubuntu:14.04
MAINTAINER profit <profit@ccmo.me>
# Grab powerdns bits
RUN apt-get update &&  apt-get -y  install lua5.1 luarocks curl wget libssl-dev dnsutils && curl -lO http://downloads.powerdns.com/releases/deb/pdns-recursor_3.6.1-1_amd64.deb && dpkg -i pdns-recursor_3.6.1-1_amd64.deb && rm -rf pdns-recursor* && apt-get clean
# Grab luarocks bits
RUN luarocks install luasocket && luarocks install json4lua && luarocks install redis-lua
# Copy over config files
COPY files-pdns/lua /etc/powerdns/
COPY files-pdns/recursor.conf /etc/powerdns/
COPY files-pdns/rsyslog.conf /etc/rsyslog.conf
# Hackey mc' hackerson startup script
ADD start.sh /start.sh
EXPOSE 53
CMD /start.sh


