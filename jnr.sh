#!/bin/bash

jnr_path="$HOME/.RemoteJupyter"
filename="$jnr_path/status.txt"
tmp_filename="$jnr_path/status.tmp"
tmp_filename1="$jnr_path/tmp1.tmp"
tmp_filename2="$jnr_path/tmp2.tmp"

have_to_kill=false
have_to_spawn=true
refresh=false
restore=false

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

	# retrieve alias from setup file
	while IFS='' read -r line ; do
		IFS='~' read jnr_alias _rest <<< "$line"
	done < "$jnr_path/setup.txt"

	echo "****************************************************************"
	echo "*                        Remote Jupyter                        *"
	echo "*                                                              *"
	echo "*     a helper to run jupyter notebooks and labs over ssh      *"
	echo "*       https://github.com/AlessandroLovo/RemoteJupyter        *"
	echo "****************************************************************"
	echo "================================================"
    echo "Usage:"
	echo "To spawn a new process:"
	echo "    $jnr_alias -h <[user@]host> [-p <port> (default 8888)]"
	echo "To kill a process:"
	echo "    $jnr_alias -kh <[user@]host> or $jnr_alias -kp <port>"
	echo "To view the list of running processes:"
	echo "    $jnr_alias -v"
	echo "To refresh [and view] the list of processes (in case some died on their own):"
	echo "    $jnr_alias -r[v]"
	echo "To restore all dead processes:"
	echo "	  $jnr_alias -R"
	echo "================================================"
	echo
	echo "-------------------"
	echo "General Wrokflow:"
	echo "1. (local machine): spawn a new process as shown above"
	echo "2. The terminal automatically moves to the remote machine"
	echo "3. (remote machine): start a jupyter notebook or lab with the aliases you set up when configuring RemoteJupyter on the remote machine"
	echo "  for example with" 
	echo "    jnr 8888"
	echo "  which launches a jupyter notebook on port 8888"
	echo "4. (remote machine): copy the url that contains 'localhost'"
	echo "5. (local machine): open a browser and paste the url"
	echo "6. Do your work"
	echo "7. (remote machine): Stop the notebook/lab by double tapping ctrl-c"
	echo "[8. (remote machine): exit]"
	echo "9. (local machine): kill the port forwarding process as shown above"
	echo "-------------------"
    exit 0
fi

# parse arguments
while getopts ":kh:p:vrR" opt; do
  	case $opt in
    	v) # show_what="$OPTARG"
    	show_list=true
		have_to_spawn=false
		;;
		r) refresh=true
		;;
		R) restore=true
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

# restore dead process
if [[ "$restore" == true ]] ; then
	count=0
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
			count=$(( count + 1 ))
			echo
			echo "Restoring dead process on port $_port: old PID $_pid, Hostname: $_hostname"

			# spawn port forwarding and save its PID
			ssh -NfL localhost:$_port:localhost:$_port $_hostname
		
			# get new process PID and write to file
			ps ax | grep "ssh -NfL localhost:$_port:" | head -n 1 > "$tmp_filename1"
			while IFS='' read -r line ; do
				IFS=' ' read _pid _rest <<< "$line"
			done < "$tmp_filename1"
			echo "$_port $_pid $_hostname" >> "$tmp_filename"
			rm "$tmp_filename1"

			echo "New PID: $_pid"
			echo
		else
			echo "$line" >> "$tmp_filename"
		fi

	done < "$filename"
 
  	mv "$tmp_filename" "$filename"

	if [[ $count == 0 ]] ; then
		echo
		echo "No dead processes to restore"
		echo
	else
		echo
		echo "Connecting to host $_hostname"
		echo
		ssh $_hostname
	fi
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