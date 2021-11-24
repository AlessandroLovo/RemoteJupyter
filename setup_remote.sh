#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo
    echo "Usage:"
    echo "    source setup_remote.sh [user@]host"
    echo
    echo "You will be ssh connected to your host and you will find the file jnr_setup_remote.sh in your home directory."
    echo "Run it with"
    echo "    source jnr_setup.sh"
    echo "which will setup the aliases to run jupyter notebook and lab remotely"
    echo
    return 0
fi

scp "jnr_setup_remote.sh" "$1:~/"
ssh "$1"