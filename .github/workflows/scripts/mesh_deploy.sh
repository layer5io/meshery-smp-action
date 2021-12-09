MESH=$1
MESHERYCTL="/usr/local/bin/mesheryctl"
echo "Checking if mesheryctl is installed"


if [ -f "${MESHERYCTL}" ]; then
    echo "Found mesheryctl, deploy $MESH"
	mesheryctl mesh deploy $MESH
   else
      printf "Mesheryctl not found. \nInstalling...\n"
	  curl -L https://git.io/meshery | DEPLOY_MESHERY=false bash -
	  echo "Installed mesheryctl successfully!"
	  mesheryctl mesh deploy $MESH
     
fi
