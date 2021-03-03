# docker-graphite
Simple graphite container with nginx based on alpine

Components included:

* Graphite
* Carbon
* Whisper
* Nginx / gunicorn

## Environment Variables:

All variables are optional.

* ```PUID``` ... The user ID to run the processes under
* ```PGID``` ... The group ID to run the processes under
* ```TZ``` ... Timezone for the container (e.g. Europe/Vienna)

Django backend options:

* ```SECRET_KEY``` ... Secret key used by Django (default 64 character random string based on the date)
* ```GRAPHITE_ALLOWED_HOSTS``` ... Hosts allowed to connect to Django backend (default ```'*'```)
* ```GRAPHITE_DATE_FORMAT``` ... Short date format (default ```'%m/%d'```)
* ```GRAPHITE_LOG_FILE_INFO```
* ```GRAPHITE_LOG_FILE_EXCEPTION```
* ```GRAPHITE_LOG_FILE_CACHE```
* ```GRAPHITE_LOG_FILE_RENDERING``` ... Log file destinations (default ```'-'``` which means logging to stdout)
* ```GRAPHITE_USE_WORKER_POOL``` ... Creates a pool of worker threads to which tasks can be dispatched. (deafault ```true```)
* ```GRAPHITE_POOL_WORKERS_PER_BACKEND``` ... The number of worker threads that should be created per backend server. (default ```8```)
* ```GRAPHITE_POOL_WORKERS``` ... A baseline number of workers that should always be created (default ```1```)

## Volumes

Exported volumes:

* ```/opt/graphite/storage``` ... Carbon database storage

## Ports

Exposed ports:

* ```80``` ... The web interface for Graphite
* ```2003``` ... Carbon plaintext protocol
* ```2004``` ... Carbon pickle protocol

## Example docker-compose file

```
version: "2.4"

networks:
  my_network:
    driver: bridge

services:
  graphite:
    image: egoaty/graphite
    environment:
      - PUID='1234'
      - PUID='1234'
      - TZ='Europe/Vienna'
    networks:
      my_network:
        aliases:
           - graphite
    ports:
      - 80:80
      - 2003:2003
      - 2004:2004
    volumes:
      - ./graphite/storage:/opt/graphite/storage
    restart: unless-stopped
```

