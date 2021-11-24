# RemoteJupyter
Utility to run a Jupyter notebook/lab over ssh

# Installation (Linux and macOS)
1. Download/clone the repository and open a terminal folder
2. Run
```source setup_local.sh```
3. Run ```source setup_remote.sh [user@]host```
4. You will be ssh connected to your host and you will find the file jnr_setup_remote.sh in your home directory.
Run it with
```source jnr_setup.sh```
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
* To refresh [and view] the list of processes (in case some died on their own):
	```jnr -r[v]```
    

# General Wrokflow
1. (local machine): spawn a new process as shown above
2. The terminal automatically moves to the remote machine
3. (remote machine): start a jupyter notebook or lab with the aliases you set up when configuring RemoteJupyter on the remote machine for example with
	```jnr 8888``` which launches a jupyter notebook on port 8888"
4. (remote machine): copy the url that contains 'localhost'
5. (local machine): open a browser and paste the url
6. Do your work
7. (remote machine): Stop the notebook/lab by double tapping `ctrl-c`
8. optional (remote machine): exit
9. (local machine): kill the port forwarding process as shown above
