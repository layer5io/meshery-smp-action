#!/usr/bin/env bash

# This script is used to start a CNCF CIL runner

token=$1
device_id=$2
hostname=$3

echo "Removing CNCF CIL machine: $hostname..."

# https://metal.equinix.com/developers/api/devices/#devices-deletedevice
remove_cil_result=$(curl -X DELETE -I -s -w %{http_code} -o /dev/null -H "X-Auth-Token: $token" https://api.equinix.com/metal/v1/devices/$device_id)

if [[ $remove_cil_result != "204" ]]; then
    echo "ERROR: Failed to remove CNCF CIL machine: $hostname."
    exit 1
fi