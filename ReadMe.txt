####################################################################################################################################
These scripts are made to be run on the client system that has NGC CLI installed.

NOTE: Your NGC CLI command that the script will ask for MUST have the --format_type json option at the end of it. 


To use these please execute launch_job.sh 
Note that logs will be created in the same folder as the scripts.
To watch logs please use tail -f $logName

Before launching these jobs please run:
	- chmod +x for all scripts
	- sed -i -e 's/\r$//' for all scripts

You will have a choice of either running in Demo or Prod mode. Functionally these are identical however, the demo script has shorter time outs so that you can test without long waits, The demo script will also relaunch jobs that are:
	KILLED BY USER
	KILLED BY ADMIN

So that you can test more easily. 


The production script will:

Leave jobs in the following states running indefinitely:
	CREATED
	PREEMPTED
	PREEMPTED_BY_ADMIN
	QUEUED
	RUNNING 

Kill and relaunch jobs that have been in the following states for => 30 minutes:
	PENDING_STORAGE_CREATION
	REQUESTING_RESOURCE
	RESOURCE_CONSUMPTION_REQUEST_IN_PROGRESS
	RESOURCE_GRANTED
	STARTING

Exit as successful when jobs are:
	CANCELED
	FINISHED_SUCCESS
	KILLED_BY_ADMIN
	KILLED_BY_USER

Relaunch jobs that are in any other state. 

####################################################################################################################################
