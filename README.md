# livereload (dockerized nodejs)

Containerized implementation of [npm livereload](https://www.npmjs.com/package/livereload) as forked by [Brian Hogan](https://github.com/napcs) ([github repo](https://github.com/napcs/node-livereload)). This container is based on Node running on Alpine and provides for easy version and node user UID/GID changes via build args. Time zone, monitored extensions, excluded files/directories and polling delays can be set via environment variables passed at runtime. The container runs under the non-root user *'node'* over the standard livereload port *35729* for compatibility with browser addons.

**Please note:** This container only generates notifications on port 35729 for livereload clients. It does NOT contain a webserver! Please see [Example run commands](#example-run-commands) and [Docker-Compose](#docker-compose) for how to add this to your webdev-stack.

## Contents

- [Private docker repository](#private-docker-repository)
- [Source/Issues](#source-issues)
- [Environment variables](#environment-variables)
- [Volume mapping](#volume-mapping)
- [Example run commands](#example-run-commands)
    - [Using environment variables](#using-environment-variables)
- [Docker-Compose](#docker-compose)
- [Final thoughts](#final-thoughts)

## Private docker repository

If you prefer, you can also use my private repository to download possibly newer containers and/or signed containers. I sign all major release tags (e.g. '1', '2', etc.) and 'latest.' Simply change `asifbacchus/livereload:tag` to `docker.asifbacchus.app/livereload/livereload:tag`.

## Source/Issues

If you want the Dockerfile or if you want to bring an issue/request to my attention, please head to either my private [git server (preferred)](https://git.asifbacchus.app/ab-docker/livereload) or [github](https://github.com/asifbacchus/livereload).

## Environment variables

All environment variables have sensible defaults and, thus, are *not* required to be set for the container to run successfully.

| variable | description                                                  | default                           |
| -------- | ------------------------------------------------------------ | --------------------------------- |
| TZ       | Set the container's time zone. NO impact on runtime, included for convenience. | Etc/UTC                           |
| EXT      | Defines monitored extensions.                                | html,xml,css,js,jsx,ts,tsx,php,py |
| EXCLUDE  | Defines *paths* to ignore.                                   | .git/,.svn/                       |
| DELAY    | Time (ms) between polling for changed files.                 | 500                               |

## Volume mapping

Obviously, this container needs something to monitor to determine whether changes have been made. This is accomplished via bind-mounting a directory from the host and is why 'polling' is necessary. Map a directory with files to be monitored to the container at */var/watch*.

## Example run commands

```bash
docker run --name livereload --restart unless-stopped \
  -v /home/user/Documents/myWebPage:/var/watch \
  -p 35729:35729 \
  asifbacchus/livereload:latest
```

The above command will run the container with a name of *livereload*, restarting with your machine unless explicitly stopped, using the default livereload port. It will monitor all files in */home/user/Documents/myWebPage* for changes.

### Using environment variables

Say you want to only monitor html and css files and you want to ignore anything going on in your 'oldversion' folder. You can set environment variables as follows:

```bash
docker run --name livereload --restart unless-stopped \
  -v /home/user/Documents/myWebPage:/var/watch \
  -p 35729:35729 \
  -e EXT="html,css" \
  -e EXCLUDE="oldversion/"
  asifbacchus/livereload:latest
```

If you wanted a longer polling period, run as follows:

```bash
docker run --name livereload --restart unless-stopped \
  -v /home/user/Documents/myWebPage:/var/watch \
  -p 35729:35729 \
  -e DELAY=3000 \
  asifbacchus/livereload:latest
```

## Docker-Compose

It is very likely this would be integrated via docker-compose with an existing webserver container (like Nginx or Apache). Add this to your docker-compose.yml:

```yaml
livereload:
  image: asifbacchus/livereload:latest
  container_name: livereload
  restart: unless-stopped
  volumes:
    - /local/directory/to/watch:/var/watch
  ports:
    - 35729:35729
  environment:
    - TZ=Region/Locality
```

Obviously, you should change `/local/directory/to/watch` and `TZ=Region/Locality` as needed. Also, please remember to verify the scope of port mapping as appropriate to your environment! You may *not* need to bind to all addresses as I have in this example.

## Final thoughts

That's it. Hopefully this is useful for you and makes it easier to run a live-reload server without having to install node on your machine. As always, let me know if you have any issues/suggestions by filing an issue on either git repo.