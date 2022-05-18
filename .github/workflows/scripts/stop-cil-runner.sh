#!/usr/bin/env bash

# This script is used to stop a CNCF CIL runner

token=$1
hostname=$2
device_id=$3

if [[ -z $device_id ]]; then
    # If it's a scheduled benchmark test, we cannot get the orrespondence between hostname and
    # device_id from previous job, so we need to use hostname to retrive device_id
    device_id=$(curl -H "X-Auth-Token: $token " https://api.equinix.com/metal/v1/projects/96a9d336-541b-42f7-9827-d845010da550/devices?hostname=${hostname} | jq '.devices[] | {id}' | jq -r .id)
fi

echo "Removing CNCF CIL machine: $hostname, device id: $device_id..."
# https://metal.equinix.com/developers/api/devices/#devices-deletedevice
remove_cil_result=$(curl -X DELETE -I -s -w %{http_code} -o /dev/null -H "X-Auth-Token: $token" https://api.equinix.com/metal/v1/devices/$device_id)

if [[ $remove_cil_result != "204" ]]; then
    echo "ERROR: Failed to remove CNCF CIL machine: $hostname, device id: $device_id."
    exit 1
fi