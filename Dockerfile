# DOCKER-VERSION 1.1.0
FROM alpine:3.2
MAINTAINER t.dettrick@uq.edu.au

# Set defaults which should be overridden on run
ENV PORTAL_URL https://dit4c.metadata.net

RUN apk add --update docker

ADD /opt /opt

CMD ["sh", "/opt/run.sh"]
