# LiveReload-npm server supporting SSL/TLS
ARG NODE_VERSION=16
ARG ALPINE_VERSION=3.14
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION}

RUN apk --update --no-cache add \
    tini \
    && mkdir /certs \
    && chown node:node /certs \
    && chmod 700 certs

ENV NODE_ENV=production
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=/home/node/.npm-global/bin:$PATH

USER node
WORKDIR /home/node
RUN mkdir -p .npm-global/bin .npm-global/lib \
    && npm config set fun false \
    && npm config set update-notifier false \
    && npm install livereload --save
COPY [ "livereload.js", "livereload.js" ]

EXPOSE 35729
VOLUME [ "/var/watch" ]

ENV TZ="Etc/UTC"
ENV LR_PORT=35729
ENV LR_EXTS="html,xml,css,js,jsx,ts,tsx,php,py"
ENV LR_EXCLUDE=".git/,.svn/,.vscode/,.idea/"
ENV LR_DELAY=500

ENTRYPOINT [ "/sbin/tini", "--" ]
CMD [ "node", "livereload.js" ]

#EOF
