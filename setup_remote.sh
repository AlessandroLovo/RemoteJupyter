#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo
    echo "Usage:"
    echo "    source setup_remote.sh [user@]host"
    echo
    echo "You will be ssh connected to your host."
    echo "Then run in the host machine from your home directory"
    echo "    source jnr_setup.sh, which will setup the aliases to run jupyter notebook and lab remotely"
    echo
    return 0
fi

scp "jnr_setup_remote.sh" "$1:~/"
ssh "$1"