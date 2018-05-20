FROM node:10-alpine
MAINTAINER Shi Han NG "shihanng@gmail.com"

RUN npm install -g @bitwarden/cli@0.3.0

ENTRYPOINT [ "/usr/local/bin/bw" ]
