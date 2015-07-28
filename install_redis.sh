#!/bin/bash
set -e
# get latest version of redis
wget http://download.redis.io/redis-stable.tar.gz
# unpack, install and create production-ready folders for redis
tar xvzf redis-stable.tar.gz
cd redis-stable
make
mkdir /etc/redis/
mkdir /var/redis/
mkdir /var/redis/6379/
# copy binaries over to run from command line
cp src/redis-cli src/redis-server /usr/bin/
cd ..
# move config files & script for our installation
mv files-redis/redis_6379 /etc/init.d/
mv files-redis/6379.conf /etc/redis/
# add the redis db to start on startup
update-rc.d redis_6379 defaults
/etc/init.d/rsyslog restart
# restart everything
/etc/init.d/redis_6379 start
# clean up
rm -rf redis-stable