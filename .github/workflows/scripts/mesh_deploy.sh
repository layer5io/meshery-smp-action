MESH=$1

echo "Checking if mesheryctl is installed"
	
if mesheryctl
	
then
	echo "Found mesheryctl, deploying $MESH"
	mesheryctl mesh deploy $MESH
	
else
	printf "Mesheryctl not found. \nInstalling...\n"
	curl -L https://git.io/meshery | DEPLOY_MESHERY=false bash -
	echo "Installed mesheryctl successfully!"
	mesheryctl mesh deploy $MESH
	
fi






