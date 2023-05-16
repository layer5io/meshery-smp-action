#!/usr/bin/env bash

# This script is used to start a CNCF CIL runner 

token=$1
hostname=$2

# Use github.run_id as the lable of runner for scheduled benchmark test
# github.run_id is a unique number for each workflow run within a repository. 
label=$GITHUB_RUN_ID

hostname="$hostname-$label"
echo "Creating CNCF CIL machine: $hostname..."

# Use user_data_scripts to register the CNCF CIL runner as a self-hosted runner
user_data_scripts="#cloud-config\nusers:\n    - default\n    - name: smp\n      groups: sudo, docker\n      sudo: ALL=(ALL) NOPASSWD:ALL\n      lock_passwd: true\nruncmd:\n    - [runuser, -l, smp, -c, \'mkdir actions-runner && cd actions-runner\']\n    - [runuser, -l, smp, -c, \'curl -o actions-runner-linux-x64-2.287.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.287.1/actions-runner-linux-x64-2.287.1.tar.gz\']\n    - [runuser, -l, smp, -c, \'tar xzf ./actions-runner-linux-x64-2.287.1.tar.gz\']\n    - [runuser, -l, smp, -c, \'export RUNNER_ALLOW_RUNASROOT=1\']\n    - [runuser, -l, smp, -c, \'./config.sh --url https://github.com/$REPOSITORY --token $REG_TOKEN --labels $hostname >> github-action-registeration.log\']\n    - [runuser, -l, smp, -c, \'./run.sh >> github-action-registeration.log\']"

# TODO: the options "operating_system", "facility", "plan" are hardcoded now, we should make them configurable
# https://metal.equinix.com/developers/api/devices/#devices-createdevice
termination_time=`date --utc -d "110 minute" +"%FT%TZ"`
device_id=$(curl -X POST -H "X-Auth-Token: $token" -s -H "Content-Type: application/json" \
-d '{"operating_system": "ubuntu_20_04", "facility": "da11", "plan": "c3.small.x86", "hostname": "'"${hostname}"'", "userdata": "'"${user_data_scripts}"'", "termination_time": "'"${termination_time}"'"}' \
https://api.equinix.com/metal/v1/projects/96a9d336-541b-42f7-9827-d845010da550/devices | jq -r .id)
if [[ -z $device_id ]]; then
    echo "ERROR: Failed to create CNCF CIL machine: $hostname..."
    exit 1
fi

# Wait 10 minutes until the machine is running 
echo "Waiting for $hostname to run..."
n=0
while [[ $n -le 10 ]]
do
    if [[ $n -eq 10 ]]; then
        echo "Waiting too long for $hostname to start, exiting..."
        exit 1 
    fi
    sleep 1m
    state=$(curl -s -H "X-Auth-Token: $token" https://api.equinix.com/metal/v1/devices/$device_id | jq -r .state)
    if [[ $state == "active" ]]; then
        echo "$hostname successfully created!"
        break
    fi
    echo "Still waiting..."
    let n++
done

# Set the outputs
echo "::set-output name=hostname::$hostname"
echo "::set-output name=label::$hostname"
echo "::set-output name=device_id::$device_id"
