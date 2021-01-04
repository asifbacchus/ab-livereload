#
# nodejs with livereload
#

# allow dynamic build by specifying base image as build arg
ARG NODE_TAG="15-alpine3.12"
FROM node:${NODE_TAG}

# change user id of node user
ARG NODE_UID=9999
RUN deluser --remove-home node \
    && addgroup -g ${NODE_UID} -S node \
    && adduser -G node -S -u ${NODE_UID} node

# add tini, timezone support and install livereload
WORKDIR /usr/local/livereload
RUN apk --update --no-cache add \
    tzdata \
    tini \
    && npm install livereload

# create default volume in case user forgets to map one
VOLUME [ "/var/watch" ]

# expose port
EXPOSE 9999

# default environment variables
ENV TZ=Etc/UTC
ENV NODE_ENV=production
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=$PATH:/home/node/.npm-global/bin
ENV EXT="html,xml,css,scss,sass,less,js,jsx,ts,tsx,php,py"
ENV EEXT=""
ENV EXCLUDE=".git/,.svn/"
ENV DELAY=500


# run node via tini by default
USER node
ENTRYPOINT [ "/sbin/tini", "--" ]
CMD [ "livereload", "--port 9999", "--debug", "--exts $EXT", "--extraExts $EEXT", "--exclusions $EXCLUDE", "--wait $DELAY" ]

# set build timestamp and version labels
ARG BUILD_DATE
LABEL org.label-schema.version="0.1"
LABEL org.label-schema.build-date=${BUILD_DATE}
#EOF