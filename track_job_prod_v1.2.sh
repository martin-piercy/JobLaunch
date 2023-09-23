#!/bin/bash

#This works. Modified to use global sleep. Left previous work in. v1.1 to clean out unused code

#Accept variables passed to us from launch_job.sh
logFileName="$1"
user_command="$2"

echo "##"                                                                                   | tee -a "$logFileName"
echo "##"                                                                                   | tee -a "$logFileName"

# Submit the job and store the JSON output in a variable
eval "job_submit_output=\$($user_command)"


# Parse the JSON output to extract the the job id, its creation date, command run and name 
id=$(echo "$job_submit_output" | jq -r '.job.id')
createdDate=$(echo "$job_submit_output" | jq -r '.job.createdDate')
commandRun=$(echo "$job_submit_output" | jq -r '.job.jobDefinition.command')
name=$(echo "$job_submit_output" | jq -r '.job.jobDefinition.name')


# Print Job details in log
echo "## Your original job ID is: $id"                                                      | tee -a "$logFileName"
echo "## Your job Name is: $name"                                                           | tee -a "$logFileName"
echo "## Your original job was created on: $createdDate"                                    | tee -a "$logFileName"
echo "##"                                                                                   | tee -a "$logFileName"

#Main function to monitor and re-launch jobs
monitor_status(){
 while true; do

    #Global 5min sleep after start/checks/restarts.
    sleep 300s
    
    #Make sure we have the most up to date status before going into evaluation. 
    job_status_output="$(ngc batch info $id --format_type json)"

    # Parse the JSON output to extract the "id" and "name" values
    jobStatus=$(echo "$job_status_output" | jq -r '.job.jobStatus.status')

    #Lets check for jobs in a state that we are happy with, running, starting etc 
    if [[ "$jobStatus" == "RUNNING" || \
            "$jobStatus" == "STARTING" || \
            "$jobStatus" == "QUEUED" || \
            "$jobStatus" == "PENDING_STORAGE_CREATION" || \
            "$jobStatus" == "PREEMPTED" || \
            "$jobStatus" == "PREEMPTED_BY_ADMIN" || \
            "$jobStatus" == "REQUESTING_RESOURCE" || \
            "$jobStatus" == "RESOURCE_GRANTED" || \
            "$jobStatus" == "REQUESTING_RESOURCE" || \
            "$jobStatus" == "CREATED" ]]; then
        
     echo "## Running: Job $id is currently $jobStatus"                                      | tee -a "$logFileName"

     # Check if the job is in Starting || Pending etc state and has been so for 30 minutes
     elapsed_time=0
     max_elapsed_time=1800  # 1800, 30 minutes in seconds

        while [[ "$jobStatus" == "STARTING" || \
                 "$jobStatus" == "PENDING_STORAGE_CREATION" || \
                 "$jobStatus" == "REQUESTING_RESOURCE" || \
                 "$jobStatus" == "RESOURCE_GRANTED" || \
                 "$jobStatus" == "REQUESTING_RESOURCE" || \
                 "$jobStatus" == "CREATED" \
                  && $elapsed_time -lt $max_elapsed_time ]]; do

            #Check if max time reached:
            if [ $elapsed_time -ge $max_elapsed_time ]; then
                echo "## max job wait time reached $max_elapsed_time seconds"                   | tee -a "$logFileName"
            break
            fi
         
         # Sleep for 120 seconds in Prod       
         sleep 120s
         #Adding 3 seconds into elapsed time to account for sleep + time to query below - is 15 checks before timeout
         ((elapsed_time += 123))

         #Lets check the Job Status now we have waited. 
         job_status_output="$(ngc batch info $id --format_type json)"
         # Parse the JSON output to extract the "id" and "name" values
         jobStatus=$(echo "$job_status_output" | jq -r '.job.jobStatus.status')
        done

        # If the job is still in any of the below states after 30 minutes, lets kill and start again
        if [[ "$jobStatus" == "STARTING" || \
                "$jobStatus" == "PENDING_STORAGE_CREATION" || \
                "$jobStatus" == "REQUESTING_RESOURCE" || \
                "$jobStatus" == "RESOURCE_GRANTED" || \
                "$jobStatus" == "REQUESTING_RESOURCE" || \
                "$jobStatus" == "CREATED" \
                 && $elapsed_time -ge $max_elapsed_time ]]; then

            echo "##"                                                                               | tee -a "$logFileName"
            echo "## Job $id remained in $jobStatus state for >= 30 minutes. Proceeding to kill"    | tee -a "$logFileName"
            
            ngc batch kill $id
            
            echo "## Re-Submitting job."                                                            | tee -a "$logFileName"
            
            eval "job_resubmit_output=\$($user_command)"
            
            # Parse the JSON output of the re-submit to extract the "id" and "name" values
            id=$(echo "$job_resubmit_output" | jq -r '.job.id')
            name=$(echo "$job_resubmit_output" | jq -r '.job.jobDefinition.name')
            
            #Reset Elapsed time
            elapsed_time=0

            echo "##"                                                                               | tee -a "$logFileName"
            echo "## Job re-submitted with ID: $id"                                                 | tee -a "$logFileName"
            echo "##"                                                                               | tee -a "$logFileName"

        fi
    
     #In Prod env use the bellow. I have hidden Killed actions so we can demo the resubmit. 
    elif [[ "$jobStatus" == "CANCELED" || \
            "$jobStatus" == "FINISHED_SUCCESS" || \
            "$jobStatus" == "KILLED_BY_ADMIN" || \
            "$jobStatus" == "KILLED_BY_USER" ]]; then

     #Uncomment the below and comment out the above elif if you want to test resubmit by killing jobs
     #elif [[ "$jobStatus" == "CANCELED" || \
     #         "$jobStatus" == "FINISHED_SUCCESS" ]]; then 

        # Job manually killed or completed. Exiting script
        echo "##"                                                                                   | tee -a "$logFileName"
        echo "## Success!"                                                                          | tee -a "$logFileName"
        echo "## Job is in $jobStatus state. Now exiting."                                          | tee -a "$logFileName"
        
        exit 0

    else
     # Job is not happy so lets re-submit
        echo "##"                                                                                   | tee -a "$logFileName"                                                   
        echo "## Job was not running as expected, Job was in state $jobStatus"                      | tee -a "$logFileName"
        echo "##"
      
        echo "## Killing job $id"                                                                   | tee -a "$logFileName"
        ngc batch kill $id

        #Wait for a minute for job to clear 
        sleep 60s

        echo "## Executing a ReSubmit..."                                                           | tee -a "$logFileName"
        #Submit Job
        eval "job_resubmit_output=\$($user_command)"
        
        # Parse the JSON output of the re-submit to extract the "id" and "name" values
        id=$(echo "$job_resubmit_output" | jq -r '.job.id')
        name=$(echo "$job_resubmit_output" | jq -r '.job.jobDefinition.name')

        echo "##"                                                                                   | tee -a "$logFileName"
        echo "## Job re-submitted with ID: $id"                                                     | tee -a "$logFileName"
        echo "##"                                                                                   | tee -a "$logFileName"

    fi

  done
}

monitor_status