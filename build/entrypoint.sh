#!/bin/sh

#
# entrypoint script for livereload-tls-npm container
#

# functions
certificateGenerateNew() {
    # generate self-signed certificate
    printf "\nGenerating new self-signed certificate:\n"
    # shellcheck disable=SC3028
    if [ -z "$CERT_HOSTNAME" ]; then export CERT_HOSTNAME="$HOSTNAME"; fi
    if ! openssl req -new -x509 -days 365 -nodes -out /certs/fullchain.pem -keyout /certs/privkey.pem -config /etc/selfsigned.cnf; then
        printf "\nUnable to generate certificate. Is your 'certs' directory writable by this container?\n\n"
        exit 55
    fi
    printf "Exporting pfx certificate..."
    if ! openssl pkcs12 -export -in /certs/fullchain.pem -inkey /certs/privkey.pem -out "/certs/${CERT_HOSTNAME}.pfx" -name "LiveReload" -passout pass:cert1234; then
        printf "\nUnable to export generated certificate as PFX.\n\n"
        exit 56
    fi

    # print message to user
    printf "\n\nA self-signed certificate has been generated and saved in the location mounted to '/certs' in this container.\n"
    printf "The certificate and private key are PEM formatted with names 'fullchain.pem' and 'privkey.pem', respectively.\n"
    printf "If you need to import them to a Windows machine, please use the '%s.pfx' file with password 'cert1234'.\n\n" "$CERT_HOSTNAME"

    if [ "$1" != "noexit" ]; then exit 0; fi
}

certificateShow() {
    certificateCheckEnabled
    printf "\nCurrently loaded certificate:\n"
    exit 0
}

certificateExport() {
    certificateCheckEnabled
    printf "\nExporting currently loaded certificate:\n"
    exit 0
}

certificateCheckEnabled() {
    if [ "$httpsEnabled" != "TRUE" ]; then
        printf "\nSSL/TLS not enabled. Please set LR_HTTPS=TRUE if you want to enable SSL/TLS.\n"
        exit 1
    fi
}

convertCaseUpper() {
    printf "%s" "$1" | tr "[:lower:]" "[:upper:]"
}

# default variable values
doCertExport=0
doCertNew=0
doCertShow=0
doServer=0
doShell=0
httpsEnabled="$(convertCaseUpper "$LR_HTTPS")"

# process action parameter
case "$1" in
listen | server | run | start)
    doServer=1
    ;;
shell)
    doShell=1
    ;;
new-cert)
    doCertNew=1
    ;;
show-cert)
    doCertShow=1
    ;;
export-cert)
    doCertExport=1
    ;;
*)
    # invalid or unknown option
    printf "\nUnknown action requested: %s\n" "$1"
    printf "Valid actions: [listen | server | run | start] | shell | new-cert | show-cert | export-cert\n\n"
    exit 1
    ;;
esac

# action: run server
if [ "$doServer" -eq 1 ]; then
    printf "Starting LiveReload server:\n"

    # https pre-flight check
    if [ "$httpsEnabled" = "TRUE" ]; then
        printf "[SSL/TLS mode enabled]\n"
        if [ -n "$(find /certs/ -type d -empty -print)" ]; then
            printf "[Generating certificate]\n"
            # certs directory is empty --> auto-generate certificates
            certificateGenerateNew 'noexit'
        else
            # certs directory contains certificates --> check if they can read
            printf "[Checking mounted certificate]\n"
            if ! [ -r "/certs/fullchain.pem" ]; then
                printf "\nERROR: SSL/TLS mode selected but unable to read certificate!\n\n"
                exit 51
            fi
            if ! [ -r "/certs/privkey.pem" ]; then
                printf "\nERROR: SSL/TLS mode selected but unable to read private key!\n\n"
                exit 52
            fi
        fi
        printf "[Certificate OK]\n"
    fi
    exec node livereload.js
    exit "$?"
fi

# action: drop to shell
if [ "$doShell" -eq 1 ]; then
    if [ -z "$2" ]; then
        printf "\nExecuting interactive shell:\n"
        exec /bin/sh
    else
        shift
        printf "\nExecuting shell: '%s'\n" "$*"
        exec /bin/sh -c "$*"
    fi
    exit "$?"
fi

# action: generate new self-signed certificate
if [ "$doCertNew" -eq 1 ]; then certificateGenerateNew; fi

# action: show loaded certificate
if [ "$doCertShow" -eq 1 ]; then certificateShow; fi

# action: export loaded certificate
if [ "$doCertExport" -eq 1 ]; then certificateExport; fi

# failsafe exit - terminate with code 99: this code should never be executed!
exit 99

# exit codes:
# 0:   normal exit, no errors
# 1:   invalid or invalid parameter passed to script
# 2:   interactive shell required
# 50:  certificate errors
# 51:    unable to read certificate/chain
# 52:    unable to read private key
# 55:    unable to generate new certificate
# 56:    unable to export certificate, likely write error
# 99:  code error

#EOF
