# ab-livereload (dockerized Livereload)

Containerized implementation of [node-livereload](https://www.npmjs.com/package/livereload) as forked by [Brian Hogan](https://github.com/napcs) ([github repo](https://github.com/napcs/node-livereload)). This container is based on Node running on Alpine and provides for easy version-pinning and node user UID/GID changes via build args. Time zone, monitored extensions, excluded files/directories and polling delays can be set via environment variables passed at runtime. The container runs under the non-root user *'node'* over the standard livereload port *35729* for compatibility with browser addons.

**Please note:** This container only generates notifications for livereload clients. It does NOT contain a webserver! Please see [Examples](#examples) and [Docker-Compose](#docker-compose) for how to add this to your webdev-stack.

## Contents

<!-- toc -->

- [Private docker repository](#private-docker-repository)
- [Source/Issues](#sourceissues)
- [Environment variables](#environment-variables)
- [Volume mapping](#volume-mapping)
    * [Certificate mount (HTTPS only)](#certificate-mount-https-only)
    * [Content mount](#content-mount)
- [Commands](#commands)
- [Examples](#examples)
    * [Run in HTTP (unsecured) mode](#run-in-http-unsecured-mode)
    * [Run in HTTPS mode with supplied certificate](#run-in-https-mode-with-supplied-certificate)
    * [Run in HTTPS mode with generated certificate](#run-in-https-mode-with-generated-certificate)
- [Livereload client](#livereload-client)
- [Permissions](#permissions)
    * [Option 1: rebuild with different UID/GID](#option-1-rebuild-with-different-uidgid)
    * [Option 2: specify runtime GID](#option-2-specify-runtime-gid)
    * [Using Let’s Encrypt](#using-lets-encrypt)
- [Docker-Compose](#docker-compose)
- [Brief changelog](#brief-changelog)
- [Final thoughts](#final-thoughts)

<!-- tocstop -->

## Private docker repository

If you prefer, you can also use my private repository to download possibly newer containers. Simply change `asifbacchus/livereload:tag` to `docker.asifbacchus.dev/ab-livereload/ab-livereload:tag`.

## Source/Issues

If you want the Dockerfile or if you want to bring an issue/request to my attention, please head to either my private [git server (preferred)](https://git.asifbacchus.dev/ab-docker/livereload) or [github](https://github.com/asifbacchus/livereload).

## Environment variables

All environment variables have sensible defaults and, thus, are *not* required to be set for the container to run successfully.

| variable      | description                                                                                                                                                                                                                                                                                                                                                                                         | default                                                                                   |
|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| TZ            | Set the container's time zone. NO impact on runtime, included for convenience.                                                                                                                                                                                                                                                                                                                      | Etc/UTC                                                                                   |
| LR_PORT       | Port over which Livereload will communicate. All clients presently expect port 35729, so I suggest leaving this alone.                                                                                                                                                                                                                                                                              | 35729                                                                                     |
| LR_EXTS       | Defines monitored extensions.                                                                                                                                                                                                                                                                                                                                                                       | html,xml,css,js,jsx,ts,tsx,php,py                                                         |
| LR_EXCLUDE    | Comma-delimited regular-expressions (Regex) that define paths or files to ignore. These are *appended* to the node-livereload upstream defaults which ignore everything in the `.git/`, `.svn/` and `.hg/` directories.<br />**N.B.** You do *not* have to use JavaScript format. The script will automatically convert things to JS-RegEx. You do, however, need to escape any special characters. | .vscode/,.idea/,.tmp$,.swp$/                                                              |
| LR_DELAY      | Time (ms) between polling for changed files.                                                                                                                                                                                                                                                                                                                                                        | 500                                                                                       |
| LR_DEBUG      | Print informational messages to the console. Allows you to see Livereload working.                                                                                                                                                                                                                                                                                                                  | true                                                                                      |
| LR_HTTPS      | Use HTTPS and WSS. In other words, use a certificate for SSL/TLS operation.                                                                                                                                                                                                                                                                                                                         | true                                                                                      |
| CERT_HOSTNAME | If the container needs to generate a self-signed certificate, this is the hostname it will use.                                                                                                                                                                                                                                                                                                     | Container hostname -- this almost *never* what you really want so don’t use this default. |

## Volume mapping

The container needs two mounts to function correctly in HTTPS mode and only one in HTTP mode:

### Certificate mount (HTTPS only)

If you do not bind-mount a directory, the container will create a volume for you. Bind-mounting or supplying a manually created volume is a much better option. The container reads certificates from this directory or, alternatively, will generate a certificate and key in this directory. Whatever you are mounting, it must map to */certs* in the container.

If you are mounting existing certificates:

- your certificate *must* be named *fullchain.pem* and be readable by the container user (UID=9999, GID=9999 by default)
- your private key *must* be named *privkey.pem* and be readable by the container user (UID=9999, GID=9999 by default)

> Important: The container runs as user *node* with UID and GID *9999* by default. You can change this by rebuilding the container or at runtime by supplying `--user "uid:gid"`. This may be necessary especially if you are bind-mounting since the container needs permissions to read both a supplied certificate *and* key. If it is generating said certificate and key, then obviously it needs *write* permissions to said mounted directory. If you are using a volume, permissions are easier. This is discussed in the [Permissions](#permissions) section.

### Content mount

Obviously, this container needs something to monitor to determine whether changes have been made. This is accomplished via bind-mounting a directory from the host and is why 'polling' is necessary. Mount a directory with files to be monitored to */watch* in the container.

## Commands

The container’s entrypoint script recognizes a few commands that tell it what you want to do:

| command   | description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
|-----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| listen    | Activate Livereload server using configured parameters.<br />Aliases: run \                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | server \| start<br />`docker run --rm ... asifbacchus/livereload listen` |
| shell     | Start container but drop to an Ash shell. Alternatvely, if you supply a command, the container will run that command in the shell, output results and then exit.<br />`docker run -it --rm ... asifbacchus/livereload shell`<br />`docker run --rm ... asifbacchus/livereload shell ls -lAsh /certs`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| new-cert  | Generate a new self-signed certificate with CN=CERT_HOSTNAME and matching DNS.1 value. Certificate and private key will be stored in */certs* as *fullchain.pem* and *privkey.pem*, respectively.<br />I strongly suggest running the container with `--user "uid:gid"` where the *gid* corresponds to one matching your webserver user, for example. That way your webserver would have read access to the generated private key. More information in the [Permissions](#permissions) section.<br />For example, running `docker run --rm -u "9999:6001" -v /etc/mycerts:/certs -e CERT_HOSTNAME=sub.domain.tld asifbacchus/livereload new-cert` would generate a new certificate and key pair in the */etc/mycerts/* directory on the host. Importantly, the private key would be readable by GID 6001 which, in this example, might be your webdev programs group including your webserver and you as the web-dev. |
| show-cert | Display the currently loaded certificate. This can be either a generated or a supplied certificate. Great way to confirm you mounted the right one!<br />`docker run --rm -v /etc/mycerts:/certs asifbacchus/livereload show-cert`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |

## Examples

### Run in HTTP (unsecured) mode

```bash
docker run -d --rm -v /var/www:/watch:ro -e LR_HTTPS=false -p 35729:35729 asifbacchus/livereload listen
```

- `-d --rm`: run in the background and remove container upon exit
- `-v ...`: mount directory to monitor
- `-e LR_HTTPS=false`: run in HTTP instead of default HTTPS mode
- `-p 35729:35729`: map on all interfaces port 35729 on the host --> port 35729 in container
- `listen`: start the Livereload server

> Depending on your environment, you may *not* want to expose your Livereload server on all interfaces! You may want to map your port to something like `127.0.0.1:35729:35729` and then establishing an SSH-tunnel from your client. This is completely dependent on your environment and beyond the scope of this readme, sorry.

### Run in HTTPS mode with supplied certificate

```bash
docker run -d --rm -v /etc/mycerts:/certs:ro -v /var/www:/watch:ro -p 35729:35729 asifbacchus/livereload listen
```

- all options same as above except we’ve included a bind-mount for the certificates
- HTTPS is the default operating mode, so it is *not necessary* to supply `LR_HTTPS=true`

### Run in HTTPS mode with generated certificate

You have two options for running with a self-signed generated certificate. If the container starts up in HTTPS mode and does not find an existing certificate, it will just make one for you. Alternatively, you can generate a certificate first and then run the container manually after -- there are use-cases for both options. Let’s start with the second option first:

```bash
# create volume
docker volume create livereload-certs

# generate a certificate readable by GID=6001 in new volume and exit
docker run --rm --user "9999:6001" -v livereload-certs:/certs -e CERT_HOSTNAME=webdev.mydomain.tld asifbacchus/livereload new-cert

# run container using our new certificate
docker run -d --rm -v livereload-certs:/certs:ro -v /home/janedoe/myWebProject:/watch:ro -p 35729:35729 asifbacchus/livereload listen
```

Or, do it all in one-shot:

```bash
# write new certificate readable by GID=5100 to a bind-mounted directory and run container in one-step
docker run -d --rm --user "9999:5100" -v /etc/mycerts:/certs -v /home/janedoe/myWebProject:/watch:ro -e CERT_HOSTNAME=webdev.myserver.tld -p 35729:35729 asifbacchus/livereload listen
```

## Livereload client

There aren’t a lot of currently updated Livereload clients and/or browser addons out there, but the ones that do exist seem to only work over HTTP. In fact, that was the impetus behind creating this container. I develop on both  *.dev* and  *.app* domains -- both of which *require* HTTPS. As a result, I couldn’t use any existing clients nor could I use the preconfigured node-livereload distribution via the command-line as version 1.x of this container did.

If you are running in an HTTP-permissive environment then lucky you! You can run this container in HTTP mode (`LR_HTTPS=false`) and use any of the clients and addons out there. If you want to use a snippet in your code instead of a client, simply insert this in the `<head>` of your page while using Livereload during dev:

```html

<script>
    document.write('<script src="http://' + (location.host || 'localhost').split(':')[0] +
            ':35729/livereload.js?snipver=1"></' + 'script>')
</script>
```

If, however, you are like me and want/need to use HTTPS then things are a little different. As I said, I can’t find a single client or addon that works over HTTPS. Therefore, you *must* use a snippet in your webpage. It’s the exact same as above, just use HTTPS instead -- again inserting in the `<head>` of your page:

```html

<script>
    document.write('<script src="https://' + (location.host || 'localhost').split(':')[0] +
            ':35729/livereload.js?snipver=1"></' + 'script>')
</script>
```

That’s it. The advantage of using the snippet is that you don’t need any clients or addons or any other garbage. Things just work so long as this is in your code. When you’re done developing and ready to go to production, just remove the snippet and Livereload is disabled like it never existed.

## Permissions

The container is run as a limited user, *node*, with UID=9999 and GID=9999 by default. While this is much more secure than running as root, it does cause some complications especially with certificates. If you are supplying a certificate then the container user must be able to read both the certificate and the private key. If you are generating a certificate-key pair, then the container needs to be able to write them somewhere *and* they have to be generated with permissions making them usable to other services such as a web server. By default the container generates *fullchain.pem* with *644* permissions and *privkey.pem* with ***640*** permissions.

> Private keys are usually generated with *600* permissions. However, this is useless in our case since this container is not a web server and, thus, this key must be shared with at least one other service (i.e. the web server). That is why it is GROUP readable via the 6**4**0 permissions. As long as your other services are in the same group, they can use this generated certificate.

Here’s the catch: By default, the node user’s GID is the same as their UID so the certificate is still only readable by the node user itself. There are two ways around this:

### Option 1: rebuild with different UID/GID

If you already have an infrastructure set up and need to plug this in, it might just be easier to alter the container user’s IDs so everything works in your environment. Clone the [git repo](https://git.asifbacchus.dev/ab-docker/livereload) and build as follows:

```bash
# clone repo
cd /usr/local/src
git clone https://git.asifbacchus.dev/ab-docker/livereload

# change directory and build
cd livereload/build
docker build --build-arg NODE_UID=1101 --build-arg NODE_GID=6001 --build-arg BUILD_DATE=$(date +%F_%T) -t livereload:latest .
```

- `NODE_UID`: optional -- desired UID for node user, in most cases the default is fine
- `NODE_GID`: desired GID for node user --> this is probably what you really want to change
- `BUILD_DATE`: optional -- applies container build date in a standardized label
- `livereload:latest`: you can of course choose any imageName:tag that suits you

Now a generated certificate-key pair will be owned by your defined UID and will be readable by any other user sharing the defined GID.

### Option 2: specify runtime GID

Maybe easier and more customizable, you can simply specify a GID to use at runtime so that things work in your environment. For example, let’s say your web server has a *www-data* group with GID 6001 which already has access to your web files. Now you want to secure everything with a certificate and add Livereload. Ok, let’s just run it with the right IDs:

```bash
# make a certificates directory with secure permissions
sudo mkdir /devCerts && chown root:www-data /devCerts && chmod 770 /devCerts
sudo ls -ldsh /devCerts
	4.0K drwxrwx--- 2 root www-data 4.0K Jul 24 16:44 /devCerts

# create certificate with hostname myserver.tld
docker run --rm --user "9999:6001" -v /devCerts:/certs -e CERT_HOSTNAME=myserver.tld asifbacchus/livereload new-cert

# check our work -- looks good!
sudo ls -lAsh /devCerts
	total 16K
	4.0K -rw-r--r-- 1 9999 www-data 1.8K Jul 24 16:46 chain.pem
	4.0K -rw-r--r-- 1 9999 www-data 1.5K Jul 24 16:46 dhparam.pem
	4.0K -rw-r--r-- 1 9999 www-data 1.8K Jul 24 16:46 fullchain.pem
	4.0K -rw-r----- 1 9999 www-data 3.2K Jul 24 16:46 privkey.pem

# run server
docker run -d --rm -v /devCerts:/certs:ro -v /usr/share/nginx/html:/watch -p 35729:35729 asifbacchus/livereload listen
```

### Using Let’s Encrypt

I won’t get too much into details here, but while Let’s Encrypt is awesome it does present a little extra work when dealing with containers. Basically, you have to remember that the *live* directory contains symlinks to the latest version of your certificate. However, if you try to mount a symlink to your container you’ll quickly find out that doesn’t work since the *target* of the link does not exist in the container also.

The most robust solution is setting up a post-renew script for your Let’s Encrypt management solution that copies these certificates to a location your container can access and use the above information to use that certificate.

Alternatively, you can alter the *group* permissions on the */etc/letsencrypt/live* and */etc/letsencrypt/archive* directories. Then change the *group* permissions on */etc/letsencrypt/archive/certname/privkey1.pem* to allow reading it. This example is for Certbot, but most LE managers should work similarly. Assuming your LE client maintains permissions (like Certbot), the GID in question can read what is needed.

A final note: You **cannot** bind-mount `/etc/letsencrypt/live/certname:/certs`. It’s the same reason as above, it will bind symlinks that are not valid within the container. You need to bind-mount each individual link so it is resolved by Docker when running the container:

```bash
docker run --rm ... -v /etc/letsencrypt/live/certname/fullchain.pem:/certs/fullchain.pem:ro -v /etc/letsencrypt/certname/privkey.pem:/certs/privkey.pem:ro ...
```

## Docker-Compose

Containers, like people, often get lonely and enjoy working with others. In the case of this container, it is quite useless if not paired with at least a web server. I’ve included the core of the actual set up I use for web development -- a customized NGINX container and this Livereload container all secured with a certificate so everything even in testing is working over TLS like in real life. Take a look at the *docker-compose.yml* for more details. If you’re using Let’s Encrypt certificates, read the section above and remember to mount the files individually. If you are interested in my AB-NGINX container which has several useful additions to the official container including a healthcheck, then [check out the repo](https://git.asifbacchus.dev/ab-docker/ab-nginx).

## Brief changelog

### Version 3.0.0

- `npm` no longer present in final build, too many un-patched security vulnerabilities.
- multi-stage build with the final image being a minimal node installation directly on the Alpine base.
- container is now ~50% smaller due to multi-stage build :-)

### Version 2.x

Starting with the 2.x version line, I’ve added two *very* important features:

- SSL/TLS support with auto-generated self-signed certificates if you don’t have your own certificates
- Healthcheck allowing for proper integration using docker-compose into a webstack

## Final thoughts

That's it. Hopefully this is useful for you and makes it easier to run a live-reload server without having to install node on your machine. As always, let me know if you have any issues/suggestions or if something isn’t well documented by filing an issue on either git repo.
