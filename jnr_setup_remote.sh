#!/bin/bash

# -----------------------------
# BE CAREFUL EDITING THIS FILE:
# this script will be sourced, which means you can set env variables just once. 
# Further modifications won't have effect
# -----------------------------

usage () {
    echo "Usage"
    echo "Standard usage:"
    echo "    source setup_remote.sh"
    echo "Specify alias different from jnr, jlr: "
    echo "    source setup_local.sh -n <jupyter notebook alias> -l <jupyter lab alias>"
    echo 
}

# parse arguments
while getopts ":hn:l:" opt; do
  	case $opt in
    	n) jnr_alias="$OPTARG"
    	;;
        l) jlr_alias="$OPTARG"
    	;;
        h) usage 
        return 0
        ;;
    	\?) echo "Invalid option -$OPTARG" >&2
    	return 1
    	;;
  	esac
done

# set default aliases if not provided
if [[ -z "$jnr_alias" ]]; then
    jnr_alias="jnr"
fi

if [[ -z "$jlr_alias" ]]; then
    jlr_alias="jlr"
fi

# check if given alias already exists
if command -v "$jnr_alias" &> /dev/null ; then
    echo "command $jnr_alias is already in use"
    echo "Please specify another alias for remote jupyter notebook by running"
    echo "    source setup_local.sh -n <alias>"
    return 1
fi

if command -v "$jlr_alias" &> /dev/null ; then
    echo "command $jlr_alias is already in use"
    echo "Please specify another alias for remote jupyter lab by running"
    echo "    source setup_local.sh -l <alias>"
    return 1
fi

# identify the type of shell
case $SHELL in
*/zsh) 
    rc_file="$HOME/.zshrc"
    ;;
*/bash)
    rc_file="$HOME/.bashrc"
    ;;
*)
    echo "Fatal: Unable to recognize shell type"
    return 1
esac

# create aliases in rc file
echo >> "$rc_file"
echo "# >> RemoteJupyter" >> "$rc_file"
echo "alias $jnr_alias='jupyter notebook --no-browser --port'" >> "$rc_file"
echo "alias $jlr_alias='jupyter lab --no-browser --port'" >> "$rc_file"
echo "# << RemoteJupyter" >> "$rc_file"
echo >> "$rc_file"

# Tell the user how to proceed
echo
echo "RemoteJupyter successfully setup"
echo "Restart the terminal or run"
echo "    source $rc_file"
echo "to start using."
echo
echo "To start a remote jupyter notebook, just type"
echo "   $jnr_alias <port>"
echo "To start a remote jupyter lab, just type"
echo "   $jlr_alias <port>"
echo "Where <port> must be the same you used on the local machine"

return 0
