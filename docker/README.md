# Robin: the dockerized version
## What does this get you?
After launching this via [docker-compose](https://docs.docker.com/compose/) you get the following:

* DNS listening on 0.0.0.0:53
* Redis listening on 0.0.0.0:6379
* Syslog logging to SYSLOG_HOST, set in docker-compose.yml. 

If syslog_host is not set, syslog merely logs to the local vm.

## How to launch
After installing docker and docker-compose:

```
sudo docker-compose build
sudo docker-compose up
```

## Upstream sources

* Pulls from the ubuntu 14.04 image
* Pulls from the upstream redis dockerfile
