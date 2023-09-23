#!/bin/bash

#Update the below with the Job Monitoring Script name
DemoMonitoringScript=track_job_demo_v1.2.sh
ProdMonitoringScript=track_job_prod_v1.2.sh

#Capture some basic information so we can create a log file
directory=$(pwd)
date=$(date +"%H:%M.%B.%d")
logFileName=$directory/$date.log
echo "$logFileName"
touch "$logFileName"


echo "####################################################################################"     | tee -a "$logFileName"
echo "##"                                                                                       | tee -a "$logFileName"
echo "##"                                                                                       | tee -a "$logFileName"
echo "##                 Welcome to our job monitoring utility."                                | tee -a "$logFileName"
echo "##"                                                                                       | tee -a "$logFileName"
echo "##  Use this utility to launch your DGX Cloud jobs from your linux workstation."          | tee -a "$logFileName"
echo "##"                                                                                       | tee -a "$logFileName"
echo "##  This utility will monitor your job and relaunch it if it fails"                       | tee -a "$logFileName"
echo "##      Your job will NOT be relaunched if it exits as:"                                  | tee -a "$logFileName"
echo "##                 - KILLED BY USER"                                                      | tee -a "$logFileName"
echo "##                 - KILLED BY ADMIN"                                                     | tee -a "$logFileName"
echo "##                 - CANCELED"                                                            | tee -a "$logFileName"
echo "##                 - FINISHED_SUCCESS"                                                    | tee -a "$logFileName"
echo "##"                                                                                       | tee -a "$logFileName"
echo "##  We will require your ngc command formatted as though you were using ngc cli"          | tee -a "$logFileName"
echo "##  Your NGC CLI command that the script will ask for MUST have the:"                     | tee -a "$logFileName"
echo "##                --format_type json"                                                     | tee -a "$logFileName"
echo "##  option at the end of it.  "                                                           | tee -a "$logFileName"
echo "##  If you are unsure of this command, please exit this script and use ngc --help"        | tee -a "$logFileName"
echo "##"                                                                                       | tee -a "$logFileName"
echo "##  You can choose to either run this script interactively or you can run it in the "     | tee -a "$logFileName"
echo "##  background and keep track of it using the logfile."                                   | tee -a "$logFileName"
echo "##"                                                                                       | tee -a "$logFileName"
echo "##  Your current logfile is $logFileName"                                                 | tee -a "$logFileName"
echo "##"                                                                                       | tee -a "$logFileName"
echo -n "##  Please enter 1 for interactive mode or 2 for background mode: "                    | tee -a "$logFileName"
read mode                                                                                       

#Check users mode choice is valid
if [[ $mode -le "0" || $mode -ge "3" ]]; then
   echo "## Please enter 1 for interactive or 2 for background mode"                            | tee -a "$logFileName"
   exit 1
fi

echo "##"
echo -n "##  Please enter 1 for DEMO mode or 2 for PRODUCTION: "                                | tee -a "$logFileName"
read script

#Check users script choice is valid and make it clear what we are executing. 
if [[ $script == "1" ]]; then
   echo "##"                                                                                    | tee -a "$logFileName"
   echo "##  ****************   Running in DEMO  mode   ***************"                        | tee -a "$logFileName"
   echo "##"                                                                                    | tee -a "$logFileName"
   echo "##  NOTE: In DEMO mode we will automatically relaunch jobs if they are:"               | tee -a "$logFileName"
   echo "##                 - KILLED BY USER"                                                   | tee -a "$logFileName"
   echo "##                 - KILLED BY ADMIN"                                                  | tee -a "$logFileName"
   echo "##  We will also check jobs in seconds, not minutes so you can observe behaviour quickly" | tee -a "$logFileName"
  
   monitoringScript=$DemoMonitoringScript
   echo "##  We will launch $monitoringScript"                                                  | tee -a "$logFileName"

elif [[ $script == "2" ]]; then
    echo "##"                                                                                   | tee -a "$logFileName"
    echo "##  ****************   Running in PRODUCTION  mode   ***************"                 | tee -a "$logFileName"
    
   monitoringScript=$ProdMonitoringScript
   
   echo "##  We will launch $monitoringScript"                                                  | tee -a "$logFileName"
   
else
    echo "##  You did not select 1 for DEMO or 2 for PRODUCTION"                                | tee -a "$logFileName"
    exit 1 
fi

echo "##"                                                                                       | tee -a "$logFileName"


#Check what mode we will run in.
   if [[ $mode == "1" ]]; then
    echo "##  Running in interactive mode"                                                      | tee -a "$logFileName"
    echo "##  Please enter your ngc command:"                                                   | tee -a "$logFileName"
    
    read user_command
    
    echo "## *******************************************************************************"   | tee -a "$logFileName"
    echo "##            This Job has been set to run the following command:"                    | tee -a "$logFileName"
    echo "##"                                                                                   | tee -a "$logFileName"
    echo "##    $user_command"                                                                  | tee -a "$logFileName"
    echo "##"                                                                                   | tee -a "$logFileName"
    echo "## *******************************************************************************"   | tee -a "$logFileName"
    echo "##"                                                                                   | tee -a "$logFileName"

    ./$monitoringScript "$logFileName" "$user_command"
    exit 0

   elif [[ $mode == "2" ]]; then
    echo "##  Running in background mode"                                                       | tee -a "$logFileName"
    echo "##  Please enter your ngc command:"                                                   | tee -a "$logFileName"

    read user_command
    
    echo "## *******************************************************************************"   | tee -a "$logFileName"
    echo "##            This Job has been set to run the following command:"                    | tee -a "$logFileName"
    echo "##"                                                                                   | tee -a "$logFileName"
    echo "##    $user_command"                                                                  | tee -a "$logFileName"
    echo "##"                                                                                   | tee -a "$logFileName"
    echo "## *******************************************************************************"   | tee -a "$logFileName"
    echo "##"                                                                                   | tee -a "$logFileName"


    ./$monitoringScript "$logFileName" "$user_command" > /dev/null 2>&1 &
    script_pid=$!
    
    echo "##  This scripts PID is: $script_pid"                                                 | tee -a "$logFileName"
    
    exit 0
   fi