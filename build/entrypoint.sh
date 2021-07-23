#!/bin/sh

#
# entrypoint script for livereload-tls-npm container
#

# functions
certificateGenerateNew() {
    printf "\nGenerating new self-signed certificate:\n"
    printf "Exporting new certificate:\n"
    exit 0
}

certificateShow() {
    printf "\nCurrently loaded certificate:\n"
    exit 0
}

certificateExport() {
    printf "\nExporting currently loaded certificate:\n"
    exit 0
}

# default variable values
doCertExport=0
doCertNew=0
doCertShow=0
doServer=0
doShell=0

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
# 50:  certificate errors
# 51:    unable to read certificate/chain
# 52:    unable to read private key
# 55:    unable to generate new certificate
# 56:    unable to export certificate, likely write error
# 99:  code error

#EOF
