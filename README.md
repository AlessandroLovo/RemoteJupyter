# RemoteJupyter
Utility to run a Jupyter notebook/lab over ssh

# Installation (Linux and macOS)
1. Download/clone the repository and open a terminal in the folder
2. Run
```source setup_local.sh [-a <alias> (default jnr)]```
3. Run ```source setup_remote.sh [user@]host```
4. You will be ssh connected to your host and you will find the file `jnr_setup_remote.sh` in your home directory.
Run it with
```source jnr_setup_remote.sh [-l <jupyter-lab alias> (default jlr)] [-n <jupyter-notebook alias> (default jnr)]```
which will setup the aliases to run jupyter notebook and lab remotely

# Usage (local machine)
Assuming your alias for RemoteJupyter is `jnr` (default), 

* To spawn a new process:
    ```jnr -h <[user@]host> [-p <port> (default 8888)]```
* To kill a process:
    ```jnr -kp <port>```
* To kill all processes on a given host
    ```jnr -kh <[user@]host>```
* To kill all processes
    ```jnr -kh all```
* To view the list of running processes:
    ```jnr -v```
* To refresh \[and view\] the list of processes (in case some died on their own):
    ```jnr -r[v]```
* To restore dead processes:
    ```jnr -R```
    

# General Workflow
1. (local machine): spawn a new process as shown above on a given port, let's say the default one 8888
2. The terminal automatically moves to the remote machine
3. (remote machine): start a jupyter notebook or lab with the aliases you set up when configuring RemoteJupyter on the remote machine for example with
	```jlr 8888``` which launches a jupyter lab on port 8888"
4. (remote machine): copy the url that contains 'localhost'
5. (local machine): open a browser and paste the url
6. ...Do your work...
7. (remote machine): Stop the notebook/lab by double tapping `ctrl-c`
8. optional (remote machine): exit
9. (local machine): kill the port forwarding process as shown above
