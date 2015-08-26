# Robin: the dockerized version
## What does this get you?
After launching this via [docker-compose](https://docs.docker.com/compose/) you get the following:

* DNS listening on 0.0.0.0:53
* Redis listening on 0.0.0.0:6379
* Elasticsearch listening at :9000
* Logstash feeding from Robin's Syslog into Elasticsearch
* Kibana UI living on localhost:5601
* Grok filters for Robin's syslog messages.


## How to launch
After installing docker and docker-compose:

```
sudo docker-compose build
sudo docker-compose up
```

## Upstream sources

* Pulls from the ubuntu 14.04 image
* Pulls from the upstream redis dockerfile
        * logRobin's Syslog into Elasticsearch
* Kibana UI living on localhost:5601
* Grok filters for Robin's syslog messages.
* ELK from https://github.com/deviantony/docker-elk
