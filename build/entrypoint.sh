#!/bin/sh

#
# entrypoint script for node-livereload-tls container
#

# functions
certificateCheckExist() {
    if [ -n "$(find /certs/ -type d -empty -print)" ]; then
        printf "noexist"
    elif ! [ -r "/certs/fullchain.pem" ]; then
        printf "noread_certificate"
    elif ! [ -r "/certs/privkey.pem" ]; then
        printf "noread_key"
    else
        printf "ok"
    fi
}

certificateGenerateNew() {
    # generate self-signed certificate and export as PFX
    printf "\nGenerating new self-signed certificate:\n"
    # shellcheck disable=SC3028
    if [ -z "$CERT_HOSTNAME" ]; then export CERT_HOSTNAME="$HOSTNAME"; fi
    if ! openssl req -new -x509 -days 365 -nodes -out /certs/fullchain.pem -keyout /certs/privkey.pem -config /etc/selfsigned.cnf; then
        printf "\nUnable to generate certificate. Is your 'certs' directory writable by this container?\n\n"
        exit 55
    fi

    # print message to user
    printf "\n\nA self-signed certificate has been generated and saved in the location mounted to '/certs' in this container.\n"
    printf "The certificate and private key are PEM formatted with names 'fullchain.pem' and 'privkey.pem', respectively.\n"
    printf "Remember to import 'fullchain.pem' to the trusted store on any client machines or you will get warnings.\n\n"
}

certificateShow() {
    printf "\nCurrently loaded certificate:\n"
    certStatus="$(certificateCheckExist)"
    case "$certStatus" in
    noexist)
        printf "[ERROR]: No certificate is loaded (certificate directory empty).\n\n"
        exit 51
        ;;
    noread_certificate)
        printf "[ERROR]: Cannot read loaded certificate.\n\n"
        exit 52
        ;;
    noread_key)
        printf "\n[WARNING]: Cannot find private key associated with certificate!\n\n"
        ;;
    esac
    if ! openssl x509 -noout -text -nameopt align,multiline -certopt no_pubkey,no_sigdump -in /certs/fullchain.pem; then
        printf "\n[ERROR]: Unable to display loaded certificate.\n\n"
        exit 52
    fi
}

convertCaseLower() {
    printf "%s" "$1" | tr "[:upper:]" "[:lower:]"
}

# default variable values
doCertNew=0
doCertShow=0
doServer=0
doShell=0

# clean-up boolean environment variables for this script and JavaScript
enableHTTPS="$(convertCaseLower "$LR_HTTPS")"
enableDebug="$(convertCaseLower "$LR_DEBUG")"
export LR_HTTPS="$enableHTTPS"
export LR_DEBUG="$enableDebug"

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
*)
    # invalid or unknown option
    printf "\nUnknown action requested: %s\n" "$1"
    printf "Valid actions: [listen | server | run | start] | shell | new-cert | show-cert\n\n"
    exit 1
    ;;
esac

# action: run server
if [ "$doServer" -eq 1 ]; then
    printf "Starting node-livereload-tls server:\n"

    # https pre-flight check
    if [ "$enableHTTPS" = "true" ]; then
        certStatus="$(certificateCheckExist)"
        case "$certStatus" in
            noexist)
                printf "[Generating certificate]\n"
                certificateGenerateNew
                ;;
            noread_certificate)
                printf "[Checking mounted certificate]"
                printf "\nERROR: SSL/TLS mode selected but unable to read certificate!\n\n"
                exit 52
                ;;
            noread_key)
                printf "[Checking mounted certificate]"
                printf "\nERROR: SSL/TLS mode selected but unable to read private key!\n\n"
                exit 53
                ;;
            ok)
                printf "[Certificate OK]\n"
                ;;
        esac
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
if [ "$doCertNew" -eq 1 ]; then
    certificateGenerateNew
    exit 0
fi

# action: show loaded certificate
if [ "$doCertShow" -eq 1 ]; then
    certificateShow
    exit 0
fi

# failsafe exit - terminate with code 99: this code should never be executed!
exit 99

# exit codes:
# 0:   normal exit, no errors
# 1:   invalid or invalid parameter passed to script
# 2:   interactive shell required
# 50:  certificate errors
# 51:    certificate directory empty
# 52:    unable to read certificate/chain
# 53:    unable to read private key
# 55:    unable to generate new certificate
# 99:  code error

#EOF
