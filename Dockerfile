#
# nodejs with livereload
#

# allow dynamic build by specifying base image as build arg
ARG NODE_TAG="16-alpine3.13"
FROM node:${NODE_TAG}

# change user id of node user
ARG NODE_UID=9999
RUN deluser --remove-home node \
    && addgroup -g ${NODE_UID} -S node \
    && adduser -G node -S -u ${NODE_UID} node

# add tini, timezone support
RUN apk --update --no-cache add tzdata tini

# labels
LABEL org.opencontainers.image.authors="Asif Bacchus <asif@bacchus.cloud>"
LABEL org.opencontainers.image.title="livereload npm"
LABEL org.opencontainers.image.description="Dockerized npm livereload running under limited user account. Environment variables allow specifying files to watch/exclude and notification delay."
LABEL org.opencontainers.image.url="https://git.asifbacchus.app/ab-docker/livereload"
LABEL org.opencontainers.image.documentation="https://git.asifbacchus.app/ab-docker/livereload/raw/branch/master/README.md"
LABEL org.opencontainers.image.source="https://git.asifbacchus.app/ab-docker/livereload.git"

# create default volume in case user forgets to map one
VOLUME [ "/var/watch" ]

# expose port
EXPOSE 35729

# default environment variables
ENV TZ=Etc/UTC
ENV NODE_ENV=production
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=$PATH:/home/node/.npm-global/bin
ENV EXT="html,xml,css,js,jsx,ts,tsx,php,py"
ENV EXCLUDE=".git/,.svn/"
ENV DELAY=500

# install livereload for node user
USER node
WORKDIR /home/node
RUN mkdir -p .npm-global/bin .npm-global/lib \
    && npm install -g livereload

# run node via tini by default
ENTRYPOINT [ "/sbin/tini", "--" ]
CMD livereload /var/watch --debug --exts $EXT --exclusions $EXCLUDE -u true --wait $DELAY

# set build timestamp and version labels
ARG BUILD_DATE
LABEL org.opencontainers.image.version="1.1"
LABEL org.opencontainers.image.vendor="nodeJS v16.3.0"
LABEL org.opencontainers.image.created=${BUILD_DATE}
#EOF
