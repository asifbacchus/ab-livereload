# LiveReload-npm server supporting SSL/TLS

# allow dynamic building by specifying base image elements as build-args
ARG NODE_VERSION=16
ARG ALPINE_VERSION=3.14
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION}

# create new node user with set id from build-arg
ARG NODE_UID=9999
RUN deluser --remove-home node \
    && addgroup -g ${NODE_UID} -S node \
    && adduser -G node -S -u ${NODE_UID} node

# create default volumes in-case user forgets, expose default port
VOLUME [ "/var/watch", "/var/certs" ]
EXPOSE 35729

# add tini, timezone support and create certificate directories
RUN apk --update --no-cache add \
    tini \
    tzdata \
    openssl \
    && chown node:node /var/certs \
    && chmod 700 /var/certs \
    && chmod +r /var/watch

# labels
LABEL org.opencontainers.image.authors="Asif Bacchus <asif@asifbacchus.dev>"
LABEL org.opencontainers.image.title="livereload npm"
LABEL org.opencontainers.image.description="Dockerized npm livereload supporting TLS and running under limited user account. Environment variables allow specifying files to watch/exclude and notification delay."
LABEL org.opencontainers.image.url="https://git.asifbacchus.dev/ab-docker/livereload"
LABEL org.opencontainers.image.documentation="https://git.asifbacchus.dev/ab-docker/livereload/raw/branch/master/README.md"
LABEL org.opencontainers.image.source="https://git.asifbacchus.dev/ab-docker/livereload.git"

# default environment variables
ENV NODE_ENV=production
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=/home/node/.npm-global/bin:$PATH
ENV TZ="Etc/UTC"
ENV LR_PORT=35729
ENV LR_EXTS="html,xml,css,js,jsx,ts,tsx,php,py"
ENV LR_EXCLUDE=".git/,.svn/,.vscode/,.idea/"
ENV LR_DELAY=500

# copy scripts, cleanup permissions and install livereload npm
COPY [ "livereload.js", "/home/node/livereload.js" ]
COPY [ "entrypoint.sh", "/usr/local/bin/entrypoint.sh" ]
RUN chown node:node /home/node/livereload.js \
    && chmod 644 /home/node/livereload.js \
    && chmod 755 /usr/local/bin/entrypoint.sh
USER node
WORKDIR /home/node
RUN mkdir -p .npm-global/bin .npm-global/lib \
    && npm config set fund false \
    && npm config set update-notifier false \
    && npm install livereload --save

# run entrypoint script by default
ENTRYPOINT [ "/sbin/tini", "--", "/usr/local/bin/entrypoint.sh" ]

# set build timestamp and version labels
ARG INTERNAL_VERSION
ARG BUILD_DATE
LABEL org.opencontainers.image.version="16.5.0, 0.9.3"
LABEL org.opencontainers.image.vendor="NODE.js, node-livereload"
LABEL dev.asifbacchus.image.name="livereload-tls-npm"
LABEL dev.asifbacchus.image.version=${INTERNAL_VERSION}
LABEL org.opencontainers.image.created=${BUILD_DATE}

#EOF
