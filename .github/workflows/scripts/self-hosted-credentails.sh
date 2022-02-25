#!/usr/bin/env bash

# This script is used to configure and verify the token of self-hosted runner
# Token must be set as a github repo secret named "CNCF_CIL_TOKEN"

token=$1

# https://metal.equinix.com/developers/api/authentication/#authentication
result=$(curl -I -s -w %{http_code} -o /dev/null -H "X-Auth-Token: $token" https://api.equinix.com/metal/v1)
if [[ $result != "200" ]]; then
    echo "ERROR: Failed to authenticate the CNCF CIL token"
    exit 1
fi
echo "Authenticate CNCF CIL token sucessfully!"