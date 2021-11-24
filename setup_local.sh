#!/bin/bash

# -----------------------------
# BE CAREFUL EDITING THIS FILE:
# this script will be sourced, which means you can set env variables just once. 
# Further modifications won't have effect
# -----------------------------

jnr_path="$HOME/.RemoteJupyter"

usage () {
    echo "Usage"
    echo "Standard usage:"
    echo "    source setup_local.sh"
    echo "Specify alias different from jnr: "
    echo "    source setup_local.sh -a <alias>"
    echo 
}


# parse arguments
while getopts ":ha:" opt; do
  	case $opt in
    	a) jnr_alias="$OPTARG"
    	;;
        h) usage 
        return 0
        ;;
    	\?) echo "Invalid option -$OPTARG" >&2
    	return 1
    	;;
  	esac
done

# set default alias if not provided
if [[ -z "$jnr_alias" ]]; then
    jnr_alias="jnr"
fi

# check if given alias already exists
if command -v "$jnr_alias" &> /dev/null ; then
    echo "command $jnr_alias is already in use"
    echo "Please specify another alias for RemoteJupyter by running"
    echo "    source setup_local.sh -a <alias>"
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

# create .RemoteJupyter folder if it doesn't exist
if [[ ! -f "$jnr_path" ]] ; then
	mkdir "$jnr_path"
fi

# create a setup file
setup_date=`date`
echo "$jnr_alias~$setup_date" > "$jnr_path/setup.txt"

# copy jnr.sh into jnr_path
cp jnr.sh "$jnr_path"

# allow jnr.sh to be executed
chmod u+x "$jnr_path/jnr.sh"

# create alias in rc file
echo >> "$rc_file"
echo "# >> RemoteJupyter" >> "$rc_file"
echo "alias $jnr_alias='$jnr_path/jnr.sh'" >> "$rc_file"
echo "# << RemoteJupyter" >> "$rc_file"
echo >> "$rc_file"

# Tell the user how to proceed
echo
echo "RemoteJupyter successfully setup with alias $jnr_alias"
echo "Restart the terminal or run"
echo "    source $rc_file"
echo "to start using."
echo "To obtain instruction on how to use, just type"
echo "   $jnr_alias"
echo 
echo "Run"
echo "    source setup_remote.sh"
echo "to setup the aliases also in the remote machine"

return 0
