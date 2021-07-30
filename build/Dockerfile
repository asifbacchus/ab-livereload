# node-livereload server supporting SSL/TLS

# allow dynamic building by specifying base image elements as build-args
ARG NODE_VERSION=16
ARG ALPINE_VERSION=3.14
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION}
ARG NODE_VERSION
ARG ALPINE_VERSION

# create new node user with set UID and GID from build-args and create volume directories
ARG NODE_UID=9999
ARG NODE_GID=9999
RUN deluser --remove-home node \
    && addgroup -g ${NODE_GID} -S node \
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
        openssl \
    && apk --update --no-cache upgrade

# labels
MAINTAINER Asif Bacchus <asif@asifbacchus.dev>
LABEL maintainer="Asif Bacchus <asif@asifbacchus.dev>"
LABEL dev.asifbacchus.docker.internalName="ab-livereload"
LABEL org.opencontainers.image.authors="Asif Bacchus <asif@asifbacchus.dev>"
LABEL org.opencontainers.image.description="Dockerized node-livereload supporting TLS and running under limited user account. Environment variables allow specifying files to watch/exclude and notification delay."
LABEL org.opencontainers.image.documentation="https://git.asifbacchus.dev/ab-docker/ab-livereload/raw/branch/master/README.md"
LABEL org.opencontainers.image.source="https://git.asifbacchus.dev/ab-docker/ab-livereload.git"
LABEL org.opencontainers.image.title="ab-livereload"
LABEL org.opencontainers.image.url="https://git.asifbacchus.dev/ab-docker/ab-livereload"
LABEL org.opencontainers.image.vendor="Asif Bacchus <asif@asifbacchus.dev>"

# default environment variables
ENV NODE_ENV=production
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=/home/node/.npm-global/bin:$PATH
ENV TZ="Etc/UTC"
ENV LR_PORT=35729
ENV LR_EXTS="html,xml,css,js,jsx,ts,tsx,php,py"
ENV LR_EXCLUDE=".vscode/,.idea/,.tmp$,.swp$"
ENV LR_DELAY=500
ENV LR_DEBUG=true
ENV LR_HTTPS=true
ENV CERT_HOSTNAME=""

# install node-livereload and express as node user then switch back to root user
USER node
WORKDIR /home/node
COPY --chown=node:node [ "package.json", "package-lock.json", "/home/node/" ]
RUN mkdir -p .npm-global/bin .npm-global/lib \
    && npm config set fund false \
    && npm config set update-notifier false \
    && npm install --save
COPY --chown=node:node [ "ab-livereload.js", "/home/node/"]

# copy scripts and fix-up all permissions
USER root
COPY [ "selfsigned.cnf", "/etc/selfsigned.cnf" ]
COPY [ "entrypoint.sh", "/usr/local/bin/entrypoint.sh" ]
RUN chown node:node /home/node/* \
    && chmod 644 /home/node/package* /home/node/ab-livereload.js \
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
ARG GIT_COMMIT
ARG BUILD_DATE
LABEL org.opencontainers.image.version="NODE=${NODE_VERSION}, node-livereload=0.9.3"
LABEL dev.asifbacchus.docker.internalVersion=${INTERNAL_VERSION}
LABEL org.opencontainers.image.revision=${GIT_COMMIT}
LABEL org.opencontainers.image.created=${BUILD_DATE}

#EOF
