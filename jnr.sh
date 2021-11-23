#!/bin/bash

filename="$HOME/.jnr/status.txt"
tmp_filename="$HOME/.jnr/status.tmp"
tmp_filename1="$HOME/.jnr/tmp1.tmp"
tmp_filename2="$HOME/.jnr/tmp2.tmp"

have_to_kill=false
have_to_spawn=true
refresh=false

port=false
hostname=false
show_list=false

# setup log file if it doesn't exist
if [[ ! -f "$filename" ]] ; then
	echo "port PID Hostname" > "$filename"
fi

# check if there are arguments
if [[ $# -eq 0 ]] ; then
	have_to_spawn=false
	echo "================================================"
    echo "Usage: to spawn a new process:"
	echo "    jnr -h <hostname> [-p <port> (default 8888)]"
	echo "To kill a process:"
	echo "    jnr -kh <hostname> or jnr -kp <port>"
	echo "To view the list of running processes:"
	echo "    jnr -v"
	echo "To refresh [and view] the list of processes (in case some died on their own):"
	echo "    jnr -r[v]"
	echo "================================================"
    exit 0
fi

# parse arguments
while getopts ":kh:p:vr" opt; do
  	case $opt in
    	v) # show_what="$OPTARG"
    	show_list=true
		have_to_spawn=false
		;;
		r) refresh=true
    	;;
    	k) have_to_kill=true
    	have_to_spawn=false
    	;;
    	h) hostname="$OPTARG"
		if [[ "$have_to_spawn" == true && "$port" == false ]] ; then
			port=8888
		fi
    	;;
    	p) port="$OPTARG"
    	;;
    	\?) echo "Invalid option -$OPTARG" >&2
    	exit 1
    	;;
  	esac
done

# refresh
if [[ "$refresh" == true ]] ; then
	while IFS='' read -r line ; do
    	IFS=' ' read _port _pid _hostname <<< "$line"
		remove=false

		if [[ "$_port" != "port" ]] ; then
			ps ax | grep "ssh -NfL localhost:$_port:" > "$tmp_filename1"
			wc -l "$tmp_filename1" > "$tmp_filename2" # read lenght of file tmp_filename1
			while IFS='' read -r line2 ; do
				IFS=' ' read _linecount _rest <<< "$line2"
			done < "$tmp_filename2"
			rm "$tmp_filename1"
			rm "$tmp_filename2"
			if [[ $_linecount -le 1 ]] ; then # tmp_filename1 contains only one line: the port forwarding has died
				remove=true
			fi
		fi

		# remove the process
		if [[ "$remove" == true ]] ; then
			echo
			echo "Removing dead process on port $_port: PID $_pid, Hostname: $_hostname"
			echo
		else
			echo "$line" >> "$tmp_filename"
		fi

	done < "$filename"
 
  	mv "$tmp_filename" "$filename"
fi

# show list of running processes
if [[ "$show_list" == true ]] ; then
  	echo

	# check if there are active processes
	wc -l "$filename" > "$tmp_filename" # write to tmp_filename the length of filename
	while IFS='' read -r line ; do
		IFS=' ' read _linecount _rest <<< "$line"
	done < "$tmp_filename"
	rm "$tmp_filename"
	if [[ $_linecount -le 1 ]] ; then
		echo "No active processes"
		echo
		exit 0
	fi

	while IFS='' read -r line ; do
		echo $line
	done < "$filename"
  	echo
	exit 0
fi

# kill port forwarding process
if [[ "$have_to_kill" == true ]] ; then
  	rm -f "$tmp_filename"
  	nothing_to_kill=true
 
  	# read status file to see if there is a process to kill
  	while IFS='' read -r line ; do
    	IFS=' ' read _port _pid _hostname <<< "$line"
		do_kill=false

		# search matching for port or hostname
		if [[ "$_port" != "port"  ]] ; then # not the first line
			if [[ "$port" != false ]] ; then #                   \/ skip the first line
				if [[ "$_port" == "$port" || "$port" == "all" ]] ; then
					do_kill=true
				fi
			elif [[ "$hostname" != false ]] ; then #                        \/ skip the first line
				if [[ "$_hostname" == "$hostname" || "$hostname" == "all" ]] ; then
					do_kill=true
				fi
			else
				echo "Use -kh <hostname> or -kp <port>"
				exit 1
			fi
		fi

		# kill the process
		if [[ "$do_kill" == true ]] ; then
			nothing_to_kill=false
			echo
			echo "Killing process on port $_port: PID $_pid, Hostname: $_hostname"
			echo
			kill "$_pid"
		else
			echo "$line" >> "$tmp_filename"
		fi

  	done < "$filename"
 
  	mv "$tmp_filename" "$filename"
 
  	# warn the user if no process is found
  	if [ "$nothing_to_kill" == true ] ; then
    	if [[ ! "$hostname" == false ]] ; then
			echo "No active process on host $hostname"
		elif [[ "$port" != false ]] ; then
			echo "No active process on port $port"
		fi
		exit 1
  	fi
	exit 0
fi
 
# spawn a port forwarding and connect to the host
if [[ "$have_to_spawn" == true && "$port" != false ]] ; then
  	# check if port or hostname are already busy
  	while IFS='' read -r line ; do
    	IFS=' ' read _port _pid _hostname <<< "$line"
		if [[ "$_port" == "$port" ]] ; then
			echo "Port $port is already busy with host $hostname"
			exit 1
		elif [[ "$_hostname" == "$hostname" ]] ; then
			echo "WARNING: You are already connected to host $hostname on port $_port"
		fi
  	done < "$filename"

	#spawn the new process
	echo
  	echo "Spawning process on port $port"
	echo

  	# spawn port forwarding and save its PID
  	ssh -NfL localhost:$port:localhost:$port $hostname
 
 	# get process PID and write to file
	ps ax | grep "ssh -NfL localhost:$port:" | head -n 1 > "$tmp_filename"
	while IFS='' read -r line ; do
		IFS=' ' read _pid _rest <<< "$line"
	done < "$tmp_filename"
	echo "$port $_pid $hostname" >> "$filename"
	rm "$tmp_filename"

	# ssh to the host
	ssh $hostname
	exit 0
fi