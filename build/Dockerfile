# node-livereload server supporting SSL/TLS

# allow dynamic building by specifying base image elements as build-args
ARG NODE_VERSION=16
ARG ALPINE_VERSION=3.14
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION}

# create new node user with set id from build-arg and create volume directories
ARG NODE_UID=9999
RUN deluser --remove-home node \
    && addgroup -g ${NODE_UID} -S node \
    && adduser -G node -S -u ${NODE_UID} node \
    && mkdir /watch /certs \
    && chown root:node /certs \
    && chmod 770 /certs

# create default volumes in-case user forgets, expose default port
VOLUME [ "/watch", "/certs" ]
EXPOSE 35729

# add tini, timezone support and create certificate directories
RUN apk --update --no-cache add \
    tini \
    tzdata \
    openssl

# labels
LABEL org.opencontainers.image.authors="Asif Bacchus <asif@asifbacchus.dev>"
LABEL org.opencontainers.image.title="node-livereload-tls"
LABEL org.opencontainers.image.description="Dockerized node-livereload supporting TLS and running under limited user account. Environment variables allow specifying files to watch/exclude and notification delay."
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
ENV LR_DEBUG=true
ENV LR_HTTPS=true
ENV CERT_HOSTNAME=""

# install node-livereload and express as node user then switch back to root user
USER node
WORKDIR /home/node
RUN mkdir -p .npm-global/bin .npm-global/lib \
    && npm config set fund false \
    && npm config set update-notifier false \
    && npm install livereload express --save

# copy scripts and fix-up all permissions
USER root
COPY [ "selfsigned.cnf", "/etc/selfsigned.cnf" ]
COPY [ "livereload.js", "/home/node/livereload.js" ]
COPY [ "entrypoint.sh", "/usr/local/bin/entrypoint.sh" ]
RUN chown node:node /home/node/livereload.js \
    && chmod 644 /home/node/livereload.js \
    && chmod 755 /usr/local/bin/entrypoint.sh \
    && chmod 644 /etc/selfsigned.cnf

HEALTHCHECK \
    --interval=10s \
    --timeout=5s \
    --start-period=60s \
    --retries=3 \
    CMD wget --spider -T 3 -q localhost:3000/api/v1/health || exit 1

# switch to node user, run entrypoint script by default
USER node
WORKDIR /home/node
ENTRYPOINT [ "/sbin/tini", "--", "/usr/local/bin/entrypoint.sh" ]

# set build timestamp and version labels
ARG INTERNAL_VERSION
ARG BUILD_DATE
LABEL org.opencontainers.image.version="16.5.0, 0.9.3"
LABEL org.opencontainers.image.vendor="NODE.js, node-livereload"
LABEL dev.asifbacchus.image.name="node-livereload-tls"
LABEL dev.asifbacchus.image.version=${INTERNAL_VERSION}
LABEL org.opencontainers.image.created=${BUILD_DATE}

#EOF
